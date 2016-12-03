-- load this config script and execute with bash helper (or loader.lua)

loader.log("message from main config script")

config =
{
	value="some text there",
	sub=
	{
		number1=123,
		number2="123",
		string="123x",
		multiline_string="line1\nline2\nline3",
		non_latin_string="Съешь еще этих мягких мексиканских кактусов, да выпей текилы",
		problematic_string=" $ $$ & && \\ \\\\ ! !! [ [[ ] ]] ( (( ) )) ' '' \" \"\" ` `` \\n \\t \\r / // ? ?? !"
	},
	paths=
	{
		tempdir=loader.tmpdir,
		workdir=loader.workdir,
		dynpath=loader.workdir .. loader.slash .. "file"
	}
}

