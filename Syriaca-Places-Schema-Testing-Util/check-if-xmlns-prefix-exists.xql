xquery version "3.0";
import module namespace functx = "http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";


let $inputCollectionUri := "C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\places\tei\"
for $doc in collection($inputCollectionUri)
  let $uri := $doc//listPlace/place/idno[1]/text()
  return if (empty(fn:namespace-uri-for-prefix("syriaca", $doc//TEI))) then $uri else () (: test if a namespace does NOT exist:)
  (: return if (not(empty(fn:namespace-uri-for-prefix("math", $doc//TEI)))) then $uri else () :) (: test if a namesapce DOES exist :)