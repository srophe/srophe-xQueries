xquery version "3.0";
import module namespace functx = "http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare option output:omit-xml-declaration "no";
declare option output "indent=no";

let $inputCollectionUri := "C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\places\tei\"
for $doc in collection($inputCollectionUri)
  where $doc//listPlace/place/state[@type="existence" and not(@source)]
  let $newStates := for $state in $doc//listPlace/place/state[@type="existence"]
    return functx:add-attributes($state, QName("", "resp"), "http://syriaca.org")
  return (delete node $doc//listPlace/place/state[@type="existence" and not(@source)],
          if($doc//listPlace/place/event) then insert node $newStates after $doc//listPlace/place/event[last()] 
          else if($doc//listPlace/place/location) then insert node $newStates after $doc//listPlace/place/location[last()]
          else if($doc//listPlace/place/desc) then insert node $newStates after $doc//listPlace/place/desc[last()]
          else insert node $newStates after $doc//listPlace/place/placeName[last()])