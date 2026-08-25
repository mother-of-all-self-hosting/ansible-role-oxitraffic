<!--
SPDX-FileCopyrightText: 2023, 2026 Slavi Pantaleev
SPDX-FileCopyrightText: 2025, 2026 Suguru Hirahara

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# OxiTraffic Ansible role

This is an [Ansible](https://www.ansible.com/) role which installs [OxiTraffic](https://codeberg.org/mo8it/oxitraffic) to run as a [Docker](https://www.docker.com/) container wrapped in a systemd service.

This role *implicitly* depends on:

- [`com.devture.ansible.role.playbook_help`](https://github.com/devture/com.devture.ansible.role.playbook_help)
- [`com.devture.ansible.role.systemd_docker_base`](https://github.com/devture/com.devture.ansible.role.systemd_docker_base)

Check [`defaults/main.yml`](defaults/main.yml) for the full list of supported options. Refer to [this page](docs/configuring-oxitraffic.md) for details about setting up the service with this role.

💡 For an Ansible playbook which integrates this role and makes it easier to use, see the [Mother-of-All-Self-Hosting Ansible playbook](https://github.com/mother-of-all-self-hosting/mash-playbook).

## Development

### pre-commit

You can optionally install a Git pre-commit hook (via [mise](https://mise.jdx.dev/) + [prek](https://prek.j178.dev/)) that runs formatting and linting checks before each commit. See [`.pre-commit-config.yaml`](./.pre-commit-config.yaml) for which hooks are to be executed.

To install the hook, run the [`just`](https://github.com/casey/just) command below:

```sh
just prek-install-git-pre-commit-hook
```

### Molecule

This role supports [Molecule](https://docs.ansible.com/projects/molecule/), an Ansible testing framework designed for developing and testing Ansible collections, playbooks, and roles.

Refer to [this page](./molecule/README.md) for details about how to utilize it.

### Releases

Tags are cut automatically, and are derived from the state of the repository rather than from commit messages. [`bin/compute-next-tag.sh`](./bin/compute-next-tag.sh) reads `oxitraffic_version` out of [`defaults/main.yml`](./defaults/main.yml) and compares it against the tags that already exist:

- a version that has never been released starts a new counter (`v0.10.6-0`);
- otherwise the counter is incremented (`v0.10.5-7`), but only when something under `defaults/`, `meta/`, `tasks/` or `templates/` has changed since the previous release. A commit that only touches documentation, CI or the Molecule scenarios does not produce a release.

Because the result depends only on the checked-out state, it does not matter in which order pull requests get merged, and any change to the role — a bugfix as much as a dependency bump — releases itself. [`bin/test-compute-next-tag.sh`](./bin/test-compute-next-tag.sh) exercises this against throwaway repositories, and runs as a prek hook whenever the script or `defaults/main.yml` changes.
