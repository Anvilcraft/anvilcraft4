# Anvilcraft 4
The 4th pack of the Anvilcraft series!

## Building
First, Install the dependencies required for compilation:
- zig (master version)
- libcurl
- libarchive

Arch:
```bash
paru -S \
    zig-git \
    curl \
    libarchive
```

Debian:
```bash
apt install \
    libcurl4-openssl-dev \
    libarchive-dev
# install zig manually
```

Run the  build script:
```bash
./build.zig
```
