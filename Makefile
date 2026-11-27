# Every recipe line is a single command that runs the same in sh and in
# Windows cmd.exe: no shell loops, conditionals, pipes or Unix-only tools.
# Lists and loops use GNU make functions instead.

GOLANGCI_VERSION := v2.15.0
LICENSE_TMPL     := .github/license-header.tmpl

# Every top-level directory with a go.mod is a tool module.
MODULES := $(patsubst %/go.mod,%,$(wildcard */go.mod))

# rwildcard lists the files under the directories in $1 that match the
# pattern in $2, walking subdirectories.
rwildcard = $(foreach d,$(wildcard $(addsuffix /*,$(1))),$(call rwildcard,$(d),$(2)) $(filter $(subst *,%,$(2)),$(d)))

.DEFAULT_GOAL := help

.PHONY: help setup tools hooks fmt lint license license-check tidy build test vuln secrets check

# help prints with $(info), and its one command (cd .) is a no-op that works in
# every shell, so make doesn't report that there was nothing to do.
help:
	$(info Targets, each run in every tool module:)
	$(info )
	$(info setup          Install dev tools and enable git hooks)
	$(info tools          Install golangci-lint $(GOLANGCI_VERSION) and addlicense)
	$(info hooks          Enable the git hooks in .githooks (once per clone))
	$(info fmt            Format code (gofmt + goimports via golangci-lint))
	$(info lint           Run golangci-lint)
	$(info license        Add missing SPDX license headers to Go files)
	$(info license-check  Check that every Go file has its SPDX header)
	$(info tidy           Check that go.mod and go.sum are tidy)
	$(info build          Build every package)
	$(info test           Run the tests with the race detector)
	$(info vuln           Scan dependencies for known vulnerabilities)
	$(info secrets        Scan the working tree for secrets with gitleaks)
	$(info check          secrets, license-check, lint, tidy and build)
	$(info )
	$(info Run a target for one tool with <target>/<tool>, e.g. make test/migrator)
	$(info Tools: $(MODULES))
	@cd .

setup: tools hooks

tools:
	go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@$(GOLANGCI_VERSION)
	go install github.com/google/addlicense@latest

hooks:
	git config core.hooksPath .githooks

fmt: $(addprefix fmt/,$(MODULES))
fmt/%:
	cd $* && golangci-lint fmt -c ../.golangci.yml ./...

lint: $(addprefix lint/,$(MODULES))
lint/%:
	cd $* && golangci-lint run -c ../.golangci.yml --timeout=5m ./...

license: $(addprefix license/,$(MODULES))
license/%:
	addlicense -f $(LICENSE_TMPL) $(call rwildcard,$*,*.go)

license-check: $(addprefix license-check/,$(MODULES))
license-check/%:
	addlicense -check -f $(LICENSE_TMPL) $(call rwildcard,$*,*.go)

tidy: $(addprefix tidy/,$(MODULES))
tidy/%:
	go -C $* mod tidy -diff

build: $(addprefix build/,$(MODULES))
build/%:
	go -C $* build ./...

test: $(addprefix test/,$(MODULES))
test/%:
	go -C $* test -race ./...

vuln: $(addprefix vuln/,$(MODULES))
vuln/%:
	go -C $* run golang.org/x/vuln/cmd/govulncheck@latest ./...

secrets:
	gitleaks dir . --redact --no-banner

check: secrets license-check lint tidy build
