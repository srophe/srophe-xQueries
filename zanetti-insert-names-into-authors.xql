xquery version "3.0";

(:Put Zanetti's French names into author records:)

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace syriaca = "http://syriaca.org";
declare namespace functx = "http://www.functx.com";

declare function syriaca:next-id($ids as xs:string*,$prefix as xs:string*)
as xs:string*
{
    let $id-nums := 
        for $id in $ids
        return number(replace($id,$prefix,''))
    return concat($prefix,(max($id-nums)+1))
};

let $bhse-authors-doc := doc("/db/apps/srophe-data/data/persons/bhse-reconciled-authors.xml")
let $bhse-authors := $bhse-authors-doc//person
let $persons := collection('/db/apps/srophe-data/data/persons/tei/')/TEI/text/body/listPerson/person
let $works := collection('/db/apps/srophe-data/data/works/tei/')/TEI/text/body/bibl[author|editor]

(:For each author in doc without an @xml:id,:)
for $bhse-author in $bhse-authors/author[not(@xml:id)]|$bhse-authors/editor[not(@xml:id)]
(:    Grab name:)
    let $author-name := $bhse-author/persName
(:    Grab entry #:)
    let $work-id := replace(replace($bhse-author/@source,'#bib',''),'-1$','')
    let $work-uri := concat('http://syriaca.org/work/',$work-id)
    let $entry := $works[idno=$work-uri]/idno[@type='BHS']/text()
(:    Get corresponding author record:)    
    let $author-uri := $bhse-author/@ref
    let $author-id := replace($author-uri,'http://syriaca.org/person/','')
    let $author-record := $persons[idno=$author-uri]
(:    If BHSE bibl exists:)    
    let $bibls := $author-record/bibl
    let $has-bhse-bibl := $bibls/bibl[ptr/@target='http://syriaca.org/bibl/649']
    let $new-cited-range := <citedRange unit='entry'>{$entry}</citedRange>
    let $sorted-citedRanges := 
        for $citedRange in ($has-bhse-bibl/citedRange,$new-cited-range)
        order by $citedRange
        return $citedRange
    (:        Count bibls (and @xml:ids):)
(:    let $bibl-numbers := :)
(:        for $id in $bibls/@xml:id:)
(:        return number(replace($id,'bib[\d]+-','')):)
(:    let $new-bibl-number := max($bibl-numbers)+1:)
    let $new-bibl-id := syriaca:next-id($bibls/@xml:id, concat('bib',$author-id,'-'))
    let $new-bibls := 
        if ($has-bhse-bibl) then
(:        add entry to it:)
            let $new-bibl := element bibl {@*, $has-bhse-bibl/*[not(name()='citedRange')],$sorted-citedRanges}
            return update replace $has-bhse-bibl with $new-bibl
        else 
            
            (:        Create bibl:)
            let $new-bibl := 
                <bibl xml:id="{$new-bibl-id}">
                    <title level="m" xml:lang="la">Bibliotheca Hagiographica Syriaca</title>
                    <ptr target="http://syriaca.org/bibl/649"/>
                    {$new-cited-range}
                </bibl>
            return update insert $new-bibl following $bibls[last()]
    (:    Create @source var:)
    let $source-bibl-id := 
        if ($has-bhse-bibl) then 
            $has-bhse-bibl/@xml:id
        else $new-bibl-id
    let $source := concat('#',$source-bibl-id)
    let $old-persNames := $author-record/persName
(:    If name already exists with same content:)
    (:        grab name:)
    let $has-matching-name := $author-record/persName[string-length(.)>0 and string(.)=string($author-name/persName)]
    let $new-persNames := 
        if ($has-matching-name) then
            (:        add @source:)
            let $matching-name-w-new-source:= 
                element persName {
                    $has-matching-name/@*[not(name()='source')],
                    attribute source {string-join(($has-matching-name/@source[.!=$source],$source),' ')},
                    $has-matching-name/node()
                }
            return update replace $has-matching-name with $matching-name-w-new-source
        else
            let $name-id := syriaca:next-id($author-record/persName/@xml:id, concat('name',$author-id,'-'))
            let $new-name := 
                element persName {
                    $author-name/@xml:lang,
                    attribute xml:id {$name-id},
                    attribute source {$source},
                    $author-name/node()}
            return update insert $new-name following $old-persNames[last()]
            

return ($new-bibls,$new-persNames)