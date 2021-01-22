xquery version "3.0";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";
declare namespace csv = "http://basex.org/modules/csv";
(:
To do:

- add abstract, compiled from creation elements with xml:id and type, etc.
- add attributes to ab for edition and translation
  - xml:lang (en for translation; from langUsage/lang/@ident for edition)
  - xml:id of form "quote\d+-1" or "-2" for second quote.
  - source referring sequentially to the first two bibls
- add anchor elements as first child below ab with edition and translation referring to each other
- bibls
  - add xml:id attributes to the first two (under Works Cited)
  - Replace Zotero URIs in bibls with C-M.org bibl module URIs
  - refs to bibls in creation/ref/@target; and the two testimonia quotes
  - replace Zotero URIs with C-M.org ones
  - deal with note elements in bibls if we add those
  - add title and author/editors based on Zotero records?? (this was a previous functionality)  
- are we doing anything with empty elements?
- are we doing anything with the notes under body?
:)
(: Functx Functions :)

declare function functx:substring-after-if-contains
(:http://www.xqueryfunctions.com/xq/functx_substring-after-if-contains.html:)
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string? {

   if (contains($arg,$delim))
   then substring-after($arg,$delim)
   else $arg
 } ;

(: CUSTOM FUNCTIONS :)

declare function local:create-editor-elements($refDoc as node(), $changeStmts as node()+, $editorUriBase as xs:string) {
  for $editor in $changeStmts
    let $editorId := fn:string($editor/@who)
    let $editorString := for $e in $refDoc/TEI/text/body/listPerson/person
      where $editorId = fn:string($e/@xml:id)
      return fn:normalize-space(fn:string-join($e//text(), " "))
    return <editor role="creator" ref="{$editorUriBase||$editorId}">{$editorString}</editor>
};

declare function local:create-respStmts($refDoc as node(), $changeStmts as node()+, $editorUriBase as xs:string) {
  let $metadataRespString := "URNs and other metadata added by"
  let $dataRespString := "Electronic text added by"
  let $teiRespString := "TEI encoding by"
  let $teiRespName := <name ref="{$editorUriBase||"wpotter"}">William L. Potter</name>
  
  let $respStmtNameSeq := for $editor in $changeStmts
    let $editorId := fn:string($editor/@who)
    let $editorString := for $e in $refDoc/TEI/text/body/listPerson/person
      where $editorId = fn:string($e/@xml:id)
      return fn:normalize-space(fn:string-join($e//text(), " "))
    return <name ref="{$editorUriBase||$editorId}">{$editorString}</name>
  
  let $teiRespStmt := <respStmt>
    <resp>{$teiRespString}</resp>
    {$teiRespName}
  </respStmt>  
  let $metadataRespStmt := <respStmt>
    <resp>{$metadataRespString}</resp>
    {$respStmtNameSeq[1]}
  </respStmt>
  let $dataRespStmt := <respStmt>
    <resp>{$dataRespString}</resp>
    {$respStmtNameSeq[2]}
  </respStmt>
  return ($teiRespStmt, $metadataRespStmt, $dataRespStmt)
};

declare function local:create-creation($oldCreation as node(), $docId as xs:string, $periodTaxonomy as node()) {
  let $newRef := <ref target="#bib{$docId}-1">{$oldCreation/ref/text()}</ref>
  let $newOrigDate := local:update-origDate($oldCreation/origDate, $periodTaxonomy)
  let $newCreation := <creation xmlns="http://www.tei-c.org/ns/1.0">This entry is taken from&#x20;{$oldCreation/title}&#x20;{$newRef}&#x20;written by&#x20;{$oldCreation/persName}&#x20;in {$newOrigDate}. This work was likely written in&#x20;{$oldCreation/origPlace}.</creation>
  return $newCreation
};

declare function local:update-origDate($origDate as node(), $periodTaxonomy) {
  let $lowDate := fn:substring-before($origDate/text(), " ")
  let $highDate := fn:substring-after($origDate/text(), " ")
  let $dateString := local:create-date-string($lowDate, $highDate)
  let $newOrigDate := if ($highDate != "") then <origDate notBefore="{$lowDate}" notAfter="{$highDate}" period="{local:lookup-period-range($lowDate, $highDate, $periodTaxonomy)}">{$dateString}</origDate>
  else <origDate notBefore="{$lowDate}" notAfter="{$highDate}" period="{local:lookup-period-singleDate($lowDate, $periodTaxonomy)}">{$dateString}</origDate>
    
  return $newOrigDate
};

declare function local:create-date-string($low, $high){
  let $lowEra := if (fn:starts-with($low, "-")) then "BCE" else "CE"
  let $highEra := if (fn:starts-with($high, "-")) then "BCE" else "CE"
  return if ($high = "") then
    if (fn:starts-with($low, "-")) then fn:string(fn:number(fn:substring-after($low, "-")))||" BCE" else fn:string(fn:number($low))||" CE"
  else if ($lowEra = $highEra) then fn:string(fn:number(functx:substring-after-if-contains($low, "-")))||"-"||fn:string(fn:number(functx:substring-after-if-contains($high, "-")))||" "||$lowEra
  else fn:string(fn:number(fn:substring-after($low, "-")))||" BCE-"||fn:string(fn:number($high))||" CE"
};

declare function local:lookup-period-range($lower as xs:string, $upper as xs:string, $xmlTable as node()) as xs:string+ {
  let $periodSeq := for $cat in $xmlTable//*:record
    where ($lower >= $cat/*:notBefore/text() and $lower <= $cat/*:notAfter/text()) or ($upper >= $cat/*:notBefore/text() and $upper <= $cat/*:notAfter/text()) or ($lower <= $cat/*:notBefore/text() and $upper >= $cat/*:notAfter/text())
    return $cat/*:catId/text()
  return "#"||fn:string-join($periodSeq, "# ")
};
declare function local:lookup-period-singleDate($date as xs:string, $xmlTable as node()) as xs:string+ {
  let $periodSeq := for $cat in $xmlTable//*:record
    where $date >= $cat/*:notBefore/text() and $date <= $cat/*:notAfter/text()
    return $cat/*:catId/text()
  return "#"||fn:string-join($periodSeq, "# ")
};

declare function local:create-langString($langUsage){
  let $langCode := fn:string($langUsage/language/@ident)
  return switch ($langCode) 
   case "grc" return "Ancient Greek"
   case "la" return "Latin"
   case "ar" return "Arabic"
   case "he" return "Hebrew"
   case "syr" return "Syriac"
   case "jpa" return "Jewish Palestinian Aramaic"
   case "tmr" return "Jewish Babylonian Aramaic"
   case "fro" return "Old French"
   case "hy" return "Armenian"
   default return ""
};

(: GLOBAL PARAMETERS :)
let $projectUriBase := "https://caesarea-maritima.org/"
let $editorUriBase := "https://caesarea-maritima.org/documentation/editors.xml#"
let $editorsXmlDocUri := "https://raw.githubusercontent.com/srophe/caesarea/master/documentation/editors.xml"
let $periodTaxonomyDocUri := "https://raw.githubusercontent.com/srophe/caesarea/master/documentation/caesarea-maritima-historical-era-taxonomy.xml"
let $inputDirectoryUri := "C:\Users\anoni\Documents\GitHub\srophe\caesarea-data\draft-data\"
let $outputDirectoryUri := "C:\Users\anoni\Desktop\caesarea-script-outputs\"
let $currentDate := fn:current-date()
(:Collection URI!!! (Will have to point to a local folder containing files to be edited):)

(: functions

:)

(: START MAIN SCRIPT :)
let $editorsDoc := fn:doc($editorsXmlDocUri)
let $periodTaxonomyDoc := fn:doc($periodTaxonomyDocUri)
let $nothing := file:create-dir($outputDirectoryUri)

(: Main Loop through Folder of Records to Process :)
for $doc in fn:collection($inputDirectoryUri)
  let $docId := $doc//publicationStmt/idno/text()
  let $docUri := $projectUriBase||"testimonia/"||$docId
  let $docTitle := <title xml:lang="en" level="a">{$doc/TEI/teiHeader/profileDesc/creation/persName/text()},&#x20;<title level="m">{$doc/TEI/teiHeader/profileDesc/creation/title/text()}</title>&#x20;{$doc//TEI/teiHeader/profileDesc/creation/ref/text()}</title>
  let $editors := local:create-editor-elements($editorsDoc, $doc//revisionDesc/change, $editorUriBase)
  let $respStmts := local:create-respStmts($editorsDoc, $doc//revisionDesc/change, $editorUriBase)
  let $newCreation := local:create-creation($doc//creation, $docId, $periodTaxonomyDoc)
  let $langString := local:create-langString($doc//profileDesc/langUsage)
  let $docUrn := fn:string($doc//profileDesc/creation/title/@ref)||":"||$doc//profileDesc/creation/ref/text()
  
  return if($docId != "") then (
    insert node $docTitle before $doc//titleStmt/title,
    insert nodes $editors after $doc//titleStmt/editor[last()],
    insert nodes $respStmts before $doc//titleStmt/respStmt[1],
    replace value of node $doc//publicationStmt/idno with $docUri||"/tei",
    replace value of node $doc//publicationStmt/date with $currentDate,
    replace node $doc//profileDesc/creation with $newCreation,
    replace value of node $doc/TEI/teiHeader/profileDesc/langUsage/language with $langString,
    replace value of node $doc//profileDesc/textClass/classCode/idno with $docUrn,
    replace value of node $doc//revisionDesc/change[1]/@when with $currentDate,
    replace value of node $doc//revisionDesc/change[2]/@when with $currentDate,
    fn:put($doc, fn:concat($outputDirectoryUri, $docId, ".xml"), map{'omit-xml-declaration': 'no'})
)