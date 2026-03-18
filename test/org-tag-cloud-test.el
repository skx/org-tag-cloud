(require 'ert)
(require 'org)
(require 'org-tag-cloud)

(ert-deftest org-tag-cloud-test-frequency-sorting ()
  "Test that tags are sorted by frequency."
  (with-temp-buffer
    (org-mode)
    ;; insert headings with tags
    (insert "* TODO Task1 :foo:bar:\n")
    (insert "* TODO Task2 :foo:baz:\n")
    (insert "* TODO Task3 :foo:bar:\n")
    ;; set sorting to frequency
    (let ((org-tag-cloud-sort-method 'frequency))
      (let ((tags (org-tag-cloud--collect)))
        ;; Expect top tag to be "foo" (3 occurrences)
        (should (string-match-p "foo" (cadr (car tags))))
        ;; Expect descending counts
        (let ((counts (mapcar #'car tags)))
          (should (cl-every (lambda (x y) (>= x y))
                            counts (cdr counts))))))))

(ert-deftest org-tag-cloud-test-alpha-sorting ()
  "Test that tags are sorted alphabetically."
  (with-temp-buffer
    (org-mode)
    ;; insert headings with tags
    (insert "* TODO Task1 :zeta:alpha:\n")
    (insert "* TODO Task2 :beta:alpha:\n")
    (insert "* TODO Task3 :gamma:beta:\n")
    ;; set sorting to alpha
    (let ((org-tag-cloud-sort-method 'alpha))
      (let ((tags (org-tag-cloud--collect)))
        (let ((names (mapcar (lambda (x) (cadr x)) tags)))
          ;; names should be sorted alphabetically
          (should (equal names (sort (copy-sequence names) #'string<))))))))


(ert-deftest org-tag-cloud-test-table-generation ()
  "Check that the tag cloud table is created correctly."
  (with-temp-buffer
    (org-mode)
    (insert "* TODO Task1 :foo:bar:\n* TODO Task2 :foo:\n")
    ;; Insert a dummy block
    (insert "#+BEGIN: tagcloud\n#+END:\n")
    ;; Move to BEGIN line
    (goto-char (point-min))
    (search-forward "#+BEGIN: tagcloud")
    ;; Force table generation
    (org-dblock-write:tagcloud nil)
    ;; The table should now contain a row for "foo"
    (goto-char (point-min))
    (should (re-search-forward "foo.*2" nil t))
    ;; And for "bar"
    (goto-char (point-min))
    (should (re-search-forward "bar.*1" nil t))))

;; ----------------------------------------------------------------------
;; Run tests
;; ----------------------------------------------------------------------

(ert-run-tests-interactively t)

;;; org-people-test.el ends here
