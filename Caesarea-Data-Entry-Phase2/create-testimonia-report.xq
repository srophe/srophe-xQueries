xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";


declare variable $local:current-testimonia :=
  collection("/home/arren/Documents/GitHub/caesarea-data/data/testimonia/tei/");
  

let $recs :=
  for $doc in $local:current-testimonia
  let $uri := $doc//body/ab[@type="identifier"]/idno/text()
  let $id := substring-after($uri, "/testimonia/")
  let $workTitle := normalize-space($doc//creation/title/text())
  let $workUrn := $doc//creation/title/@ref/string()
  
  let $range := normalize-space($doc//creation/ref/text())
  
  let $authorName := normalize-space($doc//creation/persName[@role="author"]/text())
  let $authorUri := $doc//creation/persName[@role="author"]/@ref/string()
  
  let $dateText := normalize-space($doc//creation/origDate/text())
  let $dateNotBefore := $doc//creation/origDate/@notBefore/string()
  let $dateNotAfter := $doc//creation/origDate/@notAfter/string()
  let $dateWhen := $doc//creation/origDate/@when/string()
  
  let $dateMachineReadable := if($dateWhen != "") then $dateWhen else $dateNotBefore||"/"||$dateNotAfter
  
  let $placeText := normalize-space($doc//creation/origPlace/text())
  let $placeUri := $doc//creation/origPlace/@ref/string()
  
  let $origLang := $doc//langUsage/language[@ana="#caesarea-language-of-original"]/text()
  let $testLang := $doc//langUsage/language[@ana="#caesarea-language-of-testimonia"]/text()
  
  let $revisionStatus := $doc//revisionDesc/@status/string()
  
  return
  <rec>
    <id>{$id}</id>
    <uri>{$uri}</uri>
    <workTitle>{$workTitle}</workTitle>
    <workURN>{$workUrn}</workURN>
    <workRange>{$range}</workRange>
    <authorName>{$authorName}</authorName>
    <authorUri>{$authorUri}</authorUri>
    <dateLabel>{$dateText}</dateLabel>
    <dateMachineReadable>{$dateMachineReadable}</dateMachineReadable>
    <origPlaceText>{$placeText}</origPlaceText>
    <origPlaceUri>{$placeUri}</origPlaceUri>
    <languageOfOriginal>{$origLang}</languageOfOriginal>
    <languageOfTestimonia>{$testLang}</languageOfTestimonia>
    <revisionStatus>{$revisionStatus}</revisionStatus>
  </rec>
  
return csv:serialize(<csv>{$recs}</csv>, map {"header": "yes"})
(:
author
author uri
title
title uri
range
date
date attrs?
place
place uri
:)