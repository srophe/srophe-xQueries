xquery version "3.0";

import module namespace cmproc="http://wlpotter.github.io/ns/cmproc" at "cmproc.xqm";
import module namespace config="http://wlpotter.github.io/ns/cm/config" at "config.xqm";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace csv = "http://basex.org/modules/csv";

declare variable $local:edited-records-from-box :=
  collection("/home/arren/Documents/ceasarea-box-files");

let $candidates :=
  for $doc in $local:edited-records-from-box
  let $docUri := $doc//body/ab[@type="identifier"]/idno/text()
  let $textualNote := $doc//body/ab[@type="edition"]/note[@type="textual"]
  let $translationNote := $doc//body/ab[@type="translation"]/note[@type="translation"]
  where not(empty($textualNote)) or not(empty($translationNote))
  
  for $prodDoc in $config:input-collection
  let $prodDocUri := $prodDoc//body/ab[@type="identifier"]/idno/text()
  where $prodDocUri = $docUri
  
  let $prodTextualNote := $prodDoc//body/ab[@type="edition"]/note[@type="textual"]
  let $prodTranslationNote := $prodDoc//body/ab[@type="translation"]/note[@type="translation"]
  
  let $missingTextualNote := ($textualNote and empty($prodTextualNote))
  let $missingTranslationNote := ($translationNote and empty($prodTranslationNote))
  
  return <el><uri>{$docUri}</uri><textNoteMissing>{$missingTextualNote}</textNoteMissing><translationNoteMissing>{$missingTranslationNote}</translationNoteMissing></el>
return $candidates[*/text() = "true"] 
