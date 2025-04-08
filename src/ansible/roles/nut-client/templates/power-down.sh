#!/bin/bash

# Fill in proper NAS variables below

main () {
  log_file="/home/{{ ansible_user }}/nut.power.log"

  log_date "==============================================================================="
  log_date "Power down event received from NUT master, initiating shutdown procedure"
  log_date "home-shutdown.sh has been initiated"
  log_date "==============================================================================="

  shutdown_nas
  shutdown_host

  log_date "==============================================================================="
  log_date "Complete home-shutdown.sh"
  log_date "==============================================================================="
}

shutdown_nas () {
  log_date "Initiated shutdown of Synology NAS by user: $USER"
  ssh -p {{ nas_ssh_port }} {{ user_name }}@{{ nas_ip }} poweroff
}

shutdown_host () {
  log_date "Initiated shutdown of $HOSTNAME by UPSMON user: $USER"
  shutdown -h +1
}

log_date () {
  # logging function formatted to include a date
  echo -e "$(date "+%m/%d/%Y %H:%M:%S"): $1" >> "$log_file" #2>&1
}

main
