xquery version "3.1";

(:
: Module Name: The Syriac Gazeteer Export to Linked Places TSV Format
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 21 March 2017
: Module Overview: This library module contains functions for transforming TEI XML 
:                  files from The Syriac Gazeteer (http://syriaca.org/geo) to 
:                  the Linked Places TSV format (v0.5) (https://github.com/LinkedPasts/linked-places-format/blob/main/tsv_0.5.md)
:)

(:~
: This module provides functions for exporting Linked Place TSV
: 
:
: @author William L. Potter
: @since February 26, 2026
: @version 1.0
:)
module namespace lptsv="http://syriaca.org/ns/lptsv";

import module namespace lpcore="http://syriaca.org/ns/lpcore" at "lpcore.xqm";

import module namespace functx="http://www.functx.com";


declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace srophe = "https://srophe.app";

(:~ 
: Create a Linked Places TSV from a collection of Syriaca place records 
: @param $collection A collection of Syriaca place records, in TEI XML
: @return String representation of the place records as a Linked Places Tab Separated Values
: :)
declare function lptsv:create-tsv-from-collection($collection as item()*) 
as xs:string
{
  let $rows :=
    for $doc in $collection
    return lptsv:create-row-from-doc($doc)
  
  return csv:serialize(<csv>{$rows}</csv>, map {"header": "yes", "field-delimiter": "	"})
};

(:~ 
: Creates a row of Linked Places data from a Syriaca place document
: @param $doc A TEI XML document representing a Syriaca place record
: @return A row of data in the Linked Places format, structured as a flattened XML node
:)
declare function lptsv:create-row-from-doc($doc as node())
as node() {
  let $place := $doc/TEI/text/body/listPlace/place
  let $uri := $place/idno[@type="URI"][starts-with(./text(), $lpcore:base-uri)]/text()
  let $id := $uri
  
  let $enHeadword := lpcore:get-english-headword($place)
    
  (: PLACE TYPE AND CROSSWALKS :)
  let $placeType := $place/@type/string()
  let $crosswalkedTypes := lpcore:get-place-type-crosswalks($placeType, $place/@ana/string())

  (: DATE INFORMATION :)
  (: TODO: split to lpcore? :)
  let $existenceState := $place/state[@type="existence"]
  let $start := $existenceState/@from/string()
  let $end := $existenceState/@to/string()
  
  let $attestationYear := lpcore:get-publication-date($doc) => substring(1, 4)
  
  (: ENTITY/CONCEPT MATCHES :)
  (: get the normalized list of URIs from the record :)
  let $matches := lptsv:get-matches-from-uris($place/idno[@type="URI"])
  
  (: NAME VARIANTS :)
  let $variants := lptsv:get-name-variants-from-placeNames($place/placeName)
  
    
  (: PARENT NAME AND ID, i.e. containers :)
  (: TBD :)
  (: Unclear if multiple values allowed? If not, how do we decide which to use? :)
  
  (: LOCATION INFO :)
  let $coords := lpcore:get-preferred-geometry($place)
  let $long := $coords[2]
  let $lat := $coords[1]
  (: TODO: currently not supported are the geo_id and geo_source fields (cf. lpcore notes) :)
  
  (: DESCRIPTION/ABSTRACT :)
  let $tsgAbstract := lpcore:get-abstract($place)
  
  (: return the row, using the LP TSV v0.5 column headers :)
  return
  <row>
    <id>{$id}</id>
    <title>{$enHeadword}</title>
    <title_source>{$lpcore:title-source}</title_source>
    <fclasses>{$crosswalkedTypes?fclasses}</fclasses>
    <aat_types>{$crosswalkedTypes?aat_types}</aat_types>
    <start>{$start}</start>
    <attestation_year>{$attestationYear}</attestation_year>
    <end>{$end}</end>
    <title_uri>{$uri}</title_uri>
    <ccodes></ccodes>
    <matches>{$matches}</matches>
    <variants>{$variants}</variants>
    <types>{$placeType}</types>
    <parent></parent>
    <parent_id></parent_id>
    <lon>{$long}</lon>
    <lat>{$lat}</lat>
    <geokwt></geokwt>
    <geo_source></geo_source>
    <geo_id></geo_id>
    <approximation></approximation>
    <description>{$tsgAbstract}</description>
  </row>
};

(: TODO: I may have misread the documentation, and additional URIs are permitted but they should just be the full URI rather than using the namespace abbreviations? :)
(:~ 
: Create the data for the matches field from the list of URIs in the Syriac place record
: @param $uris A sequence of tei:idno elements containing URIs that are close matches to the Syriaca place record
: @return A string of semi-colon delimited matches using the LP TSV namespace abbrevations :)
declare function lptsv:get-matches-from-uris($uris as node()*)
as xs:string {
  let $uriList := for $uri in $uris return $uri//text() => string-join(" ") => normalize-space()
  
  (: For each URI, check it against the URI base record in the match sources :)
  (: Add the ID portion based on the pattern, prefixed with the source key :)
  let $matches :=
    for $uri in $uriList
    for $source in map:keys($lpcore:entity-match-sources)
    where contains($uri, $lpcore:entity-match-sources?$source?base)
    return $source||":"||substring-after($uri, $lpcore:entity-match-sources?$source?base)
 return string-join($matches, ";")
};

(:~ 
: Collect the Syriaca place names into a semi-colon delimited string of variants, tagged by language
: @param $placeNames A sequence of tei:placeName elements, with an xml:lang attribute
: @return A string representing a semi-colon delimited sequence of name variants, tagged by language :)
declare function lptsv:get-name-variants-from-placeNames($placeNames as node()+)
as xs:string
{
  let $variants :=
    for $name in $placeNames
      let $nameString := $name//text() => string-join(" ") => normalize-space()
      let $langCode := $name/@xml:lang/string()
      let $langCode := if($langCode = "en-x-srp1") then "en" else $langCode (: normalize the custom transliterations :)
      return $nameString||"@"||$langCode
  return distinct-values($variants) => string-join(";")
};