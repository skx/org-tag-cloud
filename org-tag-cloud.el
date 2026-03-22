;;; org-tag-cloud.el --- Easily maintain a tag-cloud of org-mode tags -*- lexical-binding: t; -*-

;; Copyright (C) 2022 - 2026  Steve Kemp

;; Author: Steve Kemp <steve@steve.fi>
;; Maintainer: Steve Kemp <steve@steve.fi>
;; Version: 0.4.0
;; Package-Requires: ((emacs "29.1") (org "9.0"))
;; Keywords: outlines, tagcloud, tags
;; URL: https://github.com/skx/org-tag-cloud

;; This file is not part of GNU Emacs.

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package is designed to allow you to maintain a "tag cloud"
;; of all the tags stored within a particular file.
;;
;; The cloud is rendered as an `org-mode' table and can be updated
;; automatically when the file is saved.  The rendered table will
;; make each tag clickable via a newly-installed protocol handler
;; for links of the form [[tag::foo]].
;;
;; There are three main functions of interest:
;;
;; `org-tag-cloud-insert' - Insert a tag cloud at the current point.
;;
;; `org-tag-cloud-update' - Update an existing cloud.
;;
;; `org-tag-cloud-save-hook' - Something to add to save-hook to
;; automate this package.

;;; Usage:

;; Require the package and add the save hook for org-mode files:
;;
;; (require 'org-tag-cloud)
;; (add-hook 'before-save-hook #'org-tag-cloud-save-hook)
;;
;; If you're using `use-package' you would instead prefer something
;; like this which has the same result:
;;
;; (use-package org-tag-cloud
;;  :after org
;;  :straight t
;;  :hook
;;    (before-save-hook . org-tag-cloud-save-hook))

;;; Configuration:

;; Sorting may be set to sort by the tag name, or the frequency
;; count - the latter is the default.  Specify the value in either
;; the configuration value `org-tag-cloud-sort-method' or inside
;; the block itself, for example:
;;
;;     #+BEGIN: tagcloud :sort alpha
;; or
;;     #+BEGIN: tagcloud :sort frequency
;;

;;; Limitations:

;; Two main limitations are related:
;;
;;  1. There can only be one tag cloud in a specific document.
;;
;;  2. The tag cloud refers only to the current file, you cannot
;;     make a cloud of tags used across multiple `org-mode' files.
;;

;;; Configuration:

(defvar org-tag-cloud-block-name "tagcloud"
  "Name of the dynamic block used for tag clouds.")

(defvar org-tag-cloud-sort-method 'frequency
  "Method to sort tags in the tag cloud.

Possible values:
- \='frequency : Sort by frequency, descending (default)
- \='alpha     : Sort alphabetically by tag name.")

(defvar org-tag-cloud-name-first t
  "Specify the column order on the generated table.

When this is non-nil the tag name is first, followed by
the frequency.  Otherwise the frequency comes first,
with the tag second.")


;;; Code:

(require 'cl-lib)
(require 'org)


(defun org-tag-cloud-insert ()
  "Insert a new block which will become a tag-cloud.

The block will be inserted at the point, and will be immediately
populated via a call to `org-tag-cloud-update'."
  (interactive "*")
  (insert "#+BEGIN: tagcloud
#+END:
"))

(defun org-tag-cloud-update ()
  "Update any existing tag-cloud.

This relies upon the fact that the tag-cloud has a static
name, which can be used by `org-find-dblock'."
  (interactive "*")
  (when (org-find-dblock org-tag-cloud-block-name)
    (let ((pos (copy-marker (point)))
          (win (selected-window))
          (start (window-start)))
      (unwind-protect
          (org-with-wide-buffer
           (org-update-dblock))
        ;; Restore everything explicitly
        (when (marker-buffer pos)
          (set-window-start win start)
          (goto-char pos)
          (set-marker pos nil))))))

;; tag:-link support

(defun org-tag-cloud--open-tag (tag)
  "Handler invoked when a TAG: link is clicked."
  (org-tags-view nil tag))


;; Create a new "tag:" link
(org-link-set-parameters
 "tag"
 :follow #'org-tag-cloud--open-tag)



;;; dblock glue

(defun org-dblock-write:tagcloud (params)
  "Called when a block of name tagcloud is to be processed.

This is the magic that updates the tag-cloud, the variable
`org-tag-cloud-name-first' is used to determine the column-order.

PARAMS is a plist of dynamic block parameters.  Recognized keys:

  :sort   - \='frequency or \='alpha (default \='frequency)
  :name   - name of the block (optional, for multiple clouds)"
  (let* ((sort-method (or (plist-get params :sort) 'frequency))
         (name-first org-tag-cloud-name-first)
         (tags (let ((org-tag-cloud-sort-method sort-method))
                 (org-tag-cloud--collect)))
         (header (if name-first "| Tag | Frequency |\n|-\n"
                   "| Frequency | Tag |\n|-\n"))
         (rows
          (mapconcat
           (lambda (row)
             (pcase-let ((`(,count ,tag) row))
               (if name-first
                   (format "| %s | %d |" tag count)
                 (format "| %d | %s |" count tag))))
           tags
           "\n")))  ;; join with newline, no trailing newline
    (insert header rows)
    (org-table-align)))

(defun org-tag-cloud--collect ()
  "Find the distinct tags, and their counts, within the current file."
  (let ((counts (make-hash-table :test #'equal)))
    ;; collect tags
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward org-complex-heading-regexp nil t)
        (dolist (tag (org-get-tags))
          (unless (string-empty-p tag)
            (cl-incf (gethash tag counts 0))))))
    ;; convert to list of (count display)
    (let ((result
           (cl-loop for tag being the hash-keys of counts
                    using (hash-values count)
                    collect (list count (format "[[tag:%s][%s]]" tag tag)))))
      ;; sort based on `org-tag-cloud-sort-method`
      (cl-case org-tag-cloud-sort-method
        (frequency (cl-sort result #'> :key #'car))
        (alpha (cl-sort result #'string< :key (lambda (x) (cadr x))))
        (t (error "Invalid `org-tag-cloud-sort-method`: %S" org-tag-cloud-sort-method))))))

;; Utility
(defun org-tag-cloud-save-hook ()
  "If the current mode is derived from `org-mode' update the tag cloud.

This will silently and safely do nothing if there is no `dblock' with the
name \='tagcloud\=' within the document."
  (when (derived-mode-p 'org-mode)
    (org-tag-cloud-update)))


(provide 'org-tag-cloud)
;;; org-tag-cloud.el ends here
