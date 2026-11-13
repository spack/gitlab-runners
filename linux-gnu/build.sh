#!/bin/bash
# Runs in the base image, see .github/workflows/linux-gnu.yml. Inputs: REGISTRY,
# TAG, TARGET, BASE, GITHUB_ACTOR, GITHUB_TOKEN; mounts: /spack, /spack-packages.
set -euo pipefail

# AlmaLinux's gcc 8.5 and what Spack needs to run. libstdc++-static (for gcc's
# bootstrap) is in powertools.
dnf install -y --setopt=install_weak_deps=False --enablerepo=powertools \
  binutils bzip2 diffutils file findutils gcc gcc-c++ git gzip libstdc++-static \
  make patch python3 tar unzip xz

mkdir /env
cp "$(dirname "$0")/spack.yaml" /env
export PATH=/spack/bin:$PATH SPACK_ENV=/env

# Generic microarchitecture, not the runner's (e.g. neoverse_n2 / zen4).
spack config add "packages:all:require:[target=$TARGET]"
# Packages are pushed as soon as they are built, so a re-run resumes.
spack mirror add --unsigned --autopush \
  --oci-username-variable GITHUB_ACTOR --oci-password-variable GITHUB_TOKEN \
  cache "oci://$REGISTRY/linux-gnu-cache"

spack concretize
# llvm has its own `require`, which takes precedence over the one for `all`.
test "$(spack --color=never find -c --format '{target}' | awk '!/^==>/ && NF {print $NF}' | sort -u)" = "$TARGET"
spack install --fail-fast

# The image: the base, a layer per package in the runtime closure of the roots,
# and the view. It is tagged in the cache's repository.
spack buildcache push --without-build-dependencies --base-image "$BASE" --tag "$TAG" --env-view cache
