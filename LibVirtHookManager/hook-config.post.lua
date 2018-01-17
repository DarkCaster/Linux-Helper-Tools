-- deps table verification
assert(type(deps)=="table", "deps config param is not a table!")
assert(type(hooks)=="nil", "config file must not include 'hooks' global parameter or table!")
assert(type(global_params)=="table" or type(global_params)=="nil", "global_params config param is incorrect!")
if global_params==nil then global_params={} end

loader.asserts={}
loader.asserts.result=nil

-- check global_params

function loader.asserts.check_globals_num(name, default)
  assert(type(global_params[name])=="number" or type(global_params[name])=="nil", "global_params.".. name .." value is incorrect!")
  if global_params[name]==nil then global_params[name]=default end
end

loader.asserts.check_globals_num("timeout", 10)
loader.asserts.check_globals_num("user", 0)
loader.asserts.check_globals_num("group", 0)

print(global_params.timeout)
print(global_params.user)
print(global_params.group)

function loader.asserts.stunnel(target)
 --return "stunnel hook verification not implemented"
end

function loader.asserts.check_ops(target, name)
  assert(type(target)=="string", name .." value is incorrect or missing (must be a string)!")
  if target~="prepare" and target~="start" and target~="started" and target~="stopped" and target~="release" then
    error("unsupported hook operation: ".. target .." for: ".. name)
  end
end

for dindex,dfield in pairs(deps) do
  assert(type(dindex)=="number", "deps[".. dindex .."] is incorrect (must be an indexed element)!")
  assert(type(dfield)=="table", "deps[".. dindex .."] value is incorrect (must be a table)!")
  assert(type(dfield.uuid)=="string", "deps[".. dindex .."].uuid value is incorrect (must be a string)!")
  dfield.uuid=string.lower(dfield.uuid)
  assert(string.len(dfield.uuid)==36,"deps[".. dindex .."].uuid value is incorrect (must be valid UUID)!" )
  assert(string.find(dfield.uuid,"^[0-9a-f]+%-[0-9a-f]+%-[0-9a-f]+%-[0-9a-f]+%-[0-9a-f]+$")~=nil,"deps[".. dindex .."].uuid value is incorrect (must be valid UUID)!")
  assert(type(dfield.hooks)=="table", "deps[".. dindex .."].hooks value is incorrect (must be a table)!")
  for index,field in pairs(dfield.hooks) do
    assert(type(index)=="number", "deps[".. dindex .."].hooks[".. index .."] is incorrect (must be an indexed element)!")
    assert(type(field)=="table", "deps[".. dindex .."].hooks[".. index .."] value is incorrect (must be a table)!")
    assert(type(field.type)=="string", "deps[".. dindex .."].hooks[".. index .."].type value is incorrect (must be a string)!")
    loader.asserts.check_ops(field.op_start,"deps[".. dindex .."].hooks[".. index .."].op_start")
    loader.asserts.check_ops(field.op_stop,"deps[".. dindex .."].hooks[".. index .."].op_stop")
    if field.type=="stunnel" then
      loader.asserts.result=loader.asserts.stunnel(field)
    else
      error("unsupported hook type: ".. field.type)
    end
    if loader.asserts.result~=nil then
      error("hook table deps[".. dindex .."].hooks[".. index .."] verification failed with error: "..loader.asserts.result)
    end
  end
  if dfield.uuid==loader.config.uuid then
    hooks=dfield.hooks
    break
  end
end

if hooks==nil then hooks="none" end
