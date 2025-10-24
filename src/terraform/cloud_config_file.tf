resource "proxmox_virtual_environment_file" "cloud_config_file" {
  for_each = {
    plex = local.plex_hostname
    # Add more VMs here as needed
    # media = "media-server"
    # apps = "apps"
  }

  content_type = "snippets"
  datastore_id = local.datastores.synology_proxmox
  node_name    = local.proxmox_node_name

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: ${each.value}
    manage_etc_hosts: true
    
    users:
      - name: ${local.default_username}
        gecos: ${title(each.value)} Admin User
        groups: [sudo, users]
        shell: /bin/bash
        ssh_authorized_keys:
          - ${trimspace(data.local_file.mac_ssh_public_key.content)}
          - ${trimspace(data.local_file.ansible_ssh_public_key.content)}
        sudo: ALL=(ALL) NOPASSWD:ALL
        lock_passwd: false
    
    package_update: true
    package_upgrade: true
    
    packages:
      - qemu-guest-agent
      - net-tools
      - curl
      - openssh-server
      - sudo
    
    write_files:
      - path: /etc/cloud/cloud.cfg.d/99-custom.cfg
        content: |
          datasource_list: [ NoCloud, ConfigDrive ]
    
    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      - systemctl restart ssh
      - echo "done" > /tmp/cloud-config.done
    
    power_state:
      delay: now
      mode: reboot
      message: Rebooting after cloud-init
      condition: True
    
    final_message: "Cloud-init completed successfully"
    EOF

    file_name = "${each.value}.cloud-config.yaml"
  }
}
