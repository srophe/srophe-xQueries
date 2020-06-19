xquery version "3.0";
declare default element namespace "http://www.tei-c.org/ns/1.0";
import module "http://www.functx.com";
declare option output:omit-xml-declaration "no";
declare option output:indent "no";

(:
This script adds CTS-URNs to tei:idno elements nested within the translation and edition tei:quote elements of Caesarea-Maritima.org testimonia records. These CTS-URNs are based on the machine readable sources stored in Caesarea-Maritima.org's bibl module. The CTS-URN is accompanied by an @xml:base attribute which, when concatenated with the URN, should create a URI that resolves to the excerpted portion of the text in another database, e.g. Perseus Digital Library.

Known issues:
- Given that not all testimonia records on Caesarea-Maritma.org have a CTS-URN for both their edition and translation, this script may return an empty text node or, if there is no URL/API base available, an empty @xml:base attribute. In such cases, these elements will need to be edited by hand. See https://github.com/srophe/caesarea/issues/72

@author: William L. Potter
@version 1.0
:)

let $collectionUri := "/Users/michelda/Documents/GitHub/srophe/srophe-xQueries/Caesarea-Testimonia-Tsv-Transforms/processTsvOutput/tsvOutput-2020-06-19"
let $jsonUri := "/Users/michelda/Documents/GitHub/srophe/srophe-xQueries/Caesarea-Testimonia-Tsv-Transforms/processTsvData/Caesarea-Maritima-Bibl-Module.json"
let $jsonFile := file:read-text($jsonUri)
let $json := json:parse($jsonFile)

for $doc in fn:collection($collectionUri)
  where not($doc/TEI/text/body/ab[@type="edition"]/idno) or not($doc/TEI/text/body/ab[@type="translation"]/idno)
  let $xmlBase := $doc/TEI/teiHeader/profileDesc/textClass/classCode/idno/@xml:base
  let $xmlBaseEdited := if ($xmlBase != "https://scaife-cts.perseus.org/api/cts?request=GetPassage&amp;urn=") then $xmlBase else "https://scaife.perseus.org/reader/"
  let $citedRange := $doc/TEI/teiHeader/profileDesc/creation/ref/text()
  let $editionBiblId := substring-after(string($doc/TEI/text/body/ab[@type="edition"]/@source), "#")
  let $editionBiblZoteroId := substring-after(string($doc/TEI/text/body/listBibl/bibl[@xml:id=$editionBiblId]/ptr/@target), "bibl/")
  let $editionUrn := for $bibl in $json/*:json/*:_
    where substring-after($bibl/*:id/text(), "items/") = $editionBiblZoteroId
    return if (substring-after($bibl/*:URL/text(), "urn:cts:") != "") then "urn:cts:"||substring-after($bibl/*:URL/text(), "urn:cts:") else ()
  let $editionUrnClean := if (substring($editionUrn, string-length($editionUrn)) = "/") then substring($editionUrn, 1, string-length($editionUrn)-1) else $editionUrn
  let $editionIdno := if ($editionUrnClean != "") then <idno xml:base="{$xmlBaseEdited}">{$editionUrnClean||":"||$citedRange}</idno> else <idno xml:base="{$xmlBaseEdited}"/>
  
  let $translationBiblId := substring-after(string($doc/TEI/text/body/ab[@type="translation"]/@source), "#")
  let $translationBiblZoteroId := substring-after(string($doc/TEI/text/body/listBibl/bibl[@xml:id=$translationBiblId]/ptr/@target), "bibl/")
  let $translationUrn := for $bibl in $json/*:json/*:_
    where substring-after($bibl/*:id/text(), "items/") = $translationBiblZoteroId
    return if (substring-after($bibl/*:URL/text(), "urn:cts:") != "") then "urn:cts:"||substring-after($bibl/*:URL/text(), "urn:cts:") else ()
  let $translationUrnClean := if (substring($translationUrn, string-length($translationUrn)) = "/") then substring($translationUrn, 1, string-length($translationUrn)-1) else $translationUrn
  let $translationIdno := if ($translationUrnClean != "") then <idno xml:base="{$xmlBaseEdited}">{$translationUrnClean||":"||$citedRange}</idno> else <idno xml:base="{$xmlBaseEdited}"/>
  return if ($doc/TEI/text/body/ab[@type="edition"] and $doc/TEI/text/body/ab[@type="translation"]) then
   (if (not($doc/TEI/text/body/ab[@type="edition"]/idno)) then insert node $editionIdno as last into $doc/TEI/text/body/ab[@type="edition"] else (), 
   if (not($doc/TEI/text/body/ab[@type="translation"]/idno)) then insert node $translationIdno as last into $doc/TEI/text/body/ab[@type="translation"] else ())
   else if ($doc/TEI/text/body/ab[@type="edition"] and not($doc/TEI/text/body/ab[@type="edition"]/idno)) then insert node $editionIdno as last into $doc/TEI/text/body/ab[@type="edition"]
   else if (not($doc/TEI/text/body/ab[@type="translation"]/idno)) then insert node $translationIdno as last into $doc/TEI/text/body/ab[@type="translation"]
   