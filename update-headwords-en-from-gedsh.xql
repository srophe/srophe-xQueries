xquery version "3.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

for $rec in collection('/db/apps/srophe-data/data/persons/tei')//tei:person[tei:persName[@xml:lang="en-x-gedsh"]][not(tei:persName[@syriaca-tags="#syriaca-headword" and @xml:lang="en"])]
let $r := $rec/ancestor::tei:TEI
let $id := replace($r/descendant::tei:idno[1],'/tei','')
let $gedesh := $rec/tei:persName[@syriaca-tags='#syriaca-headword'][@xml:lang='en-x-gedsh']
let $english := 
                <persName xmlns="http://www.tei-c.org/ns/1.0"  xml:id="name{substring-after($id,'http://syriaca.org/person/')}-0" xml:lang="en" syriaca-tags="#syriaca-headword">
                    {$gedesh/child::*}
                </persName>
return (
        update insert $english preceding $rec/tei:persName[1],
        update insert 
            <change xmlns="http://www.tei-c.org/ns/1.0" who="http://syriaca.org/documentation/editors.xml#wsalesky" when="{current-date()}">Create English headword from Gedesh headword.</change>
          preceding $r/descendant::tei:teiHeader/tei:revisionDesc/tei:change[1],
    update value $r/descendant::tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:date with current-date()
    )
