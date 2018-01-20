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
  -- ctrldir, pidfile and logging, will be placed at tmp_dir location if following parameters is missing
  -- by default, ctrldir avaliable at /tmp/qemu-hooks-<domain uuid>/vde.<id>,
  -- log at /tmp/qemu-hooks-<domain uuid>/vde.<id>.log,
  -- pid at /tmp/qemu-hooks-<domain uuid>/vde.<id>.pid,

  -- ctrldir=loader.path.combine(loader.slash,"tmp","vde.example.ctrldir"),
  -- pid=loader.path.combine(loader.slash,"tmp","vde.example.pid"),
  -- log=loader.path.combine(loader.slash,"tmp","vde.example.log"),

  -- tap device conenction (optional), empty string or missing value will disable tap device creation and connection
  tap="vde_example",
  netns="vde_example", -- move tap device to separate netns if set
  netns_cleanup=true,
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
