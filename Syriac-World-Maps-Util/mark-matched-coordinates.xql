xquery version "3.1";

let $xmlTreeUri := "C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Syriac-World-Maps-Util\placeTreeMaster.xml"
let $coordinatesXml := doc("C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Syriac-World-Maps-Util\SyriacWorldPreciseLocations.xml")
let $doc := doc($xmlTreeUri)

for $mark in $coordinatesXml/*:kml/*:Document/*:Folder/*:Placemark
  where not(empty($mark/*:matchUri))
  let $matchUri := $mark/*:matchUri/text()
  for $rec in $doc/*:list/*:record
    where empty($rec/*:Use_coordinates_from_Nov17Revised/*:label)
    return if($matchUri = $rec/*:Syriaca_URI/*:label/text()) then insert node <Use_coordinates_from_Nov17Revised><label>Y</label></Use_coordinates_from_Nov17Revised> into $rec