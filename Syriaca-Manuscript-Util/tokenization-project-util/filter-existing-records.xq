xquery version "3.0";
import module namespace functx = "http://www.functx.com";

let $inFileUri := "C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Syriaca-Manuscript-Util\tokenization-project-util\wright-catalogue-html-ALL-manuscripts-chunked-draft.xml"
let $csvCompareUri := "C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Syriaca-Manuscript-Util\tokenization-project-util\drafted-manuscripts-to-filter-out.csv"
let $csvCompareDoc := csv:parse(file:read-text($csvCompareUri), map{"header": "true", "separator": "	", "quotes": "yes"})

let $newDoc := <doc>{for $div in fn:doc($inFileUri)//*:div
  let $msIdRaw := string($div/@xml:id)
  let $msIdNoTrailingPeriod := if (substring($msIdRaw, fn:string-length($msIdRaw)) = ".") then fn:substring($msIdRaw, 1, fn:string-length($msIdRaw) - 1) else $msIdRaw
  let $msIdNormalizedDash := fn:replace($msIdNoTrailingPeriod, "—", "-")
  let $match := for $row in $csvCompareDoc//*:record
    return if ($msIdNormalizedDash = $row/*:Shelf-mark-as-id/text()) then 1 else ()
    
  return if(not(empty($match))) then () else $div}</doc>
return $newDoc
(: return $csvCompareDoc :)