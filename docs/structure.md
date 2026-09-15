# Repository structure

```text
.
├── .codex/                                      # Codex agent configuration
│   ├── AGENTS.md                                # Repository instructions for Codex
│   ├── config.toml                              # Enables configured agents
│   └── agents/
│       └── documentation.toml                   # Documentation-agent definition and scope
├── .github/
│   └── workflows/
│       └── documentation-agent.yml              # Documentation-update automation on main
├── ansible/                                     # Service and host configuration
│   ├── README.md                                # Playbook commands and operating notes
│   ├── inventory/
│   │   └── homelab.yml                          # Managed hosts and address mapping
│   └── playbooks/
│       ├── jellyfin/
│       │   ├── qbittorrent-setup.yml            # Installs and starts qBittorrent-nox
│       │   ├── radarr-setup.yml                 # Installs and starts Radarr
│       │   ├── setup-jellyfin.yml               # Configures Jellyfin and its Caddy proxy route
│       │   ├── setup-mount-points.yml           # Configures Jellyfin LXC bind mounts in Proxmox
│       │   └── update-debian.yml                # Updates Debian LXC packages
│       └── nas/
│           ├── samba-setup.yml                  # Configures NAS Samba shares
│           ├── samba-teardown.yml               # Removes Samba while retaining share data
│           └── setup-syncthing.yml              # Installs Syncthing on both Debian LXC hosts
├── docs/                                        # Repository documentation
│   ├── architecture.md                           # Confirmed homelab topology and dependencies
│   ├── architecture-diagram/                     # Archify architecture-diagram source and delivered artifacts
│   │   ├── alomalab-homelab.architecture.html    # Delivered interactive architecture diagram
│   │   └── alomalab-homelab.architecture.json    # Source for the confirmed topology diagram
│   ├── LOGS.md                                  # Chronological implementation log
│   └── structure.md                              # This guide
├── terraform/                                   # Proxmox infrastructure definitions
│   ├── .terraform.lock.hcl                      # Locked provider selections
│   ├── versions.tf                              # Root Terraform and provider requirements
│   ├── environments/
│   │   └── homelab/
│   │       ├── .terraform.lock.hcl              # Environment provider lock file
│   │       ├── k3s.tf                           # K3s control-plane VM declaration
│   │       ├── lxc.tf                           # NAS and Jellyfin LXC declarations
│   │       ├── network.tf                       # Instantiates the K3s SDN and bridge module
│   │       ├── providers.tf                     # Proxmox provider configuration
│   │       ├── variables.tf                     # Environment inputs and credentials
│   │       └── versions.tf                      # Environment Terraform requirements
│   ├── modules/                                 # Reusable Proxmox infrastructure modules
│       ├── k3s/
│       │   ├── main.tf                          # Ubuntu VM image download and VM resource
│       │   ├── outputs.tf                       # Reserved module outputs file (currently empty)
│       │   ├── variables.tf                     # K3s VM inputs
│       │   └── versions.tf                      # Module Terraform requirements
│       ├── pve-lxc/
│           ├── main.tf                          # Reusable Debian LXC resource
│           ├── outputs.tf                       # LXC ID, hostname, and node outputs
│           ├── variables.tf                     # LXC resource inputs, including bind mounts
│           └── versions.tf                      # Module Terraform requirements
│       └── sdn/
│           ├── main.tf                          # K3s SDN zone, VNet, subnet, applier, and bridge
│           ├── variable.tf                      # Reserved module variables file (currently empty)
│           └── versions.tf                      # Module Terraform requirements
│   └── versions.tf                               # Root Terraform and provider requirements
└── .gitignore                                   # Excludes local Terraform artifacts
```

`terraform/` provisions the LXC infrastructure, K3s network, and control-plane
VM; `ansible/` configures hosts and services after provisioning. `.github/`
contains GitHub Actions automation, while `.codex/` constrains the
repository-local documentation agent. After a
qualifying documentation-agent run, the workflow renders the Archify source to
an HTML artifact in `docs/architecture-diagram/`. The workflow creates a
documentation pull request with the
`DOCUMENTATION_PR_TOKEN` repository secret when it has documentation changes to
publish. Generated Terraform working directories, state, variable files, and
backup state files are excluded by `.gitignore`; a committed state backup is
not part of the maintained repository structure.
