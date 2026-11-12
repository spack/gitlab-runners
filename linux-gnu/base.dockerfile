# Runtime base of the linux-gnu CI image. Everything else in the image is
# Spack-built and layered on top by `spack buildcache push --base-image`.
#
# AlmaLinux 8 fixes the glibc floor of whatever CI builds in this image at
# 2.28; check-glibc.sh guards against RHEL-style symbol backports raising it.
ARG BASE_IMAGE=docker.io/library/almalinux:8@sha256:2d0f2eb2a83cc09dbc2eb92fade4dbe8f709628149e81aa00aec70630406603b
FROM ${BASE_IMAGE}

# glibc-devel: headers, crt objects and linker scripts for the Spack-built gcc.
# Do not upgrade glibc here: the floor must stay at the pinned base image's.
RUN dnf install -y --setopt=install_weak_deps=False \
      glibc-devel \
      procps-ng \
      which \
 && dnf clean all \
 && rm -rf /var/cache/dnf \
 # Make packages link Spack's libxcrypt instead of the system libcrypt.
 && rm -f /usr/lib64/libcrypt.so

CMD ["/bin/bash"]
