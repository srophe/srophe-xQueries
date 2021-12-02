xquery version "3.0";

(:
: Creates a CSV file that contains the Syriaca.org records for persons, places, 
: and works that lack both a CBSC idno **and** a CBSC bibl entry. Some of these
: may never require a CBSC keyword. But some may have one that is just unmatched.
: Last run on all data on 2021-12-02.
:
: @author William L. Potter
: @version 1.0
: @date 2021-12-02
:)
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace srophe="https://srophe.app";

import module namespace functx="http://www.functx.com";

let $personsColl := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\persons\tei\")
let $placesColl := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\places\tei\")
let $worksColl := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\works\tei\")

let $csvOptions := map{'header': true ()}

let $persons := 
  for $person in $personsColl
  let $recordUri := $person//text/body/listPerson/person/idno[1]/text()
  let $enHeadword := $person//titleStmt/title[@level="a"]/text()
  let $enHeadword := normalize-space(functx:substring-before-if-contains($enHeadword, " —"))
  
  let $cbscIdno := 
    for $idno in $person//text/body/listPerson/person/idno
    return if(contains($idno/text(), "csc.org.il")) then $idno/text()
  let $cbscIdno := string-join($cbscIdno, "|")
  
  let $cbscBibls := $person//text/body/listPerson/person/bibl[ptr/@target = "http://syriaca.org/bibl/5"]
  
  let $cbscBiblTargetAttributes := $cbscBibls/citedRange[@unit="entry"]/@target
  let $cbscBiblTarget := for $target in $cbscBiblTargetAttributes
    return string($target)
  let $cbscBiblTarget := string-join($cbscBiblTarget, "|")
  let $cbscBiblKeyword := $cbscBibls/citedRange[@unit="entry"]/text()
  let $cbscBiblKeyword := string-join($cbscBiblKeyword, "|")
  
  let $noCbscData := boolean(($cbscIdno || $cbscBiblTarget || $cbscBiblKeyword) = "")
  return if($noCbscData) then
  <record>
    <syriacaUri>{$recordUri}</syriacaUri>
    <syriacaEnglishHeadword>{$enHeadword}</syriacaEnglishHeadword>
    <category>person</category>
  </record>

let $places := 
  for $place in $placesColl
  let $recordUri := $place//text/body/listPlace/place/idno[1]/text()
  let $enHeadword := $place//titleStmt/title[@level="a"]/text()
  let $enHeadword := normalize-space(functx:substring-before-if-contains($enHeadword, " —"))
  
  let $cbscIdno := 
    for $idno in $place//text/body/listPlace/place/idno
    return if(contains($idno/text(), "csc.org.il")) then $idno/text()
  let $cbscIdno := string-join($cbscIdno, "|")
  
  let $cbscBibls := $place//text/body/listPlace/place/bibl[ptr/@target = "http://syriaca.org/bibl/5"]
  
  let $cbscBiblTargetAttributes := $cbscBibls/citedRange[@unit="entry"]/@target
  let $cbscBiblTarget := for $target in $cbscBiblTargetAttributes
    return string($target)
  let $cbscBiblTarget := string-join($cbscBiblTarget, "|")
  let $cbscBiblKeyword := $cbscBibls/citedRange[@unit="entry"]/text()
  let $cbscBiblKeyword := string-join($cbscBiblKeyword, "|")
  
  let $noCbscData := boolean(($cbscIdno || $cbscBiblTarget || $cbscBiblKeyword) = "")
  return if($noCbscData) then
  <record>
    <syriacaUri>{$recordUri}</syriacaUri>
    <syriacaEnglishHeadword>{$enHeadword}</syriacaEnglishHeadword>
    <category>place</category>
  </record>
  
  let $works := 
  for $work in $worksColl
  let $recordUri := $work//text/body/bibl/idno[1]/text()
  let $enHeadword := $work//titleStmt/title[@level="a"]/text()
  let $enHeadword := normalize-space(functx:substring-before-if-contains($enHeadword, " —"))
  
  let $cbscIdno := 
    for $idno in $work//text/body/bibl/idno
    return if(contains($idno/text(), "csc.org.il")) then $idno/text()
  let $cbscIdno := string-join($cbscIdno, "|")
  
  let $cbscBibls := $work//text/body/bibl/bibl[ptr/@target = "http://syriaca.org/bibl/5"]
  
  let $cbscBiblTargetAttributes := $cbscBibls/citedRange[@unit="entry"]/@target
  let $cbscBiblTarget := for $target in $cbscBiblTargetAttributes
    return string($target)
  let $cbscBiblTarget := string-join($cbscBiblTarget, "|")
  let $cbscBiblKeyword := $cbscBibls/citedRange[@unit="entry"]/text()
  let $cbscBiblKeyword := string-join($cbscBiblKeyword, "|")
  
  let $noCbscData := boolean(($cbscIdno || $cbscBiblTarget || $cbscBiblKeyword) = "")
  return if($noCbscData) then
  <record>
    <syriacaUri>{$recordUri}</syriacaUri>
    <syriacaEnglishHeadword>{$enHeadword}</syriacaEnglishHeadword>
    <category>work</category>
  </record>


let $xmlDoc := <csv>{$persons, $places, $works}</csv>
return csv:serialize($xmlDoc, $csvOptions)