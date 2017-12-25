mine_functions:
  network.ip_addrs: [eth0]

dcos:
  minion_bootstrap: true
  cluster_name: asdf
  bootstrap_port: 65432
  version: 1.10.2
  cleanup_genconf: true
