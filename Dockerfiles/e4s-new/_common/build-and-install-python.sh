#!/bin/bash -e

## Helpers
. utilities.sh

require_env \
 CACHE_ONLY \
 PYTHON_MIRROR \
 PYTHON_PATH \
 PYTHON_VERSION \
 SPACK_CORE_ROOT

sys_arch=$(arch)
if [[ $sys_arch == "aarch64" ]]; then
  spack_target=aarch64
elif [[ $sys_arch == "x86_64" ]]; then
  spack_target=x86_64_v3
elif [[ $sys_arch == "ppc64le" ]]; then
  spack_target=ppc64le
else
  _err "ERROR: Cannot process system architecture"
  exit 1
fi

. /etc/os-release
cmd . $SPACK_CORE_ROOT/share/spack/setup-env.sh
if [[ $ID == "rocky" ]] ; then
  source scl_source enable gcc-toolset-13
fi
cmd spack -e . compiler find
cmd spack -e . config add packages:all:require:[target=$spack_target]
cmd spack -e . add python@$PYTHON_VERSION +bz2+crypt+ctypes+dbm~debug+libxml2+lzma+optimizations+pic+pyexpat+pythoncmd+readline+shared+sqlite3+ssl~tkinter+uuid+zlib

if ! is_true $CACHE_ONLY ; then
   export AWS_ACCESS_KEY_ID=$(cat /run/secrets/AWS_ACCESS_KEY_ID)
   export AWS_SECRET_ACCESS_KEY=$(cat /run/secrets/AWS_SECRET_ACCESS_KEY)

multi_cmd "$(cat <<EOF

## Build from source + push to cache (use padding to enable flexibility in installation)
spack config add 'config:install_tree:padded_length:256'
spack mirror add --autopush remote s3://$PYTHON_MIRROR
spack env activate -d .
spack gpg trust /run/secrets/SIGNING_KEY
spack concretize -f | tee concretize.log
spack env depfile -o Makefile
spack config add "config:db_lock_timeout:120"
spack config add "config:connect_timeout:60"
make -j16 -k SPACK_COLOR=always --output-sync=recurse || true
spack install
spack env deactivate

## Update buildcache index
spack buildcache update-index --keys remote

## Cleanup
spack mirror rm remote
spack config remove "config:install_tree:padded_length"

EOF
)"

fi


multi_cmd "$(cat <<EOF

## Install from cache into final location
spack mirror add --scope site remote https://$PYTHON_MIRROR
spack buildcache keys -it
spack config add "config:install_tree:root:$PYTHON_PATH/pkgs"
spack config add "config:install_tree:projections:all:'{name}-{version}'"
spack config add "config:db_lock_timeout:120"
spack config add "config:connect_timeout:60"
spack -e . install --cache-only

## Install pip
spack load python
which python | grep $PYTHON_VERSION
wget -q https://bootstrap.pypa.io/get-pip.py
python get-pip.py
which pip | grep $PYTHON_VERSION

## Cleanup
rm -rf .spack-env

EOF
)"
