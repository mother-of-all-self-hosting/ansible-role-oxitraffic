# OxiTraffic Ansible Role

![OxiTraffic Logo](assets/logo.svg)

OxiTraffic is a self-hosted, simple and privacy respecting website traffic tracker. This role helps you to set up OxiTraffic:

- with everything run in [Docker](https://www.docker.com/) containers
- powered by [the official OxiTraffic container image](https://hub.docker.com/r/mo8it/oxitraffic)


## Installing

To configure and install OxiTraffic on your own server(s), you should use a playbook like [Mother of all self-hosting](https://github.com/mother-of-all-self-hosting/mash-playbook) or write your own.

# Configuring this role for your playbook

```
oxitraffic_enabled: true
oxitraffic_hostname: 'example.org'

oxitraffic_db_host:

oxitraffic_db_name:
oxitraffic_db_user:
oxitraffic_db_password:
```

# Developer Notes

