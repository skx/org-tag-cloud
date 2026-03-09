EMACS ?= emacs

# Run all tests by default.
MATCH ?=

.PHONY: bytecompile

bytecompile:
	$(EMACS) --batch -L . -l org-tag-cloud.el -eval '(byte-compile-file "org-tag-cloud.el")'
