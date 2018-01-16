-- deps table verification
assert(type(deps)=="table", "deps config param is not a table!")

loader.asserts={}
loader.asserts.result=nil

function loader.asserts.stunnel(target)
 return "stunne profile assert failed"
end

for dindex,dfield in pairs(deps) do
  assert(type(dindex)=="number", "deps[".. dindex .."] is incorrect (must be an indexed element)!")
  assert(type(dfield)=="table", "deps[".. dindex .."] value is incorrect (must be a table)!")
  assert(type(dfield.uuid)=="string", "deps[".. dindex .."].uuid value is incorrect (must be a string)!")
  assert(type(dfield.hooks)=="table", "deps[".. dindex .."].hooks value is incorrect (must be a table)!")
  for index,field in pairs(dfield.hooks) do
    assert(type(index)=="number", "deps[".. dindex .."].hooks[".. index .."] is incorrect (must be an indexed element)!")
    assert(type(field)=="table", "deps[".. dindex .."].hooks[".. index .."] value is incorrect (must be a table)!")
    assert(type(field.type)=="string", "deps[".. dindex .."].hooks[".. index .."].type value is incorrect (must be a string)!")
    assert(type(field.op)=="string", "deps[".. dindex .."].hooks[".. index .."].op value is incorrect (must be a string)!")
    if field.op~="prepare" and field.op~="start" and field.op~="started" and field.op~="stopped" and field.op~="release" and field.op~="migrate" and field.op~="restore" and field.op~="reconnect" and field.op~="attach" then
      error("unsupported hook operation: "..field.op)
    end
    if field.type=="stunnel" then
      loader.asserts.result=loader.asserts.stunnel(field)
    else
      error("unsupported hook type: "..field.type)
    end
    if loader.asserts.result~=nil then
      error("hook table deps[".. dindex .."].hooks[".. index .."] verification failed with error: "..loader.asserts.result)
    end
  end
end
