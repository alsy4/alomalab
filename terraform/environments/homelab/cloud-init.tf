resource "proxmox_virtual_environment_file" "worker_bootstrap" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node

  source_raw {
    file_name = "worker-bootstrap.yaml"
    data      = <<-EOF
        #cloud-config
        package_update: true
        packages:
          - curl
          - qemu-guest-agent

        write_files:
          - path: /usr/local/sbin/worker-bootstrap.sh
            permissions: '0755'
            content: |
              #!/bin/bash
              set -euo pipefail
              echo "Worker bootstrap started"
              # Add your commands here.
              systemctl enable --now qemu-guest-agent
              echo "Worker bootstrap completed"

        runcmd:
          - [bash, /usr/local/sbin/worker-bootstrap.sh]
      EOF
  }
}
