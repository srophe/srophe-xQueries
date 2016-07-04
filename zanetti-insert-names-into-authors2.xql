xquery version "3.0";

(:Put Zanetti's French names into author records:)

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace syriaca = "http://syriaca.org";
declare namespace functx = "http://www.functx.com";

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
declare function syriaca:next-id($ids as xs:string*,$prefix as xs:string*)
as xs:string*
{
    if (count($ids) > 0) then
        let $id-nums := 
            for $id in $ids
            return number(replace($id,$prefix,''))
        return concat($prefix,(1+max($id-nums)))
    else concat($prefix,1)
};

declare function syriaca:remove-attribute($nodes as node()*,$attribute as xs:string)
as node()*
{
    for $node in $nodes
    return element {name($node)} {$node/@*[not(name()=$attribute)],$node/node()}
};

declare function syriaca:update-attribute($input-node as node()*,$attribute as xs:string,$attribute-value as xs:string)
as node()*
{
    for $node in $input-node
        return
            element {xs:QName(name($node))} {
                        $node/@*[name()!=$attribute], 
                        attribute {xs:QName($attribute)} {$attribute-value}, 
                        $node/node()}
};

let $bhse-authors-doc := doc("/db/apps/srophe-data/data/persons/bhse-reconciled-authors.xml")
let $bhse-authors := $bhse-authors-doc//person/(author|editor)[not(@xml:id)]
(: Using just Ephrem for now for testing :)
let $persons := collection('/db/apps/srophe-data/data/persons/tei/')/TEI
let $works := collection('/db/apps/srophe-data/data/works/tei/')/TEI/text/body/bibl[author|editor]

for $person-record in $persons[text/body/listPerson/person/idno[starts-with(.,'http://syriaca.org')]/text()=$bhse-authors/@ref]
    let $person := $person-record/text/body/listPerson/person
    let $person-id := replace($person/idno[starts-with(.,'http://syriaca.org')],'http://syriaca.org/person/','')
    let $persNames-to-add := $bhse-authors[@ref=$person/idno/text()]/persName
    let $persName-sources := $persNames-to-add/@source
    let $persNames-no-sources := syriaca:remove-attribute($persNames-to-add, 'source')
    let $persNames-unique := functx:distinct-deep($persNames-no-sources)
(:    Test whether already has a BHSE name.:)
(:    let $has-bhse-name := $person[persName[replace(@source,'#','')=$person/bibl/@xml:id[../ptr/@target='http://syriaca.org/bibl/649']]]:)
    let $work-ids := 
        for $id in $persName-sources
        return replace(replace($id,'#bib',''),'-[\d]+$','')
    let $work-uris :=
        for $id in $work-ids
        return concat('http://syriaca.org/work/',$id)
    let $bhs-entries := 
        for $uri in $work-uris
        return $works[idno/text()=$uri]/idno[@type="BHS"]/text()
    let $bhs-citedRanges := 
        for $entry in $bhs-entries
        order by number($entry)
        return <citedRange unit='entry'>{$entry}</citedRange>
    let $bhs-bibl-id := syriaca:next-id($person/bibl/@xml:id, concat('bib',$person-id,'-'))
    let $bhs-bibl := 
        <bibl xml:id="{$bhs-bibl-id}">
            <title level="m" xml:lang="la">Bibliotheca Hagiographica Syriaca</title>
            <ptr target="http://syriaca.org/bibl/649"/>
            {$bhs-citedRanges}
        </bibl>
    let $new-persNames := 
        for $persName at $i in $persNames-unique
        let $persName-id-prefix := concat('name',$person-id,'-')
        let $persName-next-id := syriaca:next-id($person/persName/@xml:id, $persName-id-prefix)
        let $persName-next-id-num := number(replace($persName-next-id,$persName-id-prefix,''))-1+$i
        let $persName-id := concat($persName-id-prefix,$persName-next-id-num)
        let $persName-w-id := syriaca:update-attribute($persName, 'xml:id', $persName-id)
        return syriaca:update-attribute($persName-w-id, 'source', concat('#',$bhs-bibl-id))
    let $changelog := 
        <change who="http://syriaca.org/documentation/editors.xml#ngibson" when="2016-04-22+02:00">Added French names from BHSE.</change>
    

    return ( 
        update insert $changelog preceding $person-record/teiHeader/revisionDesc/change[1],
        update insert $new-persNames following $person/persName[last()],
        update insert $bhs-bibl into $person
        )