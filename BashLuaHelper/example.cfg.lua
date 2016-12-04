-- load this config script and execute with bash helper (or loader.lua)

loader.log("message from main config script")

config =
{
	value="this variable is not selected for export, see example.bash for details",
	sub=
	{
		number1=123,
		number2="123",
		string="123x",
		multiline_string="line1\nline2\nline3",
		non_latin_string="Съешь еще этих мягких мексиканских кактусов, да выпей текилы",
		problematic_string=" $ $$ & && \\ \\\\ ! !! [ [[ ] ]] ( (( ) )) ' '' \" \"\" ` `` \\n \\t \\r / // ? ?? !",
		sub=
		{
			message="another message",
		},
	},
	paths=
	{
		tempdir=loader.tmpdir,
		workdir=loader.workdir,
		dynpath=loader.workdir .. "file",
		tempdir_raw=loader.tmpdir_raw,
		workdir_raw=loader.workdir_raw,
		dynpath_raw=loader.workdir_raw .. loader.slash .. "file",
	}
}

-- add yet another value
config.sub.sub.message2="yet " .. config.sub.sub.message

