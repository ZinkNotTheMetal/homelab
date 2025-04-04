# My Homelab

If you are new to 'Homelab'ing I recommend investigating it more, but it allows you
to have a server that is on my local network so that I don't need to pay for external
services. The external services that I use will be listed below. There are some great
resources when it comes to running a Homelab and you should definitely see if
it's right for you!

## Resources

- [/r/selfhosted - Reddit](https://www.reddit.com/r/selfhosted/)
- [selfh.st](https://selfh.st)
- [Ansible](https://www.ansible.com)
- [My Smart Home Configuration](https://github.com/ZinkNotTheMetal/my-smart-home)

## Equipment

This can vary depending on budget and amount of space that you have available.

But here is what my current Home Lab server exists of:

- [NUC8-i3 Short](https://amzn.to/43ttxG5) - [Newer model here](https://amzn.to/44L3w69)
- [32GB RAM](https://amzn.to/43q9doY)
- 128GB NVME Drive - [1TB Drive for same cost I paid](https://amzn.to/3ro1B97)

In addition:

- 3x [Raspberry Pi Zero W](https://)
- 1x [Raspberry Pi Model 4 - 4 GB](https://)

## Why and how is your home server in GitHub?

GitHub provides me a great place to store my configuration and share with the
community the work I put into keeping this server up to date. [Ansible](https://www.ansible.com)
let's me run this configuration deterministically so that my server can stay up
to date and make sure that no configuration is done manually.
I found out quickly when I started maintaining my homelab that it became very difficult
to maintain all the changes that I wanted to make. Watching some of my favorite
YouTubers they maintain a list of docker-compose files that will do something similar,
but with Ansible I can automate and schedule this to be ran to ensure my homelab
is functioning properly and I'm able to monitor if things fail.
This gives me the ability to write playbooks to ensure that things weren't done
manually and switches my mentality to automate and test first using version control.

## What all does it run? 🤷‍♂️

The Intel machine I purchased above is running very well and has had a very small
downtime since it's initial purchase. It's been working for me since January 2019
and I haven't seen a reason to upgrade for the current list of apps that I run.
I would recommend this machine or something similar for a low power consumption
capable device.

## Operating System

[Debian w/o a UI](https://)

[Docker](https://www.docker.com) - is also paramount for my setup. I have found that
utilizing containers it makes testing and homelab-ing easier for setup and tear down.
My first trial is to SSH into the machine run a docker command then convert it
to Ansible once I have found that the service provides me value.

## Applications

### [Server Prerequisites](docs/SERVER_PREREQUISITES.md)

Ensure that you look over and run any necessary commands in Server Prerequisites
before you run any ansible command. There are some steps that are required before
any Ansible run.

| Application Name | Ansible Role | Description |
|----------|----------|----------|
| [at](https://linuxize.com/post/at-command-in-linux/) | Common | Similar to cron but more descriptive in my opinion |
| [docker](https://www.docker.com) | Common | Explained above but used to run applications in a containerized environment |
| [PiHole](https://pi-hole.net) | DNS | This allows me to block traffic to ads at the DNS level and remove them from my network. I put this in it's own role as I install backup instances in case the main node goes down |
| [IT Tools](https://) | Application | IT Tools is a collection of utilities that can come in handy for developers / IT Professionals |
| [Mealie](https://mealie.io) | Application | This creates a personal website to store all of our favorite recipes, it also allows you to put in a URL and pull the recipe from the internet which comes in handy. |
| [Netboot](https://) | Application | This creates a network share that can help with installing linux distributions to new VMs without needing to download the ISO or needing external media (USB Drive) |
| [Portainer](https://www.portainer.io) | Application | Powerful dashboard for all things docker. I don't use it very often and find myself defaulting to the docker commandline but can be helpful |
| [pgAdmin](https://) | Application | PostGREs SQL admin tool via a website that allows me to login into database servers, execute scripts and view data |
| [Stirling PDF](https://) | Application | Stirling PDF is a collection of utilities that help with PDFs (i.e. splitting out pages, converting, modifying metadata) |
| [Traccar](https://) | Application | Open source Life360(TM) application that allows you to track location information locally. It's a free service that helps with location based Home automations |
| [Watchtower](https://containrrr.dev/watchtower) | Application | Service that keeps all docker images up to date as long as they have a proper label in docker |
| [Traefik](https://) | Application | Reverse proxy and certificate provider for all container services. This allows me to type in friendly names into my address bar instead of having to remember which port the application specified |
| [Plex](https://www.plex.tv) | Application | A local media player with fantastic support, unfortunately closed source and I did purchase a lifetime license |
| [Tautulli](https://tautulli.com) | Application | Tool for statistics for the Plex Server |
| [Overseerr](https://) | Application | Helpful application to manage when I want to purchase or find someone who purchased a movie for Plex |
| [Prowlarr](https://) | Application | IYKYK |
| [Radarr](https://) | Application | Movie Manager to alert me of my current media and manage requests of movies that I would like to see that I don't have in my library yet |
| [Sonarr](https://) | Application | TV Manager to alert me when a new episode of my favorite TV shows come out so that I can DVR them |
| [Transmission](https://transmissionbt.com) | Application | Great for downloading .iso / open source software that are larger files that many people are seeding |
| [Authentik](https://) | N/A | Single Sign-on provider that I use so that services can utilize a single password without having to setup a different user/password for each service |
| [NUT (Network UPS Tools)](https://www.networkupstools.org) | N/A | Tool to monitor multiple UPSs in my home. I have a client / server setup. Explained in [TechnoTim's NUT](https://) setup. |

I also run Home Assistant, Node-Red, ESP Home, ZWaveJS and others but
more information on that topic can be found at my other repository

[My Smart Home Configuration](https://github.com/ZinkNotTheMetal/my-smart-home)
