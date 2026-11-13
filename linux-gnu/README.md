Image for Spack's GitLab CI on linux (x86_64_v3 and aarch64), built from a Spack
environment on top of AlmaLinux 8 (glibc 2.28).

- [`base.dockerfile`](base.dockerfile): the runtime base, AlmaLinux 8 plus `glibc-devel`.
- [`spack.yaml`](spack.yaml): gcc@14, llvm@23 and the tools CI needs.
- [`build.sh`](build.sh): installs the environment in the base image and pushes it
  as an image with `spack buildcache push --base-image <base> --tag <tag> --env-view`.
- [`test-ci.sh`](test-ci.sh): concretizes and partly builds a spack-packages CI
  stack in the image.

[`.github/workflows/linux-gnu.yml`](../.github/workflows/linux-gnu.yml) runs this
on x86_64 and aarch64 runners and publishes `ghcr.io/<owner>/linux-gnu:<branch>`
(multi-arch). `ghcr.io/<owner>/linux-gnu-cache` is the OCI build cache.
