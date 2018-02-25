assert(type(actions)=="nil", "config file must not include 'actions' global parameter or table!")
assert(type(global_params)=="table" or type(global_params)=="nil", "global_params config param is incorrect!")
if global_params==nil then
  global_params={}
  global_params.uri="qemu:///system"
else
  assert(type(global_params.uri)=="string", "global_params.uri global config param is incorrect!")
end

-- load actions
if loader.lua_version.num>=5002000 then
  actions=load("return " .. loader.config.profile)()
else
  actions=loadstring("return " .. loader.config.profile)()
end

loader.asserts={}
loader.asserts.result=nil

function loader.asserts.domstart(target)
  if type(target.name)~="string" then return "name field is missing or incorrect!" end
end

function loader.asserts.xpra_client(target)
end

function loader.asserts.rdp_client(target)
end

assert(type(actions)=="table", "selected actions profile is incorrect (it must be a table)")

for dindex,dfield in pairs(actions) do
  if dindex=="desktop_file" then
    -- verify desktop file definitions
  else
    assert(type(dindex)=="number", loader.config.profile.."[".. dindex .."] is incorrect (must be an indexed element)!")
    assert(type(dfield)=="table", loader.config.profile.."[".. dindex .."] value is incorrect (must be a table)!")
    assert(type(dfield.type)=="string", loader.config.profile..".type must be a string")
    if dfield.type=="start_domain" then
      loader.asserts.result=loader.asserts.domstart(dfield)
    elseif dfield.type=="xpra_client" then
      loader.asserts.result=loader.asserts.xpra_client(dfield)
    elseif  dfield.type=="rdp_client" then
      loader.asserts.result=loader.asserts.rdp_client(dfield)
    else
      error("unsupported action type: ".. dfield.type)
    end
    if loader.asserts.result~=nil then
      error("table "..loader.config.profile.."[".. dindex .."] verification failed with error: "..loader.asserts.result)
    end
  end
end
