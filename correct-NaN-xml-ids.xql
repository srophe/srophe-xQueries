xquery version "3.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace syriaca = "http://syriaca.org";
declare namespace functx = "http://www.functx.com";

declare function syriaca:next-id($ids as xs:string*,$prefix as xs:string*,$i as xs:double*)
as xs:string*
{
    let $offset := if ($i) then $i else 1
    return 
        if (count($ids) > 0) then
            let $id-nums := 
                for $id in $ids
                return number(replace($id,$prefix,''))
            return concat($prefix,($i+max($id-nums)))
        else concat($prefix,$i)
};
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

let $persons := collection('/db/apps/srophe-data/data/persons/tei/')/TEI

for $person-record in $persons[descendant-or-self::*[contains(@xml:id,'NaN')]]
    let $person := $person-record/text/body/listPerson/person
    let $person-id := replace($person/idno[@type='URI' and matches(.,'http://syriaca\.org')],'http://syriaca\.org/person/','')
    let $update-node := 
        for $node at $i in $person/descendant-or-self::*[contains(@xml:id,'NaN')]
        let $prefix := 
            if ($node/name()='persName') then concat('name',$person-id,'-')
            else if ($node/name()='bibl') then concat('bib',$person-id,'-')
            else concat($node/name(),$person-id,'-')
        let $xml-id := 
            if ($prefix) then 
                syriaca:next-id
                    ($person/descendant-or-self::*[name()=$node/name()]/@xml:id[matches(.,'\d$')], 
                    $prefix[1], 
                    $i) 
            else()
        return update replace $node with syriaca:update-attribute($node, 'xml:id', $xml-id)
    return $update-node