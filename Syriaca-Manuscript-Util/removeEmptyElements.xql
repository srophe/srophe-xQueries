xquery version "3.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare default element namespace "http://www.tei-c.org/ns/1.0";

declare function local:remove-empty-elements($element as element()) as element()? {
if ($element/* or matches(string-join($element/text(), ""), "\S+") or $element/@*)
 then 
 element {node-name($element)}
 {$element/@*,
 for $child in $element/node()
 return
 if ($child instance of element())
 then local:remove-empty-elements($child)
 else $child
 }
 else ()
};

declare function local:remove-empty-with-attributes($element as element()) as element()? {
  (:for instance, the above function leaves <quote xml:lang="syr"/>:)
  if ($element/* or matches(string-join($element/text(), ""), "\S+") or $element/@*[local-name() != "lang"])
 then 
 element {node-name($element)}
 {$element/@*,
 for $child in $element/node()
 return
 if ($child instance of element())
 then local:remove-empty-with-attributes($child)
 else $child
 }
 else ()
};

declare function local:remove-empty-attributes($element as element()) as element() { element { node-name($element)} { $element/@*[string(.)], for $child in $element/node( ) return if ($child instance of element()) then local:remove-empty-attributes($child) else $child } };

let $editor := "srophe-util"
let $changeLog := "CHANGED: deleted empty elements and attributes"
let $change := <change xmlns="http://www.tei-c.org/ns/1.0" who="http://syriaca.org/documentation/editors.xml#{$editor}" when="{fn:current-date()}">{$changeLog}</change>
let $inputDirectory := "C:/Users/anoni/Documents/GitHub/srophe/wright-catalogue/data/4_to_be_checked/postProcessingOutputs/"
(: let $doc := fn:doc(fn:concat($inputDirectory, "49.xml")) :)
for $doc in fn:collection($inputDirectory)
  where not($doc//msPart) and count($doc//revisionDesc/change[@who="http://syriaca.org/documentation/editors.xml#srophe-util"]) < 2
  let $msContentsNoEmptyAttributes := local:remove-empty-attributes($doc//msContents)
  let $msContentsRemovedEmpty := local:remove-empty-elements($msContentsNoEmptyAttributes)
  let $msContentsUpdated := local:remove-empty-with-attributes($msContentsRemovedEmpty)
  
  let $textLang := $doc//msContents/textLang
  let $revisedMsContents := <msContents xmlns="http://www.tei-c.org/ns/1.0">
  {
    $textLang,
    for $el in $msContentsUpdated/msItem
      (: for $subEl in $el/*
        return if ($subEl/text() or $subEl/* or $subEl/@*[local-name() != 'lang']) then $subEl else () :)
      return $el
  }
  </msContents>
  let $additionsUpdatedNoEmptyAttributes := local:remove-empty-attributes($doc//physDesc/additions)
  let $noEmptyAttributeOrigin := local:remove-empty-attributes($doc//msDesc/history/origin)
  return (replace node $doc//msContents with $revisedMsContents,
      replace node $doc//physDesc/additions with $additionsUpdatedNoEmptyAttributes,
      replace node $doc//msDesc/history/origin with $noEmptyAttributeOrigin,
      insert node $change before $doc//revisionDesc/change[1])