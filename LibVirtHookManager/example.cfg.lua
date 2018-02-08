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
  tap_macaddr="00:16:3E:9E:05:6F",
  netns="vde_example", -- create separate netns and move tap device to separate netns
  netns_cleanup=true, -- will remove netns on exit, true by default
}

dhclient_example = {
  type="ndhc", -- dhclient in netns
  id=3,
  op_start="prepare",
  op_stop="release",
  netns="vde_example", -- netns name, where service will be launched
  -- extra cmdline switches,
  cmdline={"-4"},
  -- leases, pidfile and logging, will be set to default location below, if missing
  pid=loader.path.combine(loader.slash,"tmp","qemu-hooks-".. loader.config.uuid,"ndhc.3.pid"),
  leases=loader.path.combine(loader.slash,"tmp","qemu-hooks-".. loader.config.uuid,"ndhc.3.leases"),
  log=loader.path.combine(loader.slash,"tmp","qemu-hooks-".. loader.config.uuid,"ndhc.3.log"),
  setup_local=true, -- perform setup of "lo" network interface inside selected netns
}

network_setup_example = {
  type="nsetup", -- setup some network parameter for selected netns
  id=4,
  op_start="prepare",
  op_stop="release",
  netns="vde_example", -- netns name, where setup will be performed
  -- various setup parameters, optional
  resolv_conf="search lan\nnameserver 192.168.1.1",
  hosts="127.0.0.1 localhost\
::1 localhost ipv6-localhost ipv6-loopback\
fe00::0 ipv6-localnet\
ff00::0 ipv6-mcastprefix\
ff02::1 ipv6-allnodes\
ff02::2 ipv6-allrouters\
ff02::3 ipv6-allhosts\
127.0.0.2 example.lan example",
  hostname="example.lan",
}

netns_miredo_example = {
  type="nmiredo", -- start miredo client service in selected netns
  id=5,
  op_start="prepare",
  op_stop="release",
  netns="vde_example", -- netns name, where setup will be performed
  -- various setup parameters, optional, will be set to provided defaults if missing:
  interface_name="teredo",
  server_address="teredo.remlab.net",
  user="nobody",
  --mtu=1280,
  -- pidfile and logfile location, will be set to provided default values if missing
  pid=loader.path.combine(loader.slash,"tmp","qemu-hooks-".. loader.config.uuid,"nmiredo.5.pid"),
  log=loader.path.combine(loader.slash,"tmp","qemu-hooks-".. loader.config.uuid,"nmiredo.5.log"),
}

global_params = {
  timeout=10,
  user=1000,
  group=100,
}

deps = {
  {
    uuid="e9ce7ae0-272a-44b5-b4b6-eca4b738127b",
    hooks = { vde_example, network_setup_example, dhclient_example, netns_miredo_example },
  },
  {
    uuid="f53e968b-d763-4973-bb59-352cd02be824",
    hooks = { stunnel_test, vde_example  },
  },
}
