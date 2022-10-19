xquery version "3.1";
import module namespace functx="http://www.functx.com";

import module namespace cmproc="http://wlpotter.github.io/ns/cmproc" at "cmproc.xqm";
import module namespace config="http://wlpotter.github.io/ns/cm/config" at "config.xqm";

declare default element namespace "http://www.tei-c.org/ns/1.0";


let $refDoc := file:read-text("/home/arren/Documents/GitHub/srophe-xQueries/Caesarea-Data-Entry-Phase2/missing-orig-dates-input.csv")
let $refDoc := csv:parse($refDoc, map{"header": "yes"})
for $row in $refDoc//*:record
let $uri := $row/*:Record_URI/text()
let $dateHumanReadable := $row/*:CreationDate/text()
let $notBefore := $row/*:notBefore/text()
let $notBefore := functx:pad-integer-to-length($notBefore, 4)
let $notAfter := $row/*:notAfter/text()
let $notAfter := functx:pad-integer-to-length($notAfter, 4)
let $when := $row/*:when/text()
let $when := if($when != "") then functx:pad-integer-to-length($when, 4) else ""
let $periodAttribute := if($when != "") 
  then cmproc:create-period-attribute-from-dates(xs:integer($when), ())
  else cmproc:create-period-attribute-from-dates(xs:integer($notBefore), xs:integer($notAfter))

let $origDate := if($when != "") then element {"origDate"} {
    attribute {"when"} {$when},
    $periodAttribute,
  $dateHumanReadable}
  else element {"origDate"} {
    attribute {"notBefore"} {$notBefore},
    attribute {"notAfter"} {$notAfter},
    $periodAttribute,
  $dateHumanReadable}
for $doc in $config:input-collection
where $uri = $doc//ab[@type="identifier"]/idno/text()
return (replace node $doc//creation/origDate with $origDate,
        replace node $doc//desc[@type="abstract"]/origDate with $origDate)