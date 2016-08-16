xquery version "3.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

for $name in doc('/db/apps/bug-test/newheadwords.xml')//tei:persName[matches(@xml:id,"name\d+-h")]
let $id := concat('http://syriaca.org/person/',substring-after(substring-before($name/@xml:id,'-'),'name'))
return 
    for $r in collection('/db/apps/srophe-data/data/persons/tei')//tei:idno[. = $id]
    let $person := $r/ancestor::tei:TEI/descendant::tei:person/tei:persName[1]
    return 
        (
        update insert $name preceding $person,    
        update insert 
            <change xmlns="http://www.tei-c.org/ns/1.0" who="http://syriaca.org/documentation/editors.xml#wsalesky" when="{current-date()}">Insert new headwords, new headword id ends with '-h'.</change>
          preceding $r/ancestor::tei:TEI/descendant::tei:teiHeader/tei:revisionDesc/tei:change[1],
    update value $r/ancestor::tei:TEI/descendant::tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:date with current-date())
