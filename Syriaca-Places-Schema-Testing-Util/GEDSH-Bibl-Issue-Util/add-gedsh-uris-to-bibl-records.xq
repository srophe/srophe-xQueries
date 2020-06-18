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

let $collectionUri := "C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\bibl\tei\"
let $changeLog := <change who="http://syriaca.org/documentation/editors.xml#wpotter" when="{fn:current-date()}">ADDED: e-GEDSH article URI.</change>

for $rec in $csvIn//*:record
  let $biblUri := fn:normalize-space($rec/*:syriaca-bibl-uri)
  let $gedshUri := fn:normalize-space($rec/*:gedsh-uri)
  let $gedshNum := fn:normalize-space($rec/*:gedsh-entry-num)
  for $doc in fn:collection($collectionUri)
    where $biblUri = fn:substring-before($doc//TEI/teiHeader/fileDesc/publicationStmt/idno/text(), "/tei")
    return (insert node <ref target="{$gedshUri}"/> as last into $doc/TEI/text/body/biblStruct/analytic,
      insert node $changeLog as first into $doc/TEI/teiHeader/revisionDesc)