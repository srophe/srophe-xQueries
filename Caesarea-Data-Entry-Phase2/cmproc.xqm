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
  let $recordId := 
    if(contains($recordId, $config:testimonia-uri-base)) then (: handle cases where the full URI was already added :)
      substring-after(functx:substring-before-if-contains($recordId, "/tei"), $config:testimonia-uri-base) (: remove the '/tei' string from the pubstmt uri, and the uri base to provide a clean record ID:)
    else
      $recordId
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
  let $record-resp-data := cmproc:collate-record-resp-data($record)
  return
  (cmproc:update-record-title($record),
   cmproc:update-editors-list($record, $record-resp-data[?is-creator = true ()] ?editor-element),
   cmproc:update-respStmt-list($record, $record-resp-data, false ()),
   replace value of node $record//publicationStmt/idno with $recUri||"/tei",
   (: insert the current year as the copyright date into the licence text :)
   replace value of node $record//publicationStmt/availability/licence/p[1] with replace($record//publicationStmt/availability/licence/p[1]/text(), "DATE", substring(string(current-date()), 1, 4)),
   replace value of node $record//publicationStmt/date with current-date(),
   cmproc:update-historical-era-taxonomy($record),
   cmproc:update-creation($record, $recUri),
   cmproc:update-langUsage-language($record),
   cmproc:update-record-urn($record),
   cmproc:update-revisionDesc($record, $record-resp-data[?change-log-message != ""] ?change-element),
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

(:
: Using the data from the unprocessed $record, returns a map that combines
: $config:resp-stmt-data with the matching respStmts in record. 
: Matches resp-text to $record//respStmt/resp/text().
: The following keys-value pairs are added:
: "editor-id": $record//respStmt/name/@ref/string()
: "respStmt": cmproc:create-respStmt("editor-id", "resp-text")
: "editor-element": if "is-creator" then cmproc:editor-id-lookup("editor-id", "editor", "creator") else ()
: "change-element": if "change-log-message" then cmproc:create-change-element("change-log-message", $config:editor-uri-base||"editor-id", current-date())
:
: A map for each respStmt found in the record is returned
:)
declare function cmproc:collate-record-resp-data($record as node())
as item()*
{
  for $respStmt in $record//titleStmt/respStmt
  for $map in for-each(map:keys($config:resp-stmt-data), $config:resp-stmt-data)
  where $respStmt/resp/text() = $map("resp-text")
  let $editorId := $respStmt/name/@ref/string()
  let $respStmtFull := if($editorId != "") then cmproc:create-respStmt($editorId, $map("resp-text")) else()
  let $editorElement := if($map("is-creator") and $editorId != "") then cmproc:editor-id-lookup($editorId, "editor", attribute {"role"} {"creator"}) else ()
  let $changeElement := if(not(empty($map("change-log-message"))) and $editorId != "") then cmproc:create-change-element($map("change-log-message"), $config:editor-uri-base||$editorId, current-date()) else ()
  return
  map:merge((
  $map,
  map:entry("editor-id", $editorId),
  map:entry("respStmt", $respStmtFull),
  map:entry("editor-element", $editorElement),
  map:entry("change-element", $changeElement)
))
};

declare function cmproc:create-change-element($changeLogMessage as xs:string, $editorUri as xs:string, $timeStamp as xs:date)
as node()
{
  element {"change"} {
    attribute {"who"} {$editorUri},
    attribute {"when"} {$timeStamp},
    $changeLogMessage
  }
};
(: Create and update record's a-level title :)
declare %updating function cmproc:update-record-title($record as node())
{
  if($record//titleStmt/title[@level="a"]) then
    replace node $record//titleStmt/title[@level="a"] with cmproc:create-record-title($record)
  else
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

declare %updating function cmproc:update-editors-list($record as node(), $creatorEditors as node()*)
{
  (delete nodes $record//titleStmt/editor,
  insert nodes cmproc:create-editors-list($record, $creatorEditors) after $record//titleStmt/principal)
};


declare function cmproc:create-editors-list($record as node(), $creatorEditors as node()*) {
  (: revise to fix so JLR is last :)
  let $creatorEditors := functx:distinct-deep($creatorEditors)
  let $jlrEditor := $creatorEditors[contains(./@ref, "jrife")]
  let $creatorEditors := $creatorEditors[not(contains(./@ref, "jrife"))]
  let $editors := ($record//titleStmt/editor, $creatorEditors, $jlrEditor)
  return functx:distinct-deep($editors)
};


declare %updating function cmproc:update-respStmt-list($record as node(), $respStmtData as item()*, $includeExistingRespStmts as xs:boolean)
{
  (delete nodes $record//titleStmt/respStmt,
  insert nodes cmproc:create-respStmt-list($record,  $respStmtData, $includeExistingRespStmts) as last into $record//titleStmt
)
};

declare function cmproc:create-respStmt-list($record as node(), $respStmtData as item()*, $includeExistingRespStmts as xs:boolean)
as node()*
{
  let $newRespStmts := 
    for $stmt in $respStmtData
    order by $stmt("pos")
    return $stmt("respStmt")
  return if($includeExistingRespStmts) then functx:distinct-deep(($newRespStmts, $record//titleStmt/respStmt))
  else functx:distinct-deep($newRespStmts)
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
  (: low date will come either from the @when attribute or the @notBefore attribute. Will cause an error if both attributes are present :)
  let $lowDate := $origDate/@when|$origDate/@notBefore
  let $highDate := $origDate/@notAfter|$origDate/@when (: if there is just a @when attribute, both dates will be the same, which will not affect later functions. It should raise an error if there is both a @notAfter and @when attribute :)
  (: use the human readable date input by the editor, otherwise construct a date string from the normalized dates :)
  let $dateString := if($origDateText != "") then $origDateText else cmproc:create-date-string($lowDate/string(), $highDate/string())
  let $lowDateInt := xs:integer($lowDate/string())
  let $highDateInt := if($highDate != "") then xs:integer($highDate/string()) else ()
  let $periodAttribute := cmproc:create-period-attribute-from-dates($lowDateInt, $highDateInt)
  return element {"origDate"} {
    $origDate/@notBefore,
    $origDate/@notAfter,
    $origDate/@when,
    $periodAttribute,
  $dateString}
};

declare function cmproc:create-date-string($low, $high){
  let $lowEra := if (starts-with($low, "-")) then "BCE" else "CE"
  let $highEra := if (starts-with($high, "-")) then "BCE" else "CE"
  return if ($high = "" or $low = $high) then (: if there is no high date, or if the dates are the same :)
    if (starts-with($low, "-")) then string(number(substring-after($low, "-")))||" BCE" else string(number($low))||" CE"
  else if ($lowEra = $highEra) then string(number(functx:substring-after-if-contains($low, "-")))||"-"||string(number(functx:substring-after-if-contains($high, "-")))||" "||$lowEra
  else string(number(substring-after($low, "-")))||" BCE-"||string(number($high))||" CE"
};

declare function cmproc:create-period-attribute-from-dates($lowDate as xs:integer, $highDate as xs:integer?)
as attribute()
{
  let $period := if($highDate and $lowDate != $highDate) then 
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
    (: if the language of the original is not set, assume it to be the same as the testimonia :)
    let $lang := 
      if($lang/@ana = "#caesarea-language-of-original" and $lang/@ident = "") then
        element {name($lang)} {$lang/@ana, $langUsage/language[@ana="#caesarea-language-of-testimonia"]/@ident, $langUsage/language[@ana="#caesarea-language-of-testimonia"]/text()}
      else $lang
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

declare %updating function cmproc:update-revisionDesc($record as node(), $changeElements as node()*)
{
  let $changeElements := 
    for $change in $changeElements
    order by $change/@when descending
    return $change
  return insert node $changeElements as first into $record//revisionDesc
};

declare %updating function cmproc:update-abstract($record as node(), $recUri as xs:string, $isCreationProcessed as xs:boolean)
{
  let $recId := functx:substring-after-if-contains($recUri, $config:testimonia-uri-base)
  (: allows selecting if this is run to update an abstract or create while post-processing :)
  let $creation := if($isCreationProcessed) then $record//profileDesc/creation else cmproc:create-creation($record, $recUri)
  let $recordType := $record//profileDesc/textClass/catRef[@scheme = "#CM-Testimonia-Type"]/@target/string()
  let $abstract := cmproc:create-abstract($creation, $record//body/ab//placeName, $recordType, $recId)
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
  let $placeNameStrings := 
    for $name in $placeNameSeq
    let $nameString := $name//text()
    let $nameString := normalize-space(string-join($nameString, " "))
    let $nameString := if(contains($nameString, "|")) then replace($nameString, "\s*\|\s*", " ") else $nameString (: replaces pipe character with a single space :)
    return $nameString
  let $placeNamesDistinct := distinct-values($placeNameStrings)
  let $isOrAre := if(count($placeNamesDistinct) >  1) then " are" else " is"
  let $quotes :=
    for $name at $i in $placeNamesDistinct
    let $nameNormalizedSpace := element {QName("http://www.tei-c.org/ns/1.0", "placeName")} {$name}
    return if ($i < count($placeNamesDistinct) - 1) then (element {"quote"} {$nameNormalizedSpace}, ", ")
    else if ($i = count($placeNamesDistinct) - 1) then (element {"quote"} {$nameNormalizedSpace}, ",")
    else ("and ", element {"quote"} {$nameNormalizedSpace})
  return ($quotes, $isOrAre, "directly")
};

declare %updating function cmproc:update-edition($record as node(), $recUri as xs:string)
{
  let $edition := cmproc:create-edition($record, $recUri)
  return replace node $record//body/ab[@type="edition"] with $edition
};

declare function cmproc:create-edition($record as node(), $recUri as xs:string) as node()
{
  let $workLangCode := if($record//profileDesc/langUsage/language[@ana="#caesarea-language-of-testimonia"]) 
    then $record//profileDesc/langUsage/language[@ana="#caesarea-language-of-testimonia"]/@ident/string()
    else $record//profileDesc/langUsage/language[1]/@ident/string()
  let $recId := functx:substring-after-if-contains($recUri, $config:testimonia-uri-base)
  let $edition := cmproc:post-process-excerpt($record//body/ab[@type="edition"], $workLangCode, $recId, $workLangCode)
  let $edition := cmproc:add-source-ab-to-excerpt($edition, $recId, "1")
  let $edition := cmproc:add-xml-lang-tags-to-excerpt-notes($edition)
  return $edition
};

declare %updating function cmproc:update-translation($record as node(), $recUri as xs:string)
{
  let $translation := cmproc:create-translation($record, $recUri)
  return replace node $record//body/ab[@type="translation"] with $translation
};

declare function cmproc:create-translation($record as node(), $recUri as xs:string) as node()
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
  return $translation
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
  return if($node instance of text() and contains($node, "|")) then
    let $pieces := tokenize($node, "\s*\|\s*")
    for $piece at $i in $pieces
    (: this interweaves an <lb/> element between the tokenized string, but does not put an extra one at the end of the strings :)
    return if($i < count($pieces)) then ($piece, element {QName("http://www.tei-c.org/ns/1.0", "lb")}{}) else $piece
    (: if the node has any children, recursively replace pipes with lb elements :)
  else if($node/child::node()) then 
    element {node-name($node)} {$node/@*, cmproc:replace-pipe-with-lb-element($node/child::node())}
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
      return if(name($node) = "note" and not($node/@xml:lang)) then  element {name($node)} {attribute {"xml:lang"} {"en"}, $node/@*, $node/child::node()}(: add xml:lang tags to notes that don't have them :)
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
    let $ptrUri := cmproc:process-bibl-uri($bibl/ptr/@target/string()) (: processes the bibl URI into the c-m format; raises an error if item key cannot be found :)
    let $ptr := element {"ptr"} {attribute {"target"} {$ptrUri}}
    let $nonEmptyCitedRanges := 
      for $citedRange in $bibl/citedRange
      where $citedRange/text()
      return $citedRange
    let $biblId := if ($isWorksCited) then attribute xml:id {"bib"||$docId||"-"||$i} else ()
    return element {"bibl"} {$biblId, $ptr, $nonEmptyCitedRanges}
  return if(count($bibls) > 0) then element {"listBibl"} {$listBibl/head, $bibls} else () (: only return a listBibl if there are non-empty bibls :)
};

declare function cmproc:process-bibl-uri($uri as xs:string)
as xs:string
{
  let $itemKey := 
    if(contains($uri, "zotero")) then (: if it's a zotero URI, the item key is after the "items/" string :)
      substring-after($uri, "items/") (: substring-after is used so that an empty string is returned if a match is not found, forcing an error to be raised :)
    else if(contains($uri, $config:bibl-uri-base)) then (: if it's a C-M style URI, the itemKey comes after the bibl-uri-base :)
      substring-after($uri, $config:bibl-uri-base)
    else () (: other formats should raise an error at present :)
  let $itemKey := functx:substring-before-if-contains($itemKey, "/") (: remove any extraneous strings following the itemKey, such as '/library', etc. :)
  return
    if(string-length($itemKey) > 0) then
      $config:bibl-uri-base||$itemKey
   else () (: this will force a type error when the itemKey cannot be extracted, which will clue us in to malformed bibl uris :)
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
    (: normalize-space(string-join($note/p[title]//text(), " ")), :)
    $note/p/list/item/p/text(),
    $note/list/item/text(),
    (: normalize-space(string-join($note/p/list/item[title]//text(), " ")), :)
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
