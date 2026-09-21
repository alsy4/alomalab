# Implementation log

[2026-09-21 06:04 UTC] - Documented current GitOps setup and database recovery

Repository and read-only cluster inspection confirmed Glance watches branch
`kube`, while monitoring uses kube-prometheus-stack 91.4.1 and branch `main`.
Both Applications were Synced/Healthy and PostgreSQL had three ready instances.
Documented manually applied PostgreSQL, local-path storage, the retired worker
cleanup performed earlier in this session, stale Ansible inventory, current
Traefik ports, and the empty PodMonitor source. This is an operational review,
not an implementation commit. Only documentation changed during this update.

[2026-09-18 10:23 UTC] - Verified the Caddy-to-K3s Glance route and documented the workload

Read-only inspection confirmed the live Glance Caddy site on Piloma forwarding
to Traefik at `192.168.0.200:32041`, two healthy Glance replicas, the host-based
Ingress, ClusterIP Service, and ConfigMap-backed configuration/assets volumes.
Added the detailed K3s SVG and Glance runbook, and updated the architecture,
repository structure, root README, and Ansible notes. Recorded DNS bypassing
Caddy, the retired NotReady Pi node, the obsolete local proxy fallback, and
Glance inside Jellyfin's managed Caddy markers. No infrastructure was changed;
this entry records direct observations, not an inferred deployment commit.

[2026-09-16 14:26 UTC] - Removed Piloma from the K3s cluster

The Raspberry Pi formerly identified as `pi-worker-01` is no longer a
Kubernetes node. Piloma (`192.168.0.14`) remains the externally managed Caddy
reverse proxy, while the K3s cluster now consists only of the Proxmox control
plane and two worker VMs at `192.168.0.200–202`.

[2026-09-16 08:15 UTC] - Added the K3s inventory and cluster setup playbook

Commits `4870582` and `6112182` added the `k3s_cluster` inventory with one
`server` (`192.168.0.200`) and two `agent` hosts (`192.168.0.201–202`), added a
Git-sourced `k3s-ansible` collection requirement, and added a wrapper that pins
K3s to `v1.36.3+k3s1` and imports `k3s.orchestration.site`. The accompanying
Debian update playbook targets `k3s_nodes`, which is not defined by the current
inventory and therefore selects no hosts.

[2026-09-15 10:36 UTC] - Expanded K3s to a three-VM cluster on vmbr0

Commit `419dcdc` moved `k3s-cp-01` from the reserved `vmbr20` subnet to
`vmbr0` at `192.168.0.200`, added `k3s-worker-01` and `k3s-worker-02` at
`192.168.0.201–202`, and imported the shared Ubuntu Jammy image into each VM.
The two workers use VMIDs `20101–20102`, one vCPU, 1 GiB of dedicated memory,
and an 8 GiB disk each. The SDN resources remained declared but ceased to be
part of the VM path.

[2026-09-15 08:06 UTC] - Added the K3s control-plane VM and separated environment declarations

Commits `8085466` and `33a628f` added the reusable K3s VM module and the
`k3s-cp-01` declaration: an Ubuntu Jammy VM (VMID `20100`) on `vmbr20` at
`192.168.20.100/24`. The VM depends on the network module. They also moved the
NAS and Jellyfin declarations to `lxc.tf` and placed the network module call
in `network.tf`. These commits declared the initial K3s host but did not install
K3s; commit `419dcdc` later replaced this single-VM network arrangement.

[2026-09-15 08:00 UTC] - Replaced the temporary VLAN module with Proxmox SDN

Commits `155b4d9` and `943ef0e` removed the temporary VLAN module and added a
Proxmox simple SDN zone (`k3szone`), VNet (`k3svnet`), and `192.168.20.0/24`
subnet. The module applies that configuration and creates the `vmbr20` Linux
bridge on `proxmox` at `192.168.20.1/24`. It does not configure upstream
routing, DHCP, DNS, or firewall policy.

[2026-09-14 08:36 UTC] - Reorganized Terraform infrastructure files

Commits `43848fa` and `b51983d` introduced the initial, temporary bridge
definition for the K3s subnet, renamed the LXC outputs file to `outputs.tf`,
and removed the obsolete root Terraform lock file. The temporary network module
was superseded by the Proxmox SDN module in the following day's changes.

[2026-09-13 07:15 UTC] - Added Syncthing provisioning for Debian LXC hosts

Commit `b34cf31` added `ansible/playbooks/nas/setup-syncthing.yml`. The
playbook installs Syncthing on every host in the `debian_lxc` inventory group,
creates the `syncthing` system account and service home at
`/var/lib/syncthing`, enables `syncthing@syncthing.service`, and checks its local
administration interface on port `8384`. Device pairing and folder selection
remain an operational step after provisioning because the playbook does not
store device IDs or folder paths.

[2026-09-13 05:42 UTC] - Configured documentation pull-request authentication

Commit `c400e45` changed the documentation workflow to use the
`DOCUMENTATION_PR_TOKEN` repository secret when it runs `gh pr create`. It now
stops with a clear error if the secret is missing. This allows the workflow to
create documentation pull requests when the repository setting prevents the
built-in GitHub token from doing so.
