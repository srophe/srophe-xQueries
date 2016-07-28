xquery version "3.0";

(:Checks for bibl records that have a <note type="tag">Subject: http://syriaca.org/...</note> :)
(:and adds the bibl as a citation to the record indicated in the subject tag.:)
(:Also deletes the subject tag from the bibl record.:)
(:See zotero-tei-2-syriaca-tei.xql for the script that converts Zotero exports into the format this script assumes .:)

(: NAMESPACES:)
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

let $entities := collection('/db/apps/srophe-data/data/')
let $bibls := $entities[matches(TEI/teiHeader/fileDesc/publicationStmt/idno,'http://syriaca.org/bibl')]/TEI/text/body/biblStruct

for $bibl in $bibls[note[@type='tag' and matches(.,'^\s*Subject:\s*')]]
    let $subjects := $bibl/note[@type='tag' and matches(.,'^\s*Subject:\s*')]
    let $related-record-uris :=
        for $subject in $subjects
        return replace($subject,'^\s*Subject:\s*','')
    let $add-citation := 
        for $uri in $related-record-uris
            let $related-record := $entities[matches(TEI/teiHeader/fileDesc/publicationStmt/idno,concat($uri,'/tei'))]/TEI
            let $related-record-id := replace($uri,'http://syriaca.org/.*?/','')
            let $record-bibls := $related-record/text/body/(bibl|listPerson/person|listPlace/place)/bibl
            let $bibl-id := syriaca:next-id($record-bibls/@xml:id, concat('bib',$related-record-id,'-'), 1)
            let $citation := 
            <bibl xml:id='{$bibl-id}'>
                {$bibl//title}
                <ptr target='{$bibl/*/idno[matches(.,'http://syriaca.org')]}'/>
            </bibl>
        return update insert $citation following $record-bibls[last()]
return ($add-citation, update delete $subjects)