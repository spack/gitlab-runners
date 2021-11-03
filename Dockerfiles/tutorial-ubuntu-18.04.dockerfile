FROM ghcr.io/spack/e4s-ubuntu-18.04:v2021-10-18

RUN apt update && apt -y install \
    build-essential \
    gcc-6 \
    g++-6 \
    gfortran-6 \
    gcc-6-multilib \
    cpp-6 \
    gcc-8 \
    g++-8 \
    gfortran-8 \
    gcc-8-multilib \
    cpp-8 \
    clang-7 \
    lldb-7 \
    lld-7 \
    && apt autoremove --purge \
    && apt clean 

ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    LANGUAGE=en_US:en \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8