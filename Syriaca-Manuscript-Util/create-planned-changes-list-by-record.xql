xquery version "3.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare default element namespace "http://www.tei-c.org/ns/1.0";

import module namespace functx = "http://www.functx.com";

let $dataUri := "C:/Users/anoni/Documents/GitHub/srophe/wright-catalogue/data/5_finalized/"
let $dataUri := fn:replace($dataUri, "\\", "/")
for $doc in fn:collection($dataUri)
  let $docId := $doc//msIdentifier/idno/text()
  let $plannedChanges := $doc//change[@type="planned"]
  return <record id="{$docId}">{for $change in $plannedChanges return <plannedChange>{$change}</plannedChange>}</record>