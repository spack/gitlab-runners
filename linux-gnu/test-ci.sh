#!/bin/bash
# Smoke test of the linux-gnu image as a spack-packages GitLab CI image. Runs
# inside the image; mimics the generate and build jobs of the developer-tools
# stacks (.ci/gitlab/.gitlab-ci.yml, .ci/gitlab/configs/ci.yaml).
#
# Inputs (environment): PACKAGES_REPOSITORY, PACKAGES_COMMIT, SPACK_CI_TARGET,
# STACK, BUILD_SPECS (space separated roots of the stack to build).
set -euo pipefail

section() { echo; echo "### $*"; }

section "Tools in the image"
for exe in python3 gcc g++ gfortran ld ar git curl gpg aws make tar xz zstd unzip patch patchelf file; do
  printf '%-10s %s\n' "$exe" "$(command -v "$exe")"
done
gcc --version | head -n1
python3 -c 'import clingo, sys; print("clingo", clingo.__version__, clingo.__file__)'
python3 -c 'import boto3, botocore; print("boto3", boto3.__version__, "botocore", botocore.__version__)'
# spack buildcache update-index uses put_object(IfMatch=...): botocore >= 1.35.70
python3 -c 'import botocore.session as s; m = s.get_session().get_service_model("s3"); assert "IfMatch" in m.operation_model("PutObject").input_shape.members'
aws --version
gpg --version | head -n1
git --version
curl --version | head -n1

workdir=$(mktemp -d)
cd "$workdir"

section "Check out spack-packages and the Spack commit its CI uses"
git init -q packages
git -C packages fetch -q --depth 1 "https://github.com/$PACKAGES_REPOSITORY.git" "$PACKAGES_COMMIT"
git -C packages checkout -q FETCH_HEAD
set -a; . packages/.ci/env; set +a
git init -q spack
git -C spack fetch -q --depth 1 "https://github.com/$SPACK_CHECKOUT_REPO.git" "$SPACK_CHECKOUT_VERSION"
git -C spack checkout -q FETCH_HEAD

export SPACK_DISABLE_LOCAL_CONFIG=1
export SPACK_USER_CACHE_PATH="$workdir/tmp/_user_cache/"
export SPACK_CI_TARGET
. spack/share/spack/setup-env.sh
spack --version
spack arch

stack="$workdir/packages/stacks/$STACK"

section "Generate: concretize $STACK"
spack env activate --without-view "$stack"
spack repo list
spack compiler find
spack compiler list
spack audit configs
start=$(date +%s)
spack -v concretize -j 4 > "$workdir/concretize.log" 2>&1 || { tail -n 60 "$workdir/concretize.log"; exit 1; }
echo "concretized in $(( $(date +%s) - start ))s"
tail -n 3 "$workdir/concretize.log"
if [ -d "$SPACK_USER_CACHE_PATH/bootstrap/store" ]; then
  echo "ERROR: Spack bootstrapped (clingo?) instead of using the image's tools:"
  find "$SPACK_USER_CACHE_PATH/bootstrap/store" -maxdepth 3 -mindepth 3
  exit 1
fi
echo "OK: nothing bootstrapped"

section "Build: ${BUILD_SPECS}"
# Like build jobs: padded install tree plus the relocation test projection.
for spec in $BUILD_SPECS; do
  hash=$(spack find -c --format '{hash}' "$spec" | head -n1)
  spack config add "config:install_tree:projections:$spec/$hash:'morepadding/{architecture.platform}-{architecture.target}/{name}-{version}-{hash}'"
done
spack install --fail-fast --no-check-signature $BUILD_SPECS
spack find -lp $BUILD_SPECS
spack env deactivate

section "Outputs do not need a glibc newer than 2.28"
newest=$(find /home/software/spack -type f \( -name '*.so*' -o -perm -u+x \) -exec sh -c 'file -b "$1" | grep -q ELF && objdump -T "$1" 2>/dev/null' _ {} \; \
  | grep -oE 'GLIBC_[0-9]+\.[0-9]+(\.[0-9]+)?' | sort -uV | tail -n1)
echo "newest GLIBC symbol version required: $newest"
test "$(printf '%s\nGLIBC_2.28\n' "$newest" | sort -V | tail -n1)" = GLIBC_2.28
