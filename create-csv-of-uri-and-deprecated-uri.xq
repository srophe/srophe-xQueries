xquery version "3.1";

declare default element namespace "http://www.tei-c.org/ns/1.0";


declare variable $local:persons-collection := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\persons\tei\");

declare variable $local:places-collection := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\places\tei\");

declare variable $local:all-records := ($local:persons-collection, $local:places-collection);

let $records := 
  for $doc in $local:all-records
  where count($doc//publicationStmt/idno) > 1
  
  let $goodUri := $doc//publicationStmt/idno[@type="URI"]
  let $goodUri := substring-before($goodUri, "/tei")
  
  (: there are cases where more than one record has been merged in, resulting in multiple deprecated URIs. :)
  (: get all the text nodes, strip the "/tei" part, and join them with a separating pipe character, "|" :)
  let $deprecatedUri := $doc//publicationStmt/idno[@type="deprecated"]/text()
  let $deprecratedUri := 
    for $uri in $deprecatedUri
    return substring-before($deprecatedUri, "/tei")
  let $deprecatedUri := string-join($deprecatedUri, "|")
  
  let $recordTitle := $doc//titleStmt/title[@level="a"]//text() (: using the a-level title from the titleStmt for now; headwords are currently not consistent across entity types (waiting on SBD and NHSL batch changes... :)
  let $recordTitle := string-join($recordTitle, " ")
  let $recordTitle := normalize-space($recordTitle)
  
  let $changeIds := $doc//idno/@change/string()
  let $changeIds := distinct-values($changeIds)
  
  let $changeDates := 
    for $id in $changeIds
      for $change in $doc//revisionDesc/change
      where $change/@xml:id/string() = substring-after($id, "#") and $change/text() != "Merged in data from [duplicate record with same URI]"
      return $change/@when/string()
  
  (: order by most recent date; join into a string with "|" separator:)
  let $changeDates := 
    for $date in $changeDates
    order by $date descending
    return $date
  
  let $changeDates := string-join($changeDates, "|")
  
  return 
  <record>
    <uri>{$goodUri}</uri>
    <deprecatedUri>{$deprecatedUri}</deprecatedUri>
    <recordTitle>{$recordTitle}</recordTitle>
    <dateOfDeprecation>{$changeDates}</dateOfDeprecation>
  </record>

return csv:serialize(<csv>{$records}</csv>, map{"header": "yes"})