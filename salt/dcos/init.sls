{% import "dcos/common_vars.sls" as dcos with context %}

{% if salt['pillar.get']('dcos:minion_bootstrap', True) %}
  {% set bootstrap_host = salt['mine.get']('I@dcos:cluster_name:{} and I@dcos:bootstrap:true'.format(dcos.cluster_name), 'network.ip_addrs', tgt_type='compound').values()|sum(start=[])|first %}
{% else %}
  {% set bootstrap_host = grains['master'] %}
{% endif %}

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
