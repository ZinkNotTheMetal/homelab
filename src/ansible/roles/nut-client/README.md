# NUT Client

## Purpose

At the moment I have individual Raspberry PIs that are attached to the UPSes
around the house.

### UPSes

1. Rack UPS - keeps networking equipment online during power outage
2. Computer UPS - keeps computer equipment online during power outage
3. ONT UPS - keeps power to the ONT device to ensure that internet connectivity
   stays online and available during a power outage

## Why this playbook

This playbook is meant to be installed on the main server. This is the central
hub for running / executing commands. These commands have the ability to power
down the NAS and the machine itself once the UPS is running low on battery.
This stops a forced shutdown when the UPS runs out of battery.