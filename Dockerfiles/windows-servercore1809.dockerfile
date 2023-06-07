FROM python:3.11-windowsservercore-1809

RUN python -m pip install --upgrade pip setuptools wheel
RUN python -m pip install pyreadline boto3 pyyaml pytz minio requests clingo
RUN rm -rf ~/.cache

CMD ["powershell", "-Command", "$ErrorActionPreference = 'Continue'; $ProgressPreference = 'SilentlyContinue';"]

ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    LANGUAGE=en_US:en \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8
