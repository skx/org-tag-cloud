;;; org-people.el --- Easily maintain a tag-cloud of org-mode tags. -*- lexical-binding: t; -*-

;; Copyright (C) 2022 - 2026  Steve Kemp

;; Author: Steve Kemp
;; Maintainer: Steve Kemp
;; Version: 0.2
;; Package-Requires: ((emacs "29.1") (org "9.0"))
;; Keywords: outlines, contacts, people
;; URL: https://github.com/skx/org-people

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
;; for links of the form [[tag::foo].
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

;;; Limitations:

;; There can only be one tag cloud in a specific document, because
;; the name is fixed.
;;
;; The tag cloud refers only to the current file, you cannot make
;; a cloud of tags used across multiple `org-mode' files.
;;

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
name, and can be found by that name with `org-find-dblock'."
  (interactive "*")
  (if (org-find-dblock "tagcloud")
      (org-update-dblock)))


;;; org-mode "tag:" link

(defun org-tag--open-tag (tag)
  "Handler invoked when a TAG: link is clicked."
  (org-tags-view nil tag))


;; Create a new "tag:" link
(org-link-set-parameters
 "tag"
 :follow #'org-tag--open-tag)



;;; dblock glue

(defun org-dblock-write:tagcloud (_params)
  "Called when a block of name tagcloud is to be processed.

This is the magic that updates the tag-cloud."
  (let ((tags (org-tag-cloud--collect)))
    (insert "| Frequency | Tag |\n|-\n")
    (dolist (row tags)
      (insert (format "| %d | %s |\n"
                      (car row)
                      (cadr row))))
                      (org-table-align)))


(defun org-tag-cloud--collect ()
  "Find the distinct tags, and their counts, within the current file."
  (let (tags)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward org-complex-heading-regexp nil t)
        (dolist (tag (org-get-tags))
          (unless (string-empty-p tag)
            (push tag tags)))))
    (cl-loop for tag in (cl-remove-duplicates tags :test #'string=)
             collect
             (list (cl-count tag tags :test #'string=)
                   (format "[[tag:%s][%s]]" tag tag))
             into result
             finally return (cl-sort result #'> :key #'car))))


;;; Utility
(defun org-tag-cloud-save-hook ()
  "If the current mode is derived from `org-mode' update the tag cloud.

This will silently and safely do nothing if there is no `dblock' with the
name 'tagcloud' within the document."
  (if (derived-mode-p 'org-mode)
    (org-tag-cloud-update)))


(provide 'org-tag-cloud)
;;; org-tag-cloud.el ends here
