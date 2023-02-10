xquery version "3.1";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:input-directory := "/home/arren/Documents/GitHub/caesarea-data/data/testimonia/tei";

declare variable $local:input-collection := collection($local:input-directory);

declare variable $local:license-text := <p>Except for materials quoted from other sources, this entry is copyright DATE by the contributors (EDITOR-NAME, et al.) and the Caesarea City and Port Exploration Project. It is licensed under the Attribution 4.0 International (CC BY 4.0) license.</p>;

for $doc in $local:input-collection
let $changeDates := 
  for $date in $doc//revisionDesc/change/@when/string()
  order by $date descending
  return $date

let $lastModified := $changeDates[1]
let $lastModified := if($lastModified = "") then $doc//publicationStmt/date/text() else $lastModified

let $pubYear := substring($lastModified, 1, 4)

let $editorName := normalize-space($doc//titleStmt/editor[@role="creator"][1]/text())

let $licenceText := $local:license-text/text()
let $licenceText := replace($licenceText, "DATE", $pubYear)
let $licenceText := replace($licenceText, "EDITOR-NAME", $editorName)
let $updatedLicence := element {"p"} {$licenceText}
return (replace node $doc//publicationStmt/availability/licence/p[1] with $updatedLicence, 
        replace value of node $doc//publicationStmt/date with $lastModified)
