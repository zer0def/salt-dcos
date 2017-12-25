{% set data = {
  'common': {
    'cleanup_paths': [
      'genconf/cluster_packages.json',
      'genconf/serve',
      'genconf/state',
    ]
  },
  '1.9.6': {
    'source': 'https://downloads.dcos.io/dcos/stable/1.9.6/dcos_generate_config.sh',
    'source_hash': 'sha512=3620a8121f806d84207548269b07287b004a38e9b2ca19f7c42c9f1dfdc828df5c9cc71d1c2975d4e1392f527046bdb078d702e95dee9ffad0575dfe927dd41e',
    'cleanup_paths': [
      'dcos-genconf.f25e9dcfd0abae4de8-5bcddd03670098e7a9.tar'
    ]
  },
  '1.10.2': {
    'source': 'https://downloads.dcos.io/dcos/stable/1.10.2/dcos_generate_config.sh',
    'source_hash': 'sha512=dc10572953b7e43290374bf6bf14cae40127f581e14ccafcc522a06c7a95a915405678c1c0bf2c63d070a290ffe9fa7800148ca56b51010099ee8dfb2fe001fc',
    'cleanup_paths': [
      'dcos-genconf.12b494a3309c65a22b-fd215e0ba8f9f9dbcc.tar'
    ]
  }
} %}
{% set version = salt['pillar.get']('dcos:version', '1.10.2') %}

{% set bootstrap_port = salt['pillar.get']('dcos:bootstrap_port', 65432) %}
{% set bootstrap_container_name = salt['pillar.get']('dcos:bootstrap_container_name', 'dcos-bootstrap') %}
{% set cluster_name = salt['pillar.get']('cluster_name', 'asdf') %}

{% set genconf = {
  'bootstrap_url': 'http://{}:{}'.format(salt['network.ip_addrs']('eth0')|first, bootstrap_port),
  'cluster_name': cluster_name,
  'exhibitor_storage_backend': 'static',
  'master_discovery': 'static',
  'resolvers': [
    '8.8.8.8', '8.8.4.4'
  ],
  'ssh_port': 22,
  'ssh_user': 'root',
  'process_timeout': 600,
  'oauth_enabled': 'false',
  'telemetry_enabled': 'false',
  'master_list': salt['saltutil.runner']('mine.get', tgt='I@dcos:cluster_name:{} and I@dcos:role:master'.format(cluster_name), fun='network.ip_addrs', tgt_type='compound').values()|sum(start=[]),
  'agent_list': salt['saltutil.runner']('mine.get', tgt='I@dcos:cluster_name:{} and I@dcos:role:slave'.format(cluster_name), fun='network.ip_addrs', tgt_type='compound').values()|sum(start=[]),
  'public_agent_list': salt['saltutil.runner']('mine.get', tgt='I@dcos:cluster_name:{} and I@dcos:role:slave_public'.format(cluster_name), fun='network.ip_addrs', tgt_type='compound').values()|sum(start=[])
} %}

{% if salt['pillar.get']('dcos:minion_bootstrap', True) %}
  {% set file_root = '/var/tmp' %}
{% else %}
  {% set file_root = '{}/{}'.format(salt['config.get']('file_roots:base')|first, 'dcos') %}
{% endif %}

{% set cleanup_paths = [] %}
{% for relpath in data['common']['cleanup_paths'] %}
  {% do cleanup_paths.append('{}/{}'.format(file_root, relpath)) %}
{% endfor %}
{% for relpath in data[version]['cleanup_paths'] %}
  {% do cleanup_paths.append('{}/{}'.format(file_root, relpath)) %}
{% endfor %}
{% set cleanup_genconf = salt['pillar.get']('dcos:cleanup_genconf', False) %}
