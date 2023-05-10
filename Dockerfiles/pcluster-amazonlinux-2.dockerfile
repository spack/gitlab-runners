FROM public.ecr.aws/amazonlinux/amazonlinux:2

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
  python3-devel \
  python3-pip \
  rsync \
  tar \
  unzip \
  wget \
  which \
  xz \
  zlib-devel \
  environment-modules \
  && localedef -i en_US -f UTF-8 en_US.UTF-8 \
  && yum clean all \
  && rm -rf /var/cache/yum/*

RUN python3 -m pip install --upgrade pip setuptools wheel \
 && python3 -m pip install gnureadline 'boto3<=1.20.35' 'botocore<=1.23.46' pyyaml pytz minio requests clingo \
 && rm -rf ~/.cache

COPY gpg.yaml /spack.yaml
RUN git clone https://github.com/spack/spack /spack \
 && (cd /spack && curl -Lfs https://github.com/spack/spack/pull/37405.patch | patch -p1) \
 && export SPACK_ROOT=/spack \
 && . /spack/share/spack/setup-env.sh \
 && spack -e . concretize \
 && spack -e . install --make \
 && spack -e . gc -y \
 && spack clean -a \
 && rm -rf /spack /spack.yaml /spack.lock /.spack-env /root/.spack

# TODO Get from /opt if we are building this on top of Pcluster AMI
# If not then use hard coded values. These are for ParallelCluster-3.5.1
RUN mkdir -p /opt/parallelcluster && echo "3.5.1" > /opt/parallelcluster/.bootstrapped
ENV SLURM_VERSION="22.05.8" \
    LIBFABRIC_MODULE_VERSION="1.17.0" \
    LIBFABRIC_MODULE="libfabric-aws/${LIBFABRIC_MODULE_VERSION}" \
    LIBFABRIC_VERSION="1.17.0" \
    GCC_VERSION="7.3.1"

RUN mkdir -p /bootstrap && \
    cd /bootstrap && \
    git clone https://github.com/spack/spack spack \
    && . spack/share/spack/setup-env.sh \
    && curl -sL https://raw.githubusercontent.com/spack/spack-configs/main/AWS/parallelcluster/postinstall.sh \
    | sed -e '/nohup/s/&$//' -e 's/nohup//' | /bin/bash \
    && spack clean -a \
    && cd /bootstrap/spack \
    && find . -type f -maxdepth 1 -delete \
    && rm -rf bin lib share var /root/.spack

ENV PATH=/bootstrap/runner/view/bin:$PATH \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    LANGUAGE=en_US:en \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

CMD ["/bin/bash"]

