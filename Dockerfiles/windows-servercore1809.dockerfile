FROM python:3.11-windowsservercore-1809

RUN python -m pip install --upgrade pip setuptools wheel
RUN python -m pip install pyreadline boto3 pyyaml pytz minio requests clingo
RUN rm -rf ~/.cache

CMD ["powershell", "-Command", "$ErrorActionPreference = 'Continue'; $ProgressPreference = 'SilentlyContinue';"]
