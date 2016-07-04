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

let $bibls := collection("/db/apps/srophe-data/data/bibl/tei/")/TEI/text/body/biblStruct
for $idno in $bibls/*/idno[@type='callNumber' and matches(.,'\d+\s')]
    let $tokenized := tokenize($idno/text(), ' ')
    let $idnos-all := 
        for $num in $tokenized
        return <idno type="URI">http://www.worldcat.org/oclc/{$num}</idno>
return 
    (update insert $idnos-all following $idno,
    update delete $idno)