xquery version "3.1";

(:
: Module Name: Caesarea-Maritima.org Testimonia Postprocessor Configuration
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 08 April 2014
: Module Overview: This module contains configuration information for
:                  running the post-processing module for newly
:                  created records for Caesarea-Maritima.org's Testimonia
:                  database.
:)

(:~ 
: This module provides the functions that generate a CSV report of tagged entities
: (authors, works, persons, places, and bibliography) in a database of manuscript
: catalogue entries.
:
: @author William L. Potter
: @version 1.0
:)
module namespace config="http://wlpotter.github.io/ns/cm/config";
import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

(: ~~~~~~~~~~~~~~ :)
(: I/O Parameters :)
(: ~~~~~~~~~~~~~~ :)

(: Change these to reflect the location of the desired input and output directories :)

(: should be a string representing the directory where input files are stored :)
declare variable $config:input-directory := "/home/arren/Documents/GitHub/srophe-xQueries/Caesarea-Data-Entry-Phase2/test-in/";

declare variable $config:input-collection := collection($config:input-directory);

(: should be a string representing the directory where processed files should be stored :)
declare variable $config:output-directory := "/home/arren/Documents/GitHub/srophe-xQueries/Caesarea-Data-Entry-Phase2/test-out/";


(: ~~~~~~~~~~~~~~~~ :)
(: Project Metadata :)
(: ~~~~~~~~~~~~~~~~ :)

declare variable $config:project-uri-base := "https://caesarea-maritima.org/testimonia/";

declare variable $config:editor-uri-base := "https://caesarea-maritima.org/documentation/editors.xml#";


(: ~~~~~~~~~~~~~~~~~~~ :)
(: Reference Documents :)
(: ~~~~~~~~~~~~~~~~~~~ :)

(: the following documents can be referenced via either https, e.g. a GitHub file, or by pointing to a local document. :)
declare variable $config:editors-doc-uri := "https://raw.githubusercontent.com/srophe/caesarea/master/documentation/editors.xml";

declare variable $config:period-taxonomy-doc-uri := "https://raw.githubusercontent.com/srophe/caesarea/master/documentation/caesarea-maritima-historical-era-taxonomy.xml";

declare variable $config:data-template-doc-uri := "https://raw.githubusercontent.com/srophe/caesarea-data/master/draft-data/testimonia-data-template.xml";


(: Reference Document Creation :)
(: note: these lines should _not_ be changed. Instead, update the file references above under "Reference Documents" :)
declare variable $config:editors-doc := doc($config:editors-doc-uri);

declare variable $config:period-taxonomy-doc := doc($config:period-taxonomy-doc-uri);

declare variable $config:data-template-doc := doc($config:data-template-doc-uri);
(:
additions?
- should have
:)

(:
- additional config options?

:)