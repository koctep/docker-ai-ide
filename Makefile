UNAME_M := $(shell uname -m)
ifeq ($(UNAME_M),x86_64)
ARCH := x64
else ifeq ($(UNAME_M),amd64)
ARCH := x64
else ifeq ($(UNAME_M),aarch64)
ARCH := arm64
else ifeq ($(UNAME_M),arm64)
ARCH := arm64
else
$(error unsupported architecture: $(UNAME_M))
endif

build: force
	docker build . \
		--no-cache \
		--build-arg USERID=$(shell id -u) \
		--build-arg USERNAME=$(shell id -u -n) \
		--build-arg ARCH=$(ARCH) \
		-t ai-ide

run: force
	./cursor.ide bash

force:

exit:
	exit 0
