Run it: `salt-run state.orchestrate dcos.orch`

You might want to run: `salt '*' saltutil.clear_cache && salt '*' saltutil.sync_all && salt '*' saltutil.refresh_pillar && salt '*' mine.update` to gather fresh information on your minions.

Assumptions made:
* This setup is deployed against nodes running Enterprise Linux 7 (tested against CentOS 7, but should work with minor tweaks to sourcing Docker's yum repo)
  * As a side note, the people behind DC/OS could easily expand their installer onto other Linux distributions, if they bothered to have incentive
* Cluster network in question operates on `eth0`
