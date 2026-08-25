#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Slavi Pantaleev
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# Prints the tag that the currently checked out commit should be released as,
# or nothing at all if it does not warrant a release.
#
# Usage: bin/compute-next-tag.sh
#
# Tags look like `v<OxiTraffic version>-<release>`, which is what this
# repository has always published (v0.6.1-0 ... v0.10.5-6):
#
# - if defaults/main.yml points at an OxiTraffic version that has never been
#   released, the release counter restarts at 0 (`v0.10.6-0`)
# - otherwise the counter is incremented (`v0.10.5-7`), but only if something
#   that actually affects the role has changed since the last release
#
# Determining the version from defaults/main.yml, rather than from the commit
# message of the pull request that got merged, makes the result independent of
# the order in which pull requests get merged, and lets any change to the role
# (bugfix, feature, dependency bump) release itself without a human tagging.
#
# The commit-message approach this replaced could only ever react to a commit
# authored by renovate[bot] whose subject matched "docker tag to ", and only
# within the last 20 commits. Every hand-written fix to this role - and there
# have been seven of them since v0.10.5-0 - went unreleased unless somebody
# tagged it themselves, and a Renovate bump that landed more than 20 commits
# ago stopped being taggable at all.

set -euo pipefail

repository_path="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$repository_path"

defaults_path='defaults/main.yml'

# Paths that shape the behavior of the role for its consumers. A commit
# touching only other paths (a README fix, CI configuration, Molecule tests)
# does not change what a playbook run does, and releasing it would only create
# churn in the repositories that consume this role.
role_defining_paths=(
	'defaults'
	'meta'
	'tasks'
	'templates'
)

# Anchored on `oxitraffic_version:` so that neither a commented-out example nor
# the variables derived from it - `oxitraffic_container_image_tag` and
# `oxitraffic_container_image_self_build_repo_version`, both of which expand
# `{{ oxitraffic_version }}` - can be mistaken for it. This is also the exact
# line the `# renovate:` annotation above it points Renovate at, so the tag and
# the bump can never disagree about which variable they mean.
version="$(sed -nE 's|^oxitraffic_version:[[:space:]]*"?([^"[:space:]]+)"?.*$|\1|p' "$defaults_path" | head -n1)"

if [ -z "$version" ]; then
	echo >&2 "Could not determine the OxiTraffic version from $defaults_path"
	exit 1
fi

# OxiTraffic's own version is carried with a leading `v` (`oxitraffic_version:
# v0.10.5`), and the tags carry one too, so the prefix is stripped and re-added
# rather than doubled. Tolerating a value without it keeps a future change of
# convention from producing `vv0.10.5-0`.
tag_prefix="v${version#v}-"

# Of all releases of this version, the highest release number. Sorted
# numerically, so that -10 is recognized as newer than -9.
last_release="$(git tag --list "${tag_prefix}*" | sed -e "s|^${tag_prefix}||" | grep -E '^[0-9]+$' | sort -n | tail -n1 || true)"

if [ -z "$last_release" ]; then
	echo >&2 "Version $version has never been released"
	echo "${tag_prefix}0"
	exit 0
fi

previous_tag="${tag_prefix}${last_release}"

if git diff --quiet "$previous_tag" HEAD -- "${role_defining_paths[@]}"; then
	echo >&2 "Nothing affecting the role has changed since $previous_tag"
	exit 0
fi

echo >&2 "The role has changed since $previous_tag"
echo "${tag_prefix}$((last_release + 1))"
