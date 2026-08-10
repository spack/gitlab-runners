#!/bin/bash -e

## Helpers
. utilities.sh

require_env \
 CACHE_ONLY \
 SPACK_CORE_ROOT \
 TOOLS_MIRROR \
 TOOLS_PATH

cmd . $SPACK_CORE_ROOT/share/spack/setup-env.sh

if ! is_true $CACHE_ONLY ; then
   export AWS_ACCESS_KEY_ID=$(cat /run/secrets/AWS_ACCESS_KEY_ID)
   export AWS_SECRET_ACCESS_KEY=$(cat /run/secrets/AWS_SECRET_ACCESS_KEY)

multi_cmd "$(cat <<EOF

## Build from source + push to cache (use padding to enable flexibility in installation)
spack config add 'config:install_tree:padded_length:256'
spack mirror add --autopush remote s3://$TOOLS_MIRROR
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
spack mirror add --scope site remote https://$TOOLS_MIRROR
spack buildcache keys -it
spack config add "config:install_tree:root:$TOOLS_PATH/pkgs"
spack config add "config:install_tree:projections:all:'{name}-{version}'"
spack config add "config:db_lock_timeout:120"
spack config add "config:connect_timeout:60"
spack -e . config add "view: $TOOLS_PATH/view"
spack -e . install -j3 -p3 --cache-only

## Cleanup
rm -rf .spack-env

EOF
)"
