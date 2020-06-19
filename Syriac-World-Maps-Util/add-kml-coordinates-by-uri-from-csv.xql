xquery version "3.1";

let $xmlTreeUri := "C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Syriac-World-Maps-Util\placeTreeMaster.xml"
let $csvUri := "C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Syriac-World-Maps-Util\HelperSheet__FinalCoordinatesMatchedByHand.csv"
let $coordinatesXml := fetch:text($csvUri) => csv:parse(map{"header":fn:true()})
let $doc := doc($xmlTreeUri)

for $row in $coordinatesXml//*:record
  where ($row/*:URI/text() != "")
  let $matchUri := $row/*:URI/text()
  let $coordinateString := $row/*:ConcatenatedCoordinates/text()
  for $rec in $doc/*:list/*:record
    return if($matchUri = $rec/*:Syriaca_URI/*:label/text()) then 
      if(exists($rec/*:KML_LongLat_DD)) then insert node <label>{$coordinateString}</label> into $rec/*:KML_LongLat_DD
      else insert node <KML_LongLat_DD><label>{$coordinateString}</label></KML_LongLat_DD> into $rec