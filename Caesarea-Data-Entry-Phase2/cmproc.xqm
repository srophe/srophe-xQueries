xquery version "3.1";

(:
: Module Name: Caesarea-Maritima.org Testimonia Postprocessor
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 08 April 2014
: Module Overview: This module contains functions for post-processing newly
:                  created records for Caesarea-Maritima.org's Testimonia
:                  database.
:)

(:~ 
: This module provides the functions that generate a CSV report of tagged entities
: (authors, works, persons, places, and bibliography) in a database of manuscript
: catalogue entries.
:
: @author William L. Potter
: @version 1.0
:)
module namespace cmproc="http://wlpotter.github.io/ns/cmproc";
import module namespace config="http://wlpotter.github.io/ns/cm/config" at "config.xqm";
import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";


declare %updating function cmproc:post-process-testimonia-record($record as node())
{
  let $recordId := $record//publicationStmt/idno/text()
  let $recUri := $config:testimonia-uri-base||$recordId
  let $outputFilePath := $config:output-directory||$recordId||".xml"
  return 
  try {
    (cmproc:update-new-testimonia-record($record, $recUri, $outputFilePath), update:output(cmproc:log-success($record, $outputFilePath)))
  }
  catch * {
    let $failure :=
      element {"failure"} {
        element {"code"} {$err:code},
        element {"description"} {$err:description},
        element {"value"} {$err:value},
        element {"module"} {$err:module},
        element {"location"} {$err:line-number||": "||$err:column-number},
        element {"additional"} {$err:additional},
        cmproc:get-record-context($record, "Failure: file not written to disk")
      }
    return update:output($failure)
  }
};

declare function cmproc:log-success($record as node(), $outputFilePath as xs:string)
as node()
{
  element {"success"} {cmproc:get-record-context($record, $outputFilePath)}
};

declare function cmproc:get-record-context($record as node(), $outputFilePath as xs:string)
as node()
{
  let $inputFileLocation := document-uri($record)
  return element {"nodeContext"}
    {
      element {"inputFileLocation"} {$inputFileLocation},
      element {"outputFileLocation"} {$outputFilePath}
    }
};

declare %updating function cmproc:update-new-testimonia-record($record as node(), $recUri as xs:string, $outputFilePath as xs:string)
{
  (cmproc:update-record-title($record),
   cmproc:update-editors-list($record),
   cmproc:update-respStmt-list($record),
   replace value of node $record//publicationStmt/idno with $recUri||"/tei",
   replace value of node $record//publicationStmt/date with current-date(),
   cmproc:update-historical-era-taxonomy($record),
   cmproc:update-creation($record, $recUri),
   cmproc:update-langUsage-language($record),
   cmproc:update-record-urn($record),
   replace value of node $record//body/ab[@type="identifier"]/idno with $recUri,
   cmproc:update-abstract($record, $recUri, false()),
   cmproc:update-edition($record, $recUri),
   cmproc:update-translation($record, $recUri),
   cmproc:update-bibls($record, $recUri),
   cmproc:update-related-subject-notes($record),
   if(not($record//body/desc[@type="context"]/text())) then delete node $record//body/desc[@type="context"] else(),
    delete node $record//comment(),
    put($record, $outputFilePath, map{'omit-xml-declaration': 'no'})
  )
};

(: Create and update record's a-level title :)
declare %updating function cmproc:update-record-title($record as node())
{
  insert node cmproc:create-record-title($record) before $record//titleStmt/title
};

declare function cmproc:create-record-title($record as node())
as node()
{
  let $author := $record/TEI/teiHeader/profileDesc/creation/persName/text()
  let $workTitle := $record/TEI/teiHeader/profileDesc/creation/title/text()
  let $range := $record/TEI/teiHeader/profileDesc/creation/ref/text()
  let $recTitle := element {"title"} 
    {
      attribute {"xml:lang"} {"en"},
      attribute {"level"} {"a"},
      $author, ", ",
      element {"title"} {attribute {"level"} {"m"}, $workTitle}, " ",
      $range}
  return $recTitle
};

declare %updating function cmproc:update-editors-list($record as node())
{
  (delete nodes $record//titleStmt/editor,
  insert nodes cmproc:create-editors-list($record) after $record//titleStmt/principal)
};


declare function cmproc:create-editors-list($record as node()) {
  let $newEditors := cmproc:create-new-editors-list($record)
  let $editors := ($record//titleStmt/editor, $newEditors)
  return functx:distinct-deep($editors)
};

declare function cmproc:create-new-editors-list($record as node())
as node()*
{
  let $role := attribute {"role"} {"creator"}
  for $editor in $record//revisionDesc/change/@who/string()
    return cmproc:editor-id-lookup($editor, "editor", $role)
};


declare %updating function cmproc:update-respStmt-list($record as node())
{
  (delete nodes $record//titleStmt/respStmt,
  insert nodes cmproc:create-respStmt-list($record) as last into $record//titleStmt
)
};

declare function cmproc:create-respStmt-list($record as node())
as node()*
{
  let $newRespStmts := cmproc:create-new-respStmt-list($record)
  return functx:distinct-deep(($newRespStmts, $record//titleStmt/respStmt))
};

declare function cmproc:create-new-respStmt-list($record as node()) 
as node()*
{
  let $creatorRespStmt := cmproc:create-respStmt($record//revisionDesc/change[2]/@who/string(), $config:resp-string-for-creator)
  let $metadataRespStmt := cmproc:create-respStmt($record//revisionDesc/change[1]/@who/string(), $config:resp-string-for-metadata)
  let $teiRespStmt := cmproc:create-respStmt($config:editor-id-for-tei, $config:resp-string-for-tei)
 
  return ($teiRespStmt, $metadataRespStmt, $creatorRespStmt)
};

declare function cmproc:create-respStmt($editorId as xs:string, $respString as xs:string)
as node()
{
  let $name := cmproc:editor-id-lookup($editorId, "name", ())
  return element {"respStmt"} {
    element {"resp"} {$respString},
    $name
  }
};

declare function cmproc:editor-id-lookup($editorId as xs:string, $elementName as xs:string, $attributes as attribute()*)
as node()
{
  let $editor := $config:editors-doc/TEI/text/body/listPerson/person[@xml:id = $editorId]
  let $editorNameString := $editor//text()
  let $editorNameString := string-join($editorNameString, " ")
  let $editorNameString := normalize-space($editorNameString)
  return element {$elementName} {
    $attributes,
    attribute {"ref"} {$config:editor-uri-base||$editorId},
    $editorNameString
  }
};

(:
- update-historical-era-taxonomy
  - replace if it's there; otherwise insert as first into //classDecl
- create-historical-era-taxonomy-node
  - desc should come from config
  - the categories should be constructed from the taxonomy doc
:)
declare %updating function cmproc:update-historical-era-taxonomy($record as node())
{
  let $taxonomy := cmproc:create-historical-era-taxonomy()
  return 
    if($record//classDecl/taxonomy[@xml:id = "CM-NEAEH"]) then
      replace node $record//classDecl/taxonomy[@xml:id = "CM-NEAEH"] with $taxonomy
    else 
      insert node $taxonomy as first into $record//classDecl
};

declare function cmproc:create-historical-era-taxonomy()
as node()
{
  let $categories :=
    for $cat in $config:period-taxonomy-doc//*:record
    let $id := $cat/*:catId/text()
    let $desc := $cat/*:catDesc/text()||", "||$cat/*:dateRangeLabel/text()
    return element {"category"} {
      attribute {"xml:id"} {$id},
      element {"catDesc"} {$desc}
    }
  return element {"taxonomy"}
  {
    attribute {"xml:id"} {$config:period-taxonomy-id},
    $config:period-taxonomy-description,
    $categories
  }
};

declare %updating function cmproc:update-creation($record, $recUri) {
  replace node $record//profileDesc/creation with cmproc:create-creation($record, $recUri)
};

declare function cmproc:create-creation($record as node(), $recUri as xs:string) 
as node()
{
  let $creation := $record//profileDesc/creation
  let $recId := functx:substring-after-if-contains($recUri, $config:testimonia-uri-base)
  let $title := if($creation/title/text() = "") then element {"title"} {$creation/title/@*, "[Untitled]"} else $creation/title
  let $ref := element {"ref"} {attribute {"target"} {"#bib"||$recId||"-1"}, $creation/ref/text()}
  let $origDate := cmproc:post-process-origDate($creation/origDate)
  return element {"creation"} {
    "This entry is taken from ",
    $title, " ", $ref,
    " written by ", $creation/persName,
    " in ",
    $origDate,
    ". This work was likely written in ",
    $creation/origPlace, "."
  }
};

declare function cmproc:post-process-origDate($origDate as node()) 
as node() {
  let $origDateText := normalize-space(string-join($origDate/text()))
  let $lowDate := functx:substring-before-if-contains($origDateText, " ")
  let $highDate := substring-after($origDateText, " ")
  let $dateString := cmproc:create-date-string($lowDate, $highDate)
  let $lowDateInt := xs:integer($lowDate)
  let $highDateInt := if($highDate != "") then xs:integer($highDate) else ()
  let $periodAttribute := cmproc:create-period-attribute-from-dates($lowDateInt, $highDateInt)
  return element {"origDate"} {
    attribute {"notBefore"} {$lowDate},
    attribute {"notAfter"} {$highDate},
    $periodAttribute,
  $dateString}
};

declare function cmproc:create-date-string($low, $high){
  let $lowEra := if (starts-with($low, "-")) then "BCE" else "CE"
  let $highEra := if (starts-with($high, "-")) then "BCE" else "CE"
  return if ($high = "") then
    if (starts-with($low, "-")) then string(number(substring-after($low, "-")))||" BCE" else string(number($low))||" CE"
  else if ($lowEra = $highEra) then string(number(functx:substring-after-if-contains($low, "-")))||"-"||string(number(functx:substring-after-if-contains($high, "-")))||" "||$lowEra
  else string(number(substring-after($low, "-")))||" BCE-"||string(number($high))||" CE"
};

declare function cmproc:create-period-attribute-from-dates($lowDate as xs:integer, $highDate as xs:integer?)
as attribute()
{
  let $period := if($highDate) then 
    cmproc:lookup-period-range($lowDate, $highDate)
    else cmproc:lookup-period-single-date($lowDate)
  let $period := distinct-values($period)
  let $period := 
    for $p in $period
    where $p != "#"
    return $p
  return attribute {"period"} {string-join($period, " ")}
};

declare function cmproc:lookup-period-range($lowDate as xs:integer, $highDate as xs:integer) as xs:string* {
  (: returns a period if the low or high date falls within it; and if the period falls within the low-high range :)
  (: returns a distinct value set, excluding "#", which would be returned if no matching period were found :)
  let $lowPeriod := cmproc:lookup-period-single-date($lowDate)
  let $highPeriod := cmproc:lookup-period-single-date($highDate)
  let $rangePeriod :=
    for $pd in $config:period-taxonomy-doc//*:record
    where $lowDate <= $pd/*:notBefore/text() and $highDate >= $pd/*:notAfter/text()
    return "#"||$pd/*:catId/text()
  let $period := ($lowPeriod, $highPeriod, $rangePeriod)
  let $period := distinct-values($period)
  for $p in $period
    where $p != "#"
    return $p
};
declare function cmproc:lookup-period-single-date($date as xs:integer) as xs:string* {
  for $pd in $config:period-taxonomy-doc//*:record
  where $date >= xs:integer($pd/*:notBefore/text()) and $date <= xs:integer($pd/*:notAfter/text())
  return "#"||$pd/*:catId/text()
};

declare %updating function cmproc:update-langUsage-language($record as node())
{
  replace node $record/TEI/teiHeader/profileDesc/langUsage with cmproc:post-process-langUsage($record//profileDesc/langUsage)
};

declare function cmproc:post-process-langUsage($langUsage as node())
as node()
{
  let $languages :=
    for $lang in $langUsage/language
    let $langCode := $lang/@ident/string()
    let $langString := 
     switch ($langCode) 
     case "ar" return "Arabic"
     case "cop" return "Coptic"
     case "fro" return "Old French"
     case "gez" return "Geʿez"
     case "grc" return "Ancient Greek"
     case "he" return "Hebrew"
     case "hy" return "Armenian"
     case "jpa" return "Jewish Palestinian Aramaic"
     case "la" return "Latin"
     case "pro" return "Old Provençal"
     case "syr" return "Syriac"
     case "tmr" return "Jewish Babylonian Aramaic"
     case "xno" return "Anglo-Norman French"   
     default return ""
    return element {name($lang)} {$lang/@*, $langString}
  return element {name($langUsage)} {$languages}
};

declare %updating function cmproc:update-record-urn($record as node())
{
  replace value of node $record//profileDesc/textClass/classCode/idno with cmproc:create-record-urn($record)
};

declare function cmproc:create-record-urn($record as node())
as xs:string?
{
  if(string($record//profileDesc/creation/title/@ref) != "") then string($record//profileDesc/creation/title/@ref)||":"||$record//profileDesc/creation/ref/text() else()
};

declare %updating function cmproc:update-abstract($record as node(), $recUri as xs:string, $isCreationProcessed as xs:boolean)
{
  let $recId := functx:substring-after-if-contains($recUri, $config:testimonia-uri-base)
  (: allows selecting if this is run to update an abstract or create while post-processing :)
  let $creation := if($isCreationProcessed) then $record//profileDesc/creation else cmproc:create-creation($record, $recUri)
  let $recordType := $record//profileDesc/textClass/catRef[@scheme = "#CM-Testimonia-Type"]/@target/string()
  let $abstract := cmproc:create-abstract($creation, $record//body/ab/placeName, $recordType, $recId)
  return
  if($record//body/desc[@type="abstract"]) then
  replace node $record//body/desc[@type="abstract"] with $abstract
  else insert node $abstract after $record//body/ab[@type="identifier"]
};

declare function cmproc:create-abstract($creation as node(), $placeNameSeq as node()*, $recType as xs:string, $recId as xs:string) {
  let $preamble := if($recType = "#direct" or $recType = "") then
    cmproc:create-abstract-preamble-from-place-name-sequence($placeNameSeq)
    (: note that this will raise an error if $placeNameSeq is empty. This is the preferred functionality to catch records that are marked with "#direct" but are missing tagged place names :)
    else "Caesarea Maritima is indirectly"
    
  return element {"desc"}
  {
    attribute {"type"} {"abstract"},
    attribute {"xml:id"} {"abstract"||$recId||"-1"},
    $preamble,
    "attested at ",
    $creation/persName, ", ",
    $creation/title, " ", $creation/ref,
    ". This passage was written ca. ",
    $creation/origDate, " possibly in ",
    $creation/origPlace, "."
  }
};

declare function cmproc:create-abstract-preamble-from-place-name-sequence($placeNameSeq as node()+)
as item()+
{
  let $placeNamesDistinct := functx:distinct-deep($placeNameSeq)
  let $isOrAre := if(count($placeNamesDistinct) >  1) then " are" else " is"
  let $quotes :=
    for $name at $i in $placeNamesDistinct
    return if ($i < count($placeNamesDistinct) - 1) then (element {"quote"} {$name}, ", ")
    else if ($i = count($placeNamesDistinct) - 1) then (element {"quote"} {$name}, ",")
    else ("and ", element {"quote"} {$name})
  return ($quotes, $isOrAre, "directly")
};

declare %updating function cmproc:update-edition($record as node(), $recUri as xs:string)
{
  let $workLangCode := if($record//profileDesc/langUsage/language[@ana="#caesarea-language-of-testimonia"]) 
    then $record//profileDesc/langUsage/language[@ana="#caesarea-language-of-testimonia"]/@ident/string()
    else $record//profileDesc/langUsage/language[1]/@ident/string()
  let $recId := functx:substring-after-if-contains($recUri, $config:testimonia-uri-base)
  let $edition := cmproc:post-process-excerpt($record//body/ab[@type="edition"], $workLangCode, $recId, $workLangCode)
  let $edition := cmproc:add-source-ab-to-excerpt($edition, $recId, "1")
  let $edition := cmproc:add-xml-lang-tags-to-excerpt-notes($edition)
  return replace node $record//body/ab[@type="edition"] with $edition
};

declare %updating function cmproc:update-translation($record as node(), $recUri as xs:string)
{
  let $workLangCode := if($record//profileDesc/langUsage/language[@ana="#caesarea-language-of-testimonia"]) 
      then $record//profileDesc/langUsage/language[@ana="#caesarea-language-of-testimonia"]/@ident/string()
      else $record//profileDesc/langUsage/language[1]/@ident/string()
  let $recId := functx:substring-after-if-contains($recUri, $config:testimonia-uri-base)
  let $translation := cmproc:post-process-excerpt($record//body/ab[@type="translation"], "en", $recId, $workLangCode)
  let $translation := if($record//body/listBibl[1]/bibl[2]/ptr/@target !="") then (: source the translation to the second works cited bibl if it has a non-empty pointer :)
    cmproc:add-source-ab-to-excerpt($translation, $recId, "2")
    else $translation
  let $translation := cmproc:add-xml-lang-tags-to-excerpt-notes($translation)
  return replace node $record//body/ab[@type="translation"] with $translation
};

declare function cmproc:post-process-excerpt($excerpt as node(), $excerptLangCode as xs:string, $docId as xs:string, $docLangCode as xs:string) as node() {
  let $quoteSeq := if(string($excerpt/@type) = "edition") then "1" else "2"
  let $correspLangCode := if($excerptLangCode = "en") then $docLangCode else "en"
  let $anchor := <anchor xml:id="testimonia-{$docId}.{$excerptLangCode}.1" corresp="#testimonia-{$docId}.{$correspLangCode}.1"/>
  let $nonEmptyChildNodes := 
    for $node in $excerpt/child::node()
    return 
    if($node instance of element()) then 
      if (name($node) = "note" and empty($node/text())) then () (: do not return empty note elements :)
      else if(name($node) = "anchor") then () (: avoid reduplicating existing anchor elements :)
      else $node
    else $node
  let $nonEmptyChildNodes := cmproc:replace-pipe-with-lb-element($nonEmptyChildNodes)
  return element ab {$excerpt/@type, attribute xml:lang {$excerptLangCode}, attribute xml:id {"quote"||$docId||"-"||$quoteSeq}, $anchor, $nonEmptyChildNodes}
};

declare function cmproc:replace-pipe-with-lb-element($items as item()+)
as item()+
{
  for $node in $items
  (: if $node is a string and contains the pattern " | ", we need to replace this pipe with a <lb/> element :)
  return if($node instance of text() and contains($node, " | ")) then
    let $pieces := tokenize($node, " \| ")
    (: interweave a <lb/> element between each section divided by the presence of the " \| " regex pattern :)
    for $piece at $i in $pieces
    return if($i < count($pieces)) then ($piece, element {"lb"}{}) else $piece
  else $node
};

declare function cmproc:add-source-ab-to-excerpt($excerpt as node(), $recId as xs:string, $biblNum as xs:string)
as node()
{
  let $sourceAb := 
    element {"ab"} {
      attribute {"type"} {"source"}, 
      attribute {"source"} {"#bib"||$recId||"-"||$biblNum}}
  return 
    element {name($excerpt)} 
      {
         $excerpt/@*, 
         $excerpt/child::node()[not(name() = "idno" or name() = "ref" or name() = "note" or name() = "ab")],
         $sourceAb,
         $excerpt/idno,
         $excerpt/ref,
         $excerpt/note
     }
};

declare function cmproc:add-xml-lang-tags-to-excerpt-notes($excerpt as node())
as node()
{
  let $updatedChildren :=
    for $node in $excerpt/child::node()
      return if(name($node) = "note" and not($node/@xml:lang)) then  element {name($node)} {attribute {"xml:lang"} {"en"}, $node/@*, $node/text()}(: add xml:lang tags to notes that don't have them :)
      else $node
  return element {name($excerpt)} {$excerpt/@*, $updatedChildren}
};

declare %updating function cmproc:update-bibls($record as node(), $recUri as xs:string)
{
  let $recId := functx:substring-after-if-contains($recUri, $config:testimonia-uri-base)
  let $worksCited := cmproc:post-process-bibls($record//body/listBibl[head/text() = $config:works-cited-listBibl-label], $recId, true ())
  let $additionalBibls := cmproc:post-process-bibls($record//body/listBibl[head/text() = $config:additional-bibls-listBibl-label], $recId, false ())
  return (
    replace node $record//body/listBibl[head/text() = $config:works-cited-listBibl-label] with $worksCited,
    replace node $record//body/listBibl[head/text() = $config:additional-bibls-listBibl-label] with $additionalBibls
  )
};

declare function cmproc:post-process-bibls($listBibl as node(), $docId as xs:string, $isWorksCited as xs:boolean)
as node()?
{
  let $bibls := for $bibl at $i in $listBibl/bibl
    where string($bibl/ptr/@target) !="" (: only return bibls that have an assigned ptr :)
    let $ptrUri := $bibl/ptr/@target/string()
    let $ptrUri := if(contains($ptrUri, "zotero"))
      then let $ptrUri := functx:substring-after-if-contains($ptrUri, "/items/")
      return functx:substring-before-if-contains($ptrUri, "/")
    else $ptrUri
    let $ptrUri := if(contains($ptrUri, $config:bibl-uri-base)) then $ptrUri else $config:bibl-uri-base||$ptrUri
    let $ptr := element {"ptr"} {attribute {"target"} {$ptrUri}}
    let $nonEmptyCitedRanges := 
      for $citedRange in $bibl/citedRange
      where $citedRange/text()
      return $citedRange
    let $biblId := if ($isWorksCited) then attribute xml:id {"bib"||$docId||"-"||$i} else ()
    return element {"bibl"} {$biblId, $ptr, $nonEmptyCitedRanges}
  return if(count($bibls) > 0) then element {"listBibl"} {$listBibl/head, $bibls} else () (: only return a listBibl if there are non-empty bibls :)
};

(:
Fixes https://github.com/srophe/caesarea-data/issues/108 for new data.
Will be deprecated once https://github.com/srophe/caesarea-data/issues/103 is implemented
:)
declare %updating function cmproc:update-related-subject-notes($record as node())
{
  (delete node $record//body/note,
  insert node cmproc:normalize-related-subjects-notes($record) as last into $record//body)
};

declare function cmproc:normalize-related-subjects-notes($record as node())
as node()+
{
  for $note in $record//text/body/note
  let $relatedSubjects :=
    (
    $note/p/text(),
    $note/p/list/item/p/text(),
    $note/list/item/text(),
    $note/p/list/item/text(),
    $note/list/item/list/item/text(),
    $note/list/item/p/text(),
    $note/p/hi/text(),
    $note/p/hi/hi/text(),
    $note/hi/text(),
    $note/text()
    )
  return element {node-name($note)} {$note/@*,
    for $subject in $relatedSubjects
    where normalize-space($subject) != ""
    order by $subject
    return element {QName("http://www.tei-c.org/ns/1.0", "p")} {normalize-space($subject)}
  }
};
