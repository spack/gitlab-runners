FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Los_Angeles

RUN apt update -y \
  && apt upgrade -y \
  && apt install -y \
  autoconf \
  automake \
  bzip2 \
  clang \
  cpio \
  curl \
  file \
  findutils \
  flang \
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
  llvm-dev \
  locales \
  locate \
  m4 \
  make \
  mercurial \
  ncurses-dev \
  patch \
  patchelf \
  pciutils \
  python3-full \
  python3-dev \
  rsync \
  unzip \
  wget \
  xz-utils \
  zlib1g-dev \
  && locale-gen en_US.UTF-8 \
  && apt autoremove --purge \
  && apt clean \
  && ln -s /usr/bin/gpg /usr/bin/gpg2 \
  && ln -s `which python3` /usr/bin/python

ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN python3 -m pip install --upgrade pip setuptools wheel \
 && python3 -m pip install gnureadline boto3 pyyaml pytz minio requests \
 && rm -rf ~/.cache

# Install AWS CLI v2 (used improve performance of `spack buildcache update-index`).

# AWS CLI Team public key, used to verify the installer signature.
# Source: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
# Fingerprint: FB5D B77F D5C1 18B8 0511  ADA8 A631 0ACC 4672 475C (expires 2027-07-01)
COPY keys/aws-cli.asc /usr/share/keyrings/aws-cli.asc

# The signature must be valid AND made by the expected key: gpg's status output
# is checked for a VALIDSIG line whose primary-key fingerprint matches.
RUN AWSCLI_ZIP="awscli-exe-linux-$(uname -m).zip" \
  && AWSCLI_KEY_FPR=FB5DB77FD5C118B80511ADA8A6310ACC4672475C \
  && curl -sSfL --retry 5 --retry-connrefused "https://awscli.amazonaws.com/${AWSCLI_ZIP}" -o /tmp/awscliv2.zip \
  && curl -sSfL --retry 5 --retry-connrefused "https://awscli.amazonaws.com/${AWSCLI_ZIP}.sig" -o /tmp/awscliv2.zip.sig \
  && export GNUPGHOME="$(mktemp -d)" \
  && gpg --batch --quiet --import /usr/share/keyrings/aws-cli.asc \
  && gpg --batch --status-fd 3 --verify /tmp/awscliv2.zip.sig /tmp/awscliv2.zip 3>"$GNUPGHOME/status" \
  && grep -Eq "^\[GNUPG:\] VALIDSIG .* ${AWSCLI_KEY_FPR}\$" "$GNUPGHOME/status" \
  && unzip -q /tmp/awscliv2.zip -d /tmp \
  && /tmp/aws/install \
  && rm -rf /tmp/awscliv2.zip /tmp/awscliv2.zip.sig /tmp/aws "$GNUPGHOME" \
  && aws --version

# Spack's optimized clingo (faster than the PyPI wheel); SPACK_COMMIT is v1.2.2.
ARG SPACK_COMMIT=3e19345b6e12f5ff1b874f4059622fc6a1fd804a
COPY scripts/bootstrap-clingo.sh /tmp/bootstrap-clingo.sh
RUN /tmp/bootstrap-clingo.sh "${SPACK_COMMIT}" && rm /tmp/bootstrap-clingo.sh

CMD ["/bin/bash"]

ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    LANGUAGE=en_US:en \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8
