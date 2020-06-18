declare namespace tei = "http://www.tei-c.org/ns/1.0";

for $r in collection('/db/apps/srophe-data/data/persons/tei/saints/tei')//tei:revisionDesc[@status="incomplete"]/ancestor::tei:TEI[descendant::tei:idno[@type='BHS']]
let $uri := replace($r/descendant::tei:idno[@type='URI'][1],'/tei','')
let $name := $r/descendant::tei:persName[@syriaca-tags='#syriaca-headword'][@xml:lang='en'][1]/text()
let $pid := substring-after($uri,'person/')
return 
    for $b at $pos in $r//tei:idno[@type='BHS']
    let $work := for $w in collection('/db/apps/srophe-data/data/works')//tei:idno[@type='BHS'][. = $b]
                 return $w/ancestor::tei:TEI
    let $work-id := replace($work/descendant::tei:idno[@type='URI'][1],'/tei','')
    let $wid := substring-after($work-id,'work/')
    let $work-title := $work/descendant::tei:title[1]/text()
    let $work-relation :=  
        if($work/descendant::tei:listRelation) then 
            if($work/descendant::tei:relation[@active = $work-id][@passive=$uri]) then ()
            else
                <relation xmlns="http://www.tei-c.org/ns/1.0" name="syriaca:commemorated" active="{$work-id}" passive="{$uri}" source="#bib{$wid}-1"/>
        else 
            <listRelation  xmlns="http://www.tei-c.org/ns/1.0">
                <relation name="syriaca:commemorated" active="{$work-id}" passive="{$uri}" source="#bib{$wid}-1"/>
            </listRelation>
    let $sourceid := string($b/ancestor::tei:TEI/descendant::tei:bibl[tei:ptr[@target = 'http://syriaca.org/bibl/649']]/@xml:id)    
    let $a := 
        <event type="attestation" xml:id="attestation{$pid}-{$pos}" source="{$sourceid}" xmlns="http://www.tei-c.org/ns/1.0">
            <p xml:lang="en"><persName ref="{$uri}">{$name}</persName> is commemorated in <title ref="{$work-id}">{$work-title}</title>.</p> </event>
    return 
        (
            update insert $a preceding $r/descendant::tei:person/tei:idno[1],
            update delete $b,
            if($work/descendant::tei:listRelation) then 
                if(not(empty($work-relation))) then
                    update insert $work-relation following $work/descendant::tei:listRelation/tei:relation                        
                else ()    
            else 
                if(not(empty($work-relation))) then
                    update insert $work-relation following $work/descendant::tei:body/tei:bibl
                else (),    
            update insert 
                <change xmlns="http://www.tei-c.org/ns/1.0" who="http://syriaca.org/documentation/editors.xml#wsalesky" 
                when="{current-date()}">Add relations and attestations for saints-overlap.</change>
                  preceding $r/descendant::tei:teiHeader/tei:revisionDesc/tei:change[1],
            update value $r/descendant::tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:date with current-date()
    
        )
