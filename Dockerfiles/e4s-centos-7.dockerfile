FROM quay.io/centos/centos:7

RUN yum update -y \
 && yum install -y epel-release centos-release-scl \
 && yum update -y \
 && yum install -y \
  autoconf \
  automake \
  bzip2 \
  cpio \
  curl \
  devtoolset-8-gcc \
  devtoolset-8-gcc-c++ \
  devtoolset-8-gcc-gfortran \
  file \
  findutils \
  gettext \
  git \
  glibc-locale-source \
  gpg \
  iputils \
  jq \
  libffi-devel \
  m4 \
  make \
  mercurial \
  mlocate \
  ncurses-devel \
  openssl-devel \
  patch \
  patchelf \
  pciutils \
  python3-devel \
  python3-pip \
  rsync \
  subversion \
  tar \
  unzip \
  wget \
  which \
  xz \
  zlib-devel \
  zstd \
  && localedef -i en_US -f UTF-8 en_US.UTF-8 \
  && yum clean all \
  && rm -rf /var/cache/yum/*

RUN python3 -m pip install --upgrade pip setuptools wheel \
 && python3 -m pip install gnureadline 'boto3<=1.20.35' 'botocore<=1.23.46' pyyaml pytz minio requests clingo \
 && rm -rf ~/.cache

CMD ["/bin/bash"]

ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    LANGUAGE=en_US:en \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    PATH=/opt/rh/devtoolset-8/root/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    LD_LIBRARY_PATH=/opt/rh/devtoolset-8/root/usr/lib64:/opt/rh/devtoolset-8/root/usr/lib:/opt/rh/devtoolset-8/root/usr/lib64/dyninst:/opt/rh/devtoolset-8/root/usr/lib/dyninst \
    PKG_CONFIG_PATH=/opt/rh/devtoolset-8/root/usr/lib64/pkgconfig \
    PYTHONPATH=/opt/rh/devtoolset-8/root/usr/lib64/python2.7/site-packages:/opt/rh/devtoolset-8/root/usr/lib/python2.7/site-packages \
    PERL5LIB=/opt/rh/devtoolset-8/root//usr/lib64/perl5/vendor_perl:/opt/rh/devtoolset-8/root/usr/lib/perl5:/opt/rh/devtoolset-8/root//usr/share/perl5/vendor_perl \
    PCP_DIR=/opt/rh/devtoolset-8/root \
    MANPATH=/opt/rh/devtoolset-8/root/usr/share/man \
    INFOPATH=/opt/rh/devtoolset-8/root/usr/share/info
