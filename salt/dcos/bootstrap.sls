{% import "dcos/common_vars.sls" as dcos with context %}

include:
  - .common

dcos_bootstrap:
  file.managed:
    - names:
      - {{ dcos.file_root }}/genconf/config.yaml:
        - makedirs: true
        - contents: {{ (dcos.genconf|yaml(False)).split('\n')|json }}
      - {{ dcos.file_root }}/genconf/ip-detect:
        - source: salt://dcos/ip-detect
        - mode: 0755
      - {{ dcos.file_root }}/dcos_generate_config.sh:
        - source: {{ dcos.data[dcos.version]['source'] }}
        - source_hash: {{ dcos.data[dcos.version]['source_hash'] }}
        - mode: 0755
    - dir_mode: 0755
  cmd.run:
    - name: /bin/bash {{ dcos.file_root }}/dcos_generate_config.sh
    - cwd: {{ dcos.file_root }}
    - require:
      - file: dcos_bootstrap
  docker_container.running:
    - name: {{ dcos.bootstrap_container_name }}
    - image: 'nginx:alpine'
    - port_bindings:
      - "{{ dcos.bootstrap_port }}:80"
    - binds:
      - "{{ dcos.file_root }}/genconf/serve:/usr/share/nginx/html:ro"
    - require:
      - cmd: dcos_bootstrap
