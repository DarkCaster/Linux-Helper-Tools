-- example config for wine-launcher script

-- prefix definition. mandatory
prefix =
{
	-- mandatory parameters:
	root = loader.workdir .. "root", -- root directory, where wine prefix will be created.
	-- optional parameters, applied on every launch and prefix create:
	arch = "win32", -- wine arch. will be exported as WINEARCH env variable, do not change after prefix created
	lang = "en_US.UTF-8",	-- override current env lang settings.
	-- wine = loader.workdir .. "winedist", -- path to wine installation. should be build and installed by wine-build.sh script
	wine = "/mnt/data/Wine/wine_distribs/wine185_suse421",
	docs = loader.workdir .. "docs", -- my documents folder(s) will be relinked to this path
	-- optional parameters, some of them will be only applied on prefix create:
	owner = "Penguinator", -- set owner
	org = "Iceberg.inc", -- set company
	menu = false, -- if set to false, it will override winemenubuilder so this prefix will not create or change xdg menus and entries at all
	dll_overrides = -- dll's will be copied from user location to wine's system32 and overriden with selected rule
	{
		-- parameter format is { <override rule>, <dll source path>, <dll target file name without path>, [optional override name that entered to winecfg window, will be created automatically if missing] }
		winemp3 = { "native", loader.workdir .. "l3codecx.acm", "winemp3.acm" },
		imm32 = { "native", loader.workdir .. "imm32.dll", "imm32.dll" },
		glu32 = { "builtin,native", loader.workdir .. "glu32.dll", "glu32.dll" },
		-- if source or target filename is missing, override name must be present. so, rule will be created, but nothing will be copied to wineprefix
		dnsapi = { "native,builtin", "", "", "dnsapi" },
	},
	-- TODO: drives configuration, custom deploy tasks and such stuff
}


