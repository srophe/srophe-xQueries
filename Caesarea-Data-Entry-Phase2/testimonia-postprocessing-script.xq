xquery version "3.0";

import module namespace cmproc="http://wlpotter.github.io/ns/cmproc" at "cmproc.xqm";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace csv = "http://basex.org/modules/csv";

(: GLOBAL PARAMETERS :)
(: Project Metadata :)
declare variable $local:project-uri-base := "https://caesarea-maritima.org/";

declare variable $local:editor-uri-base := "https://caesarea-maritima.org/documentation/editors.xml#";

(: Reference Documents :)

declare variable $local:editors-doc-uri := "https://raw.githubusercontent.com/srophe/caesarea/master/documentation/editors.xml";
declare variable $local:editors-doc := doc($local:editors-doc-uri);

declare variable $local:period-taxonomy-doc-uri := "https://raw.githubusercontent.com/srophe/caesarea/master/documentation/caesarea-maritima-historical-era-taxonomy.xml";
declare variable $local:period-taxonomy-doc := doc($local:period-taxonomy-doc-uri);

(: I/O Parameters :)
declare variable $local:input-directory := "/home/arren/Documents/GitHub/srophe-xQueries/Caesarea-Data-Entry-Phase2/test-in/";
declare variable $local:input-collection := collection($local:input-directory);

declare variable $local:output-directory := "/home/arren/Documents/GitHub/srophe-xQueries/Caesarea-Data-Entry-Phase2/test-out/";

(: START MAIN SCRIPT :)

(: initialize runtime :)
let $currentDate := fn:current-date()
let $nothing := file:create-dir($local:output-directory)

(: Main Loop through Folder of Records to Process :)
for $doc in $local:input-collection
  let $docId := $doc//publicationStmt/idno/text()
  let $docUri := $local:project-uri-base||"testimonia/"||$docId
  let $docTitle := <title xml:lang="en" level="a">{$doc/TEI/teiHeader/profileDesc/creation/persName/text()},&#x20;<title level="m">{$doc/TEI/teiHeader/profileDesc/creation/title/text()}</title>&#x20;{$doc//TEI/teiHeader/profileDesc/creation/ref/text()}</title>
  let $editors := cmproc:create-editor-elements($local:editors-doc, $doc//revisionDesc/change, $local:editor-uri-base)
  let $respStmts := cmproc:create-respStmts($local:editors-doc, $doc//revisionDesc/change, $local:editor-uri-base)
  let $newCreation := cmproc:create-creation($doc//creation, $docId, $local:period-taxonomy-doc)
  let $langString := cmproc:create-langString($doc//profileDesc/langUsage)
  let $docUrn := if(fn:string($doc//profileDesc/creation/title/@ref) != "") then fn:string($doc//profileDesc/creation/title/@ref)||":"||$doc//profileDesc/creation/ref/text() else()
  let $abstract := cmproc:create-abstract($newCreation, $doc//ab/placeName, fn:string($doc//catRef[@scheme="#CM-Testimonia-Type"]/@target), $docId)
  let $edition := cmproc:update-excerpt($doc//body/ab[@type="edition"], fn:string($doc//profileDesc/langUsage/language/@ident), $docId, fn:string($doc//profileDesc/langUsage/language/@ident))
  let $translation := cmproc:update-excerpt($doc//body/ab[@type="translation"], "en", $docId, fn:string($doc//profileDesc/langUsage/language/@ident))
  let $newWorksCited := cmproc:update-bibls($doc//listBibl[1], $docId, "yes", $local:project-uri-base)
  let $newAdditionalBibl := cmproc:update-bibls($doc//listBibl[2], $docId, "no", $local:project-uri-base)
  let $normalizedRelatedSubjectsNotes := cmproc:normalize-related-subjects-notes($doc)
  
  (:Updating Expressions:)
  return if($docId != "") then (
    insert node $docTitle before $doc//titleStmt/title,
    insert nodes $editors after $doc//titleStmt/editor[last()],
    insert nodes $respStmts before $doc//titleStmt/respStmt[1],
    replace value of node $doc//publicationStmt/idno with $docUri||"/tei",
    replace value of node $doc//publicationStmt/date with $currentDate,
    replace node $doc//profileDesc/creation with $newCreation,
    replace value of node $doc/TEI/teiHeader/profileDesc/langUsage/language with $langString,
    replace value of node $doc//profileDesc/textClass/classCode/idno with $docUrn,
    replace value of node $doc//body/ab[@type="identifier"]/idno with $docUri,
    replace node $doc//body/desc[@type="abstract"] with $abstract,
    replace node $doc//body/ab[@type="edition"] with $edition,
    replace node $doc//body/ab[@type="translation"] with $translation,
    replace node $doc//listBibl[1] with $newWorksCited,
    replace node $doc//listBibl[2] with $newAdditionalBibl,
    if(not($doc//body/desc[@type="context"]/text())) then delete node $doc//body/desc[@type="context"] else(),
    delete node $doc//comment(),
    delete node $doc//body/note,
    insert node $normalizedRelatedSubjectsNotes as last into $doc//body,
    fn:put($doc, fn:concat($local:output-directory, $docId, ".xml"), map{'omit-xml-declaration': 'no'})
) else ()