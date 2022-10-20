xquery version "3.0";

import module namespace cmproc="http://wlpotter.github.io/ns/cmproc" at "cmproc.xqm";
import module namespace config="http://wlpotter.github.io/ns/cm/config" at "config.xqm";
import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:edited-doc-collection :=
  let $collUri := "/home/arren/Documents/caesarea_edited-files_2022-10-19"
  return collection($collUri);
  
declare variable $local:editor-change-log :=
(: eventually move to config...:)
element {"change"} {attribute {"who"} {$config:editor-uri-base||"jrife"},
  attribute {"when"} {current-date()},
  "CHANGED: Proofreading and general edits"};

declare function local:update-edition($record as node(), $recUri as xs:string)
{
  let $workLangCode := $record//profileDesc/langUsage/language/@ident/string()
  let $recId := functx:substring-after-if-contains($recUri, $config:testimonia-uri-base)
  let $edition := cmproc:post-process-excerpt($record//body/ab[@type="edition"], $workLangCode, $recId, $workLangCode)
  let $edition := cmproc:add-source-ab-to-excerpt($edition, $recId, "1")
  let $edition := cmproc:add-xml-lang-tags-to-excerpt-notes($edition)
  return $edition
};

declare function local:update-translation($record as node(), $recUri as xs:string)
{
  let $workLangCode := $record//profileDesc/langUsage/language/@ident/string()
  let $recId := functx:substring-after-if-contains($recUri, $config:testimonia-uri-base)
  let $translation := cmproc:post-process-excerpt($record//body/ab[@type="translation"], "en", $recId, $workLangCode)
  let $translation := if($record//body/listBibl[1]/bibl[2]/ptr/@target !="") then (: source the translation to the second works cited bibl if it has a non-empty pointer :)
    cmproc:add-source-ab-to-excerpt($translation, $recId, "2")
    else $translation
  let $translation := cmproc:add-xml-lang-tags-to-excerpt-notes($translation)
  return $translation
};

for $editedDoc in $local:edited-doc-collection
let $uri := $editedDoc//ab[@type="identifier"]/idno/text()
let $matchingDoc := 
  for $doc in $config:input-collection
  return if($uri = $doc//ab[@type="identifier"]/idno/text()) then $doc else()

let $edition := local:update-edition($editedDoc, $uri)
let $translation := if($editedDoc//body/ab[@type="translation"]) then local:update-translation($editedDoc, $uri) else()

let $worksCited := $editedDoc//body/listBibl[head/text() = $config:works-cited-listBibl-label]
let $worksCited := cmproc:post-process-bibls($worksCited, substring-after($uri, $config:testimonia-uri-base), true ())

let $addBibls := $editedDoc//body/listBibl[head/text() = $config:additional-bibls-listBibl-label]
let $addBibls := if(not(empty($addBibls))) then cmproc:post-process-bibls($addBibls, substring-after($uri, $config:testimonia-uri-base), false ()) else()
let $relatedNotes := cmproc:normalize-related-subjects-notes($editedDoc)

return
try {
  
  if($matchingDoc) then
  (
  replace node $matchingDoc//titleStmt/title[@level="a"] with $editedDoc//titleStmt/title[@level="a"],
  replace node $matchingDoc//profileDesc/creation with $editedDoc//profileDesc/creation,
  replace node $matchingDoc//profileDesc/langUsage with $editedDoc//profileDesc/langUsage,
  replace node $matchingDoc//profileDesc/textClass with $editedDoc//profileDesc/textClass,
  insert node $local:editor-change-log as first into $matchingDoc//revisionDesc,
  if($matchingDoc//body/desc[@type="context"]) 
    then replace node $matchingDoc//body/desc[@type="context"] with $editedDoc//body/desc[@type="context"]
    else insert node $editedDoc//body/desc[@type="context"] before $matchingDoc//body/ab[@type="edition"],
  replace node $matchingDoc//body/ab[@type="edition"] with $edition,
  if($matchingDoc//body/ab[@type="translation"]) 
    then replace node $matchingDoc//body/ab[@type="translation"] with $translation
    else insert node $translation after $matchingDoc//body/ab[@type="edition"],
  replace node $matchingDoc//body/listBibl[head/text() = $config:works-cited-listBibl-label] with $worksCited,
  if($matchingDoc//listBibl[head/text() = $config:additional-bibls-listBibl-label]) then 
    replace node $matchingDoc//listBibl[head/text() = $config:additional-bibls-listBibl-label] with $addBibls
  else (),
  delete node $matchingDoc//body/note,
  insert node $relatedNotes as last into $matchingDoc//body
)
else ()}
catch *{
      let $failure :=
      element {"failure"} {
        element {"code"} {$err:code},
        element {"description"} {$err:description},
        element {"value"} {$err:value},
        element {"module"} {$err:module},
        element {"location"} {$err:line-number||": "||$err:column-number},
        element {"additional"} {$err:additional},
        cmproc:get-record-context($editedDoc, "Failure: file not written to disk")
      }
      return update:output($failure)
}

