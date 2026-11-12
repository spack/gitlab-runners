#!/bin/sh
# Install Spack's optimized clingo and make it importable by python3.
# Usage: bootstrap-clingo.sh <spack-commit> [bootstrap-root]
set -eu

SPACK_COMMIT="${1:?usage: bootstrap-clingo.sh <spack-commit> [bootstrap-root]}"
ROOT_ARG="${2:-/opt/spack-bootstrap}"

# Spack skips bootstrapping if python3 can already import clingo.
if CLINGO_FILE=$(python3 -c 'import clingo; print(clingo.__file__)' 2>/dev/null); then
  echo "error: python3 already imports clingo from $CLINGO_FILE; remove it first" >&2
  exit 1
fi

# Spack would reuse a clingo already in the store instead of SPACK_COMMIT's.
if [ -e "$ROOT_ARG/store" ]; then
  echo "error: $ROOT_ARG/store already exists; use an empty bootstrap root" >&2
  exit 1
fi

# Absolute path, since it ends up in the .pth.
BOOTSTRAP_ROOT=$(mkdir -p "$ROOT_ARG" && CDPATH= cd "$ROOT_ARG" && pwd -P)
# site, not sysconfig: Debian's sysconfig purelib isn't on sys.path before Python 3.10.
SITE_DIR=$(python3 -c 'import site; print(site.getsitepackages()[0])')
SPACK_DIR="$(mktemp -d)"
trap 'rm -rf "$SPACK_DIR"' EXIT

# Throwaway Spack; the commit only picks which clingo build is installed.
git init -q "$SPACK_DIR"
git -C "$SPACK_DIR" fetch -q --depth 1 https://github.com/spack/spack.git "$SPACK_COMMIT"
git -C "$SPACK_DIR" checkout -q FETCH_HEAD
export SPACK_USER_CONFIG_PATH="$SPACK_DIR/.user" SPACK_USER_CACHE_PATH="$SPACK_DIR/.user"
"$SPACK_DIR/bin/spack" bootstrap root --scope site "$BOOTSTRAP_ROOT"
"$SPACK_DIR/bin/spack" bootstrap disable --scope site spack-install
"$SPACK_DIR/bin/spack" bootstrap now

# The store started empty, so any match is the clingo just installed.
PY_TAG=$(python3 -c 'import sys; print("cpython-%d%d" % sys.version_info[:2])')
CLINGO_SO=$(find "$BOOTSTRAP_ROOT/store" -name "clingo.${PY_TAG}-*.so")
echo "clingo builds matching ${PY_TAG}: ${CLINGO_SO:-none}"
test -n "$CLINGO_SO"

mkdir -p "$SITE_DIR"
dirname "$CLINGO_SO" > "$SITE_DIR/spack-clingo.pth"

python3 -c 'import clingo; print("clingo", clingo.__version__, "from", clingo.__file__)'
