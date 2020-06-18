xquery version "3.0";
import module namespace functx = "http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare option output:omit-xml-declaration "no";
declare option output "indent=no";

(: 
This script fixes https://github.com/srophe/srophe-app-data/issues/766 by removing the tei:link elements connecting a tei:note of @type="deprecation" and adding an @target attribute to the corresponding tei:note.

@author: William L. Potter
@version 1.0
:)
let $inputCollectionUri := "C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\places\tei\"
for $doc in collection($inputCollectionUri)
  where $doc//listPlace/place/note[@type="deprecation"]
  let $newDeprecationNotes := for $depNote in $doc//listPlace/place/note[@type="deprecation"]
    let $deprecationId := string($depNote/@xml:id)
    let $nameTargets := for $link in $doc//listPlace/place/link
      let $targetFull := string($link/@target)
      let $targetSeq := tokenize($targetFull, " ")
      let $nameTarget := $targetSeq[1]
      let $idTarget := substring-after($targetSeq[2], "#")
      return if ($idTarget = $deprecationId) then $nameTarget else ()
    let $newDeprecationNote := functx:add-attributes($depNote, QName("","target"), string-join($nameTargets, " "))
    return $newDeprecationNote
  return (delete node $doc//listPlace/place/note[@type="deprecation"],
  delete node $doc//listPlace/place/link,
  insert node $newDeprecationNotes before $doc//listPlace/place/idno[1])
 