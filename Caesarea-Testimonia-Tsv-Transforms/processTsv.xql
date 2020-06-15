xquery version "3.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";
declare option output:omit-xml-declaration "no";
declare option output:indent "no";
(:
This script transforms lines of TSV data into TEI XML records for deployment in the Testimonia module of caesarea-maritima.org


@author: William L. Potter
@version 1.0
:)
(:Function declarations:)

declare function functx:chars
  ( $arg as xs:string? )  as xs:string* {

   for $ch in string-to-codepoints($arg)
   return codepoints-to-string($ch)
 } ;
 
 declare function functx:value-union
  ( $arg1 as xs:anyAtomicType* ,
    $arg2 as xs:anyAtomicType* )  as xs:anyAtomicType* {

  distinct-values(($arg1, $arg2))
 } ;
 
declare function local:create-teiHeader($rec, $uri, $projectConfig){
  let $docTitle := if($rec/*:workAuthor/text() != '') then <title xmlns="http://www.tei-c.org/ns/1.0" xml:lang="en" level="a">{$rec/*:workAuthor/text()}, <title level="m">{$rec/*:work/text()}</title>&#x20;{$rec/*:citedRangeWork/text()}</title>
  else <title xmlns="http://www.tei-c.org/ns/1.0" xml:lang="en" level="a"><title level="m">{$rec/*:work/text()}</title>&#x20;{$rec/*:citedRangeWork/text()}</title>
  let $staticTitleStmt := $projectConfig/*:configuration/*:staticMetadata/*:titleStmtStatic/*[not(self::*:respStmt)]
  let $staticRespStmt := $projectConfig/*:configuration/*:staticMetadata/*:titleStmtStatic/*:respStmt
  let $addedByLookupSeq := tokenize(normalize-space($rec/*:added_by/text()), "#")
  let $addedByData := for $adder in $addedByLookupSeq
    for $creator in $projectConfig/*:configuration/*:creatorLookup/*:creator
      return if($adder = normalize-space($creator/*:lookupString/text())) then $creator else()
  let $lookupEditors := $addedByData/*:editor
  let $lookupRespStmts := $addedByData/*:respStmt
  let $titleStmt := <titleStmt xmlns="http://www.tei-c.org/ns/1.0">{$docTitle, $staticTitleStmt, $lookupEditors, $staticRespStmt[1], $lookupRespStmts, $staticRespStmt[2]}</titleStmt>
  
  let $editionStmt := $projectConfig/*:configuration/*:staticMetadata/*:editionStmtStatic/*
  let $publicationStmtStatic := $projectConfig/*:configuration/*:staticMetadata/*:publicationStmtStatic/*
  let $publicationStmt := local:create-publicationStmt($uri, $publicationStmtStatic)
  let $seriesStmt := $projectConfig/*:configuration/*:staticMetadata/*:seriesStmtStatic/*
  let $sourceDesc := $projectConfig/*:configuration/*:staticMetadata/*:sourceDescStatic/*
  let $fileDesc := <fileDesc xmlns="http://www.tei-c.org/ns/1.0">{$titleStmt, $editionStmt, $publicationStmt, $seriesStmt, $sourceDesc}</fileDesc>
  
  let $encodingDesc := $projectConfig/*:configuration/*:staticMetadata/*:encodingDescStatic/*
  let $profileDesc := local:create-profileDesc($rec, $projectConfig)
  let $revisionDesc := <revisionDesc xmlns="http://www.tei-c.org/ns/1.0" status="draft"><change who="{$projectConfig/*:configuration/*:editorUri/text()}" when="{fn:current-date()}">CREATED: testimonium</change></revisionDesc>
  return <teiHeader xmlns="http://www.tei-c.org/ns/1.0">{$fileDesc, $encodingDesc, $profileDesc, $revisionDesc}</teiHeader>
  (:
  - encodingDesc
  - profileDesc !!
  :)
};

declare function local:create-publicationStmt($uri, $staticMetadata) {
  let $docUri := $uri||"/tei"
  return 
  <publicationStmt xmlns="http://www.tei-c.org/ns/1.0">
    {$staticMetadata/*:authority}
    <idno type="URI">{$docUri}</idno>
        {$staticMetadata/*:availability}
        <date>{fn:current-date()}</date>
  </publicationStmt>
};
declare function local:create-profileDesc($rec, $projectConfig) {
  let $origDate := local:create-origDate($rec/*:creationDate/text())
  let $creation := if($rec/*:workAuthor/text() != '') then <creation xmlns="http://www.tei-c.org/ns/1.0">This entry is taken from <title ref="{$rec/*:workUrn/text()}" type="uniform" level="m">{$rec/*:work/text()}</title> <ref target="#bib{$rec/*:uri/text()}-1">{$rec/*:citedRangeWork/text()}</ref> written by <persName ref="{$rec/*:sourceUriWorkAuthor/text()}" role="author">{$rec/*:workAuthor/text()}</persName> in {$origDate}. This work was likely written in <origPlace ref="{$rec/*:creationLocationUri/text()}">{$rec/*:creationLocation/text()}</origPlace>.</creation>
  else <creation xmlns="http://www.tei-c.org/ns/1.0">This entry is taken from <title ref="{$rec/*:workUrn/text()}" type="uniform" level="m" xml:lang="en">{$rec/*:work/text()}</title> <ref target="#bib{$rec/*:uri/text()}-1">{$rec/*:citedRangeWork/text()}</ref> written in {$origDate}. This work was likely written in <origPlace ref="{$rec/*:creationLocationUri/text()}">{$rec/*:creationLocation/text()}</origPlace>.</creation>       
  let $language := for $lang in $projectConfig/*:configuration/*:langUsageTable/*:language
    where string($lang/@ident) = $rec/*:workLang/text()
    return $lang
  let $langUsage := <langUsage xmlns="http://www.tei-c.org/ns/1.0">{$language}</langUsage>
  let $classCode := <classCode xmlns="http://www.tei-c.org/ns/1.0" scheme="https://distributed-text-services.github.io/specifications/"><idno xml:base="{$rec/*:workUriBase/text()}" type="CTS-URN">{$rec/*:workUrn/text()||":"||$rec/*:citedRangeWork/text()}</idno></classCode>
  return <profileDesc xmlns="http://www.tei-c.org/ns/1.0">
    <abstract><p/></abstract>
    {$creation, $langUsage}
    <textClass>
      {$classCode}
      {if ($rec/*:catRef/text() != "") then <catRef scheme="#CM-NEAEH" target="#{$rec/*:catRef/text()}"/> else()}
    </textClass>
    </profileDesc>
};

declare function local:create-origDate($origDateString){
  (:Requires dates of one of these three forms: "93 BCE", "93 - 94 CE", "3 BCE - 5 CE":)
   let $origDateSet := tokenize($origDateString, " ")
   let $origDateAttr := local:create-origDate-attributes($origDateSet)
   let $origDate := if (count($origDateSet) = 2) then <origDate when="{$origDateAttr[1]}" xmlns="http://www.tei-c.org/ns/1.0"><date>{$origDateString}</date></origDate>
   else <origDate notBefore="{$origDateAttr[1]}" notAfter="{$origDateAttr[2]}" xmlns="http://www.tei-c.org/ns/1.0">{$origDateString}</origDate>
   return $origDate
};

declare function local:create-origDate-attributes($dateSet){
  
  let $dateLowVal := $dateSet[1]
  let $dateLowEra := if(count($dateSet)=2) then $dateSet[2]
    else if(count($dateSet)=4) then $dateSet[4]
    else if(count($dateSet)=5) then $dateSet[2]
  let $dateHighVal := if(count($dateSet)=2) then ""
    else if(count($dateSet)=4) then $dateSet[3]
    else if(count($dateSet)=5) then $dateSet[4]
  let $dateHighEra := if(count($dateSet)=2) then ""
    else if(count($dateSet)=4) then $dateSet[4]
    else if(count($dateSet)=5) then $dateSet[5]
  let $dateLowAttr := local:create-date-attribute($dateLowVal, $dateLowEra)
  let $dateHighAttr := local:create-date-attribute($dateHighVal, $dateHighEra)
  return ($dateLowAttr, $dateHighAttr)
};

declare function local:create-date-attribute($dateVal, $dateEra){
  let $countDigits := count(functx:chars($dateVal))
  let $leadingZeroes := if($countDigits=1) then "000" else if ($countDigits = 2) then "00" else if ($countDigits=3) then "0" else ()
  return if($dateEra = "CE") then $leadingZeroes||$dateVal else if($dateEra="BCE") then "-"||$leadingZeroes||$dateVal
};

declare function local:create-teiBody($rec, $uri){
  let $docId := fn:substring-after($uri, "testimonia/")
  (: Extracting and assigning data from TSV record :)
  let $editionText := $rec/*:edition1/text()
  let $editionTypoCorr := $rec/*:edition1_typosCorrected/text()
  let $translationText :=$rec/*:translation1/text()
  let $translationTypoCorr := $rec/*:translation1_typosCorrected/text()
  let $workTitle := $rec/*:work/text()
  let $workUrn := $rec/*:workUrn/text()
  let $workSection := $rec/*:citedRangeWork/text()
  let $authorString := $rec/*:workAuthor/text()
  let $authorUri := $rec/*:sourceUriWorkAuthor/text()
  let $editionLang := $rec/*:edition1Lang/text()
  let $translationLang := $rec/*:translation1Lang/text()
  let $editionUri := $rec/*:edition1SourceUri/text()
  let $editionCitedRange := $rec/*:edition1CitedRange/text()
  let $translationUri := $rec/*:translation1SourceUri/text()
  let $translationCitedRange := $rec/*:translation1CitedRange/text()
  let $editionPrintUri := $rec/*:printedEdition1Uri/text()
  let $translationPrintUri := $rec/*:printedTranslation1Uri/text()
  
  (:creating components of the teiBody:)
  let $identifier := <ab type="identifier" xmlns="http://www.tei-c.org/ns/1.0"><idno type="URI">{$uri}</idno></ab>
  let $abstractText := if($rec/*:isIndirectReference/text() != "") then "indirect" else ()
  let $abstract := <desc type="abstract" xmlns="http://www.tei-c.org/ns/1.0">{$abstractText}</desc>(: local:create-abstract($docId, $editionText, $translationText, $workTitle, $workUrn, $workSection, $authorString, $authorUri) :)
  let $editionAnchor := if($editionText != "" and $translationText != "") then <anchor xmlns="http://www.tei-c.org/ns/1.0" xml:id="testimonia-{$docId}.{$editionLang}.1" corresp="testimonia-{$docId}.{$translationLang}.1"/> else ()
  let $translationAnchor := if($editionText != "" and $translationText != "") then <anchor xmlns="http://www.tei-c.org/ns/1.0" xml:id="testimonia-{$docId}.{$translationLang}.1" corresp="testimonia-{$docId}.{$editionLang}.1"/> else ()
  let $edition := local:create-quote($docId, "edition", $editionText, $editionLang, $editionTypoCorr, $editionAnchor)
  let $translation := local:create-quote($docId, "translation", $translationText, $translationLang, $translationTypoCorr, $translationAnchor)
  
  let $bibls := local:create-listBibl($docId, $editionUri, $editionCitedRange, $translationUri, $translationCitedRange, $editionPrintUri, $translationPrintUri)
  return <text xmlns="http://www.tei-c.org/ns/1.0">
    <body>{$identifier, $abstract, $edition, $translation, $bibls}
    </body>
   </text>
};
(: 
Note: This function has been separated into its own update script.

declare function local:create-abstract($docId, $edition, $translation, $workTitle, $workUrn, $workSection, $authorString, $authorUri){
  let $namesListEdition := for $name at $pos in fn:tokenize($edition, "\$")[position()>1]
    return fn:substring-before($name, "%")
  let $namesListTranslation := for $name at $pos in fn:tokenize($translation, "\$")[position()>1]
    return fn:substring-before($name, "%")
  let $namesList := functx:value-union($namesListEdition, $namesListTranslation)
  let $citationUrn := $workUrn||":"||$workSection
  let $placeNameSequence := local:create-placeNames-sequence($namesList)
  return if ($authorString != '') then <desc type="abstract" xml:id="abstract{$docId}-1" xmlns="http://www.tei-c.org/ns/1.0">The following place names are attested in <persName role="author" ref="{$authorUri}">{$authorString}</persName>&apos;s <title ref="{$citationUrn}">{$workTitle}</title> {$workSection}: {$placeNameSequence}</desc>
  else <desc type="abstract" xml:id="abstract{$docId}-1" xmlns="http://www.tei-c.org/ns/1.0">The following place names are attested in <title ref="{$citationUrn}">{$workTitle}, {$workSection}</title>: {$placeNameSequence}</desc>
}; :)

declare function local:create-placeNames-sequence($namesSequence){
  let $numNames := count($namesSequence)
  let $nameElementSequence := for $name in $namesSequence
    return <placeName xmlns="http://www.tei-c.org/ns/1.0">{$name}</placeName>
  return $nameElementSequence
};

declare function local:create-quote($docId, $quoteType, $quoteText, $quoteLang, $typoCorr, $anchor) {
  let $sourceBase := "#bib"||$docId||"-"
  let $quoteSeq := if($quoteType = "edition") then "1" else "2"
  let $quoteId := "quote"||$docId||"-"||$quoteSeq
  let $sourceAttr := $sourceBase||$quoteSeq
  return if ($quoteText != '') then <ab type="{$quoteType}" xml:lang="{$quoteLang}" xml:id="{$quoteId}" source="{$sourceAttr}" xmlns="http://www.tei-c.org/ns/1.0">
{
  $anchor,
  let $substringList := for $subString at $pos in fn:tokenize($quoteText, "\$")
    return fn:tokenize($subString, "%")
    for $subString at $pos in $substringList
      return if($pos mod 2 != 0) then $subString
      else <placeName xml:lang="{$quoteLang}">{$subString}</placeName>

}
{if ($typoCorr != '') then <note type="corrigenda" xmlns="http://www.tei-c.org/ns/1.0">Inaccuracies found in the transcription of the electronic text compared to its printed source have been corrected.</note>}</ab>
  else ()
};

declare function local:create-bibl($docId, $uri, $citedRange, $seq as xs:string?){
  let $biblId := "bib"||$docId||"-"||$seq
  return if (fn:substring-after($uri, "bibl/") = '') then ()
  else if ($seq != "") then 
  <bibl xml:id="{$biblId}" xmlns="http://www.tei-c.org/ns/1.0">
    <ptr target="{$uri}"/>
    <citedRange>{$citedRange}</citedRange>
  </bibl>
  else 
  <bibl xmlns="http://www.tei-c.org/ns/1.0">
    <ptr target="{$uri}"/>
    <citedRange>{$citedRange}</citedRange>
  </bibl>
};

declare function local:create-listBibl($docId, $editionUri, $editionCitedRange, $translationUri, $translationCitedRange, $editionPrintUri, $translationPrintUri){
  let $editionBibl := local:create-bibl($docId, $editionUri, $editionCitedRange, "1")
  let $translationBibl := local:create-bibl($docId, $translationUri, $translationCitedRange, "2")
  let $editionPrintBibl := local:create-bibl($docId, $editionPrintUri, $editionCitedRange, "")
  let $translationPrintBibl := local:create-bibl($docId, $translationPrintUri, $translationCitedRange, "")
  
  return (<listBibl xmlns="http://www.tei-c.org/ns/1.0">{$editionBibl, $translationBibl}</listBibl>, <listBibl xmlns="http://www.tei-c.org/ns/1.0">{$editionPrintBibl, $translationPrintBibl}</listBibl>)
};
(:
****************
START MAIN QUERY
****************
Link data from config files
Project config stores metadata for the XML records, such as editor strings, URI bases, etc.
Local config stores paths and options for linking in the TSV input, creating the output directory, and so forth
:)
let $configDirectoryUrl := "processTsvData/"
let $localConfig := doc($configDirectoryUrl||"configLocal.xml")
let $projectConfig := doc($configDirectoryUrl||"configProject.xml")

let $inputFileString := $localConfig/configuration/inputFileUri/text()(:The input CSV file should have a header row. :)
let $delimiter := $localConfig/configuration/delimiter/text()
let $outputPath := $localConfig/configuration/outputPath/text()

(:reading in CSV data:)
let $inputFile := file:read-text($inputFileString)
let $xmlFile := csv:parse($inputFile, map{"header": "true", "separator": $delimiter, "quotes": "no"})
let $nothing := file:create-dir($outputPath)

let $uriBase := $projectConfig/configuration/uriBase/text()
(:looping through csv data:)
for $rec in $xmlFile/csv/record
  (: where $rec/*:uri/text() = 2 :)(: for testing a single record; comment out if running on directory:)
  let $docUri := $uriBase||$rec/uri/text()
  let $teiHeader := local:create-teiHeader($rec, $docUri, $projectConfig)
  let $teiBody := local:create-teiBody($rec, $docUri)
  let $doc := document {
    processing-instruction xml-model {
        'type="application/xml" href="http://www.tei-c.org/release/xml/tei/custom/schema/relaxng/tei_all.rng" schematypens="http://relaxng.org/ns/structure/1.0"'
    },
    <TEI xmlns="http://www.tei-c.org/ns/1.0">{$teiHeader, $teiBody}</TEI>
}
  return file:write($outputPath||$rec/uri/text()||'.xml',  $doc, map { 'omit-xml-declaration': 'no'})
