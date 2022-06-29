# Anvilcraft 4
The 4th pack of the Anvilcraft series!

## Building
First, Install the dependencies required for compilation:
- zig (master version)
- haxe
- libcurl
- libarchive

Arch:
```bash
paru -S \
    zig-git \
    haxe \
    curl \
    libarchive
```

Debian:
```bash
apt install \
    haxe \
    libcurl4-openssl-dev \
    libarchive-dev
# install zig manually
```

Install `kubejs-haxe`:
```bash
haxelib install kubejs
```

Run the  build script:
```bash
./build.zig
```
