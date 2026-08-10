#!/bin/bash -e

name=e4s-rocm-base-x86_64
version=v7.2.0
source_image=${SOURCE_IMAGE:-ecpe4s/ubuntu24.04-runner-x86_64-gcc-13.3:1772469543}
output_image="${REGISTRY:-ecpe4s}/${name}:${BUILD_TAG:-$version-$(date +%s)}"

. ../_common/utilities.sh

cmd docker build \
 -t "${output_image}" \
 --build-arg SOURCE_IMAGE=$source_image \
 --progress=plain \
 -f ./Dockerfile .
