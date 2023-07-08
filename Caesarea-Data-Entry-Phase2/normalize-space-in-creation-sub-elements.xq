xquery version "3.0";

import module namespace cmproc="http://wlpotter.github.io/ns/cmproc" at "cmproc.xqm";
import module namespace config="http://wlpotter.github.io/ns/cm/config" at "config.xqm";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace csv = "http://basex.org/modules/csv";

for $doc in $config:input-collection
let $docUri := $doc//body/ab[@type="identifier"]/idno/text()
(:
normalize the whitespace in sub-elements of tei:creation
:)
for $child in $doc//creation/*
return 
  try {
  replace value of node $child with normalize-space($child/text())
   }
 catch* 
  {
    let $failure :=
      element {"failure"} {
        element {"code"} {$err:code},
        element {"description"} {$err:description},
        element {"value"} {$err:value},
        element {"module"} {$err:module},
        element {"location"} {$err:line-number||": "||$err:column-number},
        element {"additional"} {$err:additional},
        cmproc:get-record-context($doc, "Failure: file not written to disk")
      }
      return update:output($failure)
  }
(: return $abstract :)