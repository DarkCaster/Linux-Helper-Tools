launcher={}
launcher.dir = loader.extra[2]
launcher.pwd = loader.extra[3]

function launcher.gen_filename(par)
 if type(par)~="string" or string.len(par)==0 then
  return "filename=\"\";"
 else
  return "filename=`winepath -w \"" .. par .. "\" 2>/dev/null`;"
 end
end

function launcher.gen_filename_from_args()
 if type(loader.args[1])=="string" then
  return launcher.gen_filename(loader.args[1])
 else
  return launcher.gen_filename("")
 end
end

