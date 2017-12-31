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
    - require_in:
      - {% if dcos.bootstrap_hosts %}salt{% else %}file{% endif %}: bootstrap

refresh_pillars:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: '*'
    - require:
      - salt: sync_everything
    - require_in:
      - {% if dcos.bootstrap_hosts %}salt{% else %}file{% endif %}: bootstrap

update_mine:
  salt.function:
    - name: mine.update
    - tgt: '*'
    - require:
      - salt: refresh_pillars
    - require_in:
      - {% if dcos.bootstrap_hosts %}salt{% else %}file{% endif %}: bootstrap

bootstrap:
{% if dcos.bootstrap_hosts %}
  salt.state:
    - tgt: 'I@dcos:cluster_name:{{ dcos.cluster_name }} and I@dcos:bootstrap:true'
    - tgt_type: compound
    - sls:
      - dcos.bootstrap
{% else %}
{% include 'dcos/bootstrap.sls_inc' %}
{% endif %}

install:
  salt.state:
    - tgt: 'I@dcos:cluster_name:{{ dcos.cluster_name }} and not I@dcos:bootstrap:true'
    - tgt_type: compound
    - sls:
      - dcos
    - require:
      - {% if dcos.bootstrap_hosts %}salt{% else %}docker_container{% endif %}: bootstrap
    - require_in:
      - {% if dcos.bootstrap_hosts %}salt{% else %}docker_container{% endif %}: bootstrap_cleanup

bootstrap_cleanup:
{% if dcos.bootstrap_hosts %}
  salt.state:
    - tgt: 'I@dcos:cluster_name:{{ dcos.cluster_name }} and I@dcos:bootstrap:true'
    - tgt_type: compound
    - sls:
      - dcos.bootstrap_cleanup
{% else %}
{% include 'dcos/bootstrap_cleanup.sls_inc' %}
{% endif %}
