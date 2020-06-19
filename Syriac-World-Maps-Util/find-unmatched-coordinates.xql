xquery version "3.1";

let $xmlTreeUri := "C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Syriac-World-Maps-Util\placeTreeMaster.xml"
let $coordinatesXml := doc("C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Syriac-World-Maps-Util\SyriacWorldPreciseLocations.xml")
let $doc := doc($xmlTreeUri)
for $rec in $doc/*:list/*:record
  where empty($rec/*:KML_LongLat_DD)
  let $placeNames := for $name in $rec/*:Label/*:label
    return $name/text()
  let $placeNamesString := string-join($placeNames, "#")
  return $rec/*:Syriaca_URI/*:label/text()||","||$placeNamesString
  