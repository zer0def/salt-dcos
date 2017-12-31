{% import "dcos/common_vars.sls" as dcos with context %}

bootstrap_cleanup:
{% include 'dcos/bootstrap_cleanup.sls_inc' %}
