xquery version "3.0";
import module namespace functx = "http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare option output:omit-xml-declaration "no";
declare option output "indent=yes";

let $inputCollectionUri := "C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\places\tei\"
for $doc in collection($inputCollectionUri)
  where $doc//listPlace/relation or $doc//listPlace/listRelation
  let $existingListRelation := $doc//listPlace/listRelation
  let $notNestedRelations := $doc//listPlace/relation
  let $updatedListRelation := <listRelation>{$existingListRelation/relation, $notNestedRelations}</listRelation>
  return (delete node $doc//listPlace/relation, 
  if($doc//listPlace/listRelation) then replace node $doc//listPlace/listRelation with $updatedListRelation
  else insert node $updatedListRelation as last into $doc//listPlace)