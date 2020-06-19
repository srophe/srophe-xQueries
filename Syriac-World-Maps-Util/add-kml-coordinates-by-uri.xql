xquery version "3.1";

let $xmlTreeUri := "C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Syriac-World-Maps-Util\placeTreeMaster.xml"
let $coordinatesXml := doc("C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Syriac-World-Maps-Util\SyriacWorldPreciseLocations.xml")
let $doc := doc($xmlTreeUri)

for $mark in $coordinatesXml/*:kml/*:Document/*:Folder/*:Placemark
  where not(empty($mark/*:matchUri))
  let $matchUri := $mark/*:matchUri/text()
  let $coordinateString := substring-before($mark/*:Point/*:coordinates/text(), ",0")
  for $rec in $doc/*:list/*:record
    return if($matchUri = $rec/*:Syriaca_URI/*:label/text()) then insert node <KML_LongLat_DD><label>{$coordinateString}</label></KML_LongLat_DD> into $rec