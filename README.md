This repository contains images that are used to run Gitlab pipelines to validate PRs in Spack.

- [`linux-gnu`](linux-gnu): Spack-built CI image for linux x86_64_v3 and aarch64,
  see [`.github/workflows/linux-gnu.yml`](.github/workflows/linux-gnu.yml).
- [`Dockerfiles`](Dockerfiles): `ubuntu-24.04` and `tutorial-ubuntu-26.04`, see [`.github/workflows/containers.yml`](.github/workflows/containers.yml).

Images are published to `ghcr.io/spack/<name>`. The Dockerfile recipes were
originally modified from ones in: https://github.com/UO-OACISS/e4s
