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

    try archiveCreateDir(zip.?, entry.?, "minecraft/");
    try archiveCreateDir(zip.?, entry.?, "minecraft/mods/");

    const writer = ArchiveWriter{ .context = zip.? };

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
                try archiveCreateDir(zip.?, entry.?, path.ptr);
            },
            .File => {
                const path = try std.mem.concatWithSentinel(
                    std.heap.c_allocator,
                    u8,
                    &[_][]const u8{ "minecraft/", e.path },
                    0,
                );
                defer std.heap.c_allocator.free(path);
                var file = try overrides.openFile(e.path, .{});
                defer file.close();

                try archiveFile(
                    zip.?,
                    entry.?,
                    &buf,
                    path,
                    file,
                );
            },
            else => {},
        }
    }

    try installMmcPackJson(zip.?, entry.?);

    const instance_cfg_data = "InstanceType=OneSix";
    c.archive_entry_set_pathname(entry, "instance.cfg");
    c.archive_entry_set_size(entry, instance_cfg_data.len);
    try handleArchiveErr(c.archive_write_header(zip, entry), zip);
    try writer.writeAll(instance_cfg_data);

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

const ArchiveWriter = std.io.Writer(
    *c.archive,
    error{ArchiveError},
    writeArchive,
);

fn writeArchive(archive: *c.archive, bytes: []const u8) error{ArchiveError}!usize {
    const result = c.archive_write_data(archive, bytes.ptr, bytes.len);
    if (result < 0) {
        try handleArchiveErr(result, archive);
    }
    return @intCast(usize, result);
}

fn archiveFile(
    archive: *c.archive,
    entry: *c.archive_entry,
    buf: []u8,
    name: [*c]const u8,
    file: std.fs.File,
) !void {
    entrySetFile(entry);
    c.archive_entry_set_pathname(entry, name);
    c.archive_entry_set_size(entry, @intCast(i64, (try file.stat()).size));
    try handleArchiveErr(c.archive_write_header(archive, entry), archive);

    const writer = ArchiveWriter{ .context = archive };
    var read = try file.read(buf);
    while (read != 0) {
        try writer.writeAll(buf[0..read]);
        read = try file.read(buf);
    }
}

/// `name` must end with '/'!
fn archiveCreateDir(
    archive: *c.archive,
    entry: *c.archive_entry,
    name: [*c]const u8,
) !void {
    entrySetDir(entry);
    c.archive_entry_set_pathname(entry, name);
    try handleArchiveErr(c.archive_write_header(archive, entry), archive);
}

fn installMmcPackJson(archive: *c.archive, entry: *c.archive_entry) !void {
    const Requires = struct {
        uid: []const u8,
        equals: ?[]const u8 = null,
        suggests: ?[]const u8 = null,
    };

    const Component = struct {
        cachedName: []const u8,
        cachedRequires: ?[]const Requires = null,
        cachedVersion: []const u8,
        cachedVolatile: ?bool = null,
        dependencyOnly: ?bool = null,
        important: ?bool = null,
        uid: []const u8,
        version: []const u8,
    };

    const data = .{
        .components = &[_]Component{
            .{
                .cachedName = "LWJGL 3",
                .cachedVersion = "3.2.2",
                .cachedVolatile = true,
                .dependencyOnly = true,
                .uid = "org.lwjgl3",
                .version = "3.2.2",
            },
            .{
                .cachedName = "Minecraft",
                .cachedRequires = &.{
                    .{
                        .uid = "org.lwjgl3",
                        .suggests = "3.2.2",
                    },
                },
                .cachedVersion = settings.minecraft_version,
                .important = true,
                .uid = "net.minecraft",
                .version = settings.minecraft_version,
            },
            .{
                .cachedName = "Intermediary Mappings",
                .cachedRequires = &.{
                    .{
                        .equals = settings.minecraft_version,
                        .uid = "net.minecraft",
                    },
                },
                .cachedVersion = settings.minecraft_version,
                .cachedVolatile = true,
                .dependencyOnly = true,
                .uid = "net.fabricmc.intermediary",
                .version = settings.minecraft_version,
            },
            .{
                .cachedName = "Fabric Loader",
                .cachedRequires = &.{
                    .{
                        .uid = "net.fabricmc.intermediary",
                    },
                },
                .cachedVersion = settings.fabric_loader_version,
                .uid = "net.fabricmc.fabric-loader",
                .version = settings.fabric_loader_version,
            },
        },
        .formatVersion = 1,
    };

    // We run the serializer twice, because we need to know the size ahead of time for zip.
    // This is faster than allocating the json on the heap.
    var counter = std.io.countingWriter(std.io.null_writer);
    try std.json.stringify(
        data,
        .{ .emit_null_optional_fields = false },
        counter.writer(),
    );

    entrySetFile(entry);
    c.archive_entry_set_size(entry, @intCast(i64, counter.bytes_written));
    c.archive_entry_set_pathname(entry, "mmc-pack.json");
    try handleArchiveErr(c.archive_write_header(archive, entry), archive);

    try std.json.stringify(
        data,
        .{ .emit_null_optional_fields = false },
        ArchiveWriter{ .context = archive },
    );
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

    const writer = ArchiveWriter{ .context = zip };
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
        try writer.writeAll(mod_buf.items);
        std.io.getStdOut().writer().print(
            "\x1b[2K\r\x1b[34m{s}\n",
            .{filename.?},
        ) catch {};
    }
}

fn entrySetDir(entry: *c.archive_entry) void {
    c.archive_entry_set_filetype(entry, c.S_IFDIR);
    c.archive_entry_set_perm(entry, 0o755);
    c.archive_entry_unset_size(entry);
}

fn entrySetFile(entry: *c.archive_entry) void {
    c.archive_entry_set_filetype(entry, c.S_IFREG);
    c.archive_entry_set_perm(entry, 0o644);
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
