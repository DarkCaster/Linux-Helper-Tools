-- example config for wine-launcher script.

-- some of extra helper global vars for use inside this config:
-- launcher_dir - directory, where all wine-launcger stuff installed
-- loader.args - indexed array, where all extra command line arguments is stored (starting from index 1)

-- prefix definition. mandatory
prefix =
{
	-- mandatory parameters:
	root = loader.path.combine(loader.workdir,"root"), -- root directory, where wine prefix will be created.
	-- optional parameters, applied on every launch and prefix create:
	arch = "win32", -- wine arch. will be exported as WINEARCH env variable, do not change after prefix created
	lang = "en_US.UTF-8",	-- override current env lang settings.
	-- wine = loader.workdir .. "winedist", -- path to wine installation. should be build and installed by wine-build.sh script
	wine = "/mnt/data/Wine/wine_distribs/wine185_suse421",
	docs = loader.path.combine(loader.workdir,"docs"), -- my documents folder(s) will be relinked to this path
	-- optional parameters, some of them will be only applied on prefix create:
	owner = "Penguinator", -- set owner
	org = "Iceberg.inc", -- set company
	menu = false, -- if set to false, it will override winemenubuilder so this prefix will not create or change xdg menus and entries at all
	-- create dll_overrides when perfix is setting up
	dll_overrides = -- dll's will be copied from user location to wine's system32 and overriden with selected rule
	{
		-- parameter format is { <override rule>, <dll source path>, <dll target file name without path>, [optional override name that entered to winecfg window, will be created automatically if missing] }
		winemp3 = { "native", loader.path.combine(loader.workdir,"extra","l3codecx.acm"), "winemp3.acm" },
		imm32 = { "native", loader.path.combine(loader.workdir,"extra","imm32.dll"), "imm32.dll" },
		glu32 = { "builtin,native", loader.path.combine(loader.workdir,"extra","glu32.dll"), "glu32.dll" },
		-- if source or target filename is missing, override name must be present. so, rule will be created, but nothing will be copied to wineprefix
		dnsapi = { "native,builtin", "", "", "dnsapi" },
	},
	-- TODO: drives configuration, custom deploy tasks and such stuff
}

-- tweaks. optional. will be applied on prefix create
-- may be reapplied if you run wine-launcher.sh with pseudoprofile "tweaks"
tweaks =
{
	-- path to winetricks script. it is mandatory for some tweaks to work
	-- download it from here: https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
	winetricks=loader.path.combine(loader.workdir,"extra","winetricks"),
	allfonts=false, -- if set to true, it will run winetricks allfonts that will download and install extra fonts
	fontsmooth="simple", -- none,simple,rgb,bgr; none - no smothing, simple - grayscale, rgb - cleartype rgb, bgr - cleartype bgr
}

-- exec profiles for configured prefix. at least one is mandatory
winecfg =
{
	-- command to run by this profile.
	run =
	{
		-- will be executed by wine-launcher using eval
		-- with all neccesary env setup for current prefix.
		-- so, you can freely use bash syntax, and combine commands together as you like.
		-- additionally, there are some helper bash functions, thay you may use:
		--     check_errors: will check last command status and perform exit if error code is not zero
		--     log <message>: will display (using echo) and log message (TODO: now it is only display message on screen)
		--
		-- first element - string: command to execute.
		"log \"starting winecfg at $PWD\"; winecfg",
		-- second element - string: optional path to set before performing exec. if omited, it will be set to "c:\windows\system32" dir inside prefix.
		prefix.root,
	},
    -- optional info for desktop file creator helper script.
	desktop =
	{
		name = "run winecfg", -- mandatory (if desktop section exist)
		comment = "winecfg for prefix at " .. prefix.root, -- optional
		icon = "wine-winecfg", -- optional
		categories = "", -- optional
		mimetype = "", -- optional
		terminal = false, -- optional
		startupnotify = false, -- optional
	},
}

-- run interactive shell with all needed env setup to start wine for current prefix
-- (try "winefile" or "wine regedit" commands for example)
shell = { run = { "bash" } }

-- run cmd.exe shell
cmd = { run = { "wine cmd.exe" } }

-- multiline bash syntax example
test = { run = { '\
log "pwd is $PWD" \
log "example" \
for i in 1 2 3 \
do \
 echo "$i" \
done \
false \
check_errors \
log "you should not see this!" \
',
"/",
 } }

