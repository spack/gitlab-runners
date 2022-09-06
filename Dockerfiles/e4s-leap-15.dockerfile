FROM registry.opensuse.org/opensuse/leap:15

ENV TZ=America/Los_Angeles

RUN zypper ref \
  && zypper up -y \
  && zypper in -y \
  autoconf \
  automake \
  bzip2 \
  curl \
  file \
  findutils \
  gcc \
  gcc-c++ \
  gcc-fortran \ 
  git \
  gzip \
  jq \
  libffi-devel \
  libopenssl-devel \
  libxml2-devel \
  m4 \
  make \
  mercurial \
  ncurses-devel \
  patch \
  patchelf \
  pciutils \
  python3-pip \
  rsync \
  tar \
  unzip \
  wget \
  xz \
  zlib-devel \
  && zypper clean

RUN python3 -m pip install --upgrade pip setuptools wheel \
 && python3 -m pip install gnureadline 'boto3<=1.20.35' 'botocore<=1.23.46' pyyaml pytz minio requests clingo \
 && rm -rf ~/.cache

CMD ["/bin/bash"]

ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    LANGUAGE=en_US:en \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

