# org-tag-cloud

This package allows you to easily generate, or update, a table of all the tags you've used within a particular `org-mode` file.


## Installation / Usage

* Save the file `org-tag-cloud.el` to a directory upon your load-path.
* Load an org-file, and position the point at a suitable location.
* Run `M-x org-tag-cloud-insert` to insert a source-block at the point.

In the future you can update your tag-cloud by running `M-x org-tag-cloud-update`.

If you wish this can be done automatically every time you save your file by adding a hook:

```lisp
(defun skx-org-tag-cloud-update-hook ()
  (when (eq major-mode 'org-mode)
    (org-tag-cloud-update)))

(add-hook 'before-save-hook #'skx-org-tag-cloud-update-hook)

```


## Tag Search Results

The table will have a clickable entry, which will show you entries matching the given tag.  By default this will prompt you to permit the execution.

You can avoid this via:

```lisp
(defun skx-org-mode-hook-eval-ok ()
    (make-variable-buffer-local 'org-confirm-elisp-link-function)
    (setq org-confirm-elisp-link-function nil))

(add-hook 'org-mode-hook 'skx-org-mode-hook-eval-ok)
```
