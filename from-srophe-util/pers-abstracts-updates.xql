xquery version "3.0";
 
declare namespace tei="http://www.tei-c.org/ns/1.0";
 
declare function local:do-alt-names($abstracts, $docs, $rec-id){
    for $alt-name in $abstracts/Alternate_Name
    return 
        if(string-length($alt-name) gt 1) then
            (
            let $addName :=
                for $persName in $docs//tei:persName[parent::tei:person]
                return
                    if($persName/text() = $alt-name/text()) then 
                        (:check for source and insert if not there or update value if it is there:)
                        if($persName/@source) then 
                            update value $persName/@source with concat('#bib',$rec-id,'-1')
                        else update insert attribute source {concat('#bib',$rec-id,'-1')} into $persName 
                    else 'false'
            return        
                if($addName = 'false') then
                    update insert
                        <persName xmlns="http://www.tei-c.org/ns/1.0" xml:id="name{$rec-id}-{(count($docs//tei:persName) + 1)}" xml:lang="en" source="#bib{$rec-id}-1">{$alt-name/node()}</persName>
                    following $docs//tei:persName[parent::tei:person][last()]
                else ()    
                )       
            else () 
};
 
(:NOTE, need to handle existing abstracts, with text, replace text? wrap it in quote? also placename does not have the tei namespace?:) 
declare function local:do-abstracts($abstracts,$docs, $rec-id){
    for $abstract in $abstracts/Abstract
    let $newAbstract := 
        if(string-length($abstracts/Not_Useful[1]/text()) gt 0) then 
            (<Not_Useful xmlns="http://www.tei-c.org/ns/1.0">{$abstracts/Not_Useful/text()}</Not_Useful>,
             <quote xmlns="http://www.tei-c.org/ns/1.0"  source="#bib{$rec-id}-1">{$abstract/node()}</quote>)
        else <quote xmlns="http://www.tei-c.org/ns/1.0" source="#bib{$rec-id}-1">{$abstract/node()}</quote>        
    return
        if($docs//tei:note[@type='abstract']) then
            update insert $newAbstract into $docs//tei:person/tei:note[@type='abstract']
        else    
            update insert 
                <note xmlns="http://www.tei-c.org/ns/1.0" type="abstract" xml:id="abstract-en-{$rec-id}">{$newAbstract}</note>
            following $docs//tei:person/tei:persName[last()]
};
 
declare function local:do-change-stmt($abstracts,$docs,$rec-id){
    let $resp := 
        <respStmt xmlns="http://www.tei-c.org/ns/1.0">
            <resp>Proofreading of GEDSH abstracts and addition of confessions and alternate names from GEDSH by</resp>
            <name type="person"ref="http://syriaca.org/documentation/editors.xml#ngibson">Nathan P. Gibson</name>
        </respStmt>
    let $change := 
        <change xmlns="http://www.tei-c.org/ns/1.0" who="http://syriaca.org/documentation/editors.xml#wsalesky" when="{current-date()}">ADDED: Abstracts, citation, additional names and confessions from GEDSH.</change>
    return
        (
         update insert $change preceding $docs/ancestor::tei:TEI/tei:teiHeader/tei:revisionDesc/tei:change[1],
         update value $docs/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:date with current-date(),
         update insert $resp following $docs/ancestor::tei:TEI/tei:teiHeader//tei:respStmt[last()])
};
 
declare function local:do-bibl($abstracts,$docs, $rec-id){
    for $bibl in $docs//tei:bibl[tei:ptr[@target = 'http://syriaca.org/bibl/1']]  
    return 
        (
        if(string-length($abstracts/Headword/text()) gt 1) then 
            for $title in $abstracts/Headword
            return
                update insert
                    <title xmlns="http://www.tei-c.org/ns/1.0" level="a" xml:lang="en">{$title/text()}</title>
                preceding $bibl/tei:title[1]    
        else (),
        if(string-length($abstracts/Author[1]/text()) gt 1) then 
            for $auth in $abstracts/Author
            return
                update insert
                    <author xmlns="http://www.tei-c.org/ns/1.0">{$auth/text()}</author>
                preceding $bibl/tei:title[1]    
        else (),
        if(string-length($abstracts/Bibl_ID/text()) gt 1) then 
            update value $bibl/tei:ptr/@target with concat('http://syriaca.org/bibl/',$abstracts/Bibl_ID/text())
        else (),
        if(string-length($abstracts/Pages/text()) gt 1) then 
            for $cite in $abstracts/Pages
            return
            if($bibl/tei:citedRange) then
                (update value $bibl/tei:citedRange with $cite/text(),
                update value $bibl/tei:citedRange/@unit with 'pp')
            else    
                update insert
                    <citedRange xmlns="http://www.tei-c.org/ns/1.0" unit="pp">{$cite/text()}</citedRange>
                following $bibl/tei:ptr    
        else () 
        )
};
 
declare function local:do-state($abstracts,$docs,$rec-id){
    if(string-length($abstracts/Affiliation[1]/text()) gt 1) then
            update insert 
                for $new-aff in $abstracts/Affiliation
                return 
                    <state xmlns="http://www.tei-c.org/ns/1.0" type="confession" source="#bib{$rec-id}-1">
                        <desc>{$new-aff/node()}</desc>
                    </state>
            preceding $docs//tei:bibl[1]
        else()
};
 
for $abstracts in doc('/db/apps/srophe/data/gedsh-abstracts-in-correction-20140729.xml')//row[Type='person']
let $id := concat('person-',$abstracts/SRP_ID[1]/text())
return 
    for $docs in collection('/db/apps/srophe/data/persons/tei')/id($id)[1]
    let $rec-id := substring-after($id,'person-')
    return 
        (
        xmldb:login('/db/apps/srophe/', 'admin', '', true()),
        local:do-abstracts($abstracts,$docs, $rec-id),
        local:do-bibl($abstracts,$docs, $rec-id),
        local:do-alt-names($abstracts, $docs, $rec-id),
        local:do-state($abstracts,$docs,$rec-id),
        local:do-change-stmt($abstracts,$docs,$rec-id)
        )
