# Build image for Spack CI stacks targeting AWS ParallelCluster on Amazon Linux 2023.
#
# The EFA installer puts libfabric in /opt/amazon/efa and rdma-core in /usr, the same
# as on a ParallelCluster node, so stacks can declare libfabric as an external. Its
# version and checksum follow aws-parallelcluster-cookbook v3.16.2.
#
# Slurm is deliberately absent: MPI libraries are built without it and started with
# `srun --mpi=pmix` (or pmi2), so the binaries do not depend on the cluster's Slurm
# version, which changes with nearly every ParallelCluster release.
FROM public.ecr.aws/amazonlinux/amazonlinux:2023

# Only what Spack itself needs; everything else is built by Spack. The base image
# already provides python3, curl-minimal and gnupg2-minimal.
RUN dnf update -y \
    && dnf install -y \
    bzip2 \
    diffutils \
    findutils \
    gcc \
    gcc-c++ \
    gcc-gfortran \
    git \
    gzip \
    patch \
    tar \
    unzip \
    which \
    xz \
    zstd \
    && dnf clean all \
    && rm -rf /var/cache/dnf/*

# boto3 for s3:// mirrors.
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN python3 -m pip install --no-cache-dir boto3

# Spack's optimized clingo build, made importable from the venv so that any Spack
# checkout uses it directly. CI sets SPACK_DISABLE_LOCAL_CONFIG and a per-job
# SPACK_USER_CACHE_PATH, so a regular bootstrap store in the image would be ignored.
RUN git clone --depth 1 https://github.com/spack/spack.git /tmp/spack \
    && /tmp/spack/bin/spack bootstrap root /opt/spack-bootstrap \
    && /tmp/spack/bin/spack bootstrap now \
    && find /opt/spack-bootstrap -type d -path '*clingo-bootstrap*/site-packages' \
       > $VIRTUAL_ENV/lib/python3.9/site-packages/spack-clingo.pth \
    && python3 -c "import clingo" \
    && rm -rf /tmp/spack ~/.spack

ARG PCLUSTER_VERSION="3.16.2" \
    EFA_INSTALLER_VERSION="1.49.0" \
    EFA_INSTALLER_SHA256="cf2e9281a2328a243c76f911a490faed43ca0fecfe4733c25e34b2e92a32c309"

LABEL parallelcluster.version="${PCLUSTER_VERSION}" \
      efa-installer.version="${EFA_INSTALLER_VERSION}"

WORKDIR /tmp/build

# Only rdma-core and libfabric (/opt/amazon/efa) are needed: skip the kernel module,
# limits, device verification, bundled Open MPI and the NCCL plugin.
RUN curl -fsSL -o efa.tar.gz https://efa-installer.amazonaws.com/aws-efa-installer-${EFA_INSTALLER_VERSION}.tar.gz \
    && echo "${EFA_INSTALLER_SHA256}  efa.tar.gz" | sha256sum -c - \
    && tar xf efa.tar.gz \
    && cd aws-efa-installer \
    && ./efa_installer.sh --yes --skip-kmod --skip-limit-conf --no-verify --skip-mpi --skip-plugin \
    && dnf clean all \
    && rm -rf /var/cache/dnf/* /tmp/build/*

WORKDIR /

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

CMD ["/bin/bash"]
