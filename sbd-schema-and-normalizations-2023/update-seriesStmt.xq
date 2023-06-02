xquery version "3.1";
import module namespace functx = "http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare option output:omit-xml-declaration "no";
declare option output "indent=no";

declare variable $local:sbd-series :=
<seriesStmt>
    <title level="s" xml:lang="en">The Syriac Biographical Dictionary</title>
    <editor role="general" ref="http://syriaca.org/documentation/editors.xml#ngibson">Nathan P. Gibson</editor>
    <editor role="general" ref="http://syriaca.org/documentation/editors.xml#dmichelson">David A. Michelson</editor>
    <editor role="general" ref="http://syriaca.org/documentation/editors.xml#jnsaint-laurent">Jeanne-Nicole Mellon Saint-Laurent</editor>
    <editor role="general" ref="http://syriaca.org/documentation/editors.xml#dschwartz">Daniel L. Schwartz</editor>
    <idno type="URI">http://syriaca.org/persons</idno>
</seriesStmt>;

declare variable $local:gateway-series-stmt :=
<seriesStmt>
  <title level="s">Gateway to the Syriac Saints</title>
  <editor role="general" ref="http://syriaca.org/documentation/editors.xml#jnsaint-laurent">Jeanne-Nicole Mellon Saint-Laurent</editor>
  <idno type="URI">http://syriaca.org/saints</idno>
</seriesStmt>;

declare variable $local:qadishe-series-stmt :=
<seriesStmt>
    <title level="m">Qadishe: A Guide to the Syriac Saints</title>
    <editor role="general" ref="http://syriaca.org/documentation/editors.xml#wpotter">Will Potter</editor>
    <editor role="general" ref="http://syriaca.org/documentation/editors.xml#dmichelson">David A. Michelson</editor>
    <editor role="general" ref="http://syriaca.org/documentation/editors.xml#jnsaint-laurent">Jeanne-Nicole Mellon Saint-Laurent</editor>
    <idno type="URI">http://syriaca.org/q</idno>
</seriesStmt>;

declare variable $local:authors-series-stmt :=
<seriesStmt>
  <title level="m">A Guide to Syriac Authors</title>
  <editor role="general" ref="http://syriaca.org/documentation/editors.xml#ngibson">Nathan P. Gibson</editor>
  <editor role="general" ref="http://syriaca.org/documentation/editors.xml#dmichelson">David A. Michelson</editor>
  <idno type="URI">http://syriaca.org/authors</idno>
</seriesStmt>;

declare variable $local:in-coll := collection("/home/arren/Documents/GitHub/srophe-app-data/data/persons/");

for $doc in $local:in-coll
where not(contains(document-uri($doc), "SyriacaPersons.xpr")) (: ignore the .xpr file :)
let $newSeriesStmt := $local:sbd-series
let $newSeriesStmt := 
  if(contains($doc//text/body/listPerson/person/@ana/string(), "syriaca-saint")) then
    ($newSeriesStmt, $local:gateway-series-stmt, $local:qadishe-series-stmt)
  else
    $newSeriesStmt
let $newSeriesStmt := 
  if(contains($doc//text/body/listPerson/person/@ana/string(), "syriaca-author")) then
    ($newSeriesStmt, $local:authors-series-stmt)
  else
    $newSeriesStmt
(: where $doc//publicationStmt/idno/text() = "http://syriaca.org/person/3728/tei" :) (: comment in or out for testing purposes :)
return 
  (delete node $doc//seriesStmt,
   insert node $newSeriesStmt after $doc//publicationStmt
 )