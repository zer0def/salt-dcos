{% import "dcos/common_vars.sls" as dcos with context %}

{% if dcos.bootstrap_hosts %}
  {% set bootstrap_host = dcos.bootstrap_hosts|first %}
{% else %}
  {% set bootstrap_host = grains['master'] %}
{% endif %}

{% set proxyminion_pillar = salt['pillar.get']('proxy', {}) %}
{% do proxyminion_pillar.update({
  'proxytype': 'marathon',
  'base_url': 'http://{}:8080'.format(salt['mine.get']('I@dcos:cluster_name:{} and I@dcos:role:master'.format(salt['pillar.get']('dcos:cluster_name', 'asdf')), 'network.ip_addrs', tgt_type='compound').values()|sum(start=[])|first)
}) %}

include:
  - .common

dcos_install:
  pkg.installed:
    - refresh: true
    - pkgs:
      - curl
      - git
      - ipset
      - wget
      - unzip
      - xz
  group.present:
    - name: nogroup
    - system: true
  cmd.run:
    - names:
      - setenforce 0
#      - '/bin/bash <(curl -s http://{{ bootstrap_host }}:{{ dcos.bootstrap_port }}/dcos_install.sh) {{ salt['pillar.get']('dcos:role', 'slave') }}'
      - 'curl -s http://{{ bootstrap_host }}:{{ dcos.bootstrap_port }}/dcos_install.sh | /bin/bash -s {{ salt['pillar.get']('dcos:role', 'slave') }}'
    - require:
      - group: dcos_install
      - pkg: dcos_common
      - pkg: dcos_install
{#
  module.run:
    - name: state.apply
    - kwargs:
        pillar:
          proxy: {{ proxyminion_pillar|json }}
    - require:
      - cmd: dcos_install

dcos_refresh_pillar:
  module.run:
    - name: saltutil.refresh_pillar
    - require:
      - module: dcos_install
#}
