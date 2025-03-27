# Prerequisites before running ansible

These things can't be done easily with Ansible so I'm just going to do them manually

1. Setup Debian (with {user_name})

2. Change power config (in case of random power failure)

   1. Reboot the server
   2. Press F2 during boot to enter BIOS Setup
   3. Go to the Power > Secondary Power Settings menu
   4. Set the option for After Power Failure to Power On
   5. Press F10 save changes and exit BIOS

3. Install sudo

   ```bash
   apt-get install sudo
   ```

4. With root user add the user to the sudo group

   ```bash
   usermod -a -G sudo {{ user_name }}
   ```

5. Add SSH Key from Ansible server to configured server

   1. Generate a key if needed

      ```bash
      ssh-keygen -t rsa
      ```

   2. Copy public keys to managed node

      ```bash
      ssh-copy-id -i ~/.ssh/id_rsa.pub <user>@<ipaddr>
      ```

6. Get ssh-key for git

   1. Run Ansible common or use the command below
  
      ```bash
      ssh-keygen -t rsa
      ```

   2. Put new key into GitHub (SSH Keys under settings)

7. Generate a PAT in docker hub

   1. Go to account
   2. Then Security
   3. Generate a new PAT with the hostname of the machine
   4. Put into vars.yml

8. Pull any git repository down to verify token

   ```bash
   cd ~/git
   git clone git@github.com:zsh-users/zsh-syntax-highlighting.git
   ```

9.  Ensure NAS has proper NFS Permissions

   1. Login to NAS
   2. Ensure NFS is enabled
   3. In Control Panel edit folder
   4. At the top tab go to NFS Permissions
   5. R/W / Hostname / no squash
   6. Save

10. Run ansible command

   ```bash
   ansible-playbook -K -i production site.yml
   ```
