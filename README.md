# org-tag-cloud

This package is designed to allow you to maintain a "tag cloud"
of all the tags stored within a particular `org-mode` file.

The cloud is rendered as an `org-mode` table and can be updated
automatically when the file is saved.  The rendered table will
make each tag clickable via a newly-installed protocol handler
for links of the form `[[tag::foo]]`.



## Example Output

This repository contains `example.org` showing the rendered result,
but note that you will need to click the "RAW" link to view it in
a readable format:

* https://raw.githubusercontent.com/skx/org-tag-cloud/refs/heads/master/example.org



## Package Overview

The cloud is rendered as an `org-mode` table and can be updated
automatically when the file is saved.  The rendered table will
make each tag clickable via a newly-installed protocol handler
for links of the form `[[tag::foo]]`.

There are three main functions of interest:

* `org-tag-cloud-insert` - Insert a tag cloud at the current point.
* `org-tag-cloud-update` - Update an existing cloud.
* `org-tag-cloud-save-hook` - Something to add to save-hook to automate updates when files are saved.

The only configuration value is `org-tag-name-first`, when this is non-nil the tag-name is listed in the first column, followed by the frequency as the second column.  When nil the ordering is reversed.



## Usage


Require the package and add the save hook for org-mode files.

If you're doing this the old-school way, having saved a copy of
the package file to a directory upon your `load-path` you can configure
it like so:

    (require 'org-tag-cloud)
    (add-hook 'before-save-hook #'org-tag-cloud-save-hook)


If you're using `use-package` you would instead prefer something
like this which has the same result:

    (use-package org-tag-cloud
     :after org
     :straight t
     :hook
       (before-save-hook . org-tag-cloud-save-hook))


Once loaded you'll find you can browse tag-search results via a new
protocol `[[tag:foo]]` - this will open a buffer showing all the entries
you have tagged with the value `foo`.



## Limitations

* There can only be one tag cloud in a specific document, because the name is fixed.
* The tag cloud refers only to the current file, you cannot make a cloud of tags used across multiple `org-mode' files.
