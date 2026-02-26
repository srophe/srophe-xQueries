xquery version "3.1";

(:
: Module Name: The Syriac Gazeteer Export to Linked Places Core Module
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 21 March 2017
: Module Overview: This library module contains core utility functions for 
:                  transforming TEI XML records from The Syriac Gazeteer (http://syriaca.org/geo)
:                  to the Linked Places data model
:)
(:~
: This module provides core utility functions for exporting Linked Place data
: 
:
: @author William L. Potter
: @since February 26, 2026
: @version 1.0
:)
module namespace lpcore="http://syriaca.org/ns/lpcore";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace srophe = "https://srophe.app";

declare variable $lpcore:place-type-crosswalk := csv:doc("place-types-crosswalk.csv", map{"header": "yes"});

declare variable $lpcore:base-uri := "http://syriaca.org/place/";

declare variable $lpcore:title-source := "The Syriac Gazetteer (http://syriaca.org/geo)";

declare variable $lpcore:entity-match-sources := {
  "dbp": {
    "name": "DBpedia", 
    "base": "http://dbpedia.org/resource/"
  },
  "pl": {
    "name": "Pleiades", 
    "base": "https://pleiades.stoa.org/places/"
  },
  "viaf": {
    "name": "Virtual International Authority File", 
    "base": "http://viaf.org/viaf/"
  },
  "wp": {
    "name": "Wikipedia", 
    "base": "wikipedia.org/wiki/"
  }
};
(:
    ?? odd format... {"gn": GeoNames, "http://www.geonames.org/"}, or data doesn't use records from GeoNames but just coordinates
    Others that could be added:
    - BnF
    - CERL (Consortium of Euro Res Libs)
    - Deutschen Nationalbibliothek
    - The Genealogical Gazeteer
    - LoC
    - Getty TGN
    - WikiData
  :)

(: FUNCTIONS :)

(:~ 
: Extract the English headword place name from a Syriaca place record
: @param A Syriaca place record (TEI XML place element)
: @return String representing the place name tagged as a headword, with language of English :)
declare function lpcore:get-english-headword($place as node())
as xs:string {
  $place/placeName[contains(@xml:lang, "en")][contains(@srophe:tags, "#syriaca-headword")]//text() 
    => string-join(" ")
    => normalize-space()
};

(:~ 
: Collates the crosswalked place types from Getty's AAT and TGN's Feature Classes
: @param $type The place type of the Syriaca record 
: @param $typeUri The corresponding URI of the place type, from Syriaca's Taxonomy 
: @return A map containing the $type, $typeUri, and the corresponding AAT and FClasses 
:)
declare function lpcore:get-place-type-crosswalks($type as xs:string,
                                                  $typeUri as xs:string)
as map(*) {
  let $crosswalkRow := $lpcore:place-type-crosswalk/*:csv/*:record[normalize-space(./*:tsg_type) = $type]
  let $fclasses := $crosswalkRow/*:fclasses/text() => normalize-space()
  let $aat_types := $crosswalkRow/*:aat_types/text() => normalize-space()
  return map {
    "type": $type,
    "type_uri": $typeUri,
    "fclasses": $fclasses,
    "aat_types": $aat_types
  }
};

(:~ 
: Get the publication date from a Syriaca place document
: @param $doc The Syriaca place record
: @return The publication date (ISO format) for the Syriaca place document :)
declare function lpcore:get-publication-date($doc as node())
as xs:string? {
  $doc/TEI/teiHeader/fileDesc/publicationStmt/date/text()
};

(:~ 
: Get the GPS locations from the Syriaca place record, optionally filtering by subtype
: @param $place The Syriaca place record containing tei:location elements
: @param $subtypeFilter Optional string for filtering by the location's subtype attribute
: @return A sequence of zero or more tei:location elements containing geometries :)
declare function lpcore:get-gps-locations($place as node(),
                                          $subtypeFilter as xs:string := ())
as node()* {
  let $locations := $place/location[@type="gps"]
  return if ($subtypeFilter and count($locations) > 1) then $locations[@subtype=$subtypeFilter] else $locations
};

(:~ Returns a sequence of strings representing the latitude and longitude geometries of a point
: From the preferred geometry of a Syriaca place record
: @param $place The place record from which to extract the geometry
: @return A sequence of two strings, representing the latitude and longitude of a point :)
declare function lpcore:get-preferred-geometry($place as node())
as xs:string* {
  let $location := lpcore:get-gps-locations($place, "preferred")
  return $location/geo/text() 
          => normalize-space()
          => tokenize(" ")
};

(:~ 
: Returns the Syriaca place record's abstract, for the corresponding series
: @param $place The Syriaca place record
: @param $series The URI for the corresponding series, defaults to the TSG series
: @return A string of the abstract/description for that place
 :)
declare function lpcore:get-abstract($place as node(),
                                     $series as xs:string := "http://syriaca.org/geo")
as xs:string? {
  $place/desc[@type="abstract"][contains(@corresp, $series)]//text() => string-join(" ") => normalize-space()
};

(:

(: TODO: geo coordinate sourcing :)
(: get the first location element that contains the preferred coordinates :)
  (: used for getting the geo source :)
  (: let $geoLocation := $coords/ancestor::location[1]
  let $locationSourceId := $geoLocation/@source/string() => substring-after("#")
  let $locationBibl := $place/bibl[@xml:id = $locationSourceId] :)
  (:
  TBD:
  - Get the title for the bibl (use a side lookup of CBSS data?)
  - If there is an entry URL, e.g. for pleiades, e.g. <citedRange unit="entry" target="https://pleiades.stoa.org/places/727105">https://pleiades.stoa.org/places/727105</citedRange> use that
  
  Discuss with Dave:
  http://syriaca.org/cbss/P8KQJ7AE = GEDSH
http://syriaca.org/cbss/NAA6P8IX = Pleiades
http://syriaca.org/cbss/RUENEDMU = Syriac World Maps
http://syriaca.org/cbss/SIUIHZRW = Syria (Syria Prōtē, Syria Deuteria, Syria Euphratēsia) (Todt and Vest, 2014)
  Do we only want geo_source and geo_uri for Pleiades? Or do we have somewhere that we can get the Geo data for GEDSH or Syriac World maps?
  - Unclear if the record URI can be the source for the coordinates? (maybe could use this also in cases of @resp="syriaca"?)
  :)
:)

declare function lpcore:get-place-name-lang-code($name as node())
as xs:string {
  let $langCode := $name/@xml:lang/string()
  (: Handle edge cases that need to be normalized :)
  return switch($langCode) 
    case "en-x-srp1" return "en"
    default return $langCode
};

declare function lpcore:get-bibl-sources($element as node())
as node()* {
  for $src in tokenize($element/@source/string(), " ")
  let $bibId := substring-after($src, "#")
  return $element/../bibl[@xml:id=$bibId]
};