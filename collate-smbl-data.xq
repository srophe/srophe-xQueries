xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace srophe="https://srophe.app";

declare variable $path-to-data := "/home/arren/Documents/GitHub/britishLibrary-data/";

declare variable $smbl-coll := collection($path-to-data||"data/tei/");

declare function local:process-origDate-attributes($dates as element()*)
as xs:string* {
  let $normalizedDates :=
    for $date in $dates
    return if($date/@when) then $date/@when/string()
    else
      $date/@notBefore/string() || "/" || $date/@notAfter/string()
  return string-join($normalizedDates, " ; ") => normalize-space()
};

let $rows :=
  for $doc in $smbl-coll
  
  for $ms in $doc//*[name() = "msDesc" or name() = "msPart"]
  
  let $uri := <uri>{$ms/msIdentifier/idno[@type="URI"]/text()}</uri>
  let $shelfmark := <shelfmark>{$ms/msIdentifier/altIdentifier/idno[@type="BL-Shelfmark"]/text() => replace("–", "-")}</shelfmark>
  let $type := switch($ms/name())
    case "msDesc" return "manuscript object"
    case "msPart" return "part"
    default return ""
  let $type := <record_type>{$type}</record_type>
  
  let $contentsSummary := <contents_summary>{
    $ms/head/note[@type="contents-note"]//text() => string-join(" ") => normalize-space()
  }</contents_summary>
  
  let $subjectHeading := <wright_subject>{$ms/head/listRelation[@type="Wright-BL-Taxonomy"]/relation/desc/text() => normalize-space()}</wright_subject>
  let $dateString := <wright_date>{$ms/history/origin/origDate[@calendar="Gregorian"]/text() => string-join(" ; ") => normalize-space()}</wright_date>
  let $dateNorm := <wright_date_norm>{local:process-origDate-attributes($ms/history/origin/origDate[@calendar="Gregorian"])}</wright_date_norm>
  
  let $wrightBibl := $ms/additional/listBibl/bibl[ptr/@target = "http://syriaca.org/bibl/8"]
  let $archiveUrl := <archive_url>{$wrightBibl/ref[@type="internet-archive-pdf"]/@target/string()}</archive_url>
  let $wrightVol := <wright_vol>{$wrightBibl/citedRange[@unit="vol"]/text()}</wright_vol>
  let $wrightPage := <wright_page>{$wrightBibl/citedRange[@unit="p"]/text()}</wright_page>
  let $wrightEntry := <wright_entry>{$wrightBibl/citedRange[@unit="entry"]/text()}</wright_entry>
  
  return <row>
    {
      $shelfmark,
      $uri,
      $type,
      $contentsSummary,
      $subjectHeading,
      $dateString,
      $dateNorm,
      $archiveUrl,
      $wrightVol,
      $wrightPage,
      $wrightEntry
    }
  </row>

return csv:serialize(<csv>{$rows}</csv>, map {"header": "yes"})