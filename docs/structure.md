# 1. Structure Overview

The propose modular structure would look like this:
homelab/
│
├── terraform/                 Infrastructure provisioning
│   ├── modules/               Reusable infrastructure building blocks
│   │   ├── proxmox-vm/        Generic Proxmox VM definition
│   │   └── proxmox-lxc/       Generic Proxmox LXC definition
│   │
│   └── environments/          Concrete deployments of those modules
│       └── homelab/           Your actual home Proxmox environment
│
├── ansible/                   OS and service configuration
│   ├── inventory/             Machines Ansible manages
│   ├── playbooks/             High-level configuration workflows
│   └── roles/                 Reusable Ansible components
│
├── kubernetes/                Desired state of workloads running in k3s
│   ├── apps/                  Applications
│   ├── infrastructure/        Cluster-level supporting services
│   └── namespaces/            Namespace definitions/policies
│
├── nix/                       Declarative Nix/NixOS machine configuration
│   └── hosts/                 Per-machine Nix configuration
│
└── secrets/                   Secret-handling documentation/configurationd

# 2. Provisioning Debian LXC for Jellyfin
Steps:
1. Modules
2. Environments
3. tfvars
4. 

# 3. Create NAS