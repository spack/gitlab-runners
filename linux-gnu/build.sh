#!/bin/bash
# Runs inside builder.dockerfile; see .github/workflows/linux-gnu.yml.
#
# Inputs (environment): REGISTRY, TAG, ARCH, TARGET, BASE, GITHUB_ACTOR, GITHUB_TOKEN.
# Mounts: /spack, /spack-packages, /env (spack.yaml, writable), /out.
set -euo pipefail

export PATH=/spack/bin:$PATH
export SPACK_DISABLE_LOCAL_CONFIG=1
export SPACK_USER_CACHE_PATH=/tmp/spack-cache

cache="oci://$REGISTRY/linux-gnu-cache"

# Use the pinned spack-packages checkout instead of cloning builtin.
spack -e /env config add "repos:builtin:/spack-packages/repos/spack_repo/builtin"
spack -e /env repo list
# Generic microarchitecture, not the runner's (e.g. neoverse_n2 / zen4).
spack -e /env config add "packages:all:require:[target=$TARGET]"
spack -e /env mirror add --unsigned --autopush \
  --oci-username-variable GITHUB_ACTOR --oci-password-variable GITHUB_TOKEN \
  cache "$cache"

# Packages are autopushed as they are built; keep the index current even if
# the build fails, so the cache can be browsed (installs do not need it).
trap 'spack -e /env buildcache update-index cache || true' EXIT

spack -e /env concretize --fresh 2>&1 | tee /out/concretize.txt
targets=$(spack --color=never -e /env find -c --format '{target}' | grep -v '^==>' | awk '{print $NF}' | sort -u | xargs)
echo "targets: $targets"
test "$targets" = "$TARGET"
spack -e /env find -c --show-full-compiler -L > /out/specs.txt || true

# Installs pull what is already in the cache and push what they build.
spack -e /env install --fail-fast -j "$(nproc)"

# Tag one image with every root and its runtime closure, on top of the base. The
# tag is created in the cache's repository: $REGISTRY/linux-gnu-cache:$TAG-$ARCH.
spack -e /env buildcache push --unsigned --update-index --without-build-dependencies \
  --base-image "$BASE-$ARCH" \
  --tag "$TAG-$ARCH" cache
