<!--
SPDX-FileCopyrightText: 2018-2025 Slavi Pantaleev
SPDX-FileCopyrightText: 2019-2022 Aaron Raimist
SPDX-FileCopyrightText: 2019-2023 MDAD project contributors
SPDX-FileCopyrightText: 2023 QEDeD
SPDX-FileCopyrightText: 2024 Fabio Bonelli
SPDX-FileCopyrightText: 2024 Nikita Chernyi
SPDX-FileCopyrightText: 2024-2026 Suguru Hirahara
SPDX-FileCopyrightText: 2026 spatterlight

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Molecule Testing

This role supports [Molecule](https://docs.ansible.com/projects/molecule/), an Ansible testing framework designed for developing and testing Ansible collections, playbooks, and roles.

## Prerequisites

To utilize Molecule you need to prepare several requirements:

- **x86** computer running one of these operating systems that make use of [systemd](https://systemd.io/):
  - **Archlinux**
  - **CentOS**, **Rocky Linux**, **AlmaLinux**, or possibly other RHEL alternatives (although your mileage may vary)
  - **Debian** (10/Buster or newer)
  - **Ubuntu** (18.04 or newer, although [20.04 may be problematic](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/ansible.md#supported-ansible-versions) if you run the Ansible playbook on it)
- `root` access on the computer which Molecule runs against
- [Ansible](http://ansible.com/) program
- [Python](https://www.python.org/)
  - Most distributions install Python by default, but some don't (e.g. Ubuntu 18.04) and require manual installation (something like `apt-get install python3`)
- [Docker](https://www.docker.com)
  - Access to Docker UNIX socket (`/var/run/docker.sock`) is required by default

## Installation

To set up the environment for using Molecule, run the command below on the terminal:

```bash
python3 -m venv ./molecule/venv
source ./molecule/venv/bin/activate
pip3 install -r ./molecule/requirements.txt
```

## Scenarios

Currently these testing scenarios are available:

### `default`

Tests a standard OxiTraffic installation against a Postgres database, and takes a page view all the way through it.

Before anything is credited to the role, the scenario runs the same container image three times in ways the role did not intend, and requires each of them to fail:

- with no configuration at all, OxiTraffic dies with `Failed to parse the configuration`;
- with the role's own rendered `config.toml` but without the Postgres socket the role bind-mounts, it dies with `Failed to connect to the PostgreSQL database` — there is no embedded or in-memory store it can fall back to, which is what makes the Postgres cross-check below mean something;
- with the socket but no network, it dies naming the exact URL `oxitraffic_tracked_origin_callback` configured, which is how that value is shown to have reached the process rather than merely the disk.

It then registers a page view the way the `count.js` tracking script does, is refused when it reports the visit before OxiTraffic's minimum delay has passed, waits it out, reports the visit, and finds exactly one visit for that path — and none for a path nobody visited — both through `/api/count` and by querying the `oxitraffic` database in Postgres directly.

Configuration is pinned in both directions along the way. The dashboard footer renders `env!("CARGO_PKG_VERSION")` and must equal `oxitraffic_version`; the image itself carries no version label, its only OCI label being `io.buildah.version`. The tracking script must carry the role's own base URL and be served for the role's `tracked_origin`. And the scenario listens on a port that is neither OxiTraffic's own fallback of 80 nor the role's default of 8080.

Finally, `NRestarts` is sampled either side of the round trip and must be zero, because `Restart=always` makes `systemctl is-active` report `active` for a container that is crash-looping.

OxiTraffic refuses to start unless it can fetch the website it is tracking, and refuses to register a path it cannot find there, so the scenario runs a `traefik/whoami` container on OxiTraffic's own network as a stand-in for that website. Reaching out to a real site would make the run depend on a third party being up, and Docker 28+ blocks container-to-host-port traffic over the bridge gateway, so a stub on the container network is needed either way.

### `default-selfbuild`

Tests a standard OxiTraffic installation with self-building the container image.

Rather than repeat the `default` scenario, it checks what only self-building can get wrong: that the image has no registry digest and no registry prefix (so it was built here rather than quietly pulled), and that the source checkout the build used is at the revision `oxitraffic_version` names. It then confirms that what came out of the build reports itself as that same version, serves a tracking script built from the role's configuration, and counts a page view into Postgres.

That version assertion is the one to watch. Upstream's `Containerfile` does not build the source it ships with — it runs `cargo install oxitraffic --locked`, which fetches whatever crates.io publishes as the latest at build time. The self-built binary is therefore only the pinned version for as long as crates.io and the container tags stay in step. If this scenario ever fails on the version while the source checkout is at the right revision, the role is self-building something other than what it pins.

Because a self-build compiles OxiTraffic from scratch, CI only runs this scenario when a version in `defaults/main.yml` actually changed, or when it is asked for via `workflow_dispatch`.

## Running

By default it is configured to run the scenarios on Ubuntu 26.04.

```bash
molecule test --scenario-name default
```

You can utilize other distributions by setting one to the `MOLECULE_DISTRO` environment variable:

```bash
# Ubuntu 24.04
MOLECULE_DISTRO=ubuntu2404 molecule test --scenario-name default

# Debian 13
MOLECULE_DISTRO=debian13 molecule test --scenario-name default

# Debian 12
MOLECULE_DISTRO=debian12 molecule test --scenario-name default
```
