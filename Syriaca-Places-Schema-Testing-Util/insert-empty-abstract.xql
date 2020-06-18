xquery version "3.0";
import module namespace functx = "http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare option output:omit-xml-declaration "no";
declare option output "indent=no";


let $inputCollectionUri := "C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\places\tei\"
for $doc in collection($inputCollectionUri)
  where not($doc//listPlace/place/desc[@type="abstract"])
  let $docId := substring-after($doc//listPlace/place/idno[1]/text(), "/place/")
  let $newDesc := <desc type="abstract" xml:id="abstract{$docId}-1" xml:lang="en"/>
  return insert node $newDesc after $doc//listPlace/place/placeName[last()]