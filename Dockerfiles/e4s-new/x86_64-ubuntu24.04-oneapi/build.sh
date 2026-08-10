#!/bin/bash -e

name=e4s-oneapi-base-x86_64
ONEAPI_VERSION=2025.3
version=v$ONEAPI_VERSION
source_image=${SOURCE_IMAGE:-ecpe4s/ubuntu24.04-runner-x86_64-gcc-13.3:1772469543}
output_image="${REGISTRY:-ecpe4s}/${name}:${BUILD_TAG:-$version-$(date +%s)}"

docker build \
 -t "${output_image}" \
 --build-arg ONEAPI_VERSION=$ONEAPI_VERSION \
 --build-arg SOURCE_IMAGE=$source_image \
 --progress=plain \
 -f ./Dockerfile .
