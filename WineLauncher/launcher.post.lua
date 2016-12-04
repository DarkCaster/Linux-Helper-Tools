assert(type(prefix)=="table", "prefix param incorrect")
assert(type(prefix.root)=="string", "prefix.root param incorrect")
assert(type(prefix.arch)=="nil" or type(prefix.arch)=="string", "prefix.arch param incorrect")
assert(type(prefix.lang)=="nil" or type(prefix.lang)=="string", "prefix.lang param incorrect")
assert(type(prefix.wine)=="nil" or type(prefix.wine)=="string", "prefix.wine param incorrect")
assert(type(prefix.docs)=="nil" or type(prefix.docs)=="string", "prefix.docs param incorrect")
assert(type(prefix.owner)=="nil" or type(prefix.owner)=="string", "prefix.owner param incorrect")
assert(type(prefix.org)=="nil" or type(prefix.org)=="string", "prefix.org param incorrect")
assert(type(prefix.menu)=="nil" or type(prefix.menu)=="boolean", "prefix.menu param incorrect")
assert(type(prefix.dll_overrides)=="nil" or type(prefix.dll_overrides)=="table", "prefix.dll_overrides param incorrect")

-- check prefix.dll_overrides and generate missing fields
if type(prefix.dll_overrides)=="table" then
 for key,value in pairs(prefix.dll_overrides) do
  assert(type(value)=="table", "prefix.dll_overrides." .. key .. " param incorrect")
  assert(#value==3 or #value==4, "prefix.dll_overrides." .. key .. " table length is incorrect")
  for index,field in pairs(value) do
   assert(type(field)=="string", "prefix.dll_overrides." .. key .. "." .. index .. " value is incorrect")
  end
  assert(value[1]=="native" or value[1]=="builtin" or value[1]=="native,builtin" or value[1]=="builtin,native", "prefix.dll_overrides." .. key .. "[1] field is incorrect")
  if type(value[4])=="nil" or value[4]=="" then
   result="empty"
   assert(value[3]~="","prefix.dll_overrides." .. key .. "[3] field is empty, cannot construct field [4] from it")
   if value[3]~=string.lower(value[3]) then
    loader.log("warning: prefix.dll_overrides.%s[3] should not contain uppercase characters!", key)
   end
   if #value[3]>4 and string.lower(string.sub(value[3], -4, -1))==".dll" then
    result=string.lower(string.sub(value[3], 1, -5))
   else
    result=value[3]
   end
   if type(value[4])=="nil" then
    table.insert(value,result)
   else
    value[4]=result
   end
  end
 end
end

-- TODO create and check profile variable from selected profile
profile={}

