xquery version "3.1";
declare namespace functx = "http://www.functx.com";
declare function functx:substring-before-if-contains
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string? {

   if (contains($arg,$delim))
   then substring-before($arg,$delim)
   else $arg
 } ;
 
 declare function functx:substring-after-if-contains
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string? {

   if (contains($arg,$delim))
   then substring-after($arg,$delim)
   else $arg
 } ;
 
 declare function functx:name-test
  ( $testname as xs:string? ,
    $names as xs:string* )  as xs:boolean {

$testname = $names
or
$names = '*'
or
functx:substring-after-if-contains($testname,':') =
   (for $name in $names
   return substring-after($name,'*:'))
or
substring-before($testname,':') =
   (for $name in $names[contains(.,':*')]
   return substring-before($name,':*'))
 } ;
 
 declare function functx:dynamic-path
  ( $parent as node() ,
    $path as xs:string )  as item()* {

  let $nextStep := functx:substring-before-if-contains($path,'/')
  let $restOfSteps := substring-after($path,'/')
  for $child in
    ($parent/*[functx:name-test(name(),$nextStep)],
     $parent/@*[functx:name-test(name(),
                              substring-after($nextStep,'@'))])
  return if ($restOfSteps)
         then functx:dynamic-path($child, $restOfSteps)
         else $child
 } ;
(:function to add data to an xml tree from a csv based on a unique identifier. This function (should be) generic enough to allow the user to specify which sheet, which identifier, and which cells to scrape data from :)
(: config declarations :)
let $csvUri := "C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Syriac-World-Maps-Util\RoutledgeSyriacWorldMaps2016-ListofPlaces_OldIDs-to-NewIDs.csv" (: specify sheet :)
let $xmlTreeUri := "C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Syriac-World-Maps-Util\placeTreeMaster.xml" (: specify the xml file to be updated :)
let $compareCells := "NEW" (:the header name of the cell you wish to compare:)
let $returnCells := "Old-ID" (: specify the header names for the desired data cells; may be a sequence -- can't seem to get that to work without a lot of headache. :)
let $identiferPath := "New_ID" (:a relative path to the identifer to use in comparison with the csv.:)


let $csv := fetch:text($csvUri) => csv:parse(map{"header":fn:true()})
let $doc := doc($xmlTreeUri)
for $rec in $doc/*:list/*:record
  let $ids := functx:dynamic-path( $rec, $identiferPath||"/label")/text()
  let $uniqueIds := fn:distinct-values($ids)
  let $oldData := functx:dynamic-path( $rec, $returnCells)
  let $newData := element {$returnCells}{
    for $id in $uniqueIds 
      for $row in $csv//*:record
        where $id = functx:dynamic-path($row, $compareCells)
        let $returnString := functx:dynamic-path($row, $returnCells)/text()
        return if ($returnString != "" and $returnString != "#N/A") then <label>{$returnString}</label> else ()}
  return if (fn:empty($oldData)) then insert node $newData into $rec
  else replace node functx:dynamic-path( $rec, $returnCells) with element {$returnCells} {$oldData/*:label, $newData/*:label}