
for $s in collection('/db/apps/srophe-data/data/spear/tei')//tei:TEI
let $id := replace($s/descendant::tei:publicationStmt/tei:idno[@type='URI'][1]/text(),'/tei','')
let $divs := count($s/descendant::tei:body/tei:div)
return 
    for $d at $i in subsequence($s/descendant::tei:body/tei:div,1,$divs)
    let $newID := concat($id,'-',$i)
    return 
        if($d/@uri) then ()
        else update insert attribute uri {$newID} into $d
