xquery version "3.0";

import module namespace cmproc="http://wlpotter.github.io/ns/cmproc" at "cmproc.xqm";
import module namespace config="http://wlpotter.github.io/ns/cm/config" at "config.xqm";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace csv = "http://basex.org/modules/csv";

for $doc in $config:input-collection
let $docId := $doc//publicationStmt/idno/text()
let $docId := substring-after($docId, $config:project-uri-base)
let $docId := substring-before($docId, "/tei")
let $abstract := cmproc:create-abstract($doc//profileDesc/creation, $doc//ab/placeName, string($doc//catRef[@scheme="#CM-Testimonia-Type"]/@target), $docId)
return replace node $doc//desc[@type="abstract"] with $abstract
(: return $abstract :)