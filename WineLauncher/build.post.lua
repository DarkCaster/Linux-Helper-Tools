-- service script, try save selected profile to "build" global var

build=profiles[profile]

assert(type(build) ~= "nil", "build profile is incorrect")
assert(build.src_get == "wget" or build.src_get == "local", "src_get value is incorrect")

