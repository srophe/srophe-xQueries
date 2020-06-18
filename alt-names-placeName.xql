xquery version "3.0";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function local:left-half-ring-place($recs){
    for $rec in $recs[descendant::tei:place/tei:placeName[contains(.,'ʿ')]]
    let $parent := $rec/descendant::tei:place
    return 
        (for $names in $parent/tei:placeName[contains(.,'ʿ')]
        let $place-name := $names/text()
        let $id := $names/@xml:id
        let $new-name := 
            (
                <placeName xmlns="http://www.tei-c.org/ns/1.0" xml:id="{concat($id,'a')}" xml:lang="en-x-srp1" syriaca-tags="#syriaca-simplified-script">{replace($place-name,'ʿ','')}</placeName>,
                <placeName xmlns="http://www.tei-c.org/ns/1.0" xml:id="{concat($id,'b')}" xml:lang="en-x-srp1" syriaca-tags="#syriaca-simplified-script">{replace($place-name,'ʿ','‘')}</placeName>
            )
        return 
            update insert $new-name following $parent/tei:placeName[last()]
       ,local:do-change-stmt($rec))
};

declare function local:right-half-ring-place($recs){
    for $rec in $recs[descendant::tei:place/tei:placeName[contains(.,'ʾ')]]
    let $parent := $rec/descendant::tei:place   
    return 
        for $names in $parent/tei:placeName[contains(.,'ʾ')]
        let $place-name := $names/text()
        let $id := $names/@xml:id
        let $new-name := 
            (
                <placeName xmlns="http://www.tei-c.org/ns/1.0" xml:id="{concat($id,'a')}" xml:lang="en-x-srp1" syriaca-tags="#syriaca-simplified-script">{replace($place-name,'ʾ','')}</placeName>,
                <placeName xmlns="http://www.tei-c.org/ns/1.0" xml:id="{concat($id,'b')}" xml:lang="en-x-srp1" syriaca-tags="#syriaca-simplified-script">{replace($place-name,'ʾ','‘')}</placeName>
            )
        return 
            update insert $new-name following $parent/tei:placeName[last()]
       ,local:do-change-stmt($rec))
        
};

declare function local:do-change-stmt($rec){
    let $change := 
        <change xmlns="http://www.tei-c.org/ns/1.0" who="http://syriaca.org/documentation/editors.xml#wsalesky" when="{current-date()}">Updated: Updated alternate names for search functionality, corrects bug in https://github.com/srophe/srophe-eXist-app/issues/874.</change>
    return
        (
         update insert $change preceding $rec/descendant::tei:teiHeader/tei:revisionDesc/tei:change[1],
         update value $rec/descendant::tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:date with current-date())
};

if(request:get-data()) then 
    'Possibly handle requests submitted by Perseids'
if(request:get-parameter('id', '')) then 
    for $rec in collection($global:data-root)//tei:TEI[.//tei:idno[@type='URI'][text() = concat($id,'/tei')]]
    return (local:right-half-ring-place($rec),local:left-half-ring-place($rec))
else 
    for $recs in collection('/db/apps/srophe-data/data/places')/tei:TEI
    return (local:right-half-ring-place($recs),local:left-half-ring-place($recs))
