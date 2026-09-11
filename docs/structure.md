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
2. variables
3. Environments
4. tfvars

```terraform
tf init
tf apply
tf state
tf destroy
```

1. Create mountpoints
2. Attach it to containers
```bash
pct set <VM-ID> -mp0 /mnt/hdd/shared,mp=/mnt/shared
pct set <VM-ID> -mp0 /mnt/hdd/media,mp=/mnt/media
```

## Remove accidentally committed file
1. 

# 3. Create NAS
