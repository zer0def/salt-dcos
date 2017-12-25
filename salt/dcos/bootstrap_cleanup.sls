{% import "dcos/common_vars.sls" as dcos with context %}

dcos_bootstrap_cleanup:
  docker_container.absent:
    - name: {{ dcos.bootstrap_container_name }}
    - force: true
  file.absent:
    - names: {{ dcos.cleanup_paths }}
    - require:
      - docker_container: dcos_bootstrap_cleanup

{% if dcos.cleanup_genconf %}
dcos_bootstrap_cleanup_genconf:
  file.absent:
    - name: {{ dcos.file_root }}/dcos_generate_config.sh
{% endif %}
