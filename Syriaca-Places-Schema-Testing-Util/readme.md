---
Title: Overview of Syriac Gazetteer Update Scripts for Edition 2.0
Author: William L. Potter
---
# Overview of Directory Contents

This directory consists of several general purpose xquery update functions that were written to aid in the batch change and schema updates for the second edition of [The Syriac Gazetteer](http://syriaca.org/geo). Most of these scripts were used in resolving [these issues](https://github.com/srophe/srophe-app-data/issues?q=is%3Aissue+is%3Aopen+label%3A2019-May-Batch-Changes).


The names of most of these scripts should give an indication of their intended purpose, many of which are rather narrow in scope and designed to resolve a single data issue.

The following scripts, in particular, could have future uses:

- generate-errorList-csv.xql
  - This script takes an XML file output from [oXygen's batch validation](https://www.oxygenxml.com/doc/versions/22.0/ug-editor/topics/project-validation-and-transformation.html) and converts it to a CSV file. To create the XML of the validation errors turned up by batch validation, right-click in the error window and select "Save results as XML...". This XML file's URI should be the input of this script (line 10).
- update-schema-assocation.xql
  - this script can be used to replace any currently declared schema associations with user-specified schema declarations (i.e., processing instructions) for a given directory.
