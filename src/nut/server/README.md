# Installing NUT Server

I am utilizing three Raspberry Pi Zero Ws to track UPSes around
the house.

## Operating System Installation

1. Insert SD Card into an SD Card Reader
2. Use Raspberry Pi Imager (available on brew)
3. Setup all configuration and use headless mode
4. Install SD and turn on Raspberry Pi

### NUT Installation

1. SSH into Raspberry Pi once up on the network

2. Update Raspberry Pi

    ```bash
    sudo apt update && sudo apt upgrade
    ```

3. Run 'lsusb' to figure out if USB is connected

    ```bash
    lsusb
    ```

4. Install NUT
   1. If needed turn off IOT firewall to pull and update packages

    ```bash
    sudo apt install nut nut-server vim
    ```

5. Turn back on firewall

6. Run NUT scanner

    ```bash
    sudo nut-scanner -U
    ```

7. Save this information (will need when we setup NUT)

8. Backup example NUT config

    ```bash
    sudo cp /etc/nut/ups.conf /etc/nut/ups.conf.bak
    ```

9. Update NUT config

    ```bash
    sudo vim /etc/nut/ups.conf
    ```

    1. Clear all information
    2. Add pollinterval = 1
    3. Add maxretries = 3
    4. Paste in UPS configuration from NUT scanner

10. Backup example NUT monitor config

    ```bash
    sudo cp /etc/nut/upsmon.conf /etc/nut/upsmon.conf.bak
    ```

11. Update UPS monitor

    ```bash
    sudo vim /etc/nut/upsmon.conf
    ```

    1. Clear all information
    2. Monitor the UPS

        ```bash
        RUN_AS_USER root
        MONITOR <upsname>@localhost 1 <username> <password> master
        ```

12. Backup example UPSD config

    ```bash
    sudo cp /etc/nut/upsd.conf /etc/nut/upsd.conf.bak
    ```

13. Configure UPSD file

    ```bash
    sudo vim /etc/nut/upsd.conf
    ```

    1. Clear all information
    2. Configure listening address (127.0.0.1 only if you want to setup local)

      ```bash
      LISTEN 0.0.0.0 3493
      ```

14. Backup example NUT config

    ```bash
    sudo cp /etc/nut/nut.conf /etc/nut/nut.conf.bak
    ```

15. Configure NUT configuration

    ```bash
    sudo vim /etc/nut/nut.conf
    ```

    ```text
    1. none: NUT is not configured, or use the Integrated Power Management, or use
       some external system to startup NUT components. So nothing is to be started.
    2. standalone: This mode address a local only configuration, with 1 UPS
       protecting the local system. This implies to start the 3 NUT layers (driver,
       upsd and upsmon) and the matching configuration files. This mode can also
       address UPS redundancy.
    3. netserver: same as for the standalone configuration, but also need
       some more network access controls (firewall, tcp-wrappers) and possibly a
       specific LISTEN directive in upsd.conf.
       Since this MODE is opened to the network, a special care should be applied
       to security concerns.
    4.  - netclient: this mode only requires upsmon.
    ```

    1. Figure the mode you want to configure

16. Backup example NUT User config

    ```bash
    sudo cp /etc/nut/upsd.users /etc/nut/upsd.users.bak
    ```

17. Configure NUT User config

    ```bash
    sudo vim /etc/nut/upsd.users
    ```

    1. Add password from step 11
    2. upsmon - user config

      ```text
      # Example
      [monuser]
        password = <password here>
        admin master
      ```

18. Restart all services

    ```bash
    sudo service nut-server restart
    sudo service nut-client restart
    sudo systemctl restart nut-monitor
    sudo upsdrvctl stop
    sudo upsdrvctl start
    ```

19. UPS Monitor is now successfully up and running
