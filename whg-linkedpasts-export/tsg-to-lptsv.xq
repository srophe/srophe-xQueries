xquery version "3.1";

(:
: Module Name: The Syriac Gazeteer Export to Linked Places TSV Format
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 21 March 2017
: Module Overview: This main module transforms TEI XML files from The Syriac
                   Gazeteer (http://syriaca.org/geo) to the Linked Places TSV
                   format (v0.5) (https://github.com/LinkedPasts/linked-places-format/blob/main/tsv_0.5.md)
:)

import module namespace lptsv="http://syriaca.org/ns/lptsv" at "lptsv.xqm";
import module namespace lpjson="http://syriaca.org/ns/lpjson" at "lpjson.xqm";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace srophe = "https://srophe.app";

let $collection := collection("/home/arren/Documents/GitHub/syriaca-data/data/places/tei/") (: TODO: make this an external variable :)
let $mode := "jsonld" (:TODO: Make this an external variable :)
(:
TODO:
- implement an lpjson module for creating JSON-LD records following the LP spec
- add an external $mode variable for selecting "csv" or "json"
- add error handling and reporting
- add output handling
:)

return switch($mode) 
  case "tsv" return lptsv:create-tsv-from-collection($collection)
  case "jsonld" return lpjson:create-jsonld-from-collection($collection)
  default return "Incorrect mode selection: "||$mode