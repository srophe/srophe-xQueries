---
Title: Caesarea Testimonia Transform Readme
Author: William L. Potter
---

# Caesarea Testimonia Transform Scripts

This directory houses XQuery scripts and their associated data files for creating Caesarea-Maritima.org testimonia TEI XML records from TSV data. The conversion from TSV to XML takes place in three stages. This document describes how to use the files in this directory to accomplish that conversion. Descriptions are given for each step and function. _The essential information is contained in the **Global Options** and **Process** sections of each script._

## General Requirements and Dependencies

- The XQuery scripts depend upon several BaseX modules, such as [file](https://docs.basex.org/wiki/File_Module) and [csv](https://docs.basex.org/wiki/CSV_Module). As such, it is highly recommended that these scripts be executed using BaseX. BaseX may be downloaded [here](http://basex.org/download/).
  - Note that certain update functions require setting global options. Instructions for setting these options assume the use of BaseX


## Overview of Transformation Process

1. [Collate edition and translation data](#collate-edition-and-translation-data):

The testimonia data have been entered as two rows in a spreadsheet: one for the edition and one for the translation. Before converting these to TEI, the two data rows need to be combined together. This is accomplished with the collateTestimoniaEditionAndTranslation.xq script.

2. [Input work-level metadata](#input-work-level-metadata):

Once the testimonia edition and translation data have been collated, work-level metadata needs to be added to the resulting TSV file, including VIAF link for author, date of composition, etc.

3. [Transform TSV to XML](#transform-tsv-to-xml):

Inputting the work-level metadata is the final stage before the records can be converted into TEI XML documents. This transform is accomplished with the processTsv.xq script. This script will need to be updated to point to the configuration files, which contain project-level metadata as well as point to the location of input and output directories required by the script.

4. [Run post-processing scripts](#run-post-processing-scripts):

The XML transform does not include the creation of several elements. This gap in functionality is in part due to the phased nature of the development of the project. These gaps are filled by several other update functions that must be run after the xml files have been created.

5. [Use regex to clean-up whitespace issues](#use-regex-to-clean-up-whitespace-issues):

Due to the way BaseX handles whitespace when executing update scripts, the previous stages result in XML files which, while complete, nevertheless have whitespace issues. These issues can be rectified with a simple find-and-replace regex.

----

# Setting Global Options in BaseX

In several cases, the global BaseX options need to be changed depending on the scripts being used. The requisite settings are listed under each heading as "Global Options". To change a setting, ensure that the Input Bar is open ("View > Input Bar"); type `set {command} {value}`, e.g. `set writeback true`. The following commands are used in these scripts:

- writeback: when true, enables update scripts to write changes to disk, allowing update functions to change input files. When false, updates are not written to disk.
- chop: when true, removes whitespace between elements. When false, preserves whitespace between elements. It is necessary to set this to false/off when working with mixed-content elements.

# Collate edition and translation data

## collateTestimoniaEditionAndTranslation.xq
- **Global Options**:
  - Writeback: false
  - Chop: off
- **BaseX Modules Used**: [file](https://docs.basex.org/wiki/File_Module) and [csv](https://docs.basex.org/wiki/CSV_Module)
- **Process**
  - Prepare input file by removing "[Next ID \d+]" from the field header "testimoniaID [Next ID 202]"
  - Set input file: change variable $input at line 56.
    - The xs:string input of the "file:read-text" function should be the URI of the TSV file containing the raw testimonia data. This will usually be a file inside the tsvSources folder.
    - Note: the input file's separator character is controlled by line 55
  - Run script
  - Copy output to a blank spreadhseet and save as a CSV file in the processTsvData folder.


# Input Work Level Metadata

This stage does not require an XQuery script. Instead, refer to the [Historical Metadata Sheet](https://docs.google.com/spreadsheets/d/1ZG8blfcVZ62zSkkW22HEbUyMYm7gaqP4wmzcts4AA1A/edit#gid=1526521449) (though this may have errors or be incomplete).

The following metadata must be entered:

- Author VIAF URI in "sourceUriWorkAuthor" column
- Creation Date in "creationDate" column
  - note: this must be of the form "\d+ [B]?CE" or "\d+ - \d+ [B]CE?" or "\d+ BCE - \d+ CE". The spaces are used by the transform to parse this into machine readable @notBefore, @notAfter, or @when attributes.
- Place of Composition in "creationLocation" column
- Pleiades link of place of composition in "creationLocationUri" column

The following metadata must be entered for certain sources
- work-level CTS-URN (e.g. urn:cts:greekLit:tlg4029.tlg002) in the "workUrn" column
  - For some records, these will need to be minted using the TLG numbers or other standardized referencing system
- URL/API base to convert a CTS-URN into a URI (e.g. http://data.perseus.org/citations/) in the "workUriBase" column.
  - It is likely the case that if the work URN must be minted, there will be no URL/API base available. In such cases, this field may remain blank

The following metadata must be batch updated
- The text languages should be updated to their ISO 2 or 3 digit codes in "workLang", "edition1Lang", and "translation1Lang" columns.
  - e.g. "Greek" becomes "grc"; "English" becomes "en"

# Transform TSV to XML

## processTsv.xq
- **Global Options**:
  - Writeback: false
  - Chop: off
- **BaseX Modules Used**: [file](https://docs.basex.org/wiki/File_Module) and [csv](https://docs.basex.org/wiki/CSV_Module)
- **Process**
  - Change settings in configLocal.xml, which should be in the processTsvData sub-directory.
    - `/configuration/inputFileUri` text node should be the file URI of the input document, likely in the processTsvData sub-directory.
    - `/configuration/outputPath` points to a directory where the XML documents will be stored (the script creates this if it does not exist). It is useful to store generated XML files in a temporary directory and moving them to the GitHub repository only after post-processing.
  - `/configuration/delimiter` controls the CSV delimiter character. By default this is a tab.
- Run script.
- This should store the XML files in the directory specified in "configLocal.xml".

# Run Post-Processing Scripts:

Several functions have been separated into stand-alone scripts that should be run after the generation of the XML from the TSV data. These should be run in the following order:

## add-origDate-period-attribute.xq

This script updates the tei:origDate by adding a @period attribute based on the date range expressed in the @notBefore/@notAfter or @when attributes using a CSV representation of the Caesarea-Maritima.org periodization.

- **Global Options**:
  - Writeback: true
  - Chop: off
- **BaseX Modules Used**: [file](https://docs.basex.org/wiki/File_Module) and [csv](https://docs.basex.org/wiki/CSV_Module)
- **Process**
  - line 38 points the script to the periodization taxonomy CSV input. Line 37 controls the delimiter character used by the CSV file.
  - line 43 points the script to the directory where the XML records to which you are adding @period attributes are stored.
  - Run script.

## create-testimonia-abstract.xql
This script generates an abstract for Caesarea-Maritima.org Testimonia records based upon information encoded in the records' tei:profileDesc and the entities tagged as tei:placeName elements in the testimonia excerpts.

- **Global Options**:
  - Writeback: true
  - Chop: off
- **BaseX Modules Used**: none
- **Process**
  - line 52 points the script to the directory where the XML records to which you are adding abstracts are stored.

## add-cts-urn-idnos-to-quotes.xq
This script adds CTS-URNs to tei:idno elements nested within the translation and edition tei:quote elements of Caesarea-Maritima.org testimonia records. These CTS-URNs are based on the machine readable sources stored in Caesarea-Maritima.org's bibl module. The CTS-URN is accompanied by an @xml:base attribute which, when concatenated with the URN, should create a URI that resolves to the excerpted portion of the text in another database, e.g. Perseus Digital Library.

- **Global Options**:
  - Writeback: true
  - Chop: off
- **BaseX Modules Used**: [file](https://docs.basex.org/wiki/File_Module) and [json](https://docs.basex.org/wiki/JSON_Module)
- **Process**
  - line 17 points the script to the directory where the XML records to which you are adding CTS-URNs are stored.
  - This script makes use of the Caesarea-Maritima.org bibl module by referencing a CSL JSON export of the library. Before running the script, an updated JSON export should be performed:
    - Sync the Zotero desktop client with the online library.
    - Right-click (or ctrl+click, on Mac) on the Caesarea-Maritima.org Group Library and select "Export Library..."
    - Select "CSL JSON"
    - Save the generated JSON export (processTsvData is a good default location)
    - update line 18 of the script to point to the exported JSON file
  - Run script.

# Use regex to clean-up whitespace issues
The following **regex** should be used as a "find-and-replace-in-files" to clean up whitespace in the abstract:

- xpath: `/TEI/text/body/desc[@type="abstract"]`
- expression to find: `<quote>\s+<placeName xml:lang="(.+?)">(.+?)</placeName>\s+</quote>`
- expression to replace: `<quote><placeName xml:lang="\1">\2</placeName></quote>`

This will remove space between the tei:quote and tei:placeName elements in the abstract, which will in turn remove a space between the quotation mark and text in the HTML display.

----

The transformed files can now be added to the local GitHub directory for srophe/caesarea-data/data/testimonia/tei. Commit these changes and push to the origin.
