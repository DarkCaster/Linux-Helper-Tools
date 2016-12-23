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
	wine_186_suse421=
	{
		src=
		{
			-- wget-tarbz2, local
			type="wget-tarbz",
			link="https://dl.winehq.org/wine/source/1.8/wine-1.8.6.tar.bz2",
			-- optional
			sign="https://dl.winehq.org/wine/source/1.8/wine-1.8.6.tar.bz2.sign",
		},
		build_seq={ prepare=build_seq.prepare, make=build_seq.make, install=build_seq.install,
			configure={ "./configure --without-capi --without-cms --without-coreaudio --without-cups --without-curses --without-hal " .. prefix_addon, 'echo "configure complete"' },
		},
	},

	wine_200rc3_suse421=
	{
		src=
		{
			-- wget-tarbz2, local
			type="wget-tarbz",
			link="https://dl.winehq.org/wine/source/2.0/wine-2.0-rc3.tar.bz2",
			-- optional
			sign="https://dl.winehq.org/wine/source/2.0/wine-2.0-rc3.tar.bz2.sign",
		},
		build_seq={ prepare=build_seq.prepare, make=build_seq.make, install=build_seq.install,
			configure={ "./configure --without-capi --without-cms --without-coreaudio --without-cups --without-curses --without-hal " .. prefix_addon, 'echo "configure complete;"', "read" },
		},
	},
}

