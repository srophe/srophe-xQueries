xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:path-to-repo := "/home/arren/Documents/GitHub/syriaca-data/";
declare variable $local:input-collection := collection($local:path-to-repo||"data/places/tei/");


for $doc in $local:input-collection
let $reverseRespStmts := 
  for $respStmt at $i in $doc/TEI/teiHeader/fileDesc/titleStmt/respStmt
  order by $i descending
  return $respStmt

return (
  delete node $doc/TEI/teiHeader/fileDesc/titleStmt/respStmt,
  insert node $reverseRespStmts as last into $doc/TEI/teiHeader/fileDesc/titleStmt
)