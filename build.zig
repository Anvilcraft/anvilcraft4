//usr/bin/env zig run $0 -lc `pkgconf --libs libarchive libcurl`; exit
// This script requires a zig compiler, libarchive and libcurl to run.
// If you're on windows, screw you lol

const std = @import("std");
const c = @cImport({
    @cInclude("curl/curl.h");
    @cInclude("archive.h");
    @cInclude("archive_entry.h");
});
const settings = @import("settings.zig");

pub fn main() !void {
    // used to buffer whatever
    var buf: [512]u8 = undefined;
    try std.fs.cwd().deleteTree(settings.build_dir);
    try std.fs.cwd().makeDir(settings.build_dir);

    var zip = c.archive_write_new();
    if (zip == null)
        return error.ArchiveNewError;
    defer _ = c.archive_write_free(zip);
    try handleArchiveErr(c.archive_write_set_format_zip(zip), zip);
    try handleArchiveErr(c.archive_write_set_format_option(
        zip,
        "zip",
        "compression-level",
        settings.compression_level,
    ), zip);
    try handleArchiveErr(c.archive_write_open_filename(
        zip,
        settings.build_dir ++ "/ac4-" ++ settings.version ++ ".zip",
    ), zip);

    var entry = c.archive_entry_new();
    defer c.archive_entry_free(entry);
    entrySetDir(entry.?);
    c.archive_entry_set_size(entry, 0);
    c.archive_entry_set_pathname(entry, "minecraft/");
    try handleArchiveErr(c.archive_write_header(zip, entry), zip);
    c.archive_entry_set_pathname(entry, "minecraft/mods/");
    try handleArchiveErr(c.archive_write_header(zip, entry), zip);

    var overrides = try std.fs.cwd().openDir("overrides", .{ .iterate = true });
    defer overrides.close();
    var walker = try overrides.walk(std.heap.c_allocator);
    defer walker.deinit();

    while (try walker.next()) |e| {
        switch (e.kind) {
            .Directory => {
                const path = try std.mem.concat(
                    std.heap.c_allocator,
                    u8,
                    &[_][]const u8{ "minecraft/", e.path, "/\x00" },
                );
                defer std.heap.c_allocator.free(path);
                entrySetDir(entry.?);
                c.archive_entry_set_pathname(entry, path.ptr);
                try handleArchiveErr(c.archive_write_header(zip, entry), zip);
            },
            .File => {
                var file = try overrides.openFile(e.path, .{});
                const stat = try file.stat();
                entrySetFile(entry.?);
                c.archive_entry_set_size(entry, @intCast(i64, stat.size));
                const path = try std.mem.concatWithSentinel(
                    std.heap.c_allocator,
                    u8,
                    &[_][]const u8{ "minecraft/", e.path },
                    0,
                );
                defer std.heap.c_allocator.free(path);
                c.archive_entry_set_pathname(entry, path);
                try handleArchiveErr(c.archive_write_header(zip, entry), zip);

                var read = try file.read(&buf);
                while (read != 0) {
                    _ = c.archive_write_data(zip, &buf, read);
                    read = try file.read(&buf);
                }
            },
            else => {},
        }
    }

    entrySetFile(entry.?);
    var file = try std.fs.cwd().openFile("mmc-pack.json", .{});
    c.archive_entry_set_pathname(entry, "mmc-pack.json");
    c.archive_entry_set_size(entry, @intCast(i64, (try file.stat()).size));
    try handleArchiveErr(c.archive_write_header(zip, entry), zip);

    var read = try file.read(&buf);
    while (read != 0) {
        _ = c.archive_write_data(zip, &buf, read);
        read = try file.read(&buf);
    }

    const instance_cfg_data = "InstanceType=OneSix";
    c.archive_entry_set_pathname(entry, "instance.cfg");
    c.archive_entry_set_size(entry, instance_cfg_data.len);
    try handleArchiveErr(c.archive_write_header(zip, entry), zip);
    _ = c.archive_write_data(
        zip,
        instance_cfg_data,
        instance_cfg_data.len,
    );

    var mods_arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer mods_arena.deinit();
    var mods = std.ArrayList([]u8).init(std.heap.c_allocator);
    defer mods.deinit();

    readMods(&mods, mods_arena.allocator()) catch |err| {
        std.log.err("Error reading mods.txt", .{});
        return err;
    };

    downloadMods(mods.items, zip.?, entry.?) catch |err| {
        std.log.err("Error downloading mods", .{});
        return err;
    };

    try handleArchiveErr(c.archive_write_close(zip), zip);
}

fn readMods(list: *std.ArrayList([]u8), alloc: std.mem.Allocator) !void {
    var file = try std.fs.cwd().openFile("mods.txt", .{});
    defer file.close();
    var line_buf: [1024]u8 = undefined;

    while (try file.reader().readUntilDelimiterOrEof(&line_buf, '\n')) |line| {
        // mods.txt has comments with "#"
        const line_without_comment = std.mem.sliceTo(line, '#');
        const trimmed_line = std.mem.trim(u8, line_without_comment, "\n\r\t ");
        if (trimmed_line.len != 0) {
            try list.append(try alloc.dupe(u8, trimmed_line));
        }
    }
}

fn curlWriteCallback(
    data: [*]const u8,
    size: usize,
    nmemb: usize,
    out: *std.ArrayList(u8),
) callconv(.C) usize {
    const realsize = size * nmemb;
    out.writer().writeAll(data[0..realsize]) catch return 0;
    return realsize;
}

fn curlInfoCallback(
    filename: *[]const u8,
    dltotal: c.curl_off_t,
    dlnow: c.curl_off_t,
    ultotal: c.curl_off_t,
    ulnow: c.curl_off_t,
) callconv(.C) usize {
    _ = ultotal;
    _ = ulnow;
    std.io.getStdOut().writer().print(
        "\x1b[2K\r\x1b[34m{s} \x1b[32m{}%",
        .{
            filename.*,
            if (dltotal != 0) @divTrunc(dlnow * 100, dltotal) else 0,
        },
    ) catch {};
    return 0;
}

fn downloadMods(
    mods: []const []const u8,
    zip: *c.archive,
    entry: *c.archive_entry,
) !void {
    var curl = c.curl_easy_init();
    if (curl == null)
        return error.CurlInitError;
    defer c.curl_easy_cleanup(curl);

    try handleCurlErr(c.curl_easy_setopt(
        curl,
        c.CURLOPT_WRITEFUNCTION,
        curlWriteCallback,
    ));
    try handleCurlErr(c.curl_easy_setopt(
        curl,
        c.CURLOPT_XFERINFOFUNCTION,
        curlInfoCallback,
    ));
    try handleCurlErr(c.curl_easy_setopt(curl, c.CURLOPT_NOPROGRESS, @as(c_long, 0)));
    try handleCurlErr(c.curl_easy_setopt(curl, c.CURLOPT_FOLLOWLOCATION, @as(c_long, 1)));

    var mod_buf = std.ArrayList(u8).init(std.heap.c_allocator);
    defer mod_buf.deinit();
    defer std.io.getStdOut().writeAll("\x1b[0\n") catch {};
    for (mods) |mod| {
        mod_buf.clearRetainingCapacity();
        var splits = std.mem.split(u8, mod, "/");
        var filename: ?[]const u8 = null;
        while (splits.next()) |split|
            filename = split;

        if (filename == null or filename.?.len == 0) {
            std.log.err("Failed to get filename of URL {s}", .{mod});
            return error.BorkedUrl;
        }

        try handleCurlErr(c.curl_easy_setopt(curl, c.CURLOPT_WRITEDATA, &mod_buf));
        try handleCurlErr(c.curl_easy_setopt(curl, c.CURLOPT_XFERINFODATA, &filename));
        try handleCurlErr(c.curl_easy_setopt(curl, c.CURLOPT_XFERINFODATA, &filename));

        const mod_cstr = try std.cstr.addNullByte(std.heap.c_allocator, mod);
        defer std.heap.c_allocator.free(mod_cstr);

        try handleCurlErr(c.curl_easy_setopt(
            curl,
            c.CURLOPT_URL,
            @ptrCast([*c]const u8, mod_cstr),
        ));
        try handleCurlErr(c.curl_easy_perform(curl));

        std.io.getStdOut().writer().print(
            "\x1b[2K\r\x1b[34m{s} \x1b[31mZipping...",
            .{filename.?},
        ) catch {};

        const file_cstr = try std.cstr.addNullByte(std.heap.c_allocator, filename.?);
        defer std.heap.c_allocator.free(file_cstr);

        var archive_path = try std.mem.concatWithSentinel(
            std.heap.c_allocator,
            u8,
            &[_][]const u8{ "minecraft/mods/", file_cstr },
            0,
        );
        defer std.heap.c_allocator.free(archive_path);

        c.archive_entry_set_pathname(entry, archive_path.ptr);
        c.archive_entry_set_size(entry, @intCast(i64, mod_buf.items.len));
        try handleArchiveErr(c.archive_write_header(zip, entry), zip);
        _ = c.archive_write_data(
            zip,
            mod_buf.items.ptr,
            mod_buf.items.len,
        );
        std.io.getStdOut().writer().print(
            "\x1b[2K\r\x1b[34m{s}\n",
            .{filename.?},
        ) catch {};
    }
}

fn entrySetDir(entry: *c.archive_entry) void {
    c.archive_entry_set_mode(entry, c.S_IFDIR | 0777);
    c.archive_entry_set_size(entry, 0);
}

fn entrySetFile(entry: *c.archive_entry) void {
    c.archive_entry_set_mode(entry, c.S_IFREG | 0777);
}

fn handleCurlErr(code: c.CURLcode) !void {
    if (code != c.CURLE_OK) {
        std.log.err("Curl error: {s}", .{c.curl_easy_strerror(code)});
        return error.CurlError;
    }
}

fn handleArchiveErr(err: anytype, archive: ?*c.archive) !void {
    if (err != c.ARCHIVE_OK) {
        if (archive) |ar| {
            if (c.archive_error_string(ar)) |err_s|
                std.log.err("Archive error: {s}", .{err_s});
        }
        return error.ArchiveError;
    }
}
