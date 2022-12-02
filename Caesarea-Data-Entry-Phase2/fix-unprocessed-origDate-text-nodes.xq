xquery version "3.0";

import module namespace cmproc="http://wlpotter.github.io/ns/cmproc" at "cmproc.xqm";
import module namespace config="http://wlpotter.github.io/ns/cm/config" at "config.xqm";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace csv = "http://basex.org/modules/csv";

for $doc in $config:input-collection
let $docUri := $doc//body/ab[@type="identifier"]/idno/text()
let $origDate := $doc//profileDesc/creation/origDate
where starts-with($origDate/text(), "0")
return replace node $doc//profileDesc/creation/origDate with  cmproc:post-process-origDate($origDate)
(: return cmproc:post-process-origDate($origDate) :)