xquery version "3.0";
import module namespace functx = "http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare option output:omit-xml-declaration "no";
declare option output "indent=no";

(: Following function is Syriac World specific:)
declare function local:create-respStmt($placeRequester, $projectConfig){
  let $requesterNameStrings := for $requester in fn:distinct-values($placeRequester/*:label/text())
    let $wordSeq := tokenize($requester, " ")
    let $requesterNormCapSeq := 
      for $word in $wordSeq
        return functx:capitalize-first(lower-case($word))
   let $requesterNormCapString := string-join($requesterNormCapSeq, " ")
    
    return $requesterNormCapString
  for $personString in $requesterNameStrings
    let $firstInitial := substring($personString, 1, 1)
    let $personNameSeq := tokenize($personString, " ")
    let $lastName := $personNameSeq[last()]
    let $personUri := "http://syriaca.org/documentation/editors.xml#"||lower-case($firstInitial)||lower-case($lastName)
    return <respStmt>
      <resp>Connection to the Syriac World identified by</resp>
      <name ref="{$personUri}">{$personString}</name>
    </respStmt>
};

declare function local:update-respStmtList($currentRespStmts, $rec, $projectConfig) {
  let $staticRespStmts := $projectConfig/*:configuration/headerMetadata/respStmtStatic/respStmt
  let $dynamicRespStmts := local:create-respStmt($rec/*:Requested-by_from_working-data, $projectConfig)
  return ($staticRespStmts, $dynamicRespStmts, $currentRespStmts)
};

(:
declare function local:create-contributors($respStmtList) {
  for $respStmt in $respStmtList
    let $editorUri := string($respStmt/name/@ref)
    let $editorString := string($respStmt/name/text())
    return if ($editorUri = "http://syriaca.org/documentation/editors.xml#mdickens" or $editorUri = "http://syriaca.org/documentation/editors.xml#htakahashi") then
      <editor role="contributor" ref="{$editorUri}">{$editorString}</editor>
};
:)

declare function local:create-new-bibls($uri, $indexDoc, $relatedChapters, $biblLookup, $nextBiblSeq) {
  let $matchRows := for $row in $indexDoc/*:csv/*:record
      where $row/*:Syriaca_URI/text() = $uri
      return $row
  let $distinctCitedRanges := fn:distinct-values(for $row in $matchRows
    return $row/*:Maps_CitedRange/text())
  let $distinctIndexPages := fn:distinct-values(for $row in $matchRows
    return $row/*:Index_CitedRange/text())
  let $mapBibls := for $citedRange at $i in $distinctCitedRanges
    let $biblId := $i+fn:number($nextBiblSeq)
    return 
      <bibl xml:id="{"bib"||substring-after($uri, "place/")||"-"||$biblId}">
        <title xml:lang="en" level="a">Diachronic Maps of Syriac Cultures and Their Geographic Contexts</title>
        <author>Ian Mladjov</author>
        <editor>David A. Michelson</editor>
        <title xml:lang="en" level="m">The Syriac World</title>
        <editor>Daniel King</editor>
        <ptr target="http://syriaca.org/bibl/QK9W3LED"/>
        <citedRange unit="map">{$citedRange}</citedRange>
      </bibl>
  let $lastMapBiblIndex := fn:count($mapBibls) + fn:number($nextBiblSeq)
  let $indexBibls := for $citedRange at $i in $distinctIndexPages
    return 
      <bibl xml:id="{"bib"||substring-after($uri, "place/")||"-"||$i+$lastMapBiblIndex}">
        <title xml:lang="en" level="a">Index of Maps</title>
        <author>William L. Potter</author>
        <author>David A. Michelson</author>
        <title xml:lang="en" level="m">The Syriac World</title>
        <editor>Daniel King</editor>
        <ptr target="http://syriaca.org/bibl/BNVESQNE"/>
        <citedRange unit="p">{$citedRange}</citedRange>
      </bibl>
  let $chapterBibls := local:create-chapter-bibls($mapBibls, $indexBibls, $relatedChapters, substring-after($uri, "place/"), $biblLookup, $nextBiblSeq)
  return ($mapBibls, $indexBibls, $chapterBibls)
};

declare function local:create-chapter-bibls($mapBibls, $indexBibls, $relatedChapters, $docId, $biblLookup, $oldBiblCount) {
  let $lastBiblId := count($mapBibls) + count($indexBibls) + fn:number($oldBiblCount)
  for $ch at $i in fn:distinct-values($relatedChapters/*:label/text())
    let $chBiblInfo := for $bibl in $biblLookup/bibl
      where fn:normalize-space($ch) = $bibl/lookupString/text()
      return $bibl
    let $title := <title xml:lang="en" level="a">{$chBiblInfo/title/text()}</title>
    let $authors := for $author in $chBiblInfo/author
      return <author>{$author/text()}</author>
    let $citedRange := <citedRange unit="p">{$chBiblInfo/pages/text()}</citedRange>
    let $biblId := $chBiblInfo/zoteroId/text()
    return <bibl xml:id="bib{$docId}-{$lastBiblId + $i}">
      {$title, $authors}
      <title xml:lang="en" level="m">The Syriac World</title>
        <editor>Daniel King</editor>
        <ptr target="http://syriaca.org/bibl/{$biblId}"/>
        {$citedRange}
    </bibl>
};

declare function local:create-idno-list($rec, $uri) {
  let $mainIdno := <idno type="URI">{"http://"||$uri}</idno>
  let $otherUris := fn:distinct-values(($rec/*:URIs_from_RevisedPlaces/*:label/text(), $rec/*:URIs_from_working-data/*[not(name(*:Source))]/*:label/text(), $rec/*:URI_from_Nov17Revised/*:label/text()))
  let $otherIdnoSeq := for $otherUri in $otherUris
    return if ($otherUri != "N/A") then <idno type="URI">{$otherUri}</idno> else()
  return ($mainIdno, $otherIdnoSeq)
};

(:START MAIN QUERY:)
let $configDirectoryUrl := "referenceData\"
let $localConfig := doc($configDirectoryUrl||"localConfig.xml")
let $projectConfig := doc($configDirectoryUrl||"projectConfig.xml")
let $indexCsvUri := $localConfig/*:configuration/*:indexCsvUri
let $indexCsv := file:read-text($indexCsvUri)
let $indexData := csv:parse($indexCsv, map{"header": "true", "separator": ",", "quotes": "yes"})
let $outputPath := $localConfig/*:configuration/*:outputPath
let $nothing := file:create-dir($outputPath)
let $updateDirectory := $localConfig/*:configuration/*:updateDirectory/text()

let $changeLog :=  <change who="{$projectConfig/*:configuration/*:editorUri/text()}" when="{fn:current-date()}">{$projectConfig/*:configuration/*:changeLogMessage/text()}</change>

(:
TO DO: 


- update publicationStmt/date ?

- placeName(s) if it doesn't exist, with bibl citation (get text nodes of each existing and string match the list with new names (referenced to bibl ids). If any are matches, add the bibl reference to it otherwise add a new placeName)
- location(s) if they don't exist, with bibl citation (same as placeNames?)
- state (existence)? (can we have multiple state elements? Don't they require a source?)
- 
:)

for $rec in doc($localConfig/*:configuration/*:inputFileUri/text())/*:list/*:record
  for $doc in fn:collection($updateDirectory)
    where $doc//listPlace/place/idno[1]/text() = "http://"||$rec/*:Syriaca_URI/*:label/text()
    let $uri := $doc//listPlace/place/idno[1]/text()
    let $updatedRespStmts := local:update-respStmtList($doc//titleStmt/respStmt, $rec, $projectConfig)
    (: let $contributorEditors := local:create-contributors($dynamicRespStmts) :)
    let $nextBiblSeq := substring-after(string($doc//listPlace/place/bibl[last()]/@xml:id), "-")
    let $newBibls := local:create-new-bibls($rec/*:Syriaca_URI/*:label/text(), $indexData, $rec/*:RelatedChapter_from_working-data, $projectConfig//chapterBiblLookupTable, $nextBiblSeq)
    let $updatedBibls := ($doc//listPlace/place/bibl, $newBibls)
    
    (:placeNames:)
    let $newIdnos := local:create-idno-list($rec, $rec/*:Syriaca_URI/*:label/text())
    let $updatedIdnos := functx:distinct-deep(($doc//listPlace/place/idno, $newIdnos))
    return <doc>{$updatedIdnos}</doc>