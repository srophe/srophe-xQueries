---
Title: Syriaca Manuscripts 2019-2020 Processing Util Readme
Author: William L. Potter
---

# Post-Processing Scripts for the 2019-2020 Phase of Syriaca Manuscript Encoding

This directory houses XQuery scripts and their associated data files for converting the skeleton XML encoding of manuscripts in Wright's ... into fully formed Syriaca manuscript records. This document describes how to use the files in this directory to accomplish that conversion. Descriptions are given for each step and function. _The essential information is contained in the **Global Options** and **Process** sections of each script._

## General Notes

Once data has been finalized in Wright Catalogue Repository it is moved to the Dev branch of Srophe-App-Data.

## General Requirements and Dependencies

- The XQuery scripts depend upon several BaseX modules, such as [file](https://docs.basex.org/wiki/File_Module) and [csv](https://docs.basex.org/wiki/CSV_Module). As such, it is highly recommended that these scripts be executed using BaseX. BaseX may be downloaded [here](http://basex.org/download/).
  - Note that certain update functions require setting global options. Instructions for setting these options assume the use of BaseX.

## Overview of the Wright Catalogue Repository Structure

Although these scripts may be housed in a separate repository, they are intended to act upon data in the [Srophe Wright Catalogue Data Repository](https://github.com/srophe/wright-catalogue/tree/master/data). An overview of that repository follows.

The logic of the [Srophe Wright Catalogue Data Repository](https://github.com/srophe/wright-catalogue/tree/master/data) roughly follows the editorial process. Currently, only [3_drafts](https://github.com/srophe/wright-catalogue/tree/master/data/3_drafts), [4_to_be_checked](https://github.com/srophe/wright-catalogue/tree/master/data/4_to_be_checked), and [5_finalized](https://github.com/srophe/wright-catalogue/tree/master/data/5_finalized) are in use. (Directories 1_raw_ocr and 2_preprocessing)

Encoders store their encoded drafts in "3_drafts" as skeleton XML records using the CSS form for oXygen Author mode.

The [post-processing script](#add-project-metadata-and-manuscript-item-numbering) stores the fully-formed TEI XML records in a directory within "4_to_be_checked". The "needs-ms-parts" folder may be used to separate out those manuscripts which require the additional encoding step of separating manuscript parts, fly leaves, and palimpsest portions into `<msPart>` elements.

Once drafted and post-processed, manuscript records can be assigned to editors to edit, and, once complete, moved to "5_finalized". (Note: for ease of access, manuscripts which are ready to edit may be copied into a Box or Dropbox folder, edited there, and copied back to the GitHub directory. Provided the files in GitHub were not changed in any other way, replacing them with the edited files will generate a .diff report that may be used to verify the accuracy of the proofreader's edits.)

After being moved to "5_finalized", they can be copied onto the [srophe-app-data dev repository](https://github.com/srophe/srophe-app-data/tree/dev/data/manuscripts/tei). This move can be indicated in the Wright Catalogue repository by moving the transferred files to the [TransferredToDevServer](https://github.com/srophe/wright-catalogue/tree/master/data/5_finalized/TransferredToDevServer) directory.


## Overview of Transformation Process

1. [Add Project Metadata and Manuscript Item Numbering](#add-project-metadata-and-manuscript-item-numbering):

The encoders enter data into the CSS form using oXygen's author mode, which results in a stripped-down encoding that lacks most project metadata, manuscript item and additions enumerations and identifiers, etc. These are added by the "postProcessingTests.xql" script (**Note**: despite the inclusion of "tests" in the script name, this is a fully functioning script) and a full-fledged TEI XML draft of the manuscript records is stored in a new directory.

2. [Remove Empty Elements and Attributes](#remove-empty-elements-and-attributes):

Using the CSS forms in oXygen's author mode results in empty elements that remain in the XML file. After the manuscript records have undergone post-processing, these empty elements and attributes may be safely removed using the "removeEmptyElements.xql" script.

3. [Edit Manuscript Records](#edit-manuscript-records)

See the [Overview of the Wright Catalogue Repository Structure](#overview-of-the-wright-catalogue-repository-structure).

4. [Move Edited Manuscripts to Dev Server](#move-edited-manuscripts-to-dev-server)

See the [Overview of the Wright Catalogue Repository Structure](#overview-of-the-wright-catalogue-repository-structure).

----

# Setting Global Options in BaseX

In several cases, the global BaseX options need to be changed depending on the scripts being used. The requisite settings are listed under each heading as "Global Options". To change a setting, ensure that the Input Bar is open ("View > Input Bar"); type `set {command} {value}`, e.g. `set writeback true`. The following commands are used in these scripts:

- writeback: when true, enables update scripts to write changes to disk, allowing update functions to change input files. When false, updates are not written to disk.
- chop: when true, removes whitespace between elements. When false, preserves whitespace between elements. It is necessary to set this to false/off when working with mixed-content elements.

# Add Project Metadata and Manuscript Item Numbering

## postProcessingTests.xql
- **Global Options**:
  - Writeback: false
  - Chop: off
- **BaseX Modules Used**: [file](https://docs.basex.org/wiki/File_Module)
- **Process**
  - Set input file directory: change variable $inputDirectory at line 412 to point to the directory where new drafts are ready to be processed.
  - Set output file directory: change variable $outputFilePath at line 413
  - Point script to the simplified Wright Decoder data table: change xs:string input of the `file:read-text` function to the file URI of the simplified Wright Decoder
    - Note: this table should include the BL Shelf-mark | Volume#page numbers | Wright Roman Numerals | Wright Dating | and Syriaca manuscript URI from the [Wright Decoder](https://docs.google.com/spreadsheets/d/183Sm8nyRtlE2Ucl5JyLg4_RvXSgTF-xB0ceacj2n3BY/edit#gid=0).
    - This table should be a tab-separated value file (TSV) with no header row.
  - Point script to the Wright Taxonomy lookup table: change variable $wrightTaxonomyCsvUri at line 416.
    - This file should be a table of the xml:id attributes associated with Wright's subject heading taxonomy mapped to the Wright numeral of the first manuscript associated with that subject heading. This table is used to determine which value to tag a given manuscript with in its `//textClass/keywords[@scheme="#Wright-BL-Taxonomy"]/list/item/ref/@target` attribute.
    - This file should be a TSV file and may contain a header row.
  - Point script to directories it should check to see if a record already exists: update the $existingRecordPathList in line 420 by adding, deleting, or editing its sequence of xs:strings
    - These file URIs should be directories where records are stored which have already been post-processed or edited. The script generates a list of files from these directories to ensure that it is only processing _new_ records. This in turn enables the script to be run on the same drafts folder without fear of reduplicating an alread-edited manuscript record.
  - Update project metadata
    - line 97 controls the person credited with project management. This respStmt can be edited or removed as needed, depending upon the phase of the project.
    - lines 49-58 control the lookup of editors for crediting the record creator. This list should be edited as needed.
  - Run script
  - The result should be newly post-processed files with project metadata, enumeration of msItems, etc.


# Remove Empty Elements and Attributes

## removeEmptyElements.xql

- **Global Options**:
  - Writeback: true
  - Chop: off
- **BaseX Modules Used**: [file](https://docs.basex.org/wiki/File_Module) and [csv](https://docs.basex.org/wiki/CSV_Module)
- **Process**
  - Point script to input folder: change variable $inputDirectory in line 39 to the directory containing the files with empty elements needing to be removed.
  - Run script
  - In order to prevent truncated whitespace from causing spacing issues in mixed-content elements, BaseX should be set to preserve whitespace (i.e., "Chop: off"). However, this causes blank lines to be retained when deleting empty elements. The following find-and-replace-in-files regex may be used to delete these empty lines:
    - Find: `\n\s*\n`
    - Replace `\n`

Records may now be edited and moved through the [Srophe Wright Catalogue Data Repository](https://github.com/srophe/wright-catalogue/tree/master/data) manually.
