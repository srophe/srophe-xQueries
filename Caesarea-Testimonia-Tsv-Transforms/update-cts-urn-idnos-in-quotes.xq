xquery version "3.0";
declare default element namespace "http://www.tei-c.org/ns/1.0";
import module "http://www.functx.com";
declare option output:omit-xml-declaration "no";
declare option output:indent "no";

declare function local:create-idno-and-ref($citationLink){
 let $urn := "urn:cts:"||fn:substring-after($citationLink, "urn:cts:")
 let $urnClean := if ($urn = "urn:cts:") then () else if (substring($urn, string-length($urn)) = "/") then substring($urn, 1, string-length($urn)-1) else $urn
 let $xmlBase := if($urnClean != "") then fn:substring-before($citationLink, "urn:cts:") else ()
 let $xmlBaseEdited := if ($xmlBase != "https://scaife-cts.perseus.org/api/cts?request=GetPassage&amp;urn=") then $xmlBase else "https://scaife.perseus.org/reader/"
 
 return if(empty($xmlBase)) then 
 (<idno xmlns="http://www.tei-c.org/ns/1.0" type="CTS-URN">{$urnClean}</idno>,
 <ref xmlns="http://www.tei-c.org/ns/1.0" target="{$citationLink}"/>)
 else 
 (<idno xmlns="http://www.tei-c.org/ns/1.0" type="CTS-URN" xml:base="{$xmlBaseEdited}">{$urnClean}</idno>,
 <ref xmlns="http://www.tei-c.org/ns/1.0" target="{$citationLink}"/>)
};

let $csvUri := "C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Caesarea-Testimonia-Tsv-Transforms\testimonia-data-simple.csv"
let $options := map {'header': true(), 'separator': ',', 'quotes': 'yes'}
let $dataLookup := csv:parse(file:read-text($csvUri), $options)

let $collectionUri := "C:\Users\anoni\Documents\GitHub\srophe\caesarea-data\data\testimonia\tei\"

for $doc in fn:collection($collectionUri)
  let $docId := fn:substring-after($doc//text/body/ab[@type="identifier"]/idno/text(), "/testimonia/")
  let $matchData := for $row in $dataLookup/*:csv/*:record
    return if (fn:number(fn:normalize-space($row/*:testimoniaID/text())) = fn:number($docId)) then $row
  let $editionLink := $matchData[*:Language/text() = "grc" or *:Language/text() = "la"]/*:Citation_Link/text()
  let $editionIdnoAndRef := local:create-idno-and-ref($editionLink)
  let $translationLink := $matchData[*:Language/text() = "en"]/*:Citation_Link/text()
  let $translationIdnoAndRef := local:create-idno-and-ref($translationLink)
  
 return (if($doc//text/body/ab[@type="edition"]) then if($doc//text/body/ab[@type="edition"]/idno) then replace node $doc//text/body/ab[@type="edition"]/idno with $editionIdnoAndRef
 else insert node $editionIdnoAndRef as last into $doc//text/body/ab[@type="edition"],
 
 if($doc//text/body/ab[@type="translation"]) then  if($doc//text/body/ab[@type="translation"]/idno) then replace node $doc//text/body/ab[@type="translation"]/idno with $translationIdnoAndRef
else insert node $translationIdnoAndRef as last into $doc//text/body/ab[@type="translation"])