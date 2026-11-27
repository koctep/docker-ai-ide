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
CLI_AGENTS := cursor agy claude codex qwen
GUI_APPS := chromium vscode cursor-ide zed

comma := ,
# EFFECTIVE_AGENTS and EFFECTIVE_NOX are target-specific, so these stay
# recursive and are expanded inside the recipe.
agent_list = $(subst $(comma), ,$(EFFECTIVE_AGENTS))
unknown_agents = $(filter-out all $(CLI_AGENTS) $(GUI_APPS),$(agent_list))
nox = $(filter 1 true,$(EFFECTIVE_NOX))
selected = $(if $(filter all,$(agent_list)),$(CLI_AGENTS) $(GUI_APPS),$(agent_list))
# NOX drops every graphical app from the selection, including "all".
enabled = $(if $(nox),$(filter-out $(GUI_APPS),$(selected)),$(selected))
dropped_gui = $(if $(nox),$(filter $(GUI_APPS),$(agent_list)))
agent_flag = $(if $(filter $(1),$(enabled)),true,false)

build: EFFECTIVE_AGENTS = $(AGENTS)
build: EFFECTIVE_NOX = $(NOX)
build-nox: EFFECTIVE_AGENTS = $(AGENTS)
build-nox: EFFECTIVE_NOX = true
build-all: EFFECTIVE_AGENTS = all
build-all: EFFECTIVE_NOX = false

build build-nox build-all: force
	$(if $(unknown_agents),$(error unknown agent: $(unknown_agents)))
	$(if $(dropped_gui),$(warning NOX=$(EFFECTIVE_NOX) skips graphical apps: $(dropped_gui)))
	ver=''; \
	if [ '$(call agent_flag,cursor)' = true ]; then \
	  ver=$$(curl -fsSL https://cursor.com/install \
	    | sed -n 's|.*downloads.cursor.com/lab/\([^/]*\)/$${OS}/$${ARCH}/agent-cli-package.tar.gz.*|\1|p'); \
	  if [ -z "$$ver" ]; then \
	    echo "failed to detect Cursor CLI version from https://cursor.com/install" >&2; \
	    exit 1; \
	  fi; \
	fi; \
	docker build . \
		--no-cache \
		--build-arg USERID=$(shell id -u) \
		--build-arg USERNAME=$(shell id -u -n) \
		--build-arg ARCH=$(ARCH) \
		--build-arg APP_CHROMIUM=$(call agent_flag,chromium) \
		--build-arg APP_VSCODE=$(call agent_flag,vscode) \
		--build-arg APP_CURSOR=$(call agent_flag,cursor-ide) \
		--build-arg APP_ZED=$(call agent_flag,zed) \
		--build-arg AGENT_CURSOR=$(call agent_flag,cursor) \
		--build-arg AGENT_AGY=$(call agent_flag,agy) \
		--build-arg AGENT_CLAUDE=$(call agent_flag,claude) \
		--build-arg AGENT_CODEX=$(call agent_flag,codex) \
		--build-arg AGENT_QWEN=$(call agent_flag,qwen) \
		--build-arg CURSOR_CLI_VERSION="$$ver" \
		-t ai-ide

test: force
	sh tests/test-td-log.sh

run: force
	./cursor.ide bash

force:

exit:
	exit 0
