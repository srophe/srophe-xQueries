xquery version "3.0";
import module namespace functx = "http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare option output:omit-xml-declaration "no";
declare option output "indent=no";

let $newRespStmts := (
<respStmt>
    <resp>Record validation, normalization, and revisions for the second edition (2.0) by</resp>
    <name ref="http://syriaca.org/documentation/editors.xml#dmichelson">David A. Michelson</name>
</respStmt>,
<respStmt>
    <resp>Record validation, normalization, and revisions for the second edition (2.0) by</resp>
    <name ref="http://syriaca.org/documentation/editors.xml#wpotter">William L. Potter</name>
</respStmt>,
<respStmt>
    <resp>Record validation, normalization, and revisions for the second edition (2.0) by</resp>
    <name ref="http://syriaca.org/documentation/editors.xml#dschwartz">Daniel L. Schwartz</name>
</respStmt>)
let $newEdition := <edition n="2.0"/>

let $inputCollectionUri := "C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\places\tei\"
for $doc in collection($inputCollectionUri)
  return (replace node $doc//editionStmt/edition with $newEdition,
  insert node $newRespStmts as last into $doc//titleStmt)
  
  