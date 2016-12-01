#!/usr/bin/lua

-- helper script basic logic:

-- parse cmdline args, save all internal state into loader lable for use inside user config scripts
-- TODO: define some basic config-script verification logic
-- ???
-- sequentially, execute lua scripts from remaining args
-- recursively iterate through global params, saving valid value contents to text files inside temp dir for later reuse inside bash scripts
-- profit!

-- storage for loader params
loader={}
loader["export"]={}

-- show usage
function loader_show_usage()
 print("usage: loader.lua <params>")
 print("")
 print("mandatory params:")
 print("-t <dir> : Temporary directory, where resulted global variables will be exported as text. It must exist.")
 print("-w <dir> : Work directory, may be reffered in used scripts as \"loader.workdir\"")
 print("-c <condif script path> : Main config script file.")
 print("-e <variable name> : Name of global variable, to be exported after script is run. You can specify multiple -e params. At least one must be specified.")
 print("")
 print("optional params:")
 print("-pre <script>: Optional lua script, executed before main config script. May contain some additional functions for use with main script. Non zero exit code aborts further execution.")
 print("-post <script>: Optional lua script, executed after main config script. May contain some some verification logic for use with main script. Non zero exit code aborts further execution.")
 os.exit(1)
end

function loader_param_set_check(par)
 if loader[par] ~= nil then
  print(string.format("param \"%s\" already set",par))
  print()
  loader_show_usage()
 end
end

function loader_param_not_set_check(par)
 if loader[par] == nil then
  print(string.format("param \"%s\" is not set",par))
  print()
  loader_show_usage()
 end
end

function loader_set_param (name, value)
 if name == nil then
  error(string.format("param \"%s\" is nil",name))
 end
 if value == nil then
  error(string.format("param \"%s\" is not set",name))
 end
 loader[name]=string.format("%s",value)
end

set=false
par="none"
exnum=-1

for i,ar in ipairs(arg) do
 if set == true then
  if par == "add_export" then
   loader.export[exnum]=string.format("%s",ar)
  else
   loader_set_param(par,ar)
  end
  set = false
 else
  if ar == "-t" then
   par="tmpdir"
  elseif ar == "-w" then
   par="workdir"
  elseif ar == "-c" then
   par="exec"
  elseif ar == "-pre" then
   par="preexec"
  elseif ar == "-post" then
   par="postexec"
  elseif ar == "-e" then
   par="add_export"
   exnum=exnum+1
  else
   print(string.format("incorrect parameter: %s",ar))
   print()
   loader_show_usage()
  end
  loader_param_set_check(par)
  set = true
 end
end

loader_param_not_set_check("tmpdir")
loader_param_not_set_check("workdir")
loader_param_not_set_check("exec")

if loader.export[0] == nil then
 print("at least one global variable name to export must be provided!")
 print()
 loader_show_usage()
end

-- unset non-needed defines

exnum=nil
set=nil
par=nil
loader_show_usage=nil
loader_param_set_check=nil
loader_param_not_set_check=nil
loader_set_param=nil

-- TODO: define some config verification logic

-- execute pre-script

if loader.preexec ~= nil then
 print("running preexec script")
 dofile(loader.preexec)
end

-- execute main script
print("running main config script")
dofile(loader.exec)

-- execute post-script
if loader.postexec ~= nil then
 print("running postexec script")
 dofile(loader.postexec)
end


