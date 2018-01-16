-- table with hook operations
stunnel_test = {
  type="stunnel",
  op="prepare",
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

deps = {
  {
    uuid="e9ce7ae0-272a-44b5-b4b6-eca4b738127b",
    hooks = { stunnel_test, },
  },
}
