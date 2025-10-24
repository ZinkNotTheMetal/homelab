data "local_file" "mac_ssh_public_key" {
  filename = "/Users/william/.ssh/id_rsa.pub"
}

data "local_file" "ansible_ssh_public_key" {
  filename = "/Users/william/.ssh/ansible_id_rsa.pub"
}
