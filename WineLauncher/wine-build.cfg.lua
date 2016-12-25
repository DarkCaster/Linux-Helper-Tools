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

custom_configure={ "./configure --without-capi --without-cms --without-coreaudio --without-cups --without-curses --without-hal " .. prefix_addon, 'echo "configure complete"' }

profiles=
{
	libmpg123=
	{
		src=
		{
			-- wget-tarbz2, local
			type="wget-tarbz",
			link="https://www.mpg123.de/download/mpg123-1.23.8.tar.bz2",
			-- optional
			sign="https://www.mpg123.de/download/mpg123-1.23.8.tar.bz2.sig",
		},
		build_seq={ prepare={ 'export CXXFLAGS="-m32"', 'export CPPFLAGS="-m32"', 'export CFLAGS="-m32"', 'export LDFLAGS="-m32"' }, make=build_seq.make, install=build_seq.install,
			configure={ "./configure --with-audio=alsa --with-default-audio=alsa --with-cpu=i586_dither --enable-shared --disable-static " .. prefix_addon, 'echo "configure complete"' },
		},
	},

	wine_1755=
	{
		src=
		{
			-- wget-tarbz2, local
			type="wget-tarbz",
			link="https://dl.winehq.org/wine/source/1.7/wine-1.7.55.tar.bz2",
			-- optional
			sign="https://dl.winehq.org/wine/source/1.7/wine-1.7.55.tar.bz2.sign",
		},
		build_seq={ prepare=build_seq.prepare, make=build_seq.make, install=build_seq.install, configure=custom_configure },
	},

	wine_186=
	{
		src=
		{
			-- wget-tarbz2, local
			type="wget-tarbz",
			link="https://dl.winehq.org/wine/source/1.8/wine-1.8.6.tar.bz2",
			-- optional
			sign="https://dl.winehq.org/wine/source/1.8/wine-1.8.6.tar.bz2.sign",
		},
		build_seq={ prepare=build_seq.prepare, make=build_seq.make, install=build_seq.install, configure=custom_configure },
	},

	wine_200rc3=
	{
		src=
		{
			-- wget-tarbz2, local
			type="wget-tarbz",
			link="https://dl.winehq.org/wine/source/2.0/wine-2.0-rc3.tar.bz2",
			-- optional
			sign="https://dl.winehq.org/wine/source/2.0/wine-2.0-rc3.tar.bz2.sign",
		},
		build_seq={ prepare=build_seq.prepare, make=build_seq.make, install=build_seq.install, configure=custom_configure },
	},

	wine_200rc3_mp3=
	{
		src=
		{
			-- wget-tarbz2, local
			type="wget-tarbz",
			link="https://dl.winehq.org/wine/source/2.0/wine-2.0-rc3.tar.bz2",
			-- optional
			sign="https://dl.winehq.org/wine/source/2.0/wine-2.0-rc3.tar.bz2.sign",
		},
		build_seq=
		{
			prepare=
			{
				string.format("\"%s\" \"%s\" \"%s\" \"%s\"", self, "libmpg123", prefix, config),
				'export CXXFLAGS="-I'.. prefix ..'/include"',
				'export CPPFLAGS="-I'.. prefix ..'/include"',
				'export CFLAGS="-I'.. prefix ..'/include"',
				'export LDFLAGS="-L'.. prefix ..'/lib"',
				'./tools/make_requests'
			},
			configure=custom_configure,
			make=build_seq.make,
			install=build_seq.install,
		},
	},
}

