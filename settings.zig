/// Version number used for the archive name
pub const version = "1.4.1";
pub const build_dir = "build";
pub const minecraft_version = "1.18.2";
pub const fabric_loader_version = "0.14.8";
/// the data for the `instance.cfg` file
pub const instance_cfg_data =
    \\InstanceType=OneSix
;
/// zip compression level. 9 is max. ask libarchive why this is a string.
pub const compression_level = "9";
