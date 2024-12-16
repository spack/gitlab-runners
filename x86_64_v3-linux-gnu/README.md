Bootstraps a build environment targeting linux with glibc 2.17 and gcc 10.

To build it run `make`. This outputs a container image `ghcr.io/spack/x86_64_v3-linux-gnu` with
tag `v<year>-<month>-<day>`.

[`stage1/`](stage1/) contains an initial compiler for use in `stage2`.
[`stage2/`](stage2/) defines the build environment.

We store the `spack.lock` files for `stage1/` and `stage2/`. Use `make reconcretize-stage1` or
`make reconcretize-stage2` to make changes to the build environment.

Binaries of `stage1/` and `stage2/` are cached in an OCI buildcache through

```make push GITHUB_USER=... GITHUB_TOKEN=...```

> [!WARNING]
> When building `stage2`, Spack adds a compiler definition to `stage2/spack.yaml` which shouldn't
> be commited.