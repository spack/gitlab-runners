FROM centos7-1 AS with-spack
ARG SPACK_COMMIT
ENV PYTHONUNBUFFERED=1
COPY stage2/spack.yaml /spack/spack.yaml
COPY stage2/spack.lock /spack/spack.lock
RUN git clone https://github.com/spack/spack.git /root/spack && \
    cd /root/spack && \
    git reset --hard $SPACK_COMMIT
RUN /root/spack/bin/spack -e /spack install --no-check-signature --cache-only
 
FROM centos:7.9.2009
ENV PATH=/spack/view/bin:$PATH
COPY CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
COPY --from=with-spack /spack /spack
RUN yum install -y glibc-devel && yum clean all && rm /lib64/libcrypt.so
