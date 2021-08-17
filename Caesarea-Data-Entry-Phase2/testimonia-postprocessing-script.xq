xquery version "3.0";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";
declare namespace csv = "http://basex.org/modules/csv";
(:
To do:
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
 declare function functx:is-node-in-sequence-deep-equal
  ( $node as node()? ,
    $seq as node()* )  as xs:boolean {

   some $nodeInSeq in $seq satisfies deep-equal($nodeInSeq,$node)
 } ;
declare function functx:distinct-deep
  ( $nodes as node()* )  as node()* {

    for $seq in (1 to count($nodes))
    return $nodes[$seq][not(functx:is-node-in-sequence-deep-equal(
                          .,$nodes[position() < $seq]))]
 } ;
 declare function functx:add-or-update-attributes
  ( $elements as element()* ,
    $attrNames as xs:QName* ,
    $attrValues as xs:anyAtomicType* )  as element()? {

   for $element in $elements
   return element { node-name($element)}
                  { for $attrName at $seq in $attrNames
                    return attribute {$attrName}
                                     {$attrValues[$seq]},
                    $element/@*[not(node-name(.) = $attrNames)],
                    $element/node() }
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

declare function local:update-origDate($origDate, $periodTaxonomy) {
  let $origDateText := fn:normalize-space(fn:string-join($origDate/text()))
  let $lowDate := fn:substring-before($origDateText, " ")
  let $highDate := fn:substring-after($origDateText, " ")
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

declare function local:create-abstract($creation as node(), $placeNameSeq, $recType as xs:string, $docId as xs:string) {
  let $placeNameSeqDistinct := functx:distinct-deep(for $placeName in $placeNameSeq
    return <quote>{$placeName}</quote>)
  let $isOrAre := if(fn:count($placeNameSeqDistinct) >  1) then "are" else "is"
  return if(fn:contains($recType, "#direct")) then <desc type="abstract" xml:id="abstract{$docId}-1">{local:node-join($placeNameSeqDistinct, ", ", "and ")}&#x20;{$isOrAre}&#x20;directly attested at&#x20;{$creation/persName},&#x20;{$creation/title}&#x20;{$creation/ref}. This passage was written circa&#x20;{$creation/origDate}&#x20;possibly in&#x20;{$creation/origPlace}.</desc>
  else <desc type="abstract" xml:id="abstract{$docId}-1">Caeasrea Maritima is indirectly attested at&#x20;{$creation/persName},&#x20;{$creation/title}&#x20;{$creation/ref}. This passage was written circa&#x20;{$creation/origDate}&#x20;possibly in&#x20;{$creation/origPlace}.</desc>
  (: EXAMPLE "Καισάρεια is directly attested at Aelius Herodian, On Orthography 2.2.4=GG III.2.451.22-27.
This passage was written circa 150-200 C.E. possibly in Alexandria. Evidence for Greek
Language; Geography." :)
  
};

(: declare function local:create-themes-list($themesNote as node()) {
  let $compareNode := <note type="theme"/>
  let $themeSeq := for $theme in $themesNote/p
    return fn:normalize-space($theme/text())
  return if ($compareNode != $themesNote) then " Evidence for "||fn:string-join($themeSeq, "; ")||"."
}; :)

declare function local:node-join($seq, $delim as xs:string, $finalDelim as xs:string?)  {
  let $nothing := ""
  for $el in $seq
    return if ($el != $seq[last()]) then ($el, $delim)
    else ($finalDelim, $el)
};

declare function local:update-excerpt($excerpt as node(), $excerptLangCode as xs:string, $docId as xs:string, $docLangCode as xs:string) as node() {
  let $quoteSeq := if(fn:string($excerpt/@type) = "edition") then "1" else "2"
  let $correspLangCode := if($excerptLangCode = "en") then $docLangCode else "en"
  let $anchor := <anchor xml:id="testimonia-{$docId}.{$excerptLangCode}.1" corresp="testimonia-{$docId}.{$correspLangCode}.1"/>
  let $otherElements := $excerpt/child::node()
  return element ab {attribute type {fn:string($excerpt/@type)}, attribute xml:lang {$excerptLangCode}, attribute xml:id {"quote"||$docId||"-"||$quoteSeq}, attribute source {"#bib"||$docId||"-"||$quoteSeq}, $anchor, $otherElements}
};

declare function local:update-bibls($listBibl as node(), $docId as xs:string, $isWorksCited as xs:string, $projectUriBase as xs:string){
  let $bibls := for $bibl at $i in $listBibl/bibl
    let $newPtr := if (fn:string($bibl/ptr/@target) !="") then <ptr target="{$projectUriBase}bibl/{fn:substring-after(fn:string($bibl/ptr/@target), "items/")}"/> else <ptr target=""/>
    return if ($isWorksCited = "yes") then element bibl {attribute xml:id {"bib"||$docId||"-"||$i}, $newPtr, $bibl/*[not(self::ptr)]} else element bibl {$newPtr, $bibl/*[not(self::ptr)]}
  return element listBibl {$listBibl/head, $bibls}
};

(: GLOBAL PARAMETERS :)
let $projectUriBase := "https://caesarea-maritima.org/"
let $editorUriBase := "https://caesarea-maritima.org/documentation/editors.xml#"
let $editorsXmlDocUri := "https://raw.githubusercontent.com/srophe/caesarea/master/documentation/editors.xml"
let $periodTaxonomyDocUri := "https://raw.githubusercontent.com/srophe/caesarea/master/documentation/caesarea-maritima-historical-era-taxonomy.xml"
let $inputDirectoryUri := "C:\Users\anoni\Desktop\CAESAREA-FILES\July-files\"
let $outputDirectoryUri := "C:\Users\anoni\Desktop\CAESAREA-FILES\july-output\"
let $currentDate := fn:current-date()

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
  let $docUrn := if(fn:string($doc//profileDesc/creation/title/@ref) != "") then fn:string($doc//profileDesc/creation/title/@ref)||":"||$doc//profileDesc/creation/ref/text()
  let $abstract := local:create-abstract($newCreation, $doc//ab/placeName, fn:string($doc//catRef[@scheme="#CM-Testimonia-Type"]/@target), $docId)
  let $edition := local:update-excerpt($doc//body/ab[@type="edition"], fn:string($doc//profileDesc/langUsage/language/@ident), $docId, fn:string($doc//profileDesc/langUsage/language/@ident))
  let $translation := local:update-excerpt($doc//body/ab[@type="translation"], "en", $docId, fn:string($doc//profileDesc/langUsage/language/@ident))
  let $newWorksCited := local:update-bibls($doc//listBibl[1], $docId, "yes", $projectUriBase)
  let $newAdditionalBibl := local:update-bibls($doc//listBibl[2], $docId, "no", $projectUriBase)
  
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
    delete node $doc//comment(),
    fn:put($doc, fn:concat($outputDirectoryUri, $docId, ".xml"), map{'omit-xml-declaration': 'no'})
)