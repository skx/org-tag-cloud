EMACS ?= emacs

org-tag-cloud.elc: org-tag-cloud.el
	$(EMACS) --batch -L . -l org-tag-cloud.el -eval '(byte-compile-file "org-tag-cloud.el")'

clean:
	find . -name '*.elc' -delete

bytecompile: org-tag-cloud.elc
