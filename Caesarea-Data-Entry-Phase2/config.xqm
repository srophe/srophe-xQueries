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
declare variable $config:input-directory := "/home/arren/Documents/GitHub/caesarea-data/data/testimonia/tei";

declare variable $config:input-collection := collection($config:input-directory);

(: should be a string representing the directory where processed files should be stored :)
declare variable $config:output-directory := "/home/arren/Documents/GitHub/caesarea-data/draft-data/out/";


(: ~~~~~~~~~~~~~~~~ :)
(: Project Metadata :)
(: ~~~~~~~~~~~~~~~~ :)

declare variable $config:project-uri-base := "https://caesarea-maritima.org/";

declare variable $config:testimonia-uri-base := $config:project-uri-base||"testimonia/";

declare variable $config:bibl-uri-base := $config:project-uri-base||"bibl/";

declare variable $config:editor-uri-base := "https://caesarea-maritima.org/documentation/editors.xml#";

(: Responsibility Statements :)

declare variable $config:resp-string-for-creator := "Electronic text added by";

declare variable $config:resp-string-for-metadata := "URNs and other metadata added by";

declare variable $config:resp-string-for-tei := "TEI encoding by";

(: the editors.xml id for the person responsible for creating the TEI file itself :)
declare variable $config:editor-id-for-tei := "jrife";

(: Historical Period Taxonomy Data :)
(: Note: the categories themselves are stored in the document addressed by $config:period-taxonomy-doc-uri and are constructed on the fly by the script :)

declare variable $config:period-taxonomy-id := "CM-NEAEH";

declare variable $config:period-taxonomy-description :=
  <desc xmlns="http://www.tei-c.org/ns/1.0">
    <title>Caesarea-Maritima.org Chronology</title>: This chronology is adapted from
                  the chronology used in <bibl>
                     <title>The New Encyclopedia of Archaeological Excavations in the Holy
                        Land</title>
                     <ptr target="https://caesarea-maritima.org/bibl/HG492LV3"/>
                  </bibl>. This taxonomy is used in the <gi>catRef</gi> encoding to classify the
                  testimonia according to the time period(s) of the events described, rather than
                  the date of composition of the testimonium. For example, Josephus may describe
                  events occuring well before the period of his writing.</desc>
;
(: Labels for the listBibls :)

declare variable $config:works-cited-listBibl-label := "Works Cited";

declare variable $config:additional-bibls-listBibl-label := "Additional Bibliography";


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

(: ~~~~~~~~~~~~~~~~~~~ :)
(: Responsibility Statements :)
(: ~~~~~~~~~~~~~~~~~~~ :)

declare variable $config:resp-stmt-data :=
  map {
    "identified":
      map {
          "pos": 5,
          "resp-text": "Testimonium identified by",
          "is-creator": true (),
          "change-log-message": ()
      },
    "transcribed":
      map {
          "pos": 4,
          "resp-text": "Testimonium transcribed by",
          "is-creator": true (),
          "change-log-message": ()
      },
      "translated":
      map {
          "pos": 3,
          "resp-text": "Testimonium translated by",
          "is-creator": true (),
          "change-log-message": ()
      },
     "tei":
      map {
          "pos": 2,
          "resp-text": "TEI record created by",
          "is-creator": false (),
          "change-log-message": "CREATED: testimonium"
      },
      "edited":
      map {
          "pos": 1,
          "resp-text": "Testimonium edited by",
          "is-creator": false (),
          "change-log-message": "CHANGED: Proofreading and general edits"
      },
      "ed-review":
      map {
          "pos": 6,
          "resp-text": "Editorial review by",
          "is-creator": false (),
          "change-log-message": ()
      },
      "res-asst":
      map {
          "pos": 7,
          "resp-text": "Research assistance by",
          "is-creator": false (),
          "change-log-message": ()
      }
  };
