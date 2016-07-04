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
(: On this particular run, only multiple authors or those with @role need to be updated :)
let $bhse-authors := $bhse-authors-doc//person[(count(author|editor) > 1) or (author/@role) or (editor/@role)]
let $works := collection('/db/apps/srophe-data/data/works/tei/')/TEI/text/body/bibl
let $persons := collection('/db/apps/srophe-data/data/persons/tei/')/TEI/text/body/listPerson/person

(:For each person that does not have @xml:id,:)
for $person in $bhse-authors
    let $authors := $person/(author|editor)
    let $work-id := replace(replace($authors[1]/@source,'#bib',''),'-1$','')
    let $work-uri := concat('http://syriaca.org/work/',$work-id)
    let $work := $works[idno=$work-uri]
    (:        Get author element of BHSE record:)
    let $work-changelog := $work/../../../teiHeader/revisionDesc
    let $change := <change who="http://syriaca.org/editors.xml#ngibson" when="{current-date()}">CHANGED: Corrected multiple author and author role info</change>
    let $work-authors := $work/*[name()='author' or name()='editor']
    let $name-attributes-to-remove := ('xml:id','corresp','source','resp')
    
    let $new-authors := 
        for $author in $authors
            let $ref-person := $persons[idno=$author/@ref]
            let $en-headword := $ref-person/persName[starts-with(@xml:lang,'en') and contains(@syriaca-tags,'#syriaca-headword')][1]
            let $syr-headword := $ref-person/persName[starts-with(@xml:lang,'syr') and contains(@syriaca-tags,'#syriaca-headword')][1]
            let $fr-zanetti-name := $ref-person/persName[@xml:lang='fr' and replace(@source,'#','')=$ref-person/bibl[ptr/@target='http://syriaca.org/bibl/649']/@xml:id][1]
            let $matching-work-author := 
                if (count($work-authors) = 1) then
                    $work-authors
                else if ($work-authors/*[@ref=$author/@ref]) then
                    $work-authors/*[@ref=$author/@ref]
                else if ($work-authors/*[text()=$fr-zanetti-name]) then
                    $work-authors/*[text()=$fr-zanetti-name]
                else $work-authors[1]
            let $work-author-attributes := $matching-work-author/@*[name()!='ref' and name()!='role' and name()!='xml:lang']
            let $new-author-content := ( 
            syriaca:remove-extra-attributes($en-headword,$name-attributes-to-remove),
            ' — ',
            syriaca:remove-extra-attributes($syr-headword,$name-attributes-to-remove),
            ' (',
            syriaca:remove-extra-attributes($fr-zanetti-name,$name-attributes-to-remove),
            ')'
            )
            return element {xs:QName(name($author))} {$matching-work-author/@*[name()!='ref' and name()!='role' and name()!='xml:lang'], attribute {xs:QName('ref')} {$author/@ref}, $author/@role, $new-author-content}
    
    
    return 
        (update insert $new-authors following $work-authors, update delete $work-authors, update insert $change preceding $work-changelog/change[1])