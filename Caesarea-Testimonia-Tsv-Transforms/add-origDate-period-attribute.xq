xquery version "3.0";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";
declare option output:indent "no";

(:
This script updates the tei:origDate by adding a @period attribute based on the date range expressed in the @notBefore/@notAfter, or @when attributes.
The period values are added following the periodization conventions established for Caesarea-Maritima.org, derived from The New Encyclopedia of Archaeological Excavations in the Holy Land

@author: William L. Potter
@version 1.0
:)
declare function functx:add-or-update-attributes
  ( $elements as element()* ,
    $attrNames as xs:QName* ,
    $attrValues as xs:anyAtomicType* )  as element()? {

   for $element in $elements
   return element { node-name($element)}
                  { for $attrName at $seq in $attrNames
                    return attribute {$attrName}
                                     {$attrValues[$seq]},
                    $element/@*[not(node-name(.) = $attrNames)],
                    $element/node() }
 } ;
declare function local:lookup-period-range($lower as xs:string, $upper as xs:string, $xmlTable as node()) as xs:string+ {
  for $cat in $xmlTable//*:record
    where ($lower >= $cat/*:notBefore/text() and $lower <= $cat/*:notAfter/text()) or ($upper >= $cat/*:notBefore/text() and $upper <= $cat/*:notAfter/text()) or ($lower <= $cat/*:notBefore/text() and $upper >= $cat/*:notAfter/text())
    return $cat/*:catId/text()
};
declare function local:lookup-period-singleDate($date as xs:string, $xmlTable as node()) as xs:string+ {
  for $cat in $xmlTable//*:record
    where $date >= $cat/*:notBefore/text() and $date <= $cat/*:notAfter/text()
    return $cat/*:catId/text()
};
let $delimiter := ","
let $inputFileString := "C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Caesarea-Testimonia-Tsv-Transforms\NEAEH-CM-TaxonomyTable.csv"
let $inputFile := file:read-text($inputFileString)
let $xmlFile := csv:parse($inputFile, map{"header": "true", "separator": $delimiter, "quotes": "no"})


for $doc in fn:collection("C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Caesarea-Testimonia-Tsv-Transforms\processTsvOutput\2020-06-10\")
  let $docId := fn:substring-after($doc//text/body/ab/idno/text(), "testimonia/")
  let $lower := string($doc//creation/origDate/@notBefore)
  let $upper := string($doc//creation/origDate/@notAfter)
  let $date := string($doc//creation/origDate/@when)
  let $periodSet := if ($date != '') then local:lookup-period-singleDate($date, $xmlFile) else local:lookup-period-range($lower, $upper, $xmlFile)
  let $periodAttrString := "#"||fn:string-join($periodSet, " #")
  let $newOrigDate := functx:add-or-update-attributes($doc//creation/origDate, fn:QName("", "period"), $periodAttrString)
  return replace node $doc//creation/origDate with $newOrigDate