-- service script, try save selected profile to "build" global var

build=profiles[profile]

assert(type(build) == "table", "build profile is incorrect")
assert(type(build.src) == "table", "src value is missing or invalid")
assert(type(build.src.link) == "string", "src_link value is missing or invalid")
assert(type(build.src.sign) == "nil" or type(build.src.sign) == "string", "src.sign value is missing or invalid")
assert(build.src.type == "wget-tarbz" or build.src.type == "local", "src_get value is incorrect")

assert(type(build.build_seq) == "table", "build_seq value is missing or invalid")
assert(type(build.build_seq.prepare) == "table", "build_seq.prepare value is missing or invalid")
assert(type(build.build_seq.configure) == "table", "build_seq.configure value is missing or invalid")
assert(type(build.build_seq.make) == "table", "build_seq.make value is missing or invalid")
assert(type(build.build_seq.install) == "table", "build_seq.install value is missing or invalid")


