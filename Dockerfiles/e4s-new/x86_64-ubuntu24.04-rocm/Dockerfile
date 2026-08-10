# check=skip=InvalidDefaultArgInFrom

ARG SOURCE_IMAGE

FROM $SOURCE_IMAGE

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Los_Angeles
 
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
 && wget -q https://repo.radeon.com/amdgpu-install/7.2/ubuntu/noble/amdgpu-install_7.2.70200-1_all.deb \
 && apt install -y ./amdgpu-install_7.2.70200-1_all.deb \
 && apt update -y \
 && amdgpu-install -y --usecase=rocm,rocmdev,hip,hiplibsdk,mllib,mlsdk --rocmrelease=7.2.0 --no-dkms \
 && apt install -y rocm-llvm-dev7.2.0

RUN echo /opt/rocm/lib > /etc/ld.so.conf.d/rocm.conf \
 && ldconfig -v

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt install libstdc++-14-dev

RUN updatedb

RUN echo export PATH=/opt/rocm/bin:'$PATH' >> /etc/bash.bashrc
ENV PATH=/opt/rocm/bin:$PATH
