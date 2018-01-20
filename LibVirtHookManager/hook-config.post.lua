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

loader.asserts.ids={}
loader.asserts.locally_checked_profiles={}
loader.asserts.globally_checked_profiles={}

function loader.asserts.add_to_checked_profiles(storage, target)
  for _,el in pairs(storage) do
    if el==target then
      return false
    end
  end
  table.insert(storage,target)
  return true
end

function loader.asserts.netns_dhclient(target)
  if type(target.leases)~="nil" and type(target.leases)~="string" then return "leases field is incorrect!" end
  if type(target.leases)~="string" then target.leases=loader.path.combine(loader.config.tmp_dir,"ndhc.".. target.id ..".leases") end
  if type(target.pid)~="nil" and type(target.pid)~="string" then return "pid field is incorrect!" end
  if type(target.pid)~="string" then target.pid=loader.path.combine(loader.config.tmp_dir,"ndhc.".. target.id ..".pid") end
  if type(target.log)~="nil" and type(target.log)~="string" then return "log field is incorrect!" end
  if type(target.log)~="string" then target.log=loader.path.combine(loader.config.tmp_dir,"ndhc.".. target.id ..".log") end
end

function loader.asserts.stunnel(target)
end

function loader.asserts.vde(target)
  if type(target.ctrldir)~="nil" and type(target.ctrldir)~="string" then return "ctrldir field is incorrect!" end
  if type(target.ctrldir)~="string" then target.ctrldir=loader.path.combine(loader.config.tmp_dir,"vde.".. target.id) end
  if type(target.pid)~="nil" and type(target.pid)~="string" then return "pid field is incorrect!" end
  if type(target.pid)~="string" then target.pid=loader.path.combine(loader.config.tmp_dir,"vde.".. target.id ..".pid") end
  if type(target.log)~="nil" and type(target.log)~="string" then return "log field is incorrect!" end
  if type(target.log)~="string" then target.log=loader.path.combine(loader.config.tmp_dir,"vde.".. target.id ..".log") end
  if type(target.tap)~="nil" and type(target.tap)~="string" then return "tap field is incorrect!" end
  if type(target.tap)~="string" then target.tap="" end
  if type(target.netns)~="nil" and type(target.netns)~="string" then return "netns field is incorrect!" end
  if type(target.netns)~="string" then target.netns="" end
  if type(target.netns_cleanup)~="nil" and type(target.netns_cleanup)~="boolean" then return "netns_cleanup field is incorrect!" end
  if type(target.netns_cleanup)~="boolean" then target.netns_cleanup=true end
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
  loader.asserts.locally_checked_profiles={}
  for index,field in pairs(dfield.hooks) do
    assert(type(index)=="number", "deps[".. dindex .."].hooks[".. index .."] is incorrect (must be an indexed element)!")
    assert(type(field)=="table", "deps[".. dindex .."].hooks[".. index .."] value is incorrect (must be a table)!")
    if loader.asserts.add_to_checked_profiles(loader.asserts.locally_checked_profiles, field) then
      if loader.asserts.add_to_checked_profiles(loader.asserts.globally_checked_profiles, field) then
        assert(type(field.id)=="number", "deps[".. dindex .."].hooks[".. index .."].id value is incorrect (must be a number)!")
        assert(type(loader.asserts.ids[field.id])=="nil", "deps[".. dindex .."].hooks[".. index .."].id must be unique!")
        loader.asserts.ids[field.id]=field.id
        assert(type(field.type)=="string", "deps[".. dindex .."].hooks[".. index .."].type value is incorrect (must be a string)!")
        loader.asserts.check_ops(field.op_start,"deps[".. dindex .."].hooks[".. index .."].op_start")
        loader.asserts.check_ops(field.op_stop,"deps[".. dindex .."].hooks[".. index .."].op_stop")
        if field.type=="stunnel" then
          loader.asserts.result=loader.asserts.stunnel(field)
        elseif field.type=="vde" then
          loader.asserts.result=loader.asserts.vde(field)
        elseif field.type=="ndhc" then
          loader.asserts.result=loader.asserts.netns_dhclient(field)
        else
          error("unsupported hook type: ".. field.type)
        end
        if loader.asserts.result~=nil then
          error("hook table deps[".. dindex .."].hooks[".. index .."] verification failed with error: "..loader.asserts.result)
        end
      end
    else
      error("deps[".. dindex .."].hooks[".. index .."] must be provided only once per hooks table")
    end
  end
  if dfield.uuid==loader.config.uuid then
    hooks=dfield.hooks
  end
end

if hooks==nil then hooks="none" end
