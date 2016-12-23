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
assert(type(prefix.extra_cmd)=="nil" or type(prefix.extra_cmd)=="table", "prefix.extra_cmd param incorrect")
assert(type(tweaks)=="nil" or type(tweaks)=="table", "tweaks param incorrect")

-- check prefix.dll_overrides and generate missing fields
if type(prefix.dll_overrides)=="table" then
 for key,value in pairs(prefix.dll_overrides) do
  assert(type(value)=="table", "prefix.dll_overrides." .. key .. " param incorrect")
  assert(#value==3 or #value==4, "prefix.dll_overrides." .. key .. " table length is incorrect")
  for index,field in ipairs(value) do
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

if type(prefix.menu)~="boolean" or prefix.menu==false then
 if type(prefix.dll_overrides)=="nil" then prefix.dll_overrides={} end
 prefix.dll_overrides.winemenubuilder = { "native", loader.extra[2] .. loader.slash .. "winemenubuilder.exe", "winemenubuilder.exe", "winemenubuilder.exe"}
end

-- create override_list to simplify loop in wine-launcher.sh
if type(prefix.dll_overrides)=="table" then
 prefix.override_list=""
 for key,value in pairs(prefix.dll_overrides) do
  if prefix.override_list == "" then
   prefix.override_list=string.format("%s",key)
  else
   prefix.override_list=string.format("%s %s", prefix.override_list, key)
  end
 end
end

-- check extra_cmd
if type(prefix.extra_cmd)=="table" then
 for index,field in ipairs(prefix.extra_cmd) do
  assert(index<3, "\"prefix.extra_cmd\" table has more than two elements")
  assert(type(field)=="string", "prefix.extra_cmd[" .. index .. "] value is incorrect")
 end
 if type(prefix.extra_cmd[2])=="nil" then
  prefix.extra_cmd[2]=loader.path.combine(prefix.root,"drive_c","windows","system32")
 end
end

-- check tweaks, generate stuff
if type(tweaks)=="table" then
 tweaks.enabled=true
 -- winetricks
 assert(type(tweaks.winetricks)=="nil" or ( type(tweaks.winetricks)=="string" and string.len(tweaks.winetricks)>0 ), "tweaks.winetricks param incorrect")
 -- allfonts
 assert(type(tweaks.allfonts)=="nil" or type(tweaks.allfonts)=="boolean", "tweaks.allfonts param incorrect")
 if type(tweaks.allfonts)~="boolean" then
  tweaks.allfonts=false
 else
  if type(tweaks.winetricks)=="nil" and tweaks.allfonts==true then
   error("allfonts tweak requires winetricks")
  end
 end
 -- fontsmooth
 assert(type(tweaks.fontsmooth)=="nil" or type(tweaks.fontsmooth)=="string", "tweaks.fontsmooth param incorrect")
 if type(tweaks.fontsmooth)=="string" then
  fontsmooth=tweaks.fontsmooth
  tweaks.fontsmooth={ enabled=true }
  if fontsmooth=="none" then
   tweaks.fontsmooth.mode=0
   tweaks.fontsmooth.type=0
   tweaks.fontsmooth.orientation=1
  elseif fontsmooth=="simple" then
   tweaks.fontsmooth.mode=2
   tweaks.fontsmooth.type=1
   tweaks.fontsmooth.orientation=1
  elseif fontsmooth=="rgb" then
   tweaks.fontsmooth.mode=2
   tweaks.fontsmooth.type=2
   tweaks.fontsmooth.orientation=1
  elseif fontsmooth=="bgr" then
   tweaks.fontsmooth.mode=2
   tweaks.fontsmooth.type=2
   tweaks.fontsmooth.orientation=0
  else
   error("fontsmooth value incorrect")
  end
 else
  tweaks.fontsmooth={ enabled=false }
 end
else
 tweaks={ enabled=false }
end

-- load profile, and perform it's verification
profile=loadstring("return " .. loader.extra[1])()

-- if "tweaks" pseudo-profile selected, then skip regular profile checks
if loader.extra[1]=="tweaks" then
 return
end

-- verify selected profile, and generate some helper stuff
assert(type(profile)=="table", "selected profile is missing or not a table")
assert(type(profile.run)=="table", "\"run\" subtable is not a table type or missing")

for index,field in ipairs(profile.run) do
 assert(index<3, "\"run\" subtable has more than two parameters")
 assert(type(field)=="string", "run[" .. index .. "] value is incorrect")
end

if type(profile.run[2])=="nil" then
 profile.run[2]=loader.path.combine(prefix.root,"drive_c","windows","system32")
 --print(profile.run[2])
end

assert(type(profile.desktop)=="nil" or type(profile.desktop)=="table", "\"desktop\" subtable is not a table type")
if type(profile.desktop)=="table" then
 assert(type(profile.desktop.name)=="string","profile.desktop.name value is incorrect")
 assert(type(profile.desktop.comment)=="nil" or type(profile.desktop.comment)=="string","profile.desktop.comment value is incorrect")
 assert(type(profile.desktop.icon)=="nil" or type(profile.desktop.icon)=="string","profile.desktop.icon value is incorrect")
 assert(type(profile.desktop.categories)=="nil" or type(profile.desktop.categories)=="string","profile.desktop.categories value is incorrect")
 assert(type(profile.desktop.mimetype)=="nil" or type(profile.desktop.mimetype)=="string","profile.desktop.mimetype value is incorrect")
 assert(type(profile.desktop.terminal)=="nil" or type(profile.desktop.terminal)=="boolean","profile.desktop.terminal value is incorrect")
 assert(type(profile.desktop.startupnotify)=="nil" or type(profile.desktop.startupnotify)=="boolean","profile.desktop.startupnotify value is incorrect")
 if type(profile.desktop.comment)=="nil" then profile.desktop.comment="wine-launcher profile for " .. profile.desktop.name end
 if type(profile.desktop.icon)=="nil" then profile.desktop.icon="wine" end
 if type(profile.desktop.categories)=="nil" then profile.desktop.categories="Application;" end
 if type(profile.desktop.mimetype)=="nil" then profile.desktop.mimetype="" end
 if type(profile.desktop.terminal)=="nil" then profile.desktop.terminal=false end
 if type(profile.desktop.startupnotify)=="nil" then profile.desktop.startupnotify=false end
 profile.desktop.filename="wine-launcher-profile-" .. loader.extra[1] .. ".desktop"
end

