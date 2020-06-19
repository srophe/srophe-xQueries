xquery version "3.0";
import module namespace functx = "http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare option output:omit-xml-declaration "no";
declare option output:method "csv";
declare option output:csv "header=yes, separator=comma, quotes=yes";
(:
This script generates a csv table of Syriaca.org person URIs matched to their corresponding e-GEDSH URIs and VIAF identifiers. 
The XML file for GEDSH is retrieved via an HTTP URI, but the Syriaca persons URI list is generated from a local clone of the data repository available on GitHub: https://github.com/srophe/srophe-app-data

Note that at this time the e-GEDSH project is planning to break out the GEDSH entries into individual TEI XML files, in which case the HTTP retrieval of the GEDSH file using fn:doc will likely break.

@author: William L. Potter
@version: 1.0
:)
(:e-Gedsh http request:)
let $gedshFull := fn:doc('https://raw.githubusercontent.com/srophe/e-gedsh/master/data/tei/eGEDSH-1.0.xml.xml')
let $dataRepositoryUri := "C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\persons\tei\"
let $uriList := <personList>{
  for $doc in fn:collection($dataRepositoryUri)
  let $syriacaUri := $doc//text/body/listPerson/person/idno[@type="URI"][1]/text()
  let $viafIdSeq := for $viafId in $doc//text/body/listPerson/person/idno[@type="URI"]/text()
    where fn:contains($viafId, "viaf.org")
    return if(not(fn:contains($viafId, "/sourceID/SRP|person_"))) then fn:substring-after($viafId, ".org/viaf/") else ()
  let $viafIdStr := fn:string-join($viafIdSeq, "|")
  return <person>
    <syriacaUri>{$syriacaUri}</syriacaUri>
    <viafIdString>{$viafIdStr}</viafIdString>
  </person>
}
 </personList>
 
let $csv := <csv>{
  for $person in $uriList/person
  
  let $gedshUri := for $entry in $gedshFull//text/body/div[@type="entry"]
    where ($entry/ab[@type="idnos"]/idno[@type="subject"]/text() = $person/syriacaUri/text())
    return $entry/ab[@type="idnos"]/idno[@type="URI"]/text()
    
  return <record>{
    $person/*,
    <gedshUri>{$gedshUri}</gedshUri>
  }</record>
  
}
</csv>
return $csv