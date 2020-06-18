xquery version "3.0";
import module namespace functx = "http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";


let $inputCollectionUri := "C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\places\tei\"
for $doc in collection($inputCollectionUri)
  let $uri := $doc//listPlace/place/idno[1]/text()
  let $namesWithApos := for $name in $doc//place/placeName
    return if (fn:starts-with($name/text(), "‘") and fn:ends-with($name/text(), "’")) then $name/text() else ()
  return if (empty($namesWithApos)) then () else $uri