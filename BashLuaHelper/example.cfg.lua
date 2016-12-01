-- load this config script and execute with bash helper (or loader.lua)
config =
{
	value="some text there",
	sub=
	{
		number1=123,
		number2="123",
		string="123x",
	},
	paths=
	{
		tempdir=loader.tmpdir,
		workdir=loader.workdir,
		dynpath=loader.workdir .. loader.slash .. "file"
	}
}

