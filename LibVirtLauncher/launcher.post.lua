assert(type(actions)=="nil", "config file must not include 'actions' global parameter or table!")
assert(type(global_params)=="table" or type(global_params)=="nil", "global_params config param is incorrect!")
if global_params==nil then global_params={} end

loader.asserts={}
loader.asserts.result=nil

-- check global_params

function loader.asserts.check_globals_num(name, default)
  assert(type(global_params[name])=="number" or type(global_params[name])=="nil", "global_params.".. name .." value is incorrect!")
  if global_params[name]==nil then global_params[name]=default end
end

-- load actions
if loader.lua_version.num>=5002000 then
  actions=load("return " .. loader.config.profile)()
else
  actions=loadstring("return " .. loader.config.profile)()
end

assert(type(actions)=="table", "selected actions profile is incorrect (it must be a table)")

-- TODO: iterate over actions elements, and verify every action-table
