xquery version "3.0";
import module namespace functx = "http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare option output:omit-xml-declaration "no";
declare option output "indent=no";


let $inputCollectionUri := "C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\places\tei\"
for $doc in collection($inputCollectionUri)
  let $oldType := string($doc//listPlace/place/@type)
  let $newType := lower-case($oldType)
  let $newPlace := functx:update-attributes($doc//listPlace/place, QName('', 'type'), $newType)
  return replace node $doc//listPlace/place with $newPlace