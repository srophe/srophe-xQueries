xquery version "3.0";
import module namespace functx = "http://www.functx.com";
declare option output:omit-xml-declaration "no";

let $inFileUri := "C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Syriaca-Manuscript-Util\tokenization-project-util\wright-catalogue-html-NEW-manuscripts-chunked.xml"
let $doc := fn:doc($inFileUri)
let $newDoc := <doc>{
  for $div in $doc//*:div
  let $xmlId := fn:string($div/@xml:id)
  return <msDesc xml:id="{$xmlId}">{
    let $potentialNotes := for $p at $i in $div/*:p
      return if (fn:matches(fn:lower-case(fn:string-join($p//text(), "")), "vellum|paper")) then functx:path-to-node-with-pos($p)
    let $notePath := $potentialNotes[1]
    for $p at $i in $div/*:p
      let $newP := if (functx:path-to-node-with-pos($p) = $notePath) then functx:change-element-names-deep($p, QName("", "p"), QName("", "note"))
        else if (functx:path-to-node-with-pos($div/*:p[position() = $i + 1]) = $notePath or $i = fn:index-of($div/*:p, $div/*:p[last()])) then functx:change-element-names-deep($p, QName("", "p"), QName("", "msIdentifier"))
        else functx:change-element-names-deep($p, QName("", "p"), QName("", "msItem"))
    return $newP
  }
  </msDesc>
}
</doc>
return $newDoc