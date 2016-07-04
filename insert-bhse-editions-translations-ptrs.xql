xquery version "3.0";

(:Convert TEI exported from Zotero to Syriaca TEI bibl records:)

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
                        attribute {xs:QName($attribute)} {$attribute-value}, 
                        $node/node()}
};

let $works := collection("/db/apps/srophe-data/data/works/tei/")/TEI/text/body/bibl
let $bibls := collection("/db/apps/srophe-data/data/bibl/tei/")/TEI/text/body/biblStruct

for $bibl in $works//bibl[idno/@type='zotero']
    let $idno-zotero := $bibl/idno[@type='zotero']
    let $bibl-matching := $bibls/(analytic|monogr)[idno[@type='zotero']=$idno-zotero]
    let $ptr := element ptr {attribute target {$bibl-matching/idno[@type='URI' and matches(.,'http://syriaca.org/bibl')]}}
return 
    (update insert $ptr following $idno-zotero,
    update delete $idno-zotero)