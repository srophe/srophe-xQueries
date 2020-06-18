---
Title: WorldCat API Query Description
Author: William L. Potter
---

# Overview

This repository holds scripts that send bibliographic metadata queries to the WorldCat API and return MARCXML records of the query result. The query runs on a set of bibliographic references, which are in the current iteration stored as CSV files, and returns MARCXML records for the top match, if one exists. These MARCXML records may then be compiled into a MARCXML collection, which may in turn be used to import into a [Zotero](https://zotero.org) library or other bibliographic management system capable of ingesting MARCXML data. Samples of the inputs and outputs of the various scripts have been included in this directory for reference.

Note that in order to use this API query, one must obtain a WorldCat API key.

Finally, in order for these records to import correctly into Zotero, the "Srophe MARCXML.js" importer needs to be moved to the Zotero importers folder, most likely, "Users/foo/Zotero/translators". This custom importer enables the storage of the OCLC number in the "Extra" field.

# Script Descriptions

## worldCatApiLookup.xq

This script takes a TSV input of bibliographic references; constructs a WorldCat API query based on the title and author information; returns a MARCXML record of the first query hit; stores that MARCXML record as a file in a user-specified directory; and appends the OCLC number of the returned record to the TSV input document, saving the resulting TSV document as its output.

## compileMarcXMLCollection.xq

This script takes as its input one or more MARCXML record files, nests them within a single MARCXML collection, and stores that collection in a user-defined folder. This MARCXML collection may be imported into Zotero using the custom "Sophe MARCXML.js" translator.
