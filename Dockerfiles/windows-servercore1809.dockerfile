# escape=`

FROM mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2019

# # Install chocolatey
# RUN Set-ExecutionPolicy Bypass -Scope Process -Force; `
#     [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
#     iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# # Install git and python3.11
# RUN choco install -y git.install
# RUN choco install -y python --version=3.11.0

# # Install spack requirements
# RUN python -m pip install --upgrade pip setuptools wheel
# RUN python -m pip install pyreadline boto3 pyyaml pytz minio requests clingo

# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]

# Install build tools including MSVC, CMake, Win-SDK
RUN curl -SL --output vs_buildtools.exe https://aka.ms/vs/17/release/vs_buildtools.exe
RUN start /w vs_buildtools.exe --quiet --wait --norestart --nocache --installPath '%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools' --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.TestTools.BuildTools --add Microsoft.VisualStudio.Component.VC.ASAN --add Microsoft.VisualStudio.Component.VC.CMake.Project --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 --add Microsoft.Component.VC.Runtime.UCRTSDK --add Microsoft.VisualStudio.Component.VC.140 --add Microsoft.VisualStudio.Component.VC.ATL --add Microsoft.VisualStudio.Component.VC.ATLMFC --add Microsoft.VisualStudio.Component.VC.CLI.Support --add Microsoft.VisualStudio.Component.VC.v141.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.18362 --add Microsoft.VisualStudio.Component.Windows10SDK.17763 --add Microsoft.VisualStudio.Component.Windows10SDK.17134 --add Microsoft.VisualStudio.Component.Windows10SDK.16299 --add Microsoft.VisualStudio.Component.VC.v141.x86.x64
RUN del /q vs_buildtools.exe

# Set env vars
ENV NVIDIA_VISIBLE_DEVICES=all `
    NVIDIA_DRIVER_CAPABILITIES=compute,utility `
    LANGUAGE=en_US:en `
    LANG=en_US.UTF-8 `
    LC_ALL=en_US.UTF-8
