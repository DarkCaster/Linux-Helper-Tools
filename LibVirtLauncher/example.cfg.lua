global_params={
  uri="qemu:///system",
}

start_domain_1={
  type="start_domain",
  name="deadbeef-dead-beef-dead-beefdeadbeef", -- domain name or uuid
}

connect_xpra_client={
  type="xpra_client",
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
