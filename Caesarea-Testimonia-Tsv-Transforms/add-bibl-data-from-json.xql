xquery version "3.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace json = "http://basex.org/modules/json";
declare namespace functx = "http://www.functx.com";
declare option output:omit-xml-declaration "no";

let $jsonUri := "C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Caesarea-Testimonia-Tsv-Transforms\processTsvData\Caesarea-Maritima-Bibl-Module.json"
let $jsonFile := file:read-text($jsonUri)
let $json := json:parse($jsonFile)
for $item in $json/json/_
  let $notes := $item/note
  let $data := fn:tokenize($notes/text(), "\n")
  for $datum in $data
    where fn:contains($datum, "CTS-URN")
    let $urn := fn:substring-after($datum, "CTS-URN: ")
    return <urn>{$urn}</urn>
  