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
│   ├── LOGS.md                                  # Chronological implementation log
│   └── structure.md                              # This guide
├── terraform/                                   # Proxmox infrastructure definitions
│   ├── .terraform.lock.hcl                      # Locked provider selections
│   ├── versions.tf                              # Root Terraform and provider requirements
│   ├── environments/
│   │   └── homelab/
│   │       ├── .terraform.lock.hcl              # Environment provider lock file
│   │       ├── main.tf                          # NAS and Jellyfin LXC declarations
│   │       ├── providers.tf                     # Proxmox provider configuration
│   │       ├── variables.tf                     # Environment inputs and credentials
│   │       └── versions.tf                      # Environment Terraform requirements
│   └── modules/
│       └── pve-lxc/
│           ├── main.tf                          # Reusable Debian LXC resource
│           ├── output.tf                        # LXC ID, hostname, and node outputs
│           ├── variables.tf                     # LXC resource inputs, including bind mounts
│           └── versions.tf                      # Module Terraform requirements
└── .gitignore                                   # Excludes local Terraform artifacts
```

`terraform/` provisions the LXC infrastructure and `ansible/` configures hosts
and services after provisioning. `.github/` contains GitHub Actions automation,
while `.codex/` constrains the repository-local documentation agent. The
workflow creates a documentation pull request with the
`DOCUMENTATION_PR_TOKEN` repository secret when it has documentation changes to
publish. Generated Terraform working directories, state, variable files, and
backup state files are excluded by `.gitignore`.
