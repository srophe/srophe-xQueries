xquery version "3.0";

(:
 : Create new TEI bibl records from bhse-reconciled-authors.xml
 : Save records to db, must be logged into eXist as admin/with admin privileges
:)
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace syriaca = "http://syriaca.org";
declare namespace functx = "http://www.functx.com";

declare function syriaca:add-new-source($input-node as node()*,$old-non-bhse-bibls as node()*,$new-bibl-prefix as xs:string*)
as node()*
{
    for $node in $input-node
        return
            if ($node/@source) then
                let $bibl-position := index-of($old-non-bhse-bibls/@xml:id,replace($node/@source,'#',''))
                let $source := if(matches($node/@source,'#bib[\d]+-1$')) then
                    concat('#',$new-bibl-prefix,1)
                    else concat('#',$new-bibl-prefix,$bibl-position+1)
                return syriaca:update-attribute($node, 'source', $source)
(:                    element {xs:QName(name($node))} {:)
(:                        $node/@*[name()!='source'], :)
(:                        attribute {xs:QName('source')} {$source}, :)
(:                        $node/node()}:)
                else $node
};
declare function syriaca:persName-id($input-node as node()*,$person-id as xs:string*)
as element()*
{
    for $node at $i in $input-node
    let $id := concat('name',$person-id,'-',$i)
    return
        element {xs:QName('persName')} {
            $node/@*, 
            attribute {xs:QName('xml:id')} {$id}, 
            $node/node()}
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
let $bhse-authors := $bhse-authors-doc//person

(:For each person:)
for $person at $i in $bhse-authors/(author|editor)[@xml:id]

(:    If author/editor has @xml:id:)
(:        Grab @xml:id:)
    let $temp-id := $person/@xml:id
    
    (:        Assign person URI:)
    let $person-id := 2783 + $i
    let $work-id := replace(replace($person/@source, '#bib',''),'-1$','')
    
    (:        Create Zanetti bibl:)
    let $bhs-idno := doc(concat('/db/apps/srophe-data/data/works/tei/',$work-id,'.xml'))//idno[@type='BHS']
    let $bhse-bibl := 
        <bibl xml:id='{concat('bib',$person-id,'-1')}'>
            <title level="m" xml:lang="la">Bibliotheca Hagiographica Syriaca</title>
            <ptr target="http://syriaca.org/bibl/649"/>
            <citedRange unit="entry">{$bhs-idno}</citedRange>
        </bibl>
        
    (:        Replace bibl IDs:)
    let $old-bibl-prefix := concat('bib',$temp-id,'-')
    let $new-bibl-prefix := concat('bib',$person-id,'-')
    let $old-non-bhse-bibls := $person/../bibl[starts-with(@xml:id,$old-bibl-prefix)]
    let $new-non-bhse-bibls := 
        for $bibl at $i in $old-non-bhse-bibls
            let $new-bibl-id := concat($new-bibl-prefix,1+$i)
            let $new-bibl := <bibl xml:id='{$new-bibl-id}'>{$bibl/node()}</bibl>
            return $new-bibl
    let $persName-lang-order := ('syr','en','ar')
    let $persNames :=
        (
            for $lang in $persName-lang-order
                return syriaca:add-new-source($person/persName[starts-with(@xml:lang,$lang) and contains(@syriaca-tags,'#syriaca-headword')],$old-non-bhse-bibls,$new-bibl-prefix),
            syriaca:add-new-source($person/persName[not(starts-with(@xml:lang,$persName-lang-order)) and contains(@syriaca-tags,'#syriaca-headword')],$old-non-bhse-bibls,$new-bibl-prefix),
            for $lang in $persName-lang-order
                return syriaca:add-new-source($person/persName[starts-with(@xml:lang,$lang) and not(contains(@syriaca-tags,'#syriaca-headword'))],$old-non-bhse-bibls,$new-bibl-prefix),
            syriaca:add-new-source($person/persName[not(starts-with(@xml:lang,$persName-lang-order)) and not(contains(@syriaca-tags,'#syriaca-headword'))],$old-non-bhse-bibls,$new-bibl-prefix)
        )
    
    (:        Assign persName @xml:ids:)
    let $persNames-w-id := syriaca:persName-id($persNames, $person-id)
    
    let $other-nodes := $person/*[not(name()=('persName','bibl'))]
    
    let $en-title := string-join($persNames-w-id[starts-with(@xml:lang,'en') and contains(@syriaca-tags,'#syriaca-headword')][1]/child::*,' ')
    let $syr-headword := string-join($persNames-w-id[starts-with(@xml:lang,'syr') and contains(@syriaca-tags,'#syriaca-headword')][1]/child::*,' ')
    let $syr-headword-foreign := <foreign xml:lang='syr'>{$syr-headword}</foreign>
    let $syr-title := 
        if ($syr-headword) then 
            (' — ',$syr-headword-foreign)
            else ()
    let $record-title := ($en-title,$syr-title)
        
    
    let $record-contents :=
    <TEI xmlns="http://www.tei-c.org/ns/1.0"
     xmlns:tei="http://www.tei-c.org/ns/1.0"
     xmlns:syriaca="http://syriaca.org"
     xml:lang="en">
   <teiHeader>
      <fileDesc>
         <titleStmt>
            <title level="a" xml:lang="en">{$record-title}</title>
            <title level="s">The Syriac Biographical Dictionary</title>
            <sponsor>Syriaca.org: The Syriac Reference Portal</sponsor>
            <funder>The National Endowment for the Humanities</funder>
            <principal>David A. Michelson</principal>
            <editor role="general"
                    ref="http://syriaca.org/documentation/editors.xml#dmichelson">David A.
                        Michelson</editor>
            <editor role="associate"
                    ref="http://syriaca.org/documentation/editors.xml#tcarlson">Thomas A.
                        Carlson</editor>
            <editor role="associate"
                    ref="http://syriaca.org/documentation/editors.xml#ngibson">Nathan P.
                        Gibson</editor>
            <editor role="associate"
                    ref="http://syriaca.org/documentation/editors.xml#jnsaint-laurent">Jeanne-Nicole Mellon Saint-Laurent</editor>
            <editor role="creator"
                    ref="http://syriaca.org/documentation/editors.xml#ngibson">Nathan P. Gibson</editor>
            <respStmt>                
               <resp>Editing and data entry by</resp>                
               <name type="person" ref="http://syriaca.org/documentation/editors.xml#ngibson">Nathan P. Gibson</name>             
            </respStmt>             
            <respStmt>
               <resp>Data architecture and encoding by</resp>
               <name type="person" ref="http://syriaca.org/documentation/editors.xml#dmichelson">David A. Michelson</name>
            </respStmt>
         </titleStmt>
         <editionStmt>
            <edition n="1.0"/>
         </editionStmt>
         <publicationStmt>
            <authority>Syriaca.org: The Syriac Reference Portal</authority>
            <idno type="URI">http://syriaca.org/person/{$person-id}/tei</idno>
            <availability>
               <licence target="http://creativecommons.org/licenses/by/3.0/">
                  <p>Distributed under a Creative Commons Attribution 3.0 Unported
                                License.</p>
               </licence>
            </availability>
            <date>{current-date()}</date>
         </publicationStmt>
         <seriesStmt>
            <title level="s">The Syriac Biographical Dictionary</title>
            <editor role="general"
                    ref="http://syriaca.org/documentation/editors.xml#dmichelson">David A.
                        Michelson</editor>
            <editor role="associate"
                    ref="http://syriaca.org/documentation/editors.xml#tcarlson">Thomas A.
                        Carlson</editor>
            <editor role="associate"
                    ref="http://syriaca.org/documentation/editors.xml#ngibson">Nathan P.
                        Gibson</editor>
            <editor role="associate"
                    ref="http://syriaca.org/documentation/editors.xml#jnsaint-laurent">Jeanne-Nicole Mellon Saint-Laurent</editor>
            <respStmt>
               <resp>Edited by</resp>
               <name type="person"
                     ref="http://syriaca.org/documentation/editors.xml#dmichelson">David A.
                            Michelson</name>
            </respStmt>
            <respStmt>
               <resp>Edited by</resp>
               <name type="person"
                     ref="http://syriaca.org/documentation/editors.xml#tcarlson">Thomas A.
                            Carlson</name>
            </respStmt>
            <respStmt>
               <resp>Edited by</resp>
               <name type="person"
                     ref="http://syriaca.org/documentation/editors.xml#ngibson">Nathan P.
                            Gibson</name>
            </respStmt>
            <respStmt>
               <resp>Edited by</resp>
               <name type="person"
                     ref="http://syriaca.org/documentation/editors.xml#jnsaint-laurent">Jeanne-Nicole Mellon Saint-Laurent</name>
            </respStmt>
            <biblScope unit="vol">2</biblScope>
            <idno type="URI">http://syriaca.org/persons</idno>
         </seriesStmt>
         <sourceDesc>
            <p>Born digital.</p>
         </sourceDesc>
      </fileDesc>
      <encodingDesc>
         <editorialDecl>
            <p>This record created following the Syriaca.org guidelines. Documentation
                        available at: <ref target="http://syriaca.org/documentation">http://syriaca.org/documentation</ref>.</p>
            <interpretation>
               <p>Approximate dates described in terms of centuries or partial centuries
                            have been interpreted as documented in <ref target="http://syriaca.org/documentation/dates.html">Syriaca.org
                                Dates</ref>.</p>
            </interpretation>
         </editorialDecl>
         <classDecl>
            <taxonomy>
               <category xml:id="syriaca-headword">
                  <catDesc>The name used by Syriaca.org for document titles, citation, and
                                disambiguation. These names have been created according to the
                                Syriac.org guidelines for headwords: <ref target="http://syriaca.org/documentation/headwords.html">http://syriaca.org/documentation/headwords.html</ref>.</catDesc>
               </category>
               <category xml:id="syriaca-anglicized">
                  <catDesc>An anglicized version of a name, included to facilitate
                                searching.</catDesc>
               </category>
            </taxonomy>
            <taxonomy>
               <category xml:id="syriaca-author">
                  <catDesc>A person who is relevant to the Guide to Syriac
                                Authors</catDesc>
               </category>
               <category xml:id="syriaca-saint">
                  <catDesc>A person who is relevant to the Bibliotheca Hagiographica
                                Syriaca.</catDesc>
               </category>
            </taxonomy>
         </classDecl>
      </encodingDesc>
      <profileDesc>
         <langUsage>
            <language ident="syr">Unvocalized Syriac of any variety or period</language>
            <language ident="syr-Syrj">Vocalized West Syriac</language>
            <language ident="syr-Syrn">Vocalized East Syriac</language>
            <language ident="en">English</language>
            <language ident="en-x-gedsh">Names or terms Romanized into English according to
                        the standards adopted by the Gorgias Encyclopedic Dictionary of the Syriac
                        Heritage</language>
            <language ident="ar">Arabic</language>
            <language ident="fr">French</language>
            <language ident="de">German</language>
            <language ident="la">Latin</language>
         </langUsage>
      </profileDesc>
      <revisionDesc status="draft">
         <change who="http://syriaca.org/documentation/editors.xml#ngibson"
                 n="1.0"
                 when="{current-date()}">CREATED: person</change>
      </revisionDesc>
   </teiHeader>
   <text>
      <body>
         <listPerson>
            <person xml:id="person-{$person-id}">
               {$persNames-w-id}
               {$bhs-idno}
               {syriaca:add-new-source($other-nodes, $old-non-bhse-bibls, $new-bibl-prefix)}
               {$bhse-bibl}
               {$new-non-bhse-bibls}
            </person>
         </listPerson>
      </body>
   </text>
</TEI>
    
    let $collection-uri := "/db/apps/srophe-data/data/persons/tei/"
    let $resource-name := concat($person-id,'.xml')
    let $person-uri := concat('http://syriaca.org/person/',$person-id)
    let $matching-persons := $bhse-authors/(author|editor)[@ref=concat('#',$temp-id)]
    return (
        xmldb:store($collection-uri, $resource-name, $record-contents),
        update replace $person with syriaca:update-attribute($person, 'ref', $person-uri),
        update replace $matching-persons with syriaca:update-attribute($matching-persons, 'ref', $person-uri)
    )





(:        Create new person record with new URIs/IDs on person element.:)
(:        Replace @refs in original file with new IDs.:)