xquery version "3.1";


let $xmlInUri := "C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Syriac-World-Maps-Util\placeTreeMaster.xml"
let $xmlOutPath := "C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Syriac-World-Maps-Util\xmlMasterTrees\"
let $newRecords := doc($xmlOutPath||"newRecordsMaster.xml")
let $oldRecords := doc($xmlOutPath||"oldRecordsMaster.xml")
let $xmlIn := doc($xmlInUri)
 for $rec in $xmlIn//*:record
  let $recId := number(substring-after($rec/*:Syriaca_URI/*:label/text(), "place/"))
  return (if ($recId lt 4000) then insert node $rec into $oldRecords
  else insert node $rec into $newRecords)