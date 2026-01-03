SHELL := /usr/bin/env bash

.PHONY: help test

help:
	@echo "Available targets: test"

test:
	bats tests
