xquery version "3.0";
import module namespace functx = "http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare option output:omit-xml-declaration "no";

declare function local:extract-additions-no-msPart($doc as node()) as node()* {
  let $msIdentifier := $doc//msDesc/msIdentifier/*
  let $volPage := $doc//teiHeader/fileDesc/sourceDesc/msDesc/additional/listBibl/bibl/citedRange[@unit="pp"]/text()
  let $sourceTitle := $doc//teiHeader/fileDesc/sourceDesc/msDesc/additional/listBibl/bibl/title/text()
  let $sourceIdnoType := string($doc//teiHeader/fileDesc/sourceDesc/msDesc/additional/listBibl/bibl/@xml:id)||"-PageRange"
  let $sourceBiblUri := string($doc//teiHeader/fileDesc/sourceDesc/msDesc/additional/listBibl/bibl/ptr/@target)
  let $biblIdent := <altIdentifier>
              <collection ref="{$sourceBiblUri}">{$sourceTitle}</collection>
              <idno type="{$sourceIdnoType}">{$doc//teiHeader/fileDesc/sourceDesc/msDesc/additional/listBibl/bibl/citedRange[@unit="pp"]/text()}</idno>
            </altIdentifier>
  let $additions := $doc//msDesc//additions
  return if (not(empty($additions)) and $doc//msDesc/msIdentifier/idno/text() != "http://syriaca.org/manuscript/") then <msDesc xmlns="http://www.tei-c.org/ns/1.0"><msIdentifier>{$msIdentifier, $biblIdent}</msIdentifier>{$additions}</msDesc> else()
};

declare function local:extract-additions-with-msPart($doc as node()) as node()* {
  let $mainMsIdentifier := $doc/TEI/teiHeader/fileDesc/sourceDesc/msDesc/msIdentifier
  let $msParts := for $msPart in $doc/TEI/teiHeader/fileDesc/sourceDesc/msDesc/msPart
    let $msIdentifier := $msPart/msIdentifier/*
    let $volPage := $msPart/additional/listBibl/bibl/citedRange[@unit="pp"]/text()
    let $sourceTitle := $msPart/additional/listBibl/bibl/title/text()
    let $sourceIdnoType := string($msPart/additional/listBibl/bibl/@xml:id)||"-PageRange"
    let $sourceBiblUri := string($msPart/additional/listBibl/bibl/ptr/@target)
    let $biblIdent := <altIdentifier>
              <collection ref="{$sourceBiblUri}">{$sourceTitle}</collection>
              <idno type="{$sourceIdnoType}">{$volPage}</idno>
            </altIdentifier>
    let $additions := $msPart/physDesc/additions[.//text() != ""]
    return if (not(empty($additions)) and $msPart/msIdentifier/idno/text() != "http://syriaca.org/manuscript/") then <msPart xmlns="http://www.tei-c.org/ns/1.0"><msIdentifier>{$msIdentifier, $biblIdent}</msIdentifier>{$additions}</msPart> else()
  return if(not(empty($msParts)) and $mainMsIdentifier//idno[@type="URI"]/text() != "http://syriaca.org/manuscript/") then <msDesc>{$mainMsIdentifier, $msParts}</msDesc> else ()
};

let $inputDirectories := ("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\manuscripts\tei", "C:\Users\anoni\Documents\GitHub\srophe\wright-catalogue\data\4_to_be_checked")
let $allDocs := for $coll in $inputDirectories
  for $doc in fn:collection($coll)
    return $doc
let $colophonDoc := for $doc in $allDocs
  return if (not($doc//msPart)) then local:extract-additions-no-msPart($doc) else local:extract-additions-with-msPart($doc)
return <list>{$colophonDoc}</list>