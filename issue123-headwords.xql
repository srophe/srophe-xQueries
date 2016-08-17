xquery version "3.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

for $r in collection('/db/apps/srophe-data/data/persons/tei')
let $id := $r/descendant::tei:idno[1]
let $title := $r/descendant::tei:titleStmt/tei:title[@level='a']
let $english := $r/descendant::tei:person/tei:persName[contains(@syriaca-tags,'#syriaca-headword')][@xml:lang = 'en'][1]
let $english-str := if($english/child::*) then string-join($english/child::*/text(),' ') else $english/text()
let $syr := if($r/descendant::tei:person/tei:persName[@syriaca-tags='#syriaca-headword'][@xml:lang='syr'][1]) then 
                $r/descendant::tei:person/tei:persName[@syriaca-tags='#syriaca-headword'][@xml:lang='syr'][1]
            else $r/descendant::tei:person/tei:persName[@xml:lang='syr'][1]
let $syr-str := if($syr/child::*) then string-join($syr/child::*/text(),' ') else $syr/text()
let $anon := 
    if($r/descendant::tei:person/tei:trait/tei:label[. = 'anonymous']) then 
        string-join($r/descendant::tei:person/tei:persName[@xml:lang="en"][contains(@syriaca-tags, '#anonymous-description')],' ')
    else ()
let $new-title := 
                <title xmlns="http://www.tei-c.org/ns/1.0" level="a" xml:lang="en">
                    {(
                        $english-str,
                        if(not(empty($anon))) then concat(' — ',$anon)
                        else if(not(empty($syr-str))) then 
                            (' — ', <foreign xml:lang="syr">{$syr-str}</foreign>)
                        else ()    
                    )}
                </title>  
let $enRef := <persName xmlns="http://www.tei-c.org/ns/1.0" ref="{replace($id,'/tei','')}">{$english-str}</persName>                
let $note := $r/descendant::tei:person/tei:note[not(descendant-or-self::tei:quote)]
let $att := $r/descendant::tei:person/tei:event[@type="attestation"]
(: May need a test for no syriac headword :)                
return     
    (
    update replace $title with $new-title,
    for $n in $note[descendant-or-self::tei:persName[@ref= replace($id,'/tei','')]]
    return update value $note/descendant-or-self::tei:persName[@ref=replace($id,'/tei','')] with $english-str,
    for $a in $att
    return 
        update replace $a/tei:p with 
            <p xmlns="http://www.tei-c.org/ns/1.0" xml:lang="en">{($enRef, ' is commemorated in ', $a/tei:p/tei:title,'.')}</p>,
    update insert 
            <change xmlns="http://www.tei-c.org/ns/1.0" who="http://syriaca.org/documentation/editors.xml#wsalesky" 
            when="{current-date()}">Update persName texts nodes from new headwords.</change>
          preceding $r/descendant::tei:teiHeader/tei:revisionDesc/tei:change[1],
    update value $r/descendant::tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:date with current-date()
    )
