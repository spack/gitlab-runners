# Build environment for linux-gnu/spack.yaml: the runtime base plus the system
# toolchain that bootstraps the Spack-built gcc (spec group `compiler`).
ARG BASE
FROM ${BASE}

RUN dnf install -y --setopt=install_weak_deps=False \
      binutils \
      bzip2 \
      diffutils \
      file \
      findutils \
      gcc \
      gcc-c++ \
      git \
      gzip \
      libstdc++-static \
      make \
      patch \
      python3 \
      tar \
      unzip \
      xz \
 && dnf clean all \
 && rm -rf /var/cache/dnf

COPY check-glibc.sh /usr/local/bin/check-glibc.sh
RUN /usr/local/bin/check-glibc.sh
