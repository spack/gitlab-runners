FROM centos:7.9.2009
COPY CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
RUN yum install -y \
    bzip2 \
    file \
    gcc \
    gcc-c++ \
    git \
    patch \
    python3 \
    vim && \
    yum clean all
