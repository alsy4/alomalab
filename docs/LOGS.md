# Implementation log

[2026-09-15 08:06 UTC] - Added the K3s control-plane VM and separated environment declarations

Commits `8085466` and `33a628f` added the reusable K3s VM module and the
`k3s-cp-01` declaration: an Ubuntu Jammy VM (VMID `20100`) on `vmbr20` at
`192.168.20.100/24`. The VM depends on the network module. They also moved the
NAS and Jellyfin declarations to `lxc.tf` and placed the network module call
in `network.tf`. These commits declare the K3s host but do not install K3s.

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
