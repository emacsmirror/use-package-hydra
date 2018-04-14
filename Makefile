test:
	$(BATCH) --eval "(progn\
	(load-file \"use-package-hydra-tests.el\")\
	(ert-run-tests-batch-and-exit))"

EMACSBIN ?= emacs
BATCH     = $(EMACSBIN) -Q --batch $(LOAD_PATH)
LOAD_PATH = -L $(TOP)
TOP := $(dir $(lastword $(MAKEFILE_LIST)))

.PHONY: test
