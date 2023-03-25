xquery version "3.1";

import module namespace functx="http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:input-collection := collection("/home/arren/Documents/GitHub/caesarea-data/data/testimonia/tei/");

declare variable $local:subject-type := "related-texts";

let $subjects := 
  for $doc in $local:input-collection
    (: let $uri := $doc//body/ab[@type="identifier"]/idno/text() :)
  return if ($local:subject-type != "all") then
    for $p in $doc//body/note[@type = $local:subject-type]/p 
      return <rec>{element {$local:subject-type} {normalize-space(string-join($p//text(), " "))}}</rec>
  else
    let $uri := $doc//body/ab[@type="identifier"]/idno/text()
    for $note in $doc//body/note
    let $subjectType := $note/@type/string()
    for $p in $note/p
    let $subject := normalize-space(string-join($p//text(), " "))
    return <rec>
      <uri>{$uri}</uri>
      <subjectType>{$subjectType}</subjectType>
      <subject>{$subject}</subject>
    </rec>

let $subjects := functx:distinct-deep($subjects)
(: return $subjects :)
return csv:serialize(<csv>{$subjects}</csv>, map {"header": "yes"})