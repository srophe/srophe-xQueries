xquery version "3.0";
import module namespace functx = "http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace srophe = "https://srophe.app";
declare option output:omit-xml-declaration "no";

declare function local:create-tei-header($rec, $projectConfig) {
  let $title := <title level="a" xml:lang="en">{$rec/*:Syriaca_Headword/*:label[1]/text()}</title>
  let $dynamicRespStmts := local:create-respStmt($rec/*:Requested-by_from_working-data, $projectConfig)
  let $contributorEditors := local:create-contributors($dynamicRespStmts)
  let $staticRespStmts := $projectConfig/*:configuration/staticMetadata/titleStmtStatic/titleStmt/respStmt
  let $titleStmt := <titleStmt>{$title, $projectConfig/*:configuration/staticMetadata/titleStmtStatic/titleStmt/*[not(self::respStmt)], $contributorEditors, $staticRespStmts, $dynamicRespStmts}</titleStmt> (:come back to both the static and dynamic metadata:)
  let $editionStmt := $projectConfig/*:configuration/staticMetadata/editionStmtStatic/*
  let $publicationStmt := local:create-publicationStmt($rec/*:Syriaca_URI/*:label/text(), $projectConfig/*:configuration/staticMetadata/publicationStmtStatic/publicationStmt)
  let $seriesStmt := $projectConfig/*:configuration/staticMetadata/seriesStmtStatic/*
  let $sourceDesc := $projectConfig/*:configuration/staticMetadata/sourceDescStatic/*
  let $fileDesc := <fileDesc>{$titleStmt, $editionStmt, $publicationStmt, $seriesStmt, $sourceDesc}</fileDesc>
  let $encodingDesc := $projectConfig/*:configuration/staticMetadata/encodingDescStatic/*
  let $profileDesc := $projectConfig/*:configuration/staticMetadata/profileDescStatic/*
  let $revisionDesc := <revisionDesc status="draft">
    <change who="{$projectConfig/*:configuration/*:editorUri/text()}" when="{fn:current-date()}">CREATED: place</change>
  </revisionDesc>
  return <teiHeader>{$fileDesc, $encodingDesc, $profileDesc, $revisionDesc}</teiHeader>
};

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

declare function local:create-contributors($respStmtList) {
  for $respStmt in $respStmtList
    let $editorUri := string($respStmt/name/@ref)
    let $editorString := string($respStmt/name/text())
    return if ($editorUri = "http://syriaca.org/documentation/editors.xml#mdickens" or $editorUri = "http://syriaca.org/documentation/editors.xml#htakahashi") then
      <editor role="contributor" ref="{$editorUri}">{$editorString}</editor>
};

declare function local:create-publicationStmt($uri, $staticMetadata) {
  let $docUri := "http://"||$uri||"/tei"
  return 
  <publicationStmt xmlns="http://www.tei-c.org/ns/1.0">
    {$staticMetadata/*:authority}
    <idno type="URI">{$docUri}</idno>
        {$staticMetadata/*:availability}
        <date>{fn:current-date()}</date>
  </publicationStmt>
};

declare function local:create-place-body($rec, $indexData, $projectConfig){
  let $uri := $rec/*:Syriaca_URI/*:label/text()
  let $docId := fn:substring-after($uri, "place/")
  let $headWord := <placeName xml:id="name{$docId}-1" xml:lang="en" srophe:tags="#syriaca-headword" source ="#bib{$docId}-1">{$rec/*:Syriaca_Headword/*:label[1]/text()}</placeName>
  let $placeType := fn:lower-case(local:create-place-type($rec, $headWord/text()))
  (: let $otherPlaceNames := if(count($rec/*:Syriaca_Headword/*:label) > 1) then local:create-other-placeNames($rec/*:Syriaca_Headword, $docId) else () :)
  let $existence := if ($rec/*:Existence_Date/*:label[1]/text() != "") then local:create-existence($rec/*:Existence_Date)
  let $idnos := local:create-idno-list($rec, $uri)
  let $bibls := local:create-bibls($uri, $indexData, $rec/*:RelatedChapter_from_working-data, $projectConfig//chapterBiblLookupTable)
  let $placeNames := local:create-placeNames($rec/*:Syriaca_Headword/*:label, $bibls, $uri, $indexData)
  let $abstract := <desc type="abstract" xml:id="abstract{$docId}-1" xml:lang="en"/>
  let $locations := if ($rec/*:KML_LongLat_DD/*:label[1]/text() != "") then local:create-location($rec, $docId, $bibls) else ()
  let $relations := if($rec/*:Related_Place[1]/*:label/text() != "") then <listRelation>{local:create-relations($rec, $docId)}</listRelation> else()
  let $notes := local:create-notes($rec)
  return <text>
    <body>
      <listPlace>
        <place type="{$placeType}">{(: $headWord, $otherPlaceNames :)$placeNames, $abstract, $locations, $existence, $idnos, $bibls}</place>
        {$relations}
      </listPlace>
      {if (not(empty($notes))) then <note xml:lang="en" type="misc">
        <list>
        {$notes}
        </list>
      </note>
    else ()}
    </body>
  </text>
};

declare function local:create-place-type($rec, $headword) {
  let $explicitPlaceTypeSeq := for $label in $rec/*:Place_Type_from_working-data/*:label
    return $label/text()
  let $explicitPlaceTypeString := fn:string-join(fn:distinct-values($explicitPlaceTypeSeq), "#")
  return if ($explicitPlaceTypeString != "") then $explicitPlaceTypeString
  else if ($rec/*:Monastery/*:label/text() != "" or $rec/*:Monastery_from_Nov17Revised/*:label/text() != "") then "monastery"
  else if ($rec/*:Region/*:label/text() != "") then "region"
  else if (fn:contains($headword, "Lake")) then "open-water"
  else if (fn:contains($headword, "River")) then "river"
  else "settlement"
};

(: declare function local:create-other-placeNames($nameList, $docId) {
  for $name at $i in $nameList/*:label
    where $i > 1
    return <placeName xml:id="name{$docId||"-"||$i}" xml:lang="en" source="#bib{$docId}-{$i}">{$name/text()}</placeName>
}; :)

declare function local:create-placeNames($nameList, $bibls, $uri, $indexDoc) {
  let $matchRows := for $row in $indexDoc/*:csv/*:record
      where $row/*:Syriaca_URI/text() = $uri
      return $row
  for $name at $i in $nameList/text()
    let $mapRange := fn:normalize-space($matchRows[fn:normalize-space(*:Syriaca_Headword/text()) = fn:normalize-space($name)]/*:Maps_CitedRange/text())
    let $indexPages := fn:normalize-space($matchRows[fn:normalize-space(*:Syriaca_Headword/text()) = fn:normalize-space($name)]/*:Index_CitedRange/text())
    let $mapBiblRef := for $bibl in $bibls[citedRange/@unit="map"]
      where ($mapRange = $bibl/citedRange/text())
      return "#"||string($bibl/@xml:id)
    let $indexBiblRef := for $bibl in $bibls[citedRange/@unit="p"]
      where ($indexPages = $bibl/citedRange/text())
      return "#"||string($bibl/@xml:id)
    let $sourceStr := fn:string-join(functx:value-union($mapBiblRef, $indexBiblRef), " ")
    return if ($i = 1) then <placeName xml:id="name{fn:substring-after($uri, "place/")}-{$i}" srophe:tags="#syriaca-headword" xml:lang="en" source="{$sourceStr}">{$name}</placeName>
    else <placeName xml:id="name{fn:substring-after($uri, "place/")}-{$i}" xml:lang="en" source="{$sourceStr}">{$name}</placeName>
};

declare function local:create-location($rec, $docId, $bibls) {
  let $locationsList := for $kml in $rec/*:KML_LongLat_DD
    for $loc in $kml/*:label
      return $loc/text()
  let $locationSourceStr := fn:string-join(for $bibl in $bibls[citedRange/@unit="map"]
    return "#"||string($bibl/@xml:id), " ")
  let $distinctLocations := fn:distinct-values($locationsList)
  let $preferredLocation := (if ($rec/*:Region/*:label/text() != "" or $rec/*:Apprx/*:label/text() != "") then 
    <location type="gps" subtype="representative" source="{$locationSourceStr}">
        <geo>{fn:replace($distinctLocations[1], ",", " ")}</geo>
    </location>
    else if (count($distinctLocations) >1) then
    <location type="gps" subtype="preferred" source="{$locationSourceStr}">
        <geo>{fn:replace($distinctLocations[1], ",", " ")}</geo>
    </location>
    else
    <location type="gps" source="{$locationSourceStr}">
        <geo>{fn:replace($distinctLocations[1], ",", " ")}</geo>
    </location>)
    let $otherLocations := for $loc at $i in $distinctLocations
      where $i > 1
      return <location type="gps" subtype="alternate" source="{$locationSourceStr}">
        <geo>{fn:replace($loc, ",", " ")}</geo>
      </location>
    return ($preferredLocation, $otherLocations)
};

declare function local:create-existence($existenceDates){
  let $existenceDateStrings := for $date in $existenceDates/*:label
    return $date/text()
  let $uniqueExistenceDates := fn:distinct-values($existenceDateStrings)
  for $date in $uniqueExistenceDates
    let $matchesAndNonMatches := <all>{functx:get-matches-and-non-matches($date, "\d+")}</all>
    let $dates := for $x in $matchesAndNonMatches/*:match
      return $x/text()
    let $lowDate := functx:pad-integer-to-length(fn:number($dates[1]), 4)
    let $highDate :=  functx:pad-integer-to-length(fn:number($dates[2]), 4)
    return <state resp="http://syriaca.org" type="existence" from="{$lowDate}" to="{$highDate}"/>
};

declare function local:create-idno-list($rec, $uri) {
  let $mainIdno := <idno type="URI">{"http://"||$uri}</idno>
  let $otherUris := fn:distinct-values(($rec/*:URIs_from_RevisedPlaces/*:label/text(), $rec/*:URIs_from_working-data/*[not(name(*:Source))]/*:label/text(), $rec/*:URI_from_Nov17Revised/*:label/text()))
  let $otherIdnoSeq := for $otherUri in $otherUris
    return if ($otherUri != "N/A") then <idno type="URI">{$otherUri}</idno> else()
  return ($mainIdno, $otherIdnoSeq)
};

declare function local:create-bibls($uri, $indexDoc, $relatedChapters, $biblLookup) {
  let $matchRows := for $row in $indexDoc/*:csv/*:record
      where $row/*:Syriaca_URI/text() = $uri
      return $row
  let $distinctCitedRanges := fn:distinct-values(for $row in $matchRows
    return $row/*:Maps_CitedRange/text())
  let $distinctIndexPages := fn:distinct-values(for $row in $matchRows
    return $row/*:Index_CitedRange/text())
  let $mapBibls := for $citedRange at $i in $distinctCitedRanges
    return 
      <bibl xml:id="{"bib"||substring-after($uri, "place/")||"-"||$i}">
        <title xml:lang="en" level="a">Diachronic Maps of Syriac Cultures and Their Geographic Contexts</title>
        <author>Ian Mladjov</author>
        <editor>David A. Michelson</editor>
        <title xml:lang="en" level="m">The Syriac World</title>
        <editor>Daniel King</editor>
        <ptr target="http://syriaca.org/bibl/QK9W3LED"/>
        <citedRange unit="map">{$citedRange}</citedRange>
      </bibl>
  let $lastMapBiblIndex := fn:count($mapBibls)
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
  let $chapterBibls := local:create-chapter-bibls($mapBibls, $indexBibls, $relatedChapters, substring-after($uri, "place/"), $biblLookup)
  return ($mapBibls, $indexBibls, $chapterBibls)
};

declare function local:create-chapter-bibls($mapBibls, $indexBibls, $relatedChapters, $docId, $biblLookup) {
  let $lastBiblId := count($mapBibls) + count($indexBibls)
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

declare function local:create-relations($rec, $docId) {
  for $relatedPlace in $rec/*:Related_Place
    return <relation name="see-also" mutual= "http://syriaca.org/place/{$docId}&#x20;http://{$relatedPlace/*:uri/text()}"/>
};

declare function local:create-notes($rec) {
  let $noteStrings := ($rec/*:Notes-From-Ian/*:label/text(), $rec/*:NewNotes4-26/*:label/text(), $rec/*:Notes-4-Ian/*:label/text(), $rec/*:TC-Notes/*:label/text(), $rec/*:My-Notes/*:label/text(), $rec/*:Other_Name/*:label/text(), $rec/*:Source/*:label/text(), $rec/*:GazetterNote_from_working-data/*:label/text(), $rec/*:Notes_from_working-data/*:label/text(), $rec/*:Notes_from_Nov17Revised/*:label/text(), $rec/*:My_notes_from_Nov17Revised/*:label/text())
 for $note in fn:distinct-values($noteStrings)
   return <item>{$note}</item>
};

(:START MAIN QUERY:)
let $configDirectoryUrl := "toTeiData\"
let $localConfig := doc($configDirectoryUrl||"localConfig.xml")
let $projectConfig := doc($configDirectoryUrl||"projectConfig.xml")
let $indexCsv := file:read-text("C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Syriac-World-Maps-Util\toTeiData\SyriacWorldPlacesIndexData.csv")
let $indexData := csv:parse($indexCsv, map{"header": "true", "separator": ",", "quotes": "yes"})
let $outputPath := $localConfig/*:configuration/*:outputPath
let $nothing := file:create-dir($outputPath)

for $rec in doc($localConfig/*:configuration/*:inputFileUri/text())/*:list/*:record
  (: where $rec/*:Syriaca_URI/*:label/text() = "syriaca.org/place/4001" <-- For testing:)
  let $doc := document {
    processing-instruction xml-model {
        'href="https://raw.githubusercontent.com/srophe/srophe-eXist-app/master/documentation/schemas/out/syriacaPlaces.compiled.rng" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"'
    }, processing-instruction xml-model {
        'href="https://raw.githubusercontent.com/srophe/srophe-eXist-app/master/documentation/schemas/out/syriacaPlaces.compiled.rng" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"'
    }, processing-instruction xml-model {
        'href="https://raw.githubusercontent.com/srophe/srophe-eXist-app/master/documentation/schemas/uniqueLangHW.sch" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"'
    }, <TEI xml:lang="{$projectConfig/*:configuration/*:baseLanguage/text()}" xmlns:syriaca="http://syriaca.org" xmlns:srophe="https://srophe.app">{local:create-tei-header($rec, $projectConfig), local:create-place-body($rec, $indexData, $projectConfig)}</TEI>}
    return if ($localConfig/*:configuration/*:outputTo/text() = "file") then file:write($outputPath||substring-after($rec/*:Syriaca_URI/*:label/text(), "place/")||'.xml',  $doc, map { 'omit-xml-declaration': 'no'})
    else $doc