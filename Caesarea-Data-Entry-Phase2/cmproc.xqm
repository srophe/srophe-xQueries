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
import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare function cmproc:create-editor-elements($refDoc as node(), $changeStmts as node()+, $editorUriBase as xs:string) {
  for $editor in $changeStmts
    let $editorId := string($editor/@who)
    let $editorString := for $e in $refDoc/TEI/text/body/listPerson/person
      where $editorId = string($e/@xml:id)
      return normalize-space(string-join($e//text(), " "))
    return <editor role="creator" ref="{$editorUriBase||$editorId}">{$editorString}</editor>
};

declare function cmproc:create-respStmts($refDoc as node(), $changeStmts as node()+, $editorUriBase as xs:string) {
  let $metadataRespString := "URNs and other metadata added by"
  let $dataRespString := "Electronic text added by"
  let $teiRespString := "TEI encoding by"
  let $teiRespName := <name ref="{$editorUriBase||"wpotter"}">William L. Potter</name>
  
  let $respStmtNameSeq := for $editor in $changeStmts
    let $editorId := string($editor/@who)
    let $editorString := for $e in $refDoc/TEI/text/body/listPerson/person
      where $editorId = string($e/@xml:id)
      return normalize-space(string-join($e//text(), " "))
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

declare function cmproc:create-creation($oldCreation as node(), $docId as xs:string, $periodTaxonomy as node()) {
  let $newRef := <ref target="#bib{$docId}-1">{$oldCreation/ref/text()}</ref>
  let $newOrigDate := cmproc:update-origDate($oldCreation/origDate, $periodTaxonomy)
  let $newCreation := <creation xmlns="http://www.tei-c.org/ns/1.0">This entry is taken from&#x20;{$oldCreation/title}&#x20;{$newRef}&#x20;written by&#x20;{$oldCreation/persName}&#x20;in {$newOrigDate}. This work was likely written in&#x20;{$oldCreation/origPlace}.</creation>
  return $newCreation
};

declare function cmproc:update-origDate($origDate, $periodTaxonomy) {
  let $origDateText := normalize-space(string-join($origDate/text()))
  let $lowDate := substring-before($origDateText, " ")
  let $highDate := substring-after($origDateText, " ")
  let $dateString := cmproc:create-date-string($lowDate, $highDate)
  let $newOrigDate := if ($highDate != "") then <origDate notBefore="{$lowDate}" notAfter="{$highDate}" period="{cmproc:lookup-period-range($lowDate, $highDate, $periodTaxonomy)}">{$dateString}</origDate>
  else <origDate notBefore="{$lowDate}" notAfter="{$highDate}" period="{cmproc:lookup-period-singleDate($lowDate, $periodTaxonomy)}">{$dateString}</origDate>
    
  return $newOrigDate
};

declare function cmproc:create-date-string($low, $high){
  let $lowEra := if (starts-with($low, "-")) then "BCE" else "CE"
  let $highEra := if (starts-with($high, "-")) then "BCE" else "CE"
  return if ($high = "") then
    if (starts-with($low, "-")) then string(number(substring-after($low, "-")))||" BCE" else string(number($low))||" CE"
  else if ($lowEra = $highEra) then string(number(functx:substring-after-if-contains($low, "-")))||"-"||string(number(functx:substring-after-if-contains($high, "-")))||" "||$lowEra
  else string(number(substring-after($low, "-")))||" BCE-"||string(number($high))||" CE"
};

declare function cmproc:lookup-period-range($lower as xs:string, $upper as xs:string, $xmlTable as node()) as xs:string+ {
  let $periodSeq := for $cat in $xmlTable//*:record
    where ($lower >= $cat/*:notBefore/text() and $lower <= $cat/*:notAfter/text()) or ($upper >= $cat/*:notBefore/text() and $upper <= $cat/*:notAfter/text()) or ($lower <= $cat/*:notBefore/text() and $upper >= $cat/*:notAfter/text())
    return $cat/*:catId/text()
  return "#"||string-join($periodSeq, " #")
};
declare function cmproc:lookup-period-singleDate($date as xs:string, $xmlTable as node()) as xs:string+ {
  let $periodSeq := for $cat in $xmlTable//*:record
    where $date >= $cat/*:notBefore/text() and $date <= $cat/*:notAfter/text()
    return $cat/*:catId/text()
  return "#"||string-join($periodSeq, " #")
};

declare function cmproc:create-langString($langUsage){
  let $langCode := string($langUsage/language/@ident)
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

declare function cmproc:create-abstract($creation as node(), $placeNameSeq, $recType as xs:string, $docId as xs:string) {
  let $placeNameSeqDistinct := functx:distinct-deep(for $placeName in $placeNameSeq
    return <quote>{$placeName}</quote>)
  let $isOrAre := if(count($placeNameSeqDistinct) >  1) then "are" else "is"
  return if(contains($recType, "#direct")) then <desc type="abstract" xml:id="abstract{$docId}-1">{cmproc:node-join($placeNameSeqDistinct, ", ", "and ")}&#x20;{$isOrAre}&#x20;directly attested at&#x20;{$creation/persName},&#x20;{$creation/title}&#x20;{$creation/ref}. This passage was written circa&#x20;{$creation/origDate}&#x20;possibly in&#x20;{$creation/origPlace}.</desc>
  else <desc type="abstract" xml:id="abstract{$docId}-1">Caeasrea Maritima is indirectly attested at&#x20;{$creation/persName},&#x20;{$creation/title}&#x20;{$creation/ref}. This passage was written circa&#x20;{$creation/origDate}&#x20;possibly in&#x20;{$creation/origPlace}.</desc>
  (: EXAMPLE "Καισάρεια is directly attested at Aelius Herodian, On Orthography 2.2.4=GG III.2.451.22-27.
This passage was written circa 150-200 C.E. possibly in Alexandria. Evidence for Greek
Language; Geography." :)
  
};

(: declare function cmproc:create-themes-list($themesNote as node()) {
  let $compareNode := <note type="theme"/>
  let $themeSeq := for $theme in $themesNote/p
    return normalize-space($theme/text())
  return if ($compareNode != $themesNote) then " Evidence for "||string-join($themeSeq, "; ")||"."
}; :)

declare function cmproc:node-join($seq, $delim as xs:string, $finalDelim as xs:string?)  {
  let $nothing := ""
  for $el in $seq
    return if ($el != $seq[last()]) then ($el, $delim)
    else ($finalDelim, $el)
};

declare function cmproc:update-excerpt($excerpt as node(), $excerptLangCode as xs:string, $docId as xs:string, $docLangCode as xs:string) as node() {
  let $quoteSeq := if(string($excerpt/@type) = "edition") then "1" else "2"
  let $correspLangCode := if($excerptLangCode = "en") then $docLangCode else "en"
  let $anchor := <anchor xml:id="testimonia-{$docId}.{$excerptLangCode}.1" corresp="#testimonia-{$docId}.{$correspLangCode}.1"/>
  let $nonEmptyChildNodes := 
    for $node in $excerpt/child::node()
    return if($node instance of element() and name($node) = "note" and not($node/text())) then () else $node (: do not return empty note elements :)
  return element ab {$excerpt/@type, attribute xml:lang {$excerptLangCode}, attribute xml:id {"quote"||$docId||"-"||$quoteSeq}, attribute source {"#bib"||$docId||"-"||$quoteSeq}, $anchor, $nonEmptyChildNodes}
};

declare function cmproc:update-bibls($listBibl as node(), $docId as xs:string, $isWorksCited as xs:string, $projectUriBase as xs:string){
  let $bibls := for $bibl at $i in $listBibl/bibl
    where string($bibl/ptr/@target) !="" (: only return bibls that have an assigned ptr :)
    let $newUri := $projectUriBase||"bibl/"||substring-after(string($bibl/ptr/@target), "items/")
    let $newUri := if(ends-with($newUri, "/")) then substring($newUri, 1, string-length($newUri) - 1) else $newUri
    let $newPtr := <ptr target="{$newUri}"/>
    let $nonEmptyCitedRanges := 
      for $citedRange in $bibl/citedRange
      where $citedRange/text()
      return $citedRange
    let $biblId := if ($isWorksCited = "yes") then attribute xml:id {"bib"||$docId||"-"||$i} else ()
    return element bibl {$biblId, $newPtr, $nonEmptyCitedRanges}
  return if(count($bibls) > 0) then element listBibl {$listBibl/head, $bibls} else () (: only return a listBibl if there are non-empty bibls :)
};

(:
Fixes https://github.com/srophe/caesarea-data/issues/108 for new data
:)
declare function cmproc:normalize-related-subjects-notes($doc as node())
as node()+
{
  for $note in $doc//text/body/note
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
