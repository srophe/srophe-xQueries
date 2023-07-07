xquery version "3.1";

import module namespace functx="http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:input-collection :=
collection("/home/arren/Documents/GitHub/caesarea-data/data/testimonia/tei");

declare variable $local:pubDates-uncorrected-drafts :=
(
  "2020-03-30-04:00",
  "2020-04-29-05:00",
  "2020-06-10-05:00",
  "2020-06-19-05:00"
);

declare variable $local:pubDates-published :=
(
  "2021-06-14-05:00",
  "2022-09-30-05:00",
  "2022-10-19-05:00",
  "2022-10-24-05:00",
  "2023-01-20-05:00",
  "2023-01-20-06:00",
  "2023-04-28-05:00",
  "2023-06-30-05:00"
);

for $doc in $local:input-collection
  let $pubDate := $doc//publicationStmt/date/text()
  let $revisionStatus := 
    if(functx:is-value-in-sequence($pubDate, $local:pubDates-uncorrected-drafts)) then
      "uncorrected-draft"
    else if(functx:is-value-in-sequence($pubDate, $local:pubDates-published)) then
      "published"
    else
      "error"
  let $errorMsg := "Error: Publication date, "||$pubDate||", not sortable into published or uncorrected-drafts. Record ID: "|| $doc//publicationStmt/idno/text()
  return if($revisionStatus = "error") then
    update:output($errorMsg)
  else
    replace value of node $doc//revisionDesc/@status with $revisionStatus
  