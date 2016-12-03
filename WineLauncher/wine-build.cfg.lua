-- extra defines (in addition to loader.*), that can be used in config:
-- prefix - path, where wine should be installed, should be used in build process
-- prefix_addon - string "--prefix=<prefix>", intended for use with configure script

build_seq=
{
	prepare = { "./tools/make_requests" },
	configure = { "./configure " .. prefix_addon, 'echo "configure complete"' },
	make = { "make" },
	install = { "make install" },
}

profiles=
{
	wine_185_suse421=
	{
		-- wget, local
		src_get="wget",
		src_link="https://dl.winehq.org/wine/source/1.8/wine-1.8.5.tar.bz2",
		-- optional
		sign_link="https://dl.winehq.org/wine/source/1.8/wine-1.8.5.tar.bz2.sign",
		build_seq={ prepare = build_seq.prepare, make=build_seq.make, install=build_seq.install,
			configure = { "./configure --without-capi --without-cms --without-coreaudio --without-cups --without-curses --without-hal" .. prefix_addon, 'echo "configure complete"' },
		},
	},
}

