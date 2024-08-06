FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Los_Angeles

RUN apt update -y \
  && apt upgrade -y \
  && apt install -y \
  autoconf \
  automake \
  bzip2 \
  cpio \
  curl \
  file \
  findutils \
  g++ \
  gcc \
  gettext \
  gfortran \
  git \
  gpg \
  iputils-ping \
  jq \
  libffi-dev \
  libssl-dev \
  libxml2-dev \
  locales \
  locate \
  m4 \
  make \
  mercurial \
  ncurses-dev \
  patch \
  patchelf \
  pciutils \
  python3-pip \
  python3-setuptools \
  python3-wheel \
  python3-gnureadline \
  python3-boto3 \
  python3-pyyaml \
  python3-pytz \
  python3-minio \
  python3-requests \
  python3-clingo \
  rsync \
  unzip \
  wget \
  zlib1g-dev \
  && locale-gen en_US.UTF-8 \
  && apt autoremove --purge \
  && apt clean \
  && ln -s /usr/bin/gpg /usr/bin/gpg2 \
  && ln -s `which python3` /usr/bin/python

CMD ["/bin/bash"]

ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    LANGUAGE=en_US:en \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8
