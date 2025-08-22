xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare variable $cbss-uri-base := "http://syriaca.org/cbss/";

declare variable $path-to-json := "/home/arren/Documents/Work_Syriaca/cbss_data-dump_local_2025-08-20.json";

declare variable $json-data := json:doc($path-to-json);

let $items :=
  for $item in $json-data/*:json/*:items/*:_
  
  let $itemType := $item/*:itemType
  
  (: this isn't exact... :)
  let $aTitle := $item/*:title
  
  (: Caution: use of `otherwise` below is based on the draft XQuery 4.0 (ca. 2025-08-20) that are pre-implemented by BaseX :)
  let $language := $item/*:language otherwise <language></language>
  
  let $jTitle := $item/*:publicationTitle otherwise <publicationTitle></publicationTitle>
  let $mTitle := $item/*:bookTitle otherwise <bookTitle></bookTitle>
  
  let $zotUri := $item/*:uri
  
  let $itemKey := $item/*:itemKey
  
  let $cbssUri := <cbssUri>{$cbss-uri-base||$itemKey}</cbssUri>
  
  
  return <item>{
    $itemType,
    $aTitle,
    $language,
    $jTitle,
    $mTitle,
    $zotUri,
    $cbssUri,
    $itemKey
  }</item>
  
return <csv>{$items}</csv> => csv:serialize(map {"header": "yes"})