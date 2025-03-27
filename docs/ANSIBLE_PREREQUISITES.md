# Ansible host

I chose to have a separate VM to do this due to the separation of concerns,
but this isn't necessary.

Whichever machine will be running the Ansible process needs the following.

1. Ansible host server (currently in Synology)

    1. Install ansible
    2. Install sudo
    3. Add user to /etc/sudoers
    4. Add net-tools
    5. Add nodejs (not necessary but can help with package.json scripts)

2. Pull down [ansible-homelab](https://github.com/ZinkNotTheMetal/ansible-homelab)

3. Run ansible commands to configure the server

## NAS Configuration

[Enable shutdown](https://andreagx.blogspot.com/2017/11/poweroff-linux-based-nas-synology-ecc.html)
