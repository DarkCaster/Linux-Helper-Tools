prefix =
{
	root = loader.path.combine(loader.workdir,"root"),
	arch = "win32",
	lang = "ru_RU.UTF-8",
	wine = "/mnt/data/Wine/wine_distribs/wine200rc3_suse421",
	docs = loader.path.combine(loader.workdir,"docs"),
	owner = "Penguinator",
	org = "Iceberg.inc",
	menu = false,
}

tweaks =
{
	winetricks=loader.path.combine(launcher.dir,"extra","winetricks"),
	allfonts=false,
	fontsmooth="simple",
}

winecfg = { run = { "winecfg" } }

shell = { run = { "bash" } }

cmd = { run = { "wine cmd.exe" } }

winetricks = { run = { tweaks.winetricks } }

control = { run = { "wine control" } }

ootake =
{
	run =
	{
		"wine Ootake.exe",
		loader.path.combine(prefix.root,"drive_c","Ootake")
	},
	desktop =
	{
		name = "Ootake",
		comment = "Ootake emulator",
		icon = loader.path.combine(loader.workdir,"turbografx.png"),
		categories = "Game;",
		terminal = false,
		startupnotify = false,
	},
}

ootake_custom =
{
	run =
	{
		loader.path.combine(loader.workdir,"mount-roms.sh") .. '\
		check_errors\
		wine Ootake.exe 1>"' .. loader.path.combine(loader.workdir,"ootake.log") ..'" 2>&1\
		' .. loader.path.combine(loader.workdir,"umount-roms.sh"),
		loader.path.combine(prefix.root,"drive_c","Ootake")
	},
	desktop =
	{
		name = "Ootake",
		comment = "Ootake emulator",
		icon = loader.path.combine(loader.workdir,"turbografx.png"),
		categories = "Game;",
		terminal = false,
		startupnotify = false,
	},
}

