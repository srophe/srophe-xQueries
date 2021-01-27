---
title: README.md
author: William L. Potter
---

## Overview

This directory contains files that assist in the creation and processing of testimonia records for [Caesarea-Maritima.org](https://caesarea-maritima.org/index.html). Two CSS files are included which are used in an oXygen XML author-mode form for data input. The XML template file has been deprecated; the current data template may be found [here](https://github.com/srophe/caesarea-data/blob/master/draft-data/testimonia-data-template.xml). The [XQuery script](https://github.com/srophe/srophe-xQueries/blob/master/Caesarea-Data-Entry-Phase2/testimonia-postprocessing-script.xq) provides the final touches before the data can be deployed on the server.

### Processing New Data

The process for preparing new data for deployment on the server are as follows, each of which is explained in detail below:

1. [Batch Update CSS Link](#batch-update-css-link)
2. [Input Missing Metadata](#input-missing-metadata)
3. [Run Post-Processing Script](#run-post-processing-script)

## Batch Update CSS Link

New data should have the following xml stylesheet assocation in the xml prolog: `<?xml-stylesheet type="text/css" href="https://raw.githubusercontent.com/srophe/srophe-xQueries/master/Caesarea-Data-Entry-Phase2/testimonia-entry.css"?>`. The CSS form referred to in this line of code provided a stream-lined view of the data template enabling project editors to quickly and efficiently create new testimonia records. This link needs to be updated to connect records to the metadata-entry-phase CSS file.

Replace `<?xml-stylesheet type="text/css" href="https://raw.githubusercontent.com/srophe/srophe-xQueries/master/Caesarea-Data-Entry-Phase2/testimonia-entry.css"?>`

with `<?xml-stylesheet type="text/css" href="https://raw.githubusercontent.com/srophe/srophe-xQueries/master/Caesarea-Data-Entry-Phase2/testimonia-metadata-entry.css"?>` in all new data records (likely those in the `/draft-data` sub-directory of the [Caesarea data repository]()).

## Input Missing Metadata

The following metadata will need to be entered manually:

- The numeric portion of the testimonia URI (e.g. 32) should be added to the `Testimonium ID` field. This may be found in [running list of testimonia IDs](https://docs.google.com/spreadsheets/d/1ZG8blfcVZ62zSkkW22HEbUyMYm7gaqP4wmzcts4AA1A/edit#gid=0) under column B. In many cases, new data will not have an assigned URI and one will need to be created and logged in that sheet.
- The [editors.xml](https://github.com/srophe/caesarea/blob/master/documentation/editors.xml) ID for the encoder entering the metadata should be added to the `Testimonium metadata entered by` field.

The following metdata may need to be entered manually:

- Testimonium URNs (not currently being implemented for v1.0 of the database)
- Link to an electronic version of the testimonium. These are not available for every record, however, when possible, input these in the `Link to Excerpt` fields.
- Zotero URIs for each bibliographic item must be added to the `Zotero URI` field. It is possible the previous encoder will have already entered these URIs.
  - If a Zotero record has not been created for the item, one will need to be created following the [Encoding Manual for A Comprehensive Bibliography on Caesarea Maritima](https://github.com/srophe/caesarea-data/wiki/TEI-Encoding-Manual-for-A-Comprehensive-Bibliography-on-Caesarea-Maritima)
  - Note: The post-processing script will delete the prose text node of the bibl element, so there is no need to remove these by hand.
 
## Run Post-Processing Script

Once the requisite metadata has been entered manually, the post-processing script can be run to finish processing records. This script runs in [BaseX](https://basex.org/).

### Setting Global Options in BaseX

BaseX's global options need to be changed to ensure this script runs properly. To change a setting, ensure that the Input Bar is open ("View > Input Bar"); type `set {command} {value}`, e.g. `set writeback true`. The following command is used in these scripts:

- writeback: when true, enables update scripts to write changes to disk, allowing update functions to change input files. When false, updates are not written to disk.
- chop: when true, removes whitespace between elements. When false, preserves whitespace between elements. It is necessary to set this to false/off when working with mixed-content elements.

These must be set as follows:

- set writeback false
- set chop off

### Updating Input and Output Directories

Two global parameters need to be changed when running this script:

1. The variable `$inputDirectoryUri` should point to the local directory storing the input documents, usually the "/draft-data" sub-directory of the local clone of the [caesarea-data](https://github.com/srophe/caesarea-data/) repository. This variable is set at [line 189](https://github.com/srophe/srophe-xQueries/blob/master/Caesarea-Data-Entry-Phase2/testimonia-postprocessing-script.xq#L189)
2. The variable `$outputDirectoryUri` should point to the directory where processed records should be stored. The script will create this directory if it does not already exist. This variable is set at [line 190](https://github.com/srophe/srophe-xQueries/blob/master/Caesarea-Data-Entry-Phase2/testimonia-postprocessing-script.xq#L190)
  - note that the script does not delete the input records, it just creates updated versions at the location specified by this variable. 
  
After running the script, the created records may be moved into the data repository and pushed to the server.
