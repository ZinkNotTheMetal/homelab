# Ansible host

I chose to have a separate VM to do this due to the separation of concerns,
but this isn't necessary.

Whichever machine will be running the Ansible process needs the following.

1. Ansible host server (currently in Synology)

    1. Install sudo
    2. Add user to sudo group

        ```bash
        su -
        usermod -aG sudo <user>
        ```

    3. Install git
    4. Install net-tools
    5. Install ansible
    6. Add SSH Key into GitHub to allow pulling my repository

        ```bash
        ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
        ```

2. Pull down [ansible-homelab](https://github.com/ZinkNotTheMetal/ansible-homelab)

3. Run ansible commands to configure the server

## NAS Configuration

[Enable shutdown](https://andreagx.blogspot.com/2017/11/poweroff-linux-based-nas-synology-ecc.html)
