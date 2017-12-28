{% import "dcos/common_vars.sls" as dcos with context %}

# make sure the salt cluster has up-to-date state
clear_caches:
  salt.function:
    - name: saltutil.clear_cache
    - tgt: '*'

sync_everything:
  salt.function:
    - name: saltutil.sync_all
    - tgt: '*'
    - require:
      - salt: clear_caches

refresh_pillars:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: '*'
    - require:
      - salt: sync_everything

update_mine:
  salt.function:
    - name: mine.update
    - tgt: '*'
    - require:
      - salt: refresh_pillars

# requires docker-py / python-docker to be installed
create_bootstrap:
{% if dcos.bootstrap_hosts %}
  salt.state:
    - tgt: 'I@dcos:cluster_name:{{ dcos.cluster_name }} and I@dcos:bootstrap:true'
    - tgt_type: compound
    - sls:
      - dcos.bootstrap
    - require:
      - salt: sync_everything
      - salt: refresh_pillars
      - salt: update_mine
{% else %}
  salt.runner:
    - name: salt.cmd
    - unless: docker container inspect {{ dcos.bootstrap_container_name }}
    - arg:
      - docker.create
    - kwarg:
        image: 'nginx:alpine'
        name: {{ dcos.bootstrap_container_name }}
        ports: '{{ dcos.bootstrap_port }}'
        port_bindings:
          - "{{ dcos.bootstrap_port }}:80"
        binds:
          - "{{ dcos.file_root }}/genconf/serve:/usr/share/nginx/html:ro"
    - require:
      - salt: sync_everything
      - salt: refresh_pillars
      - salt: update_mine

genconf_config:
  salt.runner:
    - name: salt.cmd
    - arg:
      - file.write
    - kwarg:
        path: {{ dcos.file_root }}/genconf/config.yaml
        args: {{ (dcos.genconf|yaml(False)).split('\n')|json }}
    - require:
      - salt: sync_everything
      - salt: refresh_pillars
      - salt: update_mine

{% set manage_file_args = salt['file.get_managed'](
  name='{}/dcos_generate_config.sh'.format(dcos.file_root),
  source=dcos.data[dcos.version]['source'],
  source_hash=dcos.data[dcos.version]['source_hash'],
  source_hash_name='{}/dcos_generate_config.sh'.format(dcos.file_root),
  mode='0755', saltenv='base', user=None, group=None, template=None, context=None, defaults=None
) %}

download_bootstrap:
  salt.runner:
    - name: salt.cmd
    - arg:
      - file.manage_file
    - kwarg:
        name: {{ dcos.file_root }}/dcos_generate_config.sh
        sfn: {{ manage_file_args[0] }}
        ret: {}
        {#
          # default `ret` dict structure
          changes: {}
          pchanges: {}
          comment: ''
          name: {{ dcos.file_root }}/dcos_generate_config.sh
          result: true
        #}
        source: {{ dcos.data[dcos.version]['source'] }}
        source_sum: {{ manage_file_args[1]|json }}
        user: {{ salt['config.get']('user') }}
        group: {{ salt['config.get']('user') }}
        mode: 0755
        saltenv: base
        backup: ''
        makedirs: true
        dir_mode: 0755

generate_genconf:
  salt.runner:
    - name: salt.cmd
    - arg:
      - cmd.run
    - kwarg:
        cmd: /bin/bash dcos_generate_config.sh
        cwd: {{ dcos.file_root }}
    - require:
      - salt: download_bootstrap
      - salt: genconf_config

start_bootstrap:
  salt.runner:
    - name: salt.cmd
    - arg:
      - docker.restart
    - kwarg:
        name: {{ dcos.bootstrap_container_name }}
    - require:
      - salt: create_bootstrap
      - salt: generate_genconf
{% endif %}
    - require_in:
      - salt: install_dcos

install_dcos:
  salt.state:
    - tgt: 'I@dcos:cluster_name:{{ dcos.cluster_name }} and not I@dcos:bootstrap:true'
    - tgt_type: compound
    - sls:
      - dcos
    - require_in:
      - salt: stop_bootstrap

stop_bootstrap:
{% if dcos.bootstrap_hosts %}
  salt.state:
    - tgt: 'I@dcos:cluster_name:{{ dcos.cluster_name }} and I@dcos:bootstrap:true'
    - tgt_type: compound
    - sls:
      - dcos.bootstrap_cleanup
{% else %}
  salt.runner:
    - name: salt.cmd
    - arg:
      - docker.rm
    - kwarg:
        name: {{ dcos.bootstrap_container_name }}
        force: true
        volumes: true

  {% for path in dcos.cleanup_paths %}
cleanup_bootstrap_{{ loop.index0 }}:
  salt.runner:
    - name: salt.cmd
    - arg:
      - file.remove
    - kwarg:
        path: {{ dcos.file_root }}/{{ path }}
    - require:
      - salt: stop_bootstrap
  {% endfor %}

  {% if dcos.cleanup_genconf %}
cleanup_genconf:
  salt.runner:
    - name: salt.cmd
    - arg:
      - file.remove
    - kwarg:
        path: {{ dcos.file_root }}/dcos_generate_config.sh
    - require:
      - salt: stop_bootstrap
  {% endif %}
{% endif %}
