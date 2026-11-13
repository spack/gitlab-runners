Build image for Spack's GitLab CI on linux (x86_64_v3 and aarch64), made entirely
from a Spack environment on top of a minimal AlmaLinux 8 base.

- [`base.dockerfile`](base.dockerfile): AlmaLinux 8 (pinned by digest) plus
  `glibc-devel`. glibc 2.28 is the floor of everything CI builds in this image;
  [`check-glibc.sh`](check-glibc.sh) fails the build if the system libc exports
  symbol versions newer than that (RHEL backports, see spack/spack#51888).
- [`builder.dockerfile`](builder.dockerfile): the base plus AlmaLinux's gcc 8.5
  and the bare minimum to run Spack.
- [`spack.yaml`](spack.yaml): gcc@14 (the compiler CI builds with) and the tools
  CI needs: Python with Spack's optimized clingo, boto3, AWS CLI v2, git, curl,
  gnupg, compression tools, ... All built with AlmaLinux's gcc 8.5, except
  llvm@23 (clang, for stacks that require `%c,cxx=llvm`), which a second spec
  group builds with the Spack-built gcc@14 so that clang uses its libstdc++.
- [`build.sh`](build.sh): concretizes and installs the environment in the
  builder, then runs `spack buildcache push --base-image <base> --tag <tag>`,
  which produces the image: the base plus one layer per package, with `PATH` and
  friends set for the root specs.
- [`test-ci.sh`](test-ci.sh): checks clang, then runs in the image like spack-packages CI does:
  concretizes a developer-tools stack (generate job) and builds part of it under
  CI's padded install tree (build jobs).

[`.github/workflows/linux-gnu.yml`](../.github/workflows/linux-gnu.yml) does all
of this natively on x86_64 and aarch64 GitHub runners and publishes:

- `ghcr.io/<owner>/linux-gnu-base:<hash>`: the runtime base
- `ghcr.io/<owner>/linux-gnu-cache`: the OCI build cache. Packages are pushed as
  soon as they are built (`autopush`), so a re-run after a timeout resumes.
- `ghcr.io/<owner>/linux-gnu-cache:<branch>-{amd64,arm64}` (`--tag` tags in the cache repository), and multi-arch
  `ghcr.io/<owner>/linux-gnu:<branch>` plus `:<date>-<run id>`.

Spack and spack-packages are pinned by commit in the workflow. Point them at
forks to build with unmerged fixes.
