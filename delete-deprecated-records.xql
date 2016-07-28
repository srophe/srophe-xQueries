xquery version "3.0";

(:This is intended to clean up your local exist-db install by removing records that have been deprecated. :)
(:It simply deletes them rather than moving them to a deprecated folder.:)

(: NAMESPACES:)
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace syriaca = "http://syriaca.org";
declare namespace functx = "http://www.functx.com";

let $entities := collection('/db/apps/srophe-data/data/')

for $record in $entities[TEI/teiHeader/fileDesc/publicationStmt/idno/@type='deprecated']/TEI
    for $deprecated-uri in $record/teiHeader/fileDesc/publicationStmt/idno[@type='deprecated']
    return if ($entities[TEI/teiHeader/fileDesc/publicationStmt/idno[@type='URI']=$deprecated-uri]) then
            let $deprecated-record := $entities[TEI/teiHeader/fileDesc/publicationStmt/idno[@type='URI']=$deprecated-uri]
            let $collection-path := util:collection-name($deprecated-record)
            let $document-path := util:document-name($deprecated-record)
            return xmldb:remove($collection-path,$document-path)
        else()