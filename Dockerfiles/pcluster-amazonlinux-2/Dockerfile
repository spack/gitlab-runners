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
    environment-modules \
    file \
    findutils \
    gcc \
    gcc-c++ \
    gcc-gfortran \
    gettext \
    git \
    iputils \
    jansson-devel \
    jq \
    libevent-devel \
    libffi-devel \
    libibverbs-core \
    libtool \
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
    perl-devel\
    python3-devel \
    python3-pip \
    rsync \
    tar \
    unzip \
    wget \
    which \
    xz \
    zlib-devel \
    && localedef -i en_US -f UTF-8 en_US.UTF-8 \
    && yum clean all \
    && rm -rf /var/cache/yum/*

RUN python3 -m pip install --upgrade pip setuptools wheel \
 && python3 -m pip install gnureadline 'boto3<=1.20.35' 'botocore<=1.23.46' pyyaml pytz minio requests clingo \
 && rm -rf ~/.cache

COPY gpg.yaml /spack.yaml
RUN git clone https://github.com/spack/spack /spack \
 && export SPACK_ROOT=/spack \
 && . /spack/share/spack/setup-env.sh \
 && spack -e . concretize \
 && spack -e . install \
 && spack -e . gc -y \
 && spack clean -a \
 && rm -rf /spack /spack.yaml /spack.lock /.spack-env /root/.spack

ARG PCLUSTER_VERSION="3.5.1" \
    LIBJWT_VERSION="1.12.0" \
    PMIX_VERSION="3.2.3" \
    SLURM_VERSION="22-05-8-1" \
    EFA_INSTALLER_VERSION="1.22.0"

# Install SLURM and libfabric as on ParalleCluster itself
RUN mkdir -p /opt/parallelcluster && echo "${PCLUSTER_VERSION}" > /opt/parallelcluster/.bootstrapped

RUN curl -sOL https://github.com/benmcollins/libjwt/archive/refs/tags/v${LIBJWT_VERSION}.tar.gz \
    && tar xf v${LIBJWT_VERSION}.tar.gz \
    && cd libjwt-${LIBJWT_VERSION}/ \
    && autoreconf --force --install \
    && ./configure --prefix=/opt/libjwt \
    && make -j $(nproc) \
    && make install && make clean \
    && cd .. \
    && rm -rf v${LIBJWT_VERSION}.tar.gz libjwt-${LIBJWT_VERSION}

RUN curl -sOL https://github.com/openpmix/openpmix/releases/download/v${PMIX_VERSION}/pmix-${PMIX_VERSION}.tar.gz \
    && tar xf pmix-${PMIX_VERSION}.tar.gz \
    && cd pmix-${PMIX_VERSION} \
    && ./autogen.pl \
    && ./configure --prefix=/opt/pmix \
    && make -j $(nproc) \
    && make install && make clean \
    && cd .. \
    && rm -rf pmix-${PMIX_VERSION}.tar.gz pmix-${PMIX_VERSION}

# Actual PCluster also configures `--enable-slurmrestd`
RUN curl -sOL https://github.com/SchedMD/slurm/archive/slurm-${SLURM_VERSION}.tar.gz \
    && tar xf slurm-${SLURM_VERSION}.tar.gz \
    && cd slurm-slurm-${SLURM_VERSION}/ \
    && ./configure --prefix=/opt/slurm --with-pmix=/opt/pmix --with-jwt=/opt/libjwt \
    && make -j $(nproc) \
    && make install && make install-contrib && make clean \
    && cd .. \
    && rm -rf slurm-${SLURM_VERSION}.tar.gz slurm-slurm-${SLURM_VERSION}

RUN curl -sOL https://efa-installer.amazonaws.com/aws-efa-installer-${EFA_INSTALLER_VERSION}.tar.gz \
    && tar xf aws-efa-installer-${EFA_INSTALLER_VERSION}.tar.gz \
    && cd aws-efa-installer \
    && ./efa_installer.sh -y -k \
    && cd .. \
    && rm -rf aws-efa-installer-${EFA_INSTALLER_VERSION}.tar.gz aws-efa-installer

# Bootstrap spack compiler installation into the eventual installation tree
# Defined in spack/share/spack/gitlab/cloud_pipelines/configs/config.yaml
ARG SPACK_ROOT="/bootstrap-compilers/spack"
ARG SPACK_TAG="develop-2025-05-18"
ARG TARGETARCH
COPY Dockerfiles/pcluster-amazonlinux-2/${TARGETARCH}/packages.yaml /root/.spack/packages.yaml
RUN mkdir -p $(dirname "${SPACK_ROOT}") \
    && git clone --depth=1 -b ${SPACK_TAG} https://github.com/spack/spack "${SPACK_ROOT}" \
    && cp "${SPACK_ROOT}/share/spack/gitlab/cloud_pipelines/configs/config.yaml" "${SPACK_ROOT}/etc/spack/config.yaml" \
    && cp "${SPACK_ROOT}/share/spack/gitlab/cloud_pipelines/configs/config.yaml" "/bootstrap/cloud_pipelines-config.yaml" \
    && . "${SPACK_ROOT}/share/spack/setup-env.sh" \
    && spack compiler add \
    && spack install gcc@12 \
    && spack buildcache create -u /bootstrap-gcc-cache $(spack find --format '/{hash}') \
    && rm -rf $(dirname "${SPACK_ROOT}") /root/.spack

# Sign the buildcache
RUN --mount=type=secret,id=bootstrap_gcc_key \
    mkdir -p $(dirname "${SPACK_ROOT}") \
    && git clone --depth=1 -b ${SPACK_TAG} https://github.com/spack/spack "${SPACK_ROOT}" \
    && . "${SPACK_ROOT}/share/spack/setup-env.sh" \
    && spack gpg trust /run/secrets/bootstrap_gcc_key \
    && secretkey_fingerprint=$(GNUPGHOME="${SPACK_ROOT}"/opt/spack/gpg gpg2 -K --with-fingerprint --with-colons | awk -F: '/fpr/{print $10}') \
    && find /bootstrap-gcc-cache/v3/manifests/spec/ -name '*.spec.manifest.json' | xargs -I {} spack gpg sign --output {}.sig --key ${secretkey_fingerprint} --clearsign {} \
    && find /bootstrap-gcc-cache/v3/manifests/spec/ -name '*.spec.manifest.json' | xargs -I {} mv {}.sig {} \
    && spack mirror add bootstrap-gcc-cache /bootstrap-gcc-cache \
    && spack buildcache update-index bootstrap-gcc-cache \
    && spack gpg publish --rebuild-index -m bootstrap-gcc-cache ${secretkey_fingerprint} \
    && rm -rf $(dirname "${SPACK_ROOT}") /root/.spack

# Add oneapi compiler into container. The stack can pick up the compilers by using ${SPACK_ROOT}/etc/spack/compilers.yaml
# intel-oneapi-compiler@2024.1.0 is the last version compatible with AL2 glibc 2.26
COPY Dockerfiles/pcluster-amazonlinux-2/${TARGETARCH}/packages.yaml /root/.spack/packages.yaml
RUN if [[ "amd64" == "${TARGETARCH}" ]]; then mkdir -p $(dirname "${SPACK_ROOT}") \
    && git clone --depth=1 -b ${SPACK_TAG} https://github.com/spack/spack.git "${SPACK_ROOT}" \
    && cp "${SPACK_ROOT}/share/spack/gitlab/cloud_pipelines/configs/config.yaml" "${SPACK_ROOT}/etc/spack/config.yaml" \
    && cp "${SPACK_ROOT}/share/spack/gitlab/cloud_pipelines/configs/config.yaml" "/bootstrap/cloud_pipelines-config.yaml" \
    && . "${SPACK_ROOT}/share/spack/setup-env.sh" \
    && spack load gcc@12 \
    && spack compiler add --scope site \
    && cd "${SPACK_ROOT}" \
    && spack install intel-oneapi-compilers@2024.1.0 \
    && . "$(spack location -i intel-oneapi-compilers)"/setvars.sh \
    && spack compiler add --scope site \
    && rm -rf $(find $(spack find --format '{prefix}' intel-oneapi-compilers) -mindepth 1 -type d -name 'conda_channel') \
    && rm -rf $(find $(spack find --format '{prefix}' intel-oneapi-compilers) -mindepth 1 -type d -name 'debugger') \
    && rm -rf $(find $(spack find --format '{prefix}' intel-oneapi-compilers) -mindepth 1 -type d -name '*32*') \
    && rm -rf $(find $(spack find --format '{prefix}' intel-oneapi-compilers) -mindepth 1 -type d -name 'oclfpga') \
    && rm -rf /opt/intel /tmp/* \
    && spack clean -a \
    && rm -rf /root/.spack ; fi

ENV PATH=/bootstrap/runner/view/bin:$PATH \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    LANGUAGE=en_US:en \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

CMD ["/bin/bash"]
