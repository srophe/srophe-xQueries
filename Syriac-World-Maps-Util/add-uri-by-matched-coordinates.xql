xquery version "3.1";

let $xmlTreeUri := "C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Syriac-World-Maps-Util\placeTreeMaster.xml"
let $coordinatesXml := doc("C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Syriac-World-Maps-Util\SyriacWorldPreciseLocations.xml")
let $doc := doc($xmlTreeUri)
for $rec in $doc/*:list/*:record
  where not(empty($rec/*:Longitude_DD_from_Nov17Revised/*:label))
  let $testLong := $rec/*:Longitude_DD_from_Nov17Revised/*:label[1]/text()
  let $testLength := string-length($testLong)
  let $uri := $rec/*:Syriaca_URI/*:label/text()
  for $mark in $coordinatesXml/*:kml/*:Document/*:Folder/*:Placemark
    let $compareLong := substring($mark/*:Point/*:coordinates/text(), 1, $testLength)
    return if($testLong = $compareLong) then insert node <matchUri>{$uri}</matchUri> into $mark
    else ()

  