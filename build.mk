SPACK ?= spack
SPACK_INSTALL_FLAGS += --no-check-signature
BUILDCACHE = $(CURDIR)/buildcache
MAKEFLAGS += -Orecurse

export SPACK_COLOR = always
export SPACK_BACKTRACE = yes

.PHONY: all

all: push
	$(SPACK) -e . gc --yes-to-all
	$(SPACK) -e . env view --link run enable /opt/spack/view

include env.mk

spack.lock: spack.yaml
	$(SPACK) -e . concretize -f

env.mk: spack.lock
	$(SPACK) -e . env depfile -o $@ --make-prefix spack

spack/push/%: spack/install/%
	$(SPACK) -e . buildcache create --unsigned --allow-root --only=package $(BUILDCACHE) /$(HASH)  # push $(SPEC)

push: $(addprefix spack/push/,$(spack/SPACK_PACKAGE_IDS))
	$(SPACK) -e . buildcache update-index $(BUILDCACHE)