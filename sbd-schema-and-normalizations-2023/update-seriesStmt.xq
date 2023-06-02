xquery version "3.0";
import module namespace functx = "http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare option output:omit-xml-declaration "no";
declare option output "indent=no";

let $newSeriesStmt := 
<seriesStmt>
    <title level="s" xml:lang="en">The Syriac Gazetteer</title>
    <editor role="general" ref="http://syriaca.org/documentation/editors.xml#dmichelson">
        <persName>David A. Michelson</persName>, <date from="2014">2014-present</date>.</editor>
    <editor role="general" ref="http://syriaca.org/documentation/editors.xml#wpotter">
        <persName>William L. Potter</persName>, <date from="2020">2020-present</date>.</editor>
    <editor role="past-general" ref="http://syriaca.org/documentation/editors.xml#tcarlson">
        <persName>Thomas A. Carlson</persName>, <date from="2014" to="2018">2014-2018</date></editor>
    <editor role="technical" ref="http://syriaca.org/documentation/editors.xml#dmichelson">
        <persName>David A. Michelson</persName>, <date from="2014">2014-present</date>.</editor>
    <editor role="technical" ref="http://syriaca.org/documentation/editors.xml#dschwartz">
    <persName>Daniel L. Schwartz</persName>, <date from="2019">2019-present</date>.</editor>
    <editor role="technical" ref="http://syriaca.org/documentation/editors.xml#wpotter">
        <persName>William L. Potter</persName>, <date from="2020">2020-present</date>.</editor>
    <idno type="URI">http://syriaca.org/geo</idno>
</seriesStmt>

let $inputCollectionUri := "C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\places\tei\"
for $doc in collection($inputCollectionUri)
  return 
  (delete node $doc/TEI/teiHeader/fileDesc/titleStmt/title[@level="m"],
  delete node $doc//TEI/teiHeader/fileDesc/titleStmt/editor[@role="general"],
  if(empty($doc//seriesStmt)) then insert node $newSeriesStmt after $doc//publicationStmt
   else replace node $doc//seriesStmt with $newSeriesStmt)