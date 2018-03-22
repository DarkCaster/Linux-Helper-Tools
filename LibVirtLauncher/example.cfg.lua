global_params={
  uri="qemu:///system",
}

start_domain_1={
  type="start_domain",
  name="deadbeef-dead-beef-dead-beefdeadbeef", -- domain name or uuid
}

connect_xpra_client={
  type="xpra_client",
  target="tcp://127.0.0.1:7777",
  tray=true,
  cmdline={"--pings=no","--notifications=no","--compressors=lz4","--encoding=rgb","--speed=100"},
  conn_timeout=60,
}

connect_rdp_client={
  type="rdp_client",
}

-- example actions profile
example={
  desktop_file={}, -- desktop file definitions, TODO.
  start_domain_1,
  connect_xpra_client,
}
