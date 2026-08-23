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

CURSOR_CLI_VERSION := $(shell curl -fsSL https://cursor.com/install \
	| sed -n 's|.*downloads.cursor.com/lab/\([^/]*\)/$${OS}/$${ARCH}/agent-cli-package.tar.gz.*|\1|p')
ifeq ($(CURSOR_CLI_VERSION),)
$(error failed to detect Cursor CLI version from https://cursor.com/install)
endif

build: force
	docker build . \
		--no-cache \
		--build-arg USERID=$(shell id -u) \
		--build-arg USERNAME=$(shell id -u -n) \
		--build-arg ARCH=$(ARCH) \
		--build-arg CURSOR_CLI_VERSION=$(CURSOR_CLI_VERSION) \
		-t ai-ide

run: force
	./cursor.ide bash

force:

exit:
	exit 0
