xquery version "3.0";

(:Convert TEI exported from Zotero to Syriaca TEI bibl records:)
(:The function xmldb:store must be run in eXist:)

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

let $zotero-doc := doc("/db/apps/srophe-data/data/bibl/fiey-bibls-zotero-export.xml")
for $zotero-bibl at $i in $zotero-doc/listBibl/biblStruct
    
    let $bibl-id := (1299 + $i)
    let $syriaca-uri := concat('http://syriaca.org/bibl/',$bibl-id)
    let $syriaca-idno := <idno type='URI'>{$syriaca-uri}</idno>
    (:tags:)
    let $zotero-id := $zotero-bibl/note[@type='tags']/note[@type='tag']/text()
    let $zotero-idno := <idno type='zotero'>{$zotero-id}</idno>
    let $zotero-idno-uri := <idno type='URI'>{string($zotero-bibl/@corresp)}</idno>
    let $callNumbers := $zotero-bibl/idno[@type='callNumber']
    let $callNumber-idnos := 
        for $num in $callNumbers
        return
            if (matches($num/text(),'^[\d]+$')) then
                <idno type='URI'>{concat('http://www.worldcat.org/oclc/',$num/text())}</idno>
            else $num
    let $issn-idnos := $zotero-bibl/idno[@type='ISSN']
    let $isbns := tokenize(normalize-space($zotero-bibl/idno[@type='ISBN']/text()),'\s')
    let $isbn-idnos := 
        for $isbn in $isbns
        return <idno type='ISBN'>{$isbn}</idno>
    let $all-idnos := ($syriaca-idno,$zotero-idno,$zotero-idno-uri,$callNumber-idnos,$issn-idnos,$isbn-idnos)
    
(:    links to external resources:)
    let $refs := 
        for $url in $zotero-bibl//note[@type='url']
        return <ref target='{$url/text()}'/>
        
    (:biblScope & @unit:)
    let $biblScopes-monogr-old := $zotero-bibl/monogr/imprint/biblScope
    let $biblScopes-monogr-new := (
        syriaca:update-attribute($biblScopes-monogr-old[@unit='volume'], 'unit', 'vol'),
        $biblScopes-monogr-old[@unit!='volume' and @unit!='page'],
        syriaca:update-attribute($biblScopes-monogr-old[@unit='page'], 'unit', 'pp')
        )
    let $biblScopes-series-old := $zotero-bibl/series/biblScope
    let $biblScopes-series-new := (
        syriaca:update-attribute($biblScopes-series-old[@unit='volume'], 'unit', 'vol'),
        $biblScopes-series-old[@unit!='volume']
        )
    (: respStmt :)
    let $resps-analytic := $zotero-bibl/analytic/respStmt
    let $resps-monogr := $zotero-bibl/monogr/respStmt
    let $translators-analytic := 
        for $translator in $resps-analytic[resp='translator']/persName
        return element editor {attribute role {'translator'},$translator/node()}
    let $translators-monogr := 
        for $translator in $resps-monogr[resp='translator']/persName
        return element editor {attribute role {'translator'},$translator/node()}
        
    let $analytic := $zotero-bibl/analytic
    let $tei-analytic :=
        if ($analytic) then
            <analytic>
                {$analytic/(author|editor),$translators-analytic}
                {$analytic/title}
                {$all-idnos}
                {$refs}
            </analytic>
            else()
            
    let $monogr := $zotero-bibl/monogr
    let $tei-monogr :=
        if ($monogr) then
            <monogr>
                {$monogr/(author|editor),$translators-monogr}
                {$monogr/title[not(@type='short')]}
                {if ($tei-analytic) then () else ($all-idnos,$refs)}
                {element imprint {$monogr/imprint/*[not(name()='biblScope') and not(name()='note')]}}
                {$biblScopes-monogr-new}
            </monogr>
            else()
    let $series := $zotero-bibl/series
    let $tei-series :=
        if ($series) then
            <series>
                {$series/(author|editor)}
                {$series/title[not(@type='short')]}
                {$biblScopes-series-new}
            </series>
            else()
    
    
        
    let $titles-all := $zotero-bibl//title[not(@type='short')]
    
    let $tei-record :=
    
    <TEI xmlns="http://www.tei-c.org/ns/1.0">
        <teiHeader>
            <fileDesc>
                <titleStmt>
                    {$titles-all}
                    <sponsor>Syriaca.org: The Syriac Reference Portal</sponsor>
                    <funder>The National Endowment for the Humanities</funder>
                    <funder>The International Balzan Prize Foundation</funder>
                    <principal>David A. Michelson</principal>
                    <editor role="general" ref="http://syriaca.org/documentation/editors.xml#dmichelson">David A. Michelson</editor>
                    <editor role="creator" ref="http://syriaca.org/documentation/editors.xml#jfiey">J. M. Fiey</editor>
                    <editor role="creator" ref="http://syriaca.org/documentation/editors.xml#jnsaint-laurent">Jeanne-Nicole Mellon Saint-Laurent</editor>
                    <editor role="creator" ref="http://syriaca.org/documentation/editors.xml#ngibson">Nathan P. Gibson</editor>
                    <editor role="creator" ref="http://syriaca.org/documentation/editors.xml#dkiger">David Kiger</editor>
                    <respStmt>
                        <resp>Data entry by</resp>
                        <name ref="http://syriaca.org/documentation/editors.xml#dkiger">David Kiger</name>
                    </respStmt>
                    <respStmt>
                        <resp>XML coded by</resp>
                        <name ref="http://syriaca.org/documentation/editors.xml#ngibson">Nathan P. Gibson</name>
                    </respStmt>
                    <respStmt>
                        <resp>TEI records generated by</resp>
                        <name ref="http://syriaca.org/documentation/editors.xml#ngibson">Nathan P. Gibson</name>
                    </respStmt>
                    <respStmt>
                        <resp>Bibliography items adapted from the work of</resp>
                        <name ref="http://syriaca.org/documentation/editors.xml#jfiey">J. M. Fiey</name>
                    </respStmt>
                </titleStmt>
                <publicationStmt>
                    <authority>Syriaca.org: The Syriac Reference Portal</authority>
                    <idno type="URI">http://syriaca.org/bibl/{$bibl-id}/tei</idno>
                    <availability>
                        <licence target="http://creativecommons.org/licenses/by/3.0/">
                            <p>Distributed under a Creative Commons Attribution 3.0 Unported License.</p>
                        </licence>
                    </availability>
                    <date>{current-date()}</date>
                </publicationStmt>
                <sourceDesc>
                    <p>Born digital.</p>
                </sourceDesc>
            </fileDesc>
            <revisionDesc>
                <change who="http://syriaca.org/documentation/editors.xml#ngibson" when="{current-date()}">CREATED: bibl</change>
            </revisionDesc>
        </teiHeader>
        <text>
            <body>
                <biblStruct>
                    {$tei-analytic}
                    {$tei-monogr}
                    {$tei-series}
                </biblStruct>
            </body>
        </text>
    </TEI>
    
    let $collection-uri := "/db/apps/srophe-data/data/bibl/tei/"
    let $resource-name := concat($bibl-id,'.xml')
    return xmldb:store($collection-uri, $resource-name, $tei-record)