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
	pulseaudio_71=
	{
		src={type="wget-tarxz", link="http://www.freedesktop.org/software/pulseaudio/releases/pulseaudio-7.1.tar.xz"},
		build_seq=
		{
			prepare=
			{
				'mkdir "gccld"',
				'ln -s /usr/lib/libjson-c.so.2 ./gccld/libjson-c.so',
				'ln -s /usr/lib/libsndfile.so.1 ./gccld/libsndfile.so',
				'export CXXFLAGS="-O2 -m32 -Wl,--no-warn-search-mismatch -I'.. prefix ..'/include"',
				'export CPPFLAGS="-m32 -Wl,--no-warn-search-mismatch -I'.. prefix ..'/include"',
				'export CFLAGS="-O2 -m32 -Wl,--no-warn-search-mismatch -I'.. prefix ..'/include"',
				'export LDFLAGS="-m32 -L$PWD/gccld -L/usr/lib -L/lib -L'.. prefix ..'/lib"',
				'export LIBS="-m32 -L$PWD/gccld -L/usr/lib -L/lib -L'.. prefix ..'/lib"',
				'export LIBJSON_LIBS="-m32 -L$PWD/gccld -L/usr/lib -ljson-c"',
				'export LIBJSON_CFLAGS="-m32 -I/usr/include/json-c"',
				'export LIBSNDFILE_LIBS="-m32 -L$PWD/gccld -L/usr/lib -lsndfile"',
				'export LIBSNDFILE_CFLAGS="-m32 -I/usr/include"',
				'export GLIB20_LIBS="-m32 -L$PWD/gccld -L/usr/lib"',
				'export GLIB20_CFLAGS="-m32 -I/usr/include/glib-2.0 -I/usr/lib64/glib-2.0/include"',
				'export UDEV_LIBS="-m32 -L$PWD/gccld -L/usr/lib"',
				'export UDEV_CFLAGS="-m32 -I/usr/include"',
				--'export LIBSOXR_LIBS="-L/usr/lib"',
				--'export PKG_CONFIG_PATH="/usr/lib/pkgconfig"',
				--'export PKG_CONFIG_LIBDIR="/usr/lib/pkgconfig"',
				--'export LD="ld -melf_i386"',
				--'export CCLD="gcc"',
			},
			configure=
			{
				"./configure --disable-static --enable-shared --enable-alsa --disable-x11 --disable-tests --disable-oss-output --disable-oss-wrapper --disable-coreaudio-output --disable-esound --disable-solaris --disable-waveout --disable-gtk3 --disable-gconf --disable-avahi --disable-jack --disable-asyncns --disable-tcpwrap --disable-lirc --disable-bluez4 --disable-bluez5 --disable-bluez5-ofono-headset --disable-bluez5-native-headset --disable-hal-compat --disable-ipv6 --disable-openssl --disable-xen --disable-orc --disable-systemd-daemon --disable-systemd-login --disable-systemd-journal --disable-manpages --disable-per-user-esound-socket --disable-default-build-tests --disable-legacy-database-entry-format --disable-udev --without-caps --with-database=simple --without-fftw --without-speex --without-soxr " .. prefix_addon,
				'echo "configure complete"',
			},
			make=build_seq.make,
			install=build_seq.install,
		},
	},

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

