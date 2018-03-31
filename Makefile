test:
	@$(BATCH) --eval "(progn\
	(load-file \"use-package-hydra-tests.el\")\
	(ert-run-tests-batch-and-exit))"
