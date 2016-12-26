-- extract filename
prefix =
{
	root = loader.path.combine(loader.workdir,"root"),
	arch = "win32",
	lang = "en_US.UTF-8",
	wine = "/mnt/data/Wine/wine_distribs/wine200rc3_suse421",
	docs = loader.path.combine(loader.workdir,"docs"),
	owner = "Penguinator",
	org = "Iceberg.inc",
	menu = false,
}

tweaks =
{
	winetricks=loader.path.combine(launcher.dir,"extra","winetricks"),
	allfonts=true,
	fontsmooth="simple",
}

winecfg = { run = { "winecfg" } }

shell = { run = { "bash" } }

cmd = { run = { "wine cmd.exe" } }

winetricks = { run = { tweaks.winetricks } }

control = { run = { "wine control" } }

notepadpp =
{
	run =
	{
		launcher.gen_filename_from_args() .. " \
		wine \"C:\\Program Files\\Notepad++\\notepad++\" \"$filename\"",
		launcher.pwd,
	},

	desktop =
	{
		name = "notepad++",
		comment = "notepad++ text editor",
		icon = loader.path.combine(loader.workdir,"notepad++.1.png"),
		categories = "Utility;TextEditor;",
		mimetype = "text/*",
		terminal = false,
		startupnotify = false,
	},
}

