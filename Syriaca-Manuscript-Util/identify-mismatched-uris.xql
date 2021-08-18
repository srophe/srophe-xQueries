xquery version "3.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare default element namespace "http://www.tei-c.org/ns/1.0";

import module namespace functx = "http://www.functx.com";

let $dataUri := "C:/Users/anoni/Documents/GitHub/srophe/wright-catalogue/data/4_to_be_checked/need-ms-parts/"
let $dataUri := fn:replace($dataUri, "\\", "/")
for $doc in fn:collection($dataUri)
  let $docId := fn:document-uri($doc)
  let $docId := fn:substring-after($docId, $dataUri)
  let $docId := fn:substring-before($docId, ".xml")
  
  let $docUri := $doc//msDesc/msIdentifier/idno/text()
  let $docUri := fn:substring-after($docUri, "manuscript/")
  
  return if($docId != $docUri) then $docId||".xml = "||$docUri
  (: return fn:document-uri($doc)||": "||$doc//msIdentifier/idno/text()||": "||$doc//msIdentifier//idno[@type="BL-Shelfmark"]/text() :)