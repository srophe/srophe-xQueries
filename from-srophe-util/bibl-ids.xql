xquery version "3.0";
declare namespace tei="http://www.tei-c.org/ns/1.0";
(: [descendant::*/@syriaca-computed-start lt $end][descendant::*/@syriaca-computed-end lt $start ] :)

declare function local:do-change-stmt($recs){
    let $change := 
        <change xmlns="http://www.tei-c.org/ns/1.0" who="http://syriaca.org/documentation/editors.xml#wsalesky" when="{current-date()}">ADDED: Renumbered bibl xml:id attributes and source references to be sequential.</change>
    return
        (
         update insert $change preceding $recs/ancestor::tei:TEI/tei:teiHeader/tei:revisionDesc/tei:change[1],
         update value $recs/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:date with current-date())
};

for $recs in collection('/db/apps/srophe/data/persons/tei')//tei:person
return 
(
    xmldb:login('/db/apps/srophe/', 'admin', '', true()),    
    let $bibl-list := $recs//tei:bibl 
    for $bibl in $bibl-list
    let $bibl-id := string($bibl/@xml:id)
    let $bibl-ref-id := concat('#',$bibl/@xml:id)
    let $new-bibl-num := index-of($bibl-list,$bibl)
    let $new-bibl-id := concat(substring-before($bibl-id,'-'),'-', $new-bibl-num)
    let $new-bibl-ref-id := concat('#',$new-bibl-id)
    return 
            (update value $bibl/@xml:id with $new-bibl-id,
            for $new-source in $recs//descendant-or-self::*[@source = $bibl-ref-id]
            return update value $new-source/@source with $new-bibl-ref-id),
    local:do-change-stmt($recs)