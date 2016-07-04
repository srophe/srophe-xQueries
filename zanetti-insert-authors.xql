xquery version "3.0";

(:Insert identified authors from bhse-authors-reconciled.xml into BHSE records.:)

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace syriaca = "http://syriaca.org";
declare namespace functx = "http://www.functx.com";

declare function syriaca:remove-extra-attributes($input-node as node()*,$attributes-to-remove as xs:string*)
as node()*
{
    for $node in $input-node
    return
        element {xs:QName(name($node))} {
            $node/@*[not(name()=$attributes-to-remove)], 
            $node/node()}
};

let $bhse-authors-doc := doc("/db/apps/srophe-data/data/persons/bhse-reconciled-authors.xml")
let $bhse-authors := $bhse-authors-doc//person
let $works := collection('/db/apps/srophe-data/data/works/tei/')/TEI/text/body/bibl
let $persons := collection('/db/apps/srophe-data/data/persons/tei/')/TEI/text/body/listPerson/person

(:For each person that does not have @xml:id,:)
for $person in $bhse-authors/(author|editor)[not(@xml:id)]
    let $work-id := replace(replace($person/@source,'#bib',''),'-1$','')
    let $work-uri := concat('http://syriaca.org/work/',$work-id)
    let $work := $works[idno=$work-uri]
    (:        Get author element of BHSE record:)
    let $work-author := $work/author|$work/editor
    (:    If there is only one author/editor element:)
    let $ref-person := $persons[idno=$person/@ref]
    let $name-attributes-to-remove := ('xml:id','corresp','source')
    let $new-author-content := ( 
        syriaca:remove-extra-attributes($ref-person/persName[starts-with(@xml:lang,'en') and contains(@syriaca-tags,'#syriaca-headword')][1],$name-attributes-to-remove),
        ' — ',
        syriaca:remove-extra-attributes($ref-person/persName[starts-with(@xml:lang,'syr') and contains(@syriaca-tags,'#syriaca-headword')][1],$name-attributes-to-remove),
        ' (',
        syriaca:remove-extra-attributes($person/persName,$name-attributes-to-remove),
        ')'
        )
    let $new-author := element {xs:QName(name($person))} {$work-author/@*[name()!='ref'], attribute {xs:QName('ref')} {$person/@ref}, $new-author-content}
    
    return 
(:        $work/idno[(name(../author)='') or (name(../editor)='')]:)
        if (count($work-author)=1) then
            update replace $work-author with $new-author
        else $new-author