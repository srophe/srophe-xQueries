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


(:
- imports
- namespace declarations
- variable declarations
- function declarations
:)
import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace srophe = "https://srophe.app";

(:
Move the following to a module or external variable
:)
let $input-coll := collection("/home/arren/Documents/GitHub/syriaca-data/data/places/tei/")
let $place-type-crosswalk := csv:doc("place-types-crosswalk.csv", map{"header": "yes"})
let $base-uri := "http://syriaca.org/place/"
let $title-source := "The Syriac Gazetteer (http://syriaca.org/geo)"
let $entity-match-sources := {
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
}
(:
    ?? odd format... {"gn": GeoNames, "http://www.geonames.org/"}
    Others that could be added:
    - BnF
    - CERL (Consortium of Euro Res Libs)
    - Deutschen Nationalbibliothek
    - The Genealogical Gazeteer
    - LoC
    - Getty TGN
    - WikiData
  :)
(:-----:)

let $rows :=
  for $doc in $input-coll
  let $place := $doc/TEI/text/body/listPlace/place
  let $uri := $place/idno[@type="URI"][starts-with(./text(), $base-uri)]/text()
  let $id := substring-after($uri, $base-uri)
  
  let $enHeadword := $place/placeName[contains(@xml:lang, "en")][contains(@srophe:tags, "#syriaca-headword")]//text() => string-join(" ") => normalize-space()
  
  (: PLACE TYPE AND CROSSWALKS :)
  let $placeType := $place/@type/string()
  let $crosswalkRow := $place-type-crosswalk/*:csv/*:record[normalize-space(./*:tsg_type) = $placeType]
  let $fclasses := $crosswalkRow/*:fclasses/text() => normalize-space()
  let $aat_types := $crosswalkRow/*:aat_types/text() => normalize-space()

  (: DATE INFORMATION :)
  let $existenceState := $place/state[@type="existence"]
  let $start := $existenceState/@from/string()
  let $end := $existenceState/@to/string()
  
  let $attestationYear := $doc/TEI/teiHeader/fileDesc/publicationStmt/date/text() => substring(1, 4)
  
  (: ENTITY/CONCEPT MATCHES :)
  (: get the normalized list of URIs from the record :)
  let $uriList := for $uri in $place/idno[@type="URI"] return $uri//text() => string-join(" ") => normalize-space()
  
  (: For each URI, check it against the URI base record in the match sources :)
  (: Add the ID portion based on the pattern, prefixed with the source key :)
  let $matches :=
    for $uri in $uriList
    for $source in map:keys($entity-match-sources)
    where contains($uri, $entity-match-sources?$source?base)
    return $source||":"||substring-after($uri, $entity-match-sources?$source?base)
 let $matches := string-join($matches, ";")
  
  (: NAME VARIANTS :)
  let $variants :=
    for $name in $place/placeName
    let $nameString := $name//text() => string-join(" ") => normalize-space()
    let $langCode := $name/@xml:lang/string()
    let $langCode := if($langCode = "en-x-srp1") then "en" else $langCode (: normalize the custom transliterations :)
    return $nameString||"@"||$langCode
  let $variants := string-join($variants, ";")
  
  
  (: PARENT NAME AND ID, i.e. containers :)
  (: TBD :)
  (: Unclear if multiple values allowed? If not, how do we decide which to use? :)
  
  (: LOCATION INFO AND SOURCES :)
  let $gps := $place/location[@type="gps"]
  let $coords := if(count($gps) > 1) then $gps[@subtype="preferred"]/geo/text() else $gps/geo/text()
  
  let $long := tokenize($coords, " ")[2]
  let $lat := tokenize($coords, " ")[1]
  
  (: get the first location element that contains the preferred coordinates :)
  (: used for getting the geo source :)
  let $geoLocation := $coords/ancestor::location[1]
  let $locationSourceId := $geoLocation/@source/string() => substring-after("#")
  let $locationBibl := $place/bibl[@xml:id = $locationSourceId]
  (:
  TBD:
  - Get the title for the bibl (use a side lookup of CBSS data?)
  - If there is an entry URL, e.g. for pleiades, e.g. <citedRange unit="entry" target="https://pleiades.stoa.org/places/727105">https://pleiades.stoa.org/places/727105</citedRange> use that
  
  Discuss with Dave:
  http://syriaca.org/cbss/P8KQJ7AE = GEDSH
http://syriaca.org/cbss/NAA6P8IX = Pleiades
http://syriaca.org/cbss/RUENEDMU = Syriac World Maps
http://syriaca.org/cbss/SIUIHZRW = Syria (Syria Prōtē, Syria Deuteria, Syria Euphratēsia) (Todt and Vest, 2014
  Do we only want geo_source and geo_uri for Pleiades? Or do we have somewhere that we can get the Geo data for GEDSH or Syriac World maps?
  - Unclear if the record URI can be the source for the coordinates? (maybe could use this also in cases of @resp="syriaca"?)
  :)
  
  (: DESCRIPTION/ABSTRACT :)
  let $tsgAbstract := $place/desc[@type="abstract"][contains(@corresp, "http://syriaca.org/geo")]//text() => string-join(" ") => normalize-space()
  
  return
  <row>
    <id>{$id}</id>
    <title>{$enHeadword}</title>
    <title_source>{$title-source}</title_source>
    <fclasses>{$fclasses}</fclasses>
    <aat_types>{$aat_types}</aat_types>
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

return csv:serialize(<csv>{$rows}</csv>, map {"header": "yes"})