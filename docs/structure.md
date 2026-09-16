# Repository structure

```text
.
├── .codex/                                      # Repository-local Codex configuration
│   ├── AGENTS.md                                # Response and workflow guidance
│   ├── config.toml                              # Enables configured agents
│   └── agents/
│       └── documentation.toml                   # Documentation-agent scope
├── .github/
│   └── workflows/
│       └── documentation-agent.yml              # Automated documentation update/render workflow
├── ansible/                                     # Host and service configuration
│   ├── README.md                                # Commands, boundaries, and operating notes
│   ├── requirements.yml                         # Git-sourced k3s-ansible collection
│   ├── inventory/
│   │   └── homelab.yml                          # LXC, Proxmox, Piloma, and K3s host groups
│   └── playbooks/
│       ├── jellyfin/
│       │   ├── qbittorrent-setup.yml            # Installs qBittorrent-nox
│       │   ├── radarr-setup.yml                 # Installs Radarr
│       │   ├── setup-jellyfin.yml               # Installs Jellyfin and manages its Caddy route
│       │   ├── setup-mount-points.yml           # Manages Jellyfin LXC bind mounts with pct
│       │   └── update-debian.yml                # Updates both Debian LXC hosts
│       ├── k3s/
│       │   ├── setup-k3s.yml                    # Imports the k3s-ansible cluster playbook
│       │   └── update-debian.yml                # K3s update playbook; target group needs alignment
│       └── nas/
│           ├── samba-setup.yml                  # Configures authenticated Samba shares
│           ├── samba-teardown.yml               # Removes Samba without deleting share data
│           └── setup-syncthing.yml              # Installs Syncthing on both Debian LXCs
├── docs/
│   ├── architecture.md                          # Implemented topology and ownership boundaries
│   ├── architecture-diagram/
│   │   ├── alomalab-homelab.architecture.json   # Archify topology source
│   │   ├── alomalab-homelab.architecture.html   # Generated interactive architecture view
│   │   ├── alomalab-homelab.architecture-redraw.html
│   │   │                                        # Diagram-design source for the static figure
│   │   └── alomalab-homelab.architecture-redraw.svg
│   │                                            # README/docs vector export
│   ├── LOGS.md                                  # Chronological implementation log
│   └── structure.md                             # This guide
├── terraform/
│   ├── versions.tf                              # Root Terraform/provider requirements
│   ├── environments/
│   │   └── homelab/
│   │       ├── .terraform.lock.hcl              # Locked environment provider selection
│   │       ├── image.tf                         # Downloads the Ubuntu Jammy cloud image
│   │       ├── k3s.tf                           # Control plane and two worker VMs
│   │       ├── lxc.tf                           # NAS and Jellyfin LXC declarations
│   │       ├── network.tf                       # Instantiates the reserved Proxmox SDN
│   │       ├── providers.tf                     # Proxmox provider configuration
│   │       ├── variables.tf                     # Environment inputs and sensitive values
│   │       └── versions.tf                      # Environment Terraform requirements
│   └── modules/
│       ├── k3s/
│       │   ├── main.tf                          # Reusable Ubuntu VM resource
│       │   ├── outputs.tf                       # Reserved module outputs file
│       │   ├── variables.tf                     # VM sizing, image, network, and account inputs
│       │   └── versions.tf                      # Module Terraform requirements
│       ├── pve-lxc/
│       │   ├── main.tf                          # Reusable Debian LXC resource
│       │   ├── outputs.tf                       # LXC ID, hostname, and node outputs
│       │   ├── variables.tf                     # LXC and bind-mount inputs
│       │   └── versions.tf                      # Module Terraform requirements
│       └── sdn/
│           ├── main.tf                          # Zone, VNet, subnet, applier, and vmbr20 bridge
│           ├── outputs.tf                       # VNet identifier
│           ├── variable.tf                      # Reserved module variables file
│           └── versions.tf                      # Module Terraform requirements
└── .gitignore                                   # Excludes local Terraform state and tfvars
```

Terraform owns the Proxmox guests and the separately declared SDN. Ansible
configures K3s and the services after provisioning. The active K3s VMs use
`vmbr0`; `network.tf` still instantiates `vmbr20`, but `k3s.tf` does not attach
the VMs to it.

Generated `.terraform/` directories, state, state backups, and `*.tfvars` are
ignored. One historical state backup,
`terraform/environments/homelab/terraform.tfstate.1789457976.backup`, remains
tracked from an earlier commit even though it is not maintained source. Treat
it as sensitive and remove it from repository history in a separate,
deliberate security change.
