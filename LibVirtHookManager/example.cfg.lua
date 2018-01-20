-- table with hook operations
stunnel_test = {
  type="stunnel",
  id=1,
  op_start="prepare",
  op_stop="release",
  client=true,
  syslog=false,
  debug=6,
  ssl_version="TLSv1.2",
  accept="127.0.0.1:43919",
  connect="127.0.0.1:443",
  close_timeout=0,
  ca_file=loader.path.combine(loader.workdir,"stunnel.crt"),
  verify=3,
}

vde_example = {
  type="vde",
  id=2,
  op_start="prepare",
  op_stop="release",
  -- ctrldir, pidfile and logging, will be set to default location below, if missing
  ctrldir=loader.path.combine(loader.slash,"tmp","qemu-hooks-".. loader.config.uuid,"vde.2"),
  pid=loader.path.combine(loader.slash,"tmp","qemu-hooks-".. loader.config.uuid,"vde.2.pid"),
  log=loader.path.combine(loader.slash,"tmp","qemu-hooks-".. loader.config.uuid,"vde.2.log"),
  -- other optional parameters
  tap="vde_example", -- create tap device and connect vde_switch to it
  netns="vde_example", -- create separate netns and move tap device to separate netns
  netns_cleanup=true, -- true, if missing - will remove netns on exit
}

global_params = {
  timeout=10,
  user=1000,
  group=100,
}

deps = {
  {
    uuid="e9ce7ae0-272a-44b5-b4b6-eca4b738127b",
    hooks = { vde_example },
  },
  {
    uuid="f53e968b-d763-4973-bb59-352cd02be824",
    hooks = { stunnel_test, vde_example  },
  },
}
