FROM public.ecr.aws/amazonlinux/amazonlinux:latest

RUN yum update -y \
 && amazon-linux-extras install -y epel \
 && yum update -y \
 && yum install -y \
  autoconf \
  automake \
  bzip2 \
  cpio \
  curl \
  file \
  findutils \
  gcc \
  gcc-c++ \
  gcc-gfortran \
  gettext \
  git \
  gpg \
  iputils \
  jq \
  libffi-devel \
  glibc-locale-source \
  m4 \
  make \
  mercurial \
  mlocate \
  ncurses-devel \
  openssl-devel \
  patch \
  patchelf \
  pciutils \
  python3-pip \
  rsync \
  unzip \
  wget \
  zlib-devel \
  && localedef -i en_US -f UTF-8 en_US.UTF-8 \
  && yum clean all \
  && rm -rf /var/cache/yum/*

RUN python3 -m pip install --upgrade pip setuptools wheel \
 && python3 -m pip install gnureadline boto3 pyyaml pytz minio requests clingo \
 && rm -rf ~/.cache

CMD ["/bin/bash"]

ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    LANGUAGE=en_US:en \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8
