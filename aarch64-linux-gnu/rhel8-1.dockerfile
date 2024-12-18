FROM redhat/ubi8:8.10-1132.1733300785
RUN yum update -y \
 && yum install -y \
    bzip2 \
    file \
    gcc \
    gcc-c++ \ 
    glibc-devel \
    libstdc++-static \
    git \
    patch \
    python3 \
    vim \
    xz && \
    yum clean all -y
