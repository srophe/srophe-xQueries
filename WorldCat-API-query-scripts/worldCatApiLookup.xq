xquery version "3.0";
(:~
 : Utility function to interact with the WorldCat search APIs to return MARCXML records based on a CSV input of citations.
 : Note that the WS Key is limited to 100 API queries per day.
 :
 : @author William Potter
 : @version 1.0
 :
 :)
 declare namespace marc="http://www.loc.gov/MARC21/slim";
 declare option output:omit-xml-declaration "no";
 declare option file:omit-xml-declaration "no";
 declare function local:queryWorldCat($query as xs:string, $key as xs:string)
{
  let $base-uri := "http://www.worldcat.org/webservices/catalog"
  let $service := "/search/worldcat/sru?"
  let $method := "query=srw.kw+all+"
  let $maximumRecords := "1"
  let $encodedQuery := fn:encode-for-uri("""" || $query || """")
  let $request := $base-uri || $service || $method ||  $encodedQuery  || "&amp;maximumRecords=" || $maximumRecords || "&amp;wskey=" || $key
  return http:send-request(<http:request method='get' href='{$request}' timeout='10'/>)
};


 declare function local:processReturnRecord($rawReturn as node()) {
   (:Strips the WorldCat SRW header information and nests the return in a MARCXML collections element.
   Alternatively, may want to save the nesting of the marc:record until the end - create a sequence of marc:record nodes using the functions and then at the end wrap that return in a <collections> element. Ask Winona what would be best. :)
   let $record := if($rawReturn//*:numberOfRecords/text() > 0) then $rawReturn//*:records/*:record/*:recordData/*:record else "no record"
   return
     if ($record != "no record") then <collection xmlns="http://www.loc.gov/MARC21/slim">{$record}</collection>
     else ()
 };
 declare function local:worldCatApiLookup ($line as xs:string, $key as xs:string){

   let $fields := tokenize($line, '\t')
   let $citationType := $fields[2]
   (: The CSV is different for book sections, because we are looking up the monograph title and editor string rather than the article title and author string. :)
   let $title := if($citationType = "Journal Article") then $fields[5] else $fields[6]
   let $author := if($citationType != "Journal Article" and $fields[9] != '') then $fields[9] else $fields[3] 
   let $query := fn:concat($author, " ", $title)
   let $return := local:queryWorldCat($query, $key)
   let $returnRecord := $return[2]

   let $processedReturnRecord := local:processReturnRecord($returnRecord)
   let $oclcNumber := if($returnRecord//*:numberOfRecords/text() > 0) then $processedReturnRecord//*:record/*:controlfield[@tag="001"]/text() else "no record found"
   (:The following line creates an updated CSV of the bibliographic data with the OCLC number appended to the final column. This allows for verifying the returned record data against the input. :)
   let $emptyVar := file:append-text-lines('file:////Users/dhlab/Documents/GitHub/miscellaneous-util-scripts/Caesarea-Biblio-Api/tsvSources/CaesareaMaratimaBibliographyModuleOUTPUT.tsv', fn:concat(fn:replace($line, '(\r?\n|\r)$', ''), "	", $oclcNumber))
   return $processedReturnRecord
 };

let $key := "***"
let $filePath := 'file:///Users/dhlab/Documents/GitHub/miscellaneous-util-scripts/Caesarea-Biblio-Api/tsvSources/CaesareaMaratimaBibliographyModule.tsv'
let $outputPath := 'file:///Users/dhlab/Documents/GitHub/miscellaneous-util-scripts/Caesarea-Biblio-Api/MARCXMLOutputs/'
let $nothing := file:create-dir($outputPath)
let $TSVDoc := file:read-text($filePath)
let $input := $TSVDoc

let $lines := tokenize($input, '\n')
for $l at $position in $lines
  (: where contains($l, "The Aqueducts of Israel") :)(:testing specific record:)
  where $position <= 99 (: testing only the first 5 rows. This will be used to ensure we stay below the record cap on our WSKey. :)
  let $null := prof:sleep(3000)
  let $rec := try { local:worldCatApiLookup($l, $key) } catch * {concat($err:code, ": ", $err:description)}
  let $oclc := $rec//*:record/*:controlfield[@tag="001"]/text()
  let $localName := if($oclc != '') then $oclc else fn:concat("noReturn", $position)
  return file:write($outputPath || $localName || '.xml', $rec, map{'omit-xml-declaration': 'no'})
