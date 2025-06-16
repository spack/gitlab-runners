# Stack: pcluster-amazonlinux-2

This directory contains dockerfiles to build the containers that the spack CI
uses to build and publish the pcluster-amazonlinux-2 stack.

One advantage of using Amazon Linux 2 is that it has one of the older glibc
versions (2.26), which increases the chance that binaries that link against
glibc may be portable to other linux distributions with newer versions of glibc.

# Testing the build process locally

You may locally test the entire process including key signing if you have an
existing gpg2 key, or you can make a testing key:

```
gpg2 --gen-key
fingerprint=$(gpg -K --with-fingerprint --with-colons | grep fpr | head)
export bootstrap_gcc_key=$(gpg --armor --export-secret-keys $fingerprint)
```

Now you can export the secret key in the environment, and build with a very
similar environment as the github runners:

```
docker build --secret id=bootstrap_gcc_key --output type=image,name=offline_test:latest --file Dockerfiles/pcluster-amazonlinux-2/Dockerfile .
```

# Multiplatform Docker Build

If necessary you can test multi-platform builds with a command like:

```
docker buildx build --file Dockerfiles/pcluster-amazonlinux-2/Dockerfile -t test2 --platform linux/arm64 -t multi-platform  .
```

# Testing the images locally

Additionally, a few docker testfiles are provided to confirm the format or
compatibility of the resulting image and buildcache.  First extract the
buildcache from the test container:

```
id=$(docker create -t offline_test)
docker cp $id:/bootstrap-gcc-cache /tmp/test-cache
docker rm -v $id
tar -C /tmp/test-cache -cf cache.tar .
rm -rf /tmp/test-cache
```
Then build the test images:
```
docker build --file Dockerfiles/pcluster-amazonlinux-2/Dockerfile.test.al2 .
docker build --file Dockerfiles/pcluster-amazonlinux-2/Dockerfile.test.ubuntu .
```

The included tests add the buildcache and install the compiler.  You may wish to
use this as a starting point to compile a particular package.

# Testing the whole stack in spack CI

After the images are built by CI in the spack/gitlab-runners repo, they will be
published to the ghcr.io container repository.  You can list the
pcluster-amazonlinux-2 images by visiting
https://github.com/spack/gitlab-runners/pkgs/container/pcluster-amazonlinux-2,
and searching for the image tagged with your PR number (e.g. pr-62).

Next a PR to spack/spack should be created, which points the CI towards this
image.  For the example of PR #62, the image was found as
`ghcr.io/spack/pcluster-amazonlinux-2:pr-62`.

As of May 2025, these are the three relevant locations to change beneath `spack/share/spack/gitlab/cloud_pipelines`:

 - [.gitlab-ci.yaml](https://github.com/spack/spack/blob/c7e6018acfbb82972e78de68f81ae400b26048c2/share/spack/gitlab/cloud_pipelines/.gitlab-ci.yml#L731) - In `.aws-pcluster-generate/image`
 - [stacks/aws-pcluster-neoverse_v1/spack.yaml](https://github.com/spack/spack/blob/c7e6018acfbb82972e78de68f81ae400b26048c2/share/spack/gitlab/cloud_pipelines/stacks/aws-pcluster-neoverse_v1/spack.yaml#L20) - In `spack/ci/pipeline-gen/build-job/image`
 - [stacks/aws-pcluster-x86_64_v4/spack.yaml](https://github.com/spack/spack/blob/c7e6018acfbb82972e78de68f81ae400b26048c2/share/spack/gitlab/cloud_pipelines/stacks/aws-pcluster-x86_64_v4/spack.yaml#L25) - In `spack/ci/pipeline-gen/build-job/image`

In all locations change the image to point to your tagged PR image.

# Tagging the final result

TODO: After everything passes, merge the PR, tag the next nightly, and point the stack's towards the tagged image.