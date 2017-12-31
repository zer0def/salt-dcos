{% import "dcos/common_vars.sls" as dcos with context %}

bootstrap:
{% include 'dcos/bootstrap.sls_inc' %}
