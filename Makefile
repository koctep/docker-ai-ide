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

AGENTS ?= all
NOX ?= false

build: EFFECTIVE_AGENTS = $(AGENTS)
build: EFFECTIVE_NOX = $(NOX)
build-nox: EFFECTIVE_AGENTS = $(AGENTS)
build-nox: EFFECTIVE_NOX = true
build-all: EFFECTIVE_AGENTS = all
build-all: EFFECTIVE_NOX = false

build build-nox build-all: force
	agents='$(EFFECTIVE_AGENTS)'; \
	agents=$$(printf '%s' "$$agents" | tr -d ' '); \
	ver=''; \
	case ",$$agents," in \
	  *,all,*|*,cursor,*) \
	    ver=$$(curl -fsSL https://cursor.com/install \
	      | sed -n 's|.*downloads.cursor.com/lab/\([^/]*\)/$${OS}/$${ARCH}/agent-cli-package.tar.gz.*|\1|p'); \
	    if [ -z "$$ver" ]; then \
	      echo "failed to detect Cursor CLI version from https://cursor.com/install" >&2; \
	      exit 1; \
	    fi ;; \
	esac; \
	docker build . \
		--no-cache \
		--build-arg USERID=$(shell id -u) \
		--build-arg USERNAME=$(shell id -u -n) \
		--build-arg ARCH=$(ARCH) \
		--build-arg NOX='$(EFFECTIVE_NOX)' \
		--build-arg AGENTS="$$agents" \
		--build-arg CURSOR_CLI_VERSION="$$ver" \
		-t ai-ide

run: force
	./cursor.ide bash

force:

exit:
	exit 0
