#!/bin/bash -e

name=ubuntu24.04-runner-x86_64-gcc-13.3
output_image="${REGISTRY:-ecpe4s}/${name}:${BUILD_TAG:-$(date +%s)}"

python_mirror=cache.e4s.io/runners-2026.02/python-pad256
python_path=/opt/python
python_version=3.12.12
spack_core_checkout=v1.1.1
spack_core_repo=https://github.com/spack/spack
spack_core_root=/spack
spack_packages_checkout=119680aeee8ea802c6111b7167583bddef97e82f
spack_packages_repo=https://github.com/spack/spack-packages
spack_packages_root=/spack-packages
tools_mirror=cache.e4s.io/runners-2026.02/tools-pad256
tools_path=/opt/tools

common_scripts=$(realpath ../_common)
. $common_scripts/utilities.sh
. $common_scripts/build-argparse.sh

check_usage_no_pos_args $@

if ! is_true $cache_only ; then
  [[ -f secrets.env ]] && . $(cat secrets.env) >/dev/null 2>&1
  require_env \
    AWS_ACCESS_KEY_ID \
    AWS_SECRET_ACCESS_KEY \
    SIGNING_KEY_PATH
  build_secrets="\
    --secret id=AWS_ACCESS_KEY_ID \
    --secret id=AWS_SECRET_ACCESS_KEY \
    --secret id=SIGNING_KEY,src=$SIGNING_KEY_PATH"
else
  build_secrets=""
fi

cmd docker build \
 -t "${output_image}" \
 --build-arg PYTHON_MIRROR=$python_mirror \
 --build-arg PYTHON_PATH=$python_path \
 --build-arg PYTHON_VERSION=$python_version \
 --build-arg SPACK_CORE_CHECKOUT=$spack_core_checkout \
 --build-arg SPACK_CORE_REPO=$spack_core_repo \
 --build-arg SPACK_CORE_ROOT=$spack_core_root \
 --build-arg SPACK_PACKAGES_CHECKOUT=$spack_packages_checkout \
 --build-arg SPACK_PACKAGES_REPO=$spack_packages_repo \
 --build-arg SPACK_PACKAGES_ROOT=$spack_packages_root \
 --build-arg TOOLS_MIRROR=$tools_mirror \
 --build-arg TOOLS_PATH=$tools_path \
 --build-arg CACHE_ONLY=$cache_only \
 $build_secrets --progress=plain \
 -f ./Dockerfile \
 --build-context shared_assets=../_common \
 .
