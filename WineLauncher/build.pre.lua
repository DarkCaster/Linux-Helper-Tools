-- service script, define some stuuf for use with main build config

self=loader.extra[1]
profile=loader.extra[2]
prefix=loader.extra[3]
config=loader.extra[4]

prefix_addon=string.format('--prefix="%s"', prefix)

