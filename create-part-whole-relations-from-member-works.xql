xquery version "3.0";

(: Create part-whole relations in literary tradition records that mirror those of their member works/branches.
   KNOWN ISSUES:  
    - Sometimes inserts multiple <change> in revision desc. :)

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace syriaca = "http://syriaca.org";
declare namespace functx = "http://www.functx.com";

declare function syriaca:remove-extra-attributes($input-node as node()*,$attributes-to-remove as xs:string*)
as node()*
{
    for $node in $input-node
    return
        if ($node/descendant-or-self::*[@*/name()=$attributes-to-remove]) then
            element {xs:QName(name($node))} {
                $node/@*[not(name()=$attributes-to-remove)], 
                syriaca:remove-extra-attributes($node/node(), $attributes-to-remove)}
        else $node
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

declare function functx:is-node-in-sequence-deep-equal
  ( $node as node()? ,
    $seq as node()* )  as xs:boolean {

   some $nodeInSeq in $seq satisfies deep-equal($nodeInSeq,$node)
 } ;
 
declare function functx:distinct-deep
  ( $nodes as node()* )  as node()* {

    for $seq in (1 to count($nodes))
    return $nodes[$seq][not(functx:is-node-in-sequence-deep-equal(
                          .,$nodes[position() < $seq]))]
 } ;

let $works := collection('/db/apps/srophe-data/data/works/tei/')/TEI

let $traditions := $works[text/body/bibl/@type='syriaca:LiteraryTradition']

(: Need to build in test whether tradition already has relation or not. :)

for $tradition in $traditions
    let $tradition-main-bibl := $tradition/text/body/bibl
    let $tradition-uri := $tradition-main-bibl/idno[starts-with(.,'http://syriaca.org')]
    let $tradition-id := replace($tradition-uri,'http://syriaca.org/work/','')
    
    let $related-texts := $works[text/body/bibl/listRelation/relation[@ref='skos:broadMatch' and index-of(tokenize(@passive,' '),$tradition-uri)]]
    let $related-uris := $related-texts/text/body/bibl/idno[starts-with(.,'http://syriaca.org')]
    let $part-whole-relations := $related-texts/text/body/bibl/listRelation/relation[@ref='dct:isPartOf']
    let $part-whole-relations-sanitized := syriaca:remove-extra-attributes($part-whole-relations, ('xml:id','source'))
    let $part-whole-relations-update-active := syriaca:update-attribute($part-whole-relations-sanitized, 'active', $tradition-uri)
    let $part-whole-relations-update-passive := 
        for $relation in $part-whole-relations-update-active
            let $passive-tradition-uri := 
                $works/text/body/bibl[idno=$relation/@passive]/listRelation/relation[@ref='skos:broadMatch']/@passive
            return if ($passive-tradition-uri) then 
                syriaca:update-attribute($relation, 'passive', $passive-tradition-uri)
            else ()
            
    let $merged-relations := 
        for $passive in distinct-values($part-whole-relations-update-passive/@passive)
        return
            if ($tradition-main-bibl/listRelation/relation[@ref='dct:isPartOf']/@passive=$passive or $tradition-uri=$passive) then 
                ()
            else
                let $all-relations := $part-whole-relations-update-passive[@passive=$passive]
                let $first-relation := $all-relations[1]
                let $distinct-labels := functx:distinct-deep($all-relations/desc/label)
                return element relation {$first-relation/@*, element desc {$distinct-labels}}
            
    let $insertion := 
        if ($merged-relations and $tradition-main-bibl/listRelation) then
            update insert $merged-relations into $tradition-main-bibl/listRelation
        else if ($merged-relations) then
            update insert element listRelation {$merged-relations} into $tradition-main-bibl 
        else ()
                
    let $change := <change who="http://syriaca.org/documentation/editors.xml#ngibson" when="{current-date()}">Added part-whole relations based on corresponding branch texts</change>

return 
    if ($merged-relations) then 
        ($insertion, update insert $change preceding $tradition/teiHeader/revisionDesc/change)
    else ()