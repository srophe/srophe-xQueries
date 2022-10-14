xquery version "3.1";
import module namespace functx="http://www.functx.com";

import module namespace cmproc="http://wlpotter.github.io/ns/cmproc" at "cmproc.xqm";
import module namespace config="http://wlpotter.github.io/ns/cm/config" at "config.xqm";

declare default element namespace "http://www.tei-c.org/ns/1.0";


for $doc in $config:input-collection
let $docId := substring-after($doc//ab[@type="identifier"]/idno/text(), $config:testimonia-uri-base)
let $edition := $doc//ab[@type="edition"]
let $edition := cmproc:add-source-ab-to-excerpt($edition, $docId, "1")
let $edition := functx:remove-attributes($edition, "source")
let $translation := $doc//ab[@type="translation"]
let $translation := if($doc//body/listBibl[1]/bibl[2]/ptr/@target !="") then cmproc:add-source-ab-to-excerpt($translation, $docId, "2") else $translation
let $translation := if($translation) then functx:remove-attributes($translation, "source") else $translation
return (replace node $doc//ab[@type="edition"] with $edition,
        if($translation) then replace node $doc//ab[@type="translation"] with $translation else ())