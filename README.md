# Run it!: `salt-run state.orchestrate dcos.orch`

Assumptions made:
* This setup is deployed against nodes running Enterprise Linux 7 (tested against CentOS 7, but should work with minor tweaks to sourcing Docker's yum repo)
  * As a side note, the people behind DC/OS could easily expand their installer onto other Linux distributions, if they bothered to have incentive
* Cluster network in question operates on `eth0`
* The pillar value `dcos:minion_bootstrap` controls whether a dedicated Salt minion bootstrap node is provisioned or whether the Salt master should be the DC/OS bootstrap source
