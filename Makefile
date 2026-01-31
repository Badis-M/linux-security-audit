SHELL := /usr/bin/env bash
BASH_SOURCES := $(shell find bin lib -type f -name '*.sh' -o -path 'bin/linux-security-audit')
TEST_SOURCES := $(shell find tests -type f -name '*.bats')

.PHONY: help syntax lint test smoke ci

help:
	@echo "Available targets: syntax lint test smoke ci"

syntax:
	bash -n $(BASH_SOURCES) $(TEST_SOURCES)

lint:
	shellcheck --exclude=SC1091,SC2034 $(BASH_SOURCES) $(TEST_SOURCES)

test:
	bats tests

smoke:
	bin/linux-security-audit version
	bin/linux-security-audit list-checks >/dev/null
	bin/linux-security-audit audit --check system --format json --no-color >/dev/null

ci: syntax lint test smoke
