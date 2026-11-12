#!/bin/sh
# Fail if the system libc defines a symbol version newer than its nominal
# release. RHEL backports symbols under newer version nodes (e.g. GLIBC_2.35 in
# RHEL 9.7's glibc 2.34, spack/spack#51888); binaries linked against those
# would not run on other distros with the "same" glibc.
set -eu

expected="GLIBC_${EXPECTED_GLIBC:-2.28}"
libc=$(ls /lib64/libc.so.6 /lib/*/libc.so.6 2>/dev/null | head -n1)

newest=$(readelf -V "$libc" | grep -oE 'GLIBC_[0-9]+\.[0-9]+(\.[0-9]+)?' | sort -uV | tail -n1)

echo "$libc: newest symbol version $newest (expected $expected)"
test "$newest" = "$expected"
