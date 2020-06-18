xquery version "3.0";
import module namespace functx = "http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare option output:omit-xml-declaration "no";
(:

@author: William L. Potter
@version: 1.0
:)

(: CSV to XML conversion :)
let $delimiter := ","
let $csvUri := "C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Syriaca-Places-Schema-Testing-Util\GEDSH-Bibl-Issue-Util\gedsh-bibl-subject-uri-associated.csv"
let $csvIn := csv:parse(file:read-text($csvUri), map{"header": "true", "separator": $delimiter, "quotes": "yes"})

let $collectionUri := "C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\persons\tei\"
for $doc in fn:collection($collectionUri)
  where $doc//listPerson/person/bibl[title[@level="a"]]/ptr[@target="http://syriaca.org/bibl/1"]
  let $footnote := $doc//listPerson/person/bibl[title[@level="a"]]/ptr[@target="http://syriaca.org/bibl/1"]/..
  let $footnoteId := string($footnote/@xml:id)
  let $articleNum := fn:substring-before($footnote/title[@level="a"]/text(), ".")
  let $newBiblUri := for $rec in $csvIn//*:record
    return if(fn:normalize-space($rec/*:gedsh-entry-number/text()) = $articleNum) then fn:normalize-space($rec/*:syriaca-bibl-uri/text())
  
  return replace node $doc//listPerson/person/bibl[@xml:id = $footnoteId]/ptr with <ptr target="{$newBiblUri}"/>