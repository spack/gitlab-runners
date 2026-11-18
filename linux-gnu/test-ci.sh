#!/bin/sh
# Smoke test of the image for spack-packages' GitLab CI. Runs inside the image and
# mimics the generate and build jobs of a stack (.ci/gitlab/.gitlab-ci.yml).
# Inputs: PACKAGES_REPOSITORY, PACKAGES_COMMIT, SPACK_CI_TARGET, STACK, ML_STACK.
set -eu

cd "$(mktemp -d)"

for exe in python3 gcc g++ gfortran clang clang++ ld.lld ld ar git curl gpg aws make tar xz zstd unzip patch patchelf file; do
  command -v "$exe"
done
aws --version
# spack buildcache update-index uses put_object(IfMatch=...): botocore >= 1.35.70
python3 -c 'import clingo, boto3, botocore.session as s; assert "IfMatch" in s.get_session().get_service_model("s3").operation_model("PutObject").input_shape.members'

# clang uses Spack's gcc@14, as there is no system gcc. Both compilers must rpath
# its runtime libraries: the loader otherwise picks AlmaLinux's older libstdc++.
clang++ -v -fsyntax-only -x c++ /dev/null 2>&1 | grep 'Selected GCC installation'
printf '#include <iostream>\nint main() { std::cout << "hello" << std::endl; }\n' > hello.cpp
for cxx in g++ clang++; do
  $cxx -O2 hello.cpp -o hello
  readelf -d hello | grep -E 'RPATH|RUNPATH'
  ./hello
done

# spack-packages and the Spack commit its CI uses.
checkout() {
  git init -q "$1"
  git -C "$1" fetch -q --depth 1 "https://github.com/$2.git" "$3"
  git -C "$1" checkout -q FETCH_HEAD
}
checkout packages "$PACKAGES_REPOSITORY" "$PACKAGES_COMMIT"
set -a; . packages/.ci/env; set +a
checkout spack "$SPACK_CHECKOUT_REPO" "$SPACK_CHECKOUT_VERSION"

export PATH="$PWD/spack/bin:$PATH" SPACK_DISABLE_LOCAL_CONFIG=1 SPACK_USER_CACHE_PATH="$PWD/user-cache"

# Generate job: concretize the stack with the image's compilers and clingo.
export SPACK_ENV="$PWD/packages/stacks/$STACK"
spack compiler find
spack audit configs
spack concretize -j 4 > /dev/null
test ! -d "$SPACK_USER_CACHE_PATH/bootstrap/store"

# Build jobs: a sample of the stack, in CI's padded install tree with the
# relocation test projection.
specs="libtree tree jq ncdu tmux patchelf py-isort gmake"
for spec in $specs; do
  hash=$(spack --color=never find -c --format '{hash}' "$spec" | awk '{print $NF}' | head -n1)
  spack config add "config:install_tree:projections:$spec/$hash:'morepadding/{architecture.platform}-{architecture.target}/{name}-{version}-{hash}'"
done
spack install --fail-fast --no-check-signature $specs

# A stack that requires %c,cxx=llvm for some packages.
SPACK_ENV="$PWD/packages/stacks/$ML_STACK" spack concretize -j 4 > /dev/null
