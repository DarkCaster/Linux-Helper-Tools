#!/usr/bin/env lua

-- Copyright (c) 2016 DarkCaster, MIT License, see https://github.com/DarkCaster/Linux-Helper-Tools for more info

-- helper script basic logic:

-- parse cmdline args, save all internal state into loader lable for use inside user config scripts
-- TODO: add logic, that perform verification of config variables passed with -e options, and explicitly transform it to one format (for example: root.sub1.sub2.value)
-- TODO: define some basic config-script verification logic
-- ???
-- sequentially, execute lua scripts from remaining args
-- recursively iterate through global params, saving valid value contents to text files inside temp dir for later reuse inside bash scripts
-- profit!

-- storage for loader params
loader={}
loader["export"]={}
loader["extra"]={}
loader["args"]={}
loader.pathseparator=package.config:sub(1,1)
loader.slash=loader.pathseparator

-- logging
function loader.log(...)
 local msg = string.format(...)
-- TODO: create more advanced logging
 print(msg)
end

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
 print("-ext <string>: You may pass multiple -ext params. Add extra string and store it inside loader.extra table (indexed by number, starting from 1). You can refer loader.extra elements in your config/pre/post scripts")
 print("-- mark completion of option list for this script. all remaining options will be stored in loader.args starting from index 1")
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

function loader_set_dir (name, value)
 -- original not processed dir
 loader_set_param(name .. "_raw",value)
 -- check last character in dir, add path separator if missing
 if string.sub(value, -1, -1) == loader.slash then
  loader_set_param(name,value)
 else
  loader_set_param(name,value .. loader.slash)
 end
end

set=false
par="none"
export_cnt=0
extra_cnt=0
args_cnt=0

for i,ar in ipairs(arg) do
 if set == true then
  if par == "add_args" then
   args_cnt=args_cnt+1
   loader.args[args_cnt] = string.format("%s",ar)
  else
   if par == "add_export" then
    loader.export[export_cnt] = string.format("%s",ar)
   elseif par == "add_extra" then
    loader.extra[extra_cnt] = string.format("%s",ar)
   elseif par == "workdir" or par == "tmpdir" then
    loader_set_dir(par,ar)
   else
    loader_set_param(par,ar)
   end
   set = false
  end
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
   export_cnt=export_cnt+1
  elseif ar == "-ext" then
   par="add_extra"
   extra_cnt=extra_cnt+1
  elseif ar == "--" then
   par="add_args"
   set_args=true
  else
   print("incorrect parameter: " .. ar)
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

if loader.export[1] == nil then
 print("at least one global variable name to export must be provided!")
 print()
 loader_show_usage()
end

-- unset non-needed defines
export_cnt=nil
extra_cnt=nul
set=nil
par=nil
args_cnt=nil
loader_show_usage=nil
loader_param_set_check=nil
loader_param_not_set_check=nil
loader_set_param=nil
loader_set_dir=nil

-- TODO: define some config verification logic

-- execute pre-script
if loader.preexec ~= nil then
 loader.log("running preexec script")
 dofile(loader.preexec)
end

-- execute main script
print("running main config script")
dofile(loader.exec)

-- execute post-script
if loader.postexec ~= nil then
 loader.log("running postexec script")
 dofile(loader.postexec)
end

function loader_export(name,value)
 local target = assert(io.open(loader.tmpdir .. loader.pathseparator .. name, "w"))
 target:write(string.format("%s",value))
 target:close()
end

function loader_recursive_export(name,node)
 --loader.log("processing table: " .. name)
 for key,value in pairs(node) do
  local cur_name=string.format("%s.%s",name,key)
  if type(value) == "boolean" or type(value) == "number" or type(value) == "string" then
   loader_export(cur_name,value)
  elseif type(value) == "table" then
   loader_recursive_export(cur_name,value)
  end
 end
end

for index,value in ipairs(loader.export) do
 local status,target=pcall(loadstring("return " .. value))
 if status == false or type(target) == "nil" then
  loader.log("requested global variable or table with name %s is not exist",value)
 elseif type(target) == "boolean" or type(target) == "number" or type(target) == "string" then
  loader_export(value,target)
 elseif type(target) == "table" then
  loader_recursive_export(value,target)
 end
end

