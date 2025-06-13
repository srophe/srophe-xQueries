xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace srophe="https://srophe.app";

declare variable $path-to-syriaca-data := "/home/arren/Documents/GitHub/syriaca-data/";

declare variable $tsg-coll := collection($path-to-syriaca-data||"data/places/tei/");

declare variable $old-syriac-world := doc("/home/arren/Documents/GitHub/srophe-xQueries/Syriac-World-Maps-Util/xmlMasterTrees/oldRecordsMaster.xml");

declare variable $new-syriac-world := doc("/home/arren/Documents/GitHub/srophe-xQueries/Syriac-World-Maps-Util/xmlMasterTrees/newRecordsMaster.xml");

(:
splits each instance and swaps lat for long to match what TSG expects
:)
declare function local:process-syriac-world-gps($coordinates as xs:string*)
as xs:string
{
  let $processed :=
    for $coord in $coordinates
    where $coord != ""
    let $lat := tokenize($coord, ",")[1]
    let $long := tokenize($coord, ",")[2]
    return $long || " " || $lat
  return string-join($processed, " | ")
};

let $existingPlaces :=
  for $doc in $tsg-coll
  let $uri := $doc//publicationStmt/idno[@type="URI"]/text() => substring-before("/tei")
  let $headword := $doc//place/placeName[@srophe:tags = "#syriaca-headword"]//text() => string-join(" | ") => normalize-space()
  let $gps := $doc//place/location[@type="gps"]/geo/text() => string-join(" | ")

  let $syriacWorldRec := $old-syriac-world/*:list/*:record[*:Syriaca_URI/*:label/text() = substring-after($uri, "http://")]
  let $syriacWorldGps := local:process-syriac-world-gps($syriacWorldRec/*:KML_LongLat_DD/*:label/text())
  let $gps := 
    if ($gps = "") then $syriacWorldGps
    else if($syriacWorldGps != "") then string-join(($gps, $syriacWorldGps), " | ")
    else $gps
  
  return <row>
    <uri>{$uri}</uri>
    <headword>{$headword}</headword>
    <gps>{$gps}</gps>
  </row>
  
 
let $newPlaces :=
  for $rec in $new-syriac-world/*:list/*:record
  let $uri := "http://"||$rec/*:Syriaca_URI/*:label/text()
  let $headword := $rec/*:Syriaca_Headword/*:label/text() => string-join(" | ") => normalize-space()
  let $gps := local:process-syriac-world-gps($rec/*:KML_LongLat_DD/*:label/text())
  
  return <row>
    <uri>{$uri}</uri>
    <headword>{$headword}</headword>
    <gps>{$gps}</gps>
  </row>


return csv:serialize(<csv>{($existingPlaces, $newPlaces)}</csv>, map {"header": "yes"})