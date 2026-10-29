SHELL := /usr/bin/env bash
BASH_SOURCES := $(shell find bin lib scripts -type f -name '*.sh' -o -path 'bin/linux-security-audit')
TEST_SOURCES := $(shell find tests -type f -name '*.bats')

.PHONY: help syntax lint test smoke ci build

help:
	@echo "Available targets: syntax lint test smoke ci build"

syntax:
	bash -n $(BASH_SOURCES) $(TEST_SOURCES)

lint:
	shellcheck --exclude=SC1091,SC2034 $(BASH_SOURCES) $(TEST_SOURCES)

test:
	bats tests

smoke:
	bash scripts/smoke.sh

ci: syntax lint test smoke

build:
	python3 scripts/build_archive.py
