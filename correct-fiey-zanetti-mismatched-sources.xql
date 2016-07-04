xquery version "3.0";

(: Correct source attributes that erroneously point to Fiey instead of Zanetti, and vice versa.:)

(: NAMESPACES:)
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace syriaca = "http://syriaca.org";
declare namespace functx = "http://www.functx.com";

declare function syriaca:update-attribute($input-node as node()*,$attribute as xs:string,$attribute-value as xs:string)
as node()*
{
    for $node in $input-node
        return
            element {xs:QName(name($node))} {
                        $node/@*[name()!=$attribute], 
                        attribute {$attribute} {$attribute-value}, 
                        $node/node()}
};

declare function syriaca:swap-sources($input-node as node()*,$source-1 as xs:string,$source-2 as xs:string)
as node()*
{
    for $node in $input-node
        let $new-node := 
            if ($node/@source=$source-1) then
                syriaca:update-attribute($node, 'source', $source-2)
            else if ($node/@source=$source-2) then
                syriaca:update-attribute($node, 'source', $source-1)
            else $node
        return 
            if ($new-node/*) then
                element {$new-node/name()} {$new-node/@*,syriaca:swap-sources($new-node/node(), $source-1, $source-2)}
            else $new-node
};

(: ------------------------------------------------------------------------ :)
(: SCRIPT BODY :)
let $persons := collection('/db/apps/srophe-data/data/persons/tei/saints/tei/')/TEI

for $person in $persons/text/body/listPerson/person[replace(persName[@xml:lang='fr-x-fiey'][1]/@source,'#','')=bibl[ptr/@target='http://syriaca.org/bibl/649']/@xml:id or replace(persName[@xml:lang='fr-x-zanetti'][1]/@source,'#','')=bibl[ptr/@target='http://syriaca.org/bibl/650']/@xml:id]
    let $bibl-id-fiey := $person/bibl[ptr/@target='http://syriaca.org/bibl/650']/@xml:id
    let $bibl-id-zanetti := $person/bibl[ptr/@target='http://syriaca.org/bibl/649']/@xml:id
    
    let $correct-person := 
        let $persName-source-fiey-new := concat('#',$bibl-id-fiey)
        let $persName-source-zanetti-new := concat('#',$bibl-id-zanetti)
        return syriaca:swap-sources($person, $persName-source-zanetti-new, $persName-source-fiey-new)
        
    let $changes := $person/../../../../teiHeader/revisionDesc/change
    let $change-new := <change who="http://syriaca.org/documentation/editors.xml#ngibson" when="2016-05-13+02:00">CHANGED: Corrected swapped source attributes for data from Fiey and Zanetti</change>
    

return (update insert $change-new preceding $changes[1],
        update replace $person with $correct-person)