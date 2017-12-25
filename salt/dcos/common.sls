dcos_common:
{% if grains['os_family'] == 'RedHat' %}
  pkgrepo.managed:
    - name: docker
    - baseurl: https://packages.docker.com/1.13/yum/repo/main/centos/7
    - enabled: 1
    - gpgcheck: 1
    - gpgkey: https://sks-keyservers.net/pks/lookup?op=get&search=0xee6d536cf7dc86e2d7d56f59a178ac6c6238f52e
  pkg.installed:
    - refresh: true
    - reload_modules: true
    - pkgs:
      - docker-engine
      - python-docker-py
    - require:
      - pkgrepo: dcos_common
    - require_in:
      - service: dcos_common
{% endif %}
  service.running:
    - name: docker
    - enable: true
