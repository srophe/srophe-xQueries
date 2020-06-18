xquery version "3.0";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";
declare option output:omit-xml-declaration "no";
declare option output:indent "no";

(:
This script generates an abstract for Caesarea-Maritima.org Testimonia records based upon information encoded in the records' tei:profileDesc and the entities tagged as tei:placeName elements in the testimonia excerpts.

@author: William L. Potter
@version 1.0
:)

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
 
declare function local:create-abstract($doc){
  let $docId := fn:substring-after($doc//body/ab[@type="identifier"]/idno/text(), "testimonia/")
  let $placeNameSeq := functx:distinct-deep(for $placeName in $doc//body/ab/placeName
    return <quote>{$placeName}</quote>)
  let $author := $doc//profileDesc/creation/persName[@role="author"]
  let $title := $doc//profileDesc/creation/title[@type="uniform"]
  let $citedRange := $doc//profileDesc/creation/ref/text()
  let $origDate := $doc//profileDesc/creation/origDate
  let $origPlace := $doc//profileDesc/creation/origPlace
  return if ($author/text() != "") then <desc type="abstract" xml:id="abstract{$docId}-1">{for $name in $placeNameSeq return if ($name = $placeNameSeq[last()] and count($placeNameSeq) != 1) then ("and ", $name) else ($name, ", ")} are place names attested in {$author}&apos;s {$title}&#x20;{$citedRange}. This testimonium was written circa&#x20;{$origDate}. This work was likely written in&#x20;{$origPlace}.</desc>
  else <desc type="abstract" xml:id="abstract{$docId}-1">{for $name in $placeNameSeq return if ($name = $placeNameSeq[last()]) then ("and ", $name) else ($name, ", ")} are place names attested in {$title}&#x20;{$citedRange}. This testimonium was written circa&#x20;{$origDate}. This work was likely written in&#x20;{$origPlace}.</desc>
};

declare function local:create-indirect-abstract($doc){
  let $docId := fn:substring-after($doc//body/ab[@type="identifier"]/idno/text(), "testimonia/")
  let $author := $doc//profileDesc/creation/persName[@role="author"]
  let $title := $doc//profileDesc/creation/title[@type="uniform"]
  let $citedRange := $doc//profileDesc/creation/ref/text()
  let $origDate := $doc//profileDesc/creation/origDate
  let $origPlace := $doc//profileDesc/creation/origPlace
  return if ($author/text() != "") then <desc type="abstract" xml:id="abstract{$docId}-1">Caesarea Maritima is indirectly attested in {$author}&apos;s {$title}&#x20;{$citedRange}. This testimonium was written circa&#x20;{$origDate}. This work was likely written in&#x20;{$origPlace}.</desc>
  else <desc type="abstract" xml:id="abstract{$docId}-1">Caesarea Maritima is indirectly attested in {$title}&#x20;{$citedRange}. This testimonium was written circa&#x20;{$origDate}. This work was likely written in&#x20;{$origPlace}.</desc>
};

let $inUrl := "C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Caesarea-Testimonia-Tsv-Transforms\processTsvOutput\2020-06-10\"
for $doc in collection($inUrl)
  let $abstract := if($doc/TEI/text/body/desc[@type="abstract"]/text() = "indirect") then local:create-indirect-abstract($doc) else local:create-abstract($doc)
  return replace node $doc//body/desc[@type="abstract"] with $abstract