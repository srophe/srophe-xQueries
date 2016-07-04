xquery version "3.0";

(: SCRIPT FOR MERGING PERSON RECORDS by ngibson :)
 
(:  INSTRUCTIONS: :)
(:  - Run this script on your local eXist-db installation. :)
(:  - You will need to scroll down to the VARIABLES section:)
(:  and change the $master-uri and $secondary-uri to the URIs of the records you want to merge. Also change the username. :)
(:  - Most of the information will be kept from both the master record and the secondary record, :)
(:  but for items that there should be only one of, the version from the master record will be kept :)
(:  (e.g., the Syriaca idnos, the #syriaca-headword tag, etc.). When there is matching data in the two records but the :)
(:  sources are different, the script *should* combine the two nodes but add another value to the @source. :)
(:  - The script is far from perfect. Try running it and then viewing the differences between the input and output files, :)
(:  using Oxygen's file diff tool or Github. :)
  
(:  KNOWN LIMITATIONS :)
(:  - No @syriaca-tags are preserved from the secondary record.:)
(:  - Source attributes pointing to bibls that don't have a ptr/@target will not be merged correctly. :)
(:    (The script uses the ptr/@target for matching with the correct source bibl.):)
 

(: NAMESPACES:)
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace syriaca = "http://syriaca.org";
declare namespace functx = "http://www.functx.com";


(: CUSTOM FUNCTIONS :)

(: COMPARISON FUNCTIONS :)
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

(: ATTRIBUTE UPDATING FUNCTIONS :)
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

declare function syriaca:remove-extra-attributes($input-node as node()*,$attributes-to-remove as xs:string*)
as node()*
{
    for $node in $input-node
    return
        if ($node/descendant-or-self::*[@*/name()=$attributes-to-remove]) then
            element {xs:QName(name($node))} {
                $node/@*[not(name()=$attributes-to-remove)], 
                syriaca:remove-extra-attributes($node/node(), $attributes-to-remove)}
        else $node
};

declare function syriaca:update-attribute($input-node as node()*,$attribute as xs:string,$attribute-value as xs:string)
as node()*
{
    for $node in $input-node
        return
            element {xs:QName(name($node))} {
                        $node/@*[name()!=$attribute], 
                        attribute {$attribute} {$attribute-value}, 
                        $node/node()}
};

declare function syriaca:update-secondary-xml-ids($secondary-nodes as node()*,$master-nodes as node()*,$master-id as xs:string,$iteration as xs:double?)
as node()*
{
    if ($secondary-nodes and ($master-nodes/@xml:id or $secondary-nodes/@xml:id)) then 
        for $secondary-node at $i in $secondary-nodes
            let $prefix-base := replace(($master-nodes/@xml:id|$secondary-nodes/@xml:id)[1],'[\d]+-[\d]+','')
            let $prefix := concat($prefix-base,$master-id,'-')
            let $new-node := 
                syriaca:update-attribute
                        ($secondary-node,
                        'xml:id',
                        syriaca:next-id($master-nodes/@xml:id, $prefix,$i + $iteration))
            return $new-node
                
        else $secondary-nodes
};
declare function syriaca:update-sources($input-nodes as node()*,$old-bibls as node()*,$new-bibls as node()*)
as node()*
{
    for $node in $input-nodes
        return if ($node/descendant-or-self::*/@source) then
            if ($node/@source) then
                let $old-bibl-id := replace($node/@source,'#','')
                let $ptr := $old-bibls[@xml:id=$old-bibl-id]/ptr/@target
                let $new-source := concat('#',$new-bibls[ptr/@target=$ptr]/@xml:id)
                return syriaca:update-attribute(
                    if ($node/descendant::*/@source) then 
                        element {name($node)} {$node/@*,syriaca:update-sources($node/node(), $old-bibls, $new-bibls)}
                        else $node,
                    'source',
                    $new-source)
                else element {name($node)} {$node/@*,syriaca:update-sources($node/node(), $old-bibls, $new-bibls)}
            else $node
};
declare function syriaca:update-relation-attributes($input-nodes as node()*,$master-id,$secondary-id)
as node()*
{
    let $master-uri := concat('http://syriaca.org/person/',$master-id)
    let $master-person-id := concat('#person-',$master-id)
    let $secondary-uri := concat('http://syriaca.org/person/',$secondary-id)
    let $secondary-person-id := concat('#person-',$secondary-id)
    for $node in $input-nodes
        let $new-attributes := 
            for $attribute in $node/(@mutual|@active|@passive)
                let $attribute-value := 
                    replace
                        (replace
                            (replace($attribute,$master-id,$master-uri),
                            $secondary-person-id,
                            $master-uri),
                        $secondary-uri,
                        $master-uri)
                return attribute {name($attribute)} {$attribute-value}
        return element {name($node)} {$node/@*[not(name()=('mutual','active','passive'))],$new-attributes,$node/node()}
};
 
(: MERGE FUNCTIONS :)
 declare function functx:value-union
  ( $arg1 as xs:anyAtomicType* ,
    $arg2 as xs:anyAtomicType* )  as xs:anyAtomicType* {

  distinct-values(($arg1, $arg2))
 } ;

declare function syriaca:merge-master-nodes($master-nodes as node()*,$secondary-nodes as node()*,$matching-secondary-node-path as xs:string*,$elements-to-join as xs:string*) as node()*
{
    for $node in $master-nodes
        let $matching-secondary-nodes := util:eval($matching-secondary-node-path)
        let $joined-elements :=
            for $element in $elements-to-join
                return functx:distinct-deep(($node|$matching-secondary-nodes)/*[name()=$element])
(:                Due to namespace issues, might have to prefix attribute on $matching-secondary-nodes :)
        let $sources := syriaca:merge-attribute-values(($node/@source,$matching-secondary-nodes/@source), 'source')
        let $syriaca-tags-secondary := 
            for $tag in $matching-secondary-nodes/@syriaca-tags
            return attribute syriaca-tags {replace($tag,'[\s]*#syriaca-headword[\s]*','')}
        let $syriaca-tags := syriaca:merge-attribute-values(($node/@syriaca-tags,$syriaca-tags-secondary), 'syriaca-tags')
        
        return 
            element {$node/name()} {$node/@*[not(name()=('source','syriaca-tags'))],$syriaca-tags,$sources,$node/node()[not(name()=$elements-to-join)],$joined-elements}
};

declare function syriaca:merge-attribute-values($attribute-values as node()*, $attribute-name as xs:string) as node()*
{
        let $joined-values := normalize-space(string-join(distinct-values($attribute-values),' '))
        return if ($joined-values) then attribute {$attribute-name} {$joined-values} else ()
};


declare function syriaca:merge-nodes($master-nodes as node()*,$secondary-nodes as node()*,$matching-test-for-secondary-nodes as xs:string*,$elements-to-join as xs:string*,$secondary-bibls as node()*,$new-bibls as node()*) as node()*
{
    let $master-id := replace(replace($new-bibls[1]/@xml:id,'bib',''),'-[\d]+$','')
    let $secondary-unique-nodes := util:eval(concat('$secondary-nodes[not(',replace($matching-test-for-secondary-nodes,'\$node','\$master-nodes'),')]'))
    let $secondary-unique := 
        let $secondary-unique-updated-ids := 
            for $node at $i in $secondary-unique-nodes
            return syriaca:update-secondary-xml-ids($node, $master-nodes, $master-id, $i - 1)
        return syriaca:update-sources($secondary-unique-updated-ids, $secondary-bibls, $new-bibls)
    let $secondary-unique-no-headwords := 
        syriaca:remove-extra-attributes($secondary-unique, 'syriaca-tags')
        
    let $master-merged := 
        syriaca:merge-master-nodes
            ($master-nodes,
            syriaca:update-sources($secondary-nodes, $secondary-bibls, $new-bibls), 
            concat('$secondary-nodes[',$matching-test-for-secondary-nodes,']'), 
            $elements-to-join)
    return 
        ($master-merged,$secondary-unique-no-headwords)
};

declare function syriaca:preserve-master($master-node as node()?,$secondary-node as node()?,$secondary-bibls as node()*,$new-bibls as node()*) as node()?
{
    let $secondary-node-updated := syriaca:update-sources($secondary-node, $secondary-bibls, $new-bibls)
    return 
        if ($master-node) then
            let $sources := 
                if (($master-node/@source and $secondary-node/@source) and 
                (syriaca:remove-extra-attributes($master-node, ('xml:id','source')) = syriaca:remove-extra-attributes($secondary-node, ('xml:id','source')))) 
                then
                    syriaca:merge-attribute-values(($master-node/@source,$secondary-node/@source), 'source')
                    else $master-node/@source
            return element {name($master-node)} {$master-node/@*[name()!='source'],$sources,$master-node/node()}
            else $secondary-node-updated
};

declare function syriaca:combine-dates($dates as node()*)  as node()? {
    if (count($dates) > 1) then
        let $new-dates := 
            for $date in $dates
            order by $date/@when, $date/@from
            return element date {$date/@*,$date/node()}
        
        return 
            element {name($dates[1])} {$new-dates}
    else ($dates)
 
 } ;


(: RECORD REWRITING FUNCTIONS :)
declare function syriaca:deprecate-merge-redirect($tei-root as node(),$redirect-uri as xs:string,$user as xs:string)

{
    let $secondary-uri := 
        replace($tei-root/teiHeader/fileDesc/publicationStmt/idno[@type='URI'][1], '/tei','')
    let $secondary-id := replace($secondary-uri,'http://syriaca.org/person/','')
    let $changes-old := $tei-root/teiHeader/revisionDesc/change
    let $change-id := syriaca:next-id($changes-old/@xml:id, concat('change',$secondary-id,'-'), 1)
    let $change-attribute := attribute change {concat('#',$change-id)}
    let $change :=
        element change 
            {attribute who {concat('http://syriaca.org/documentation/editors.xml#',$user)},
            attribute when {current-date()},
            attribute xml:id {$change-id},
            concat('Merged into [',$redirect-uri,'] and deprecated.')
            }
            
    let $title-old := $tei-root/teiHeader/fileDesc/titleStmt/title[@level='a']
    let $title := element title {$title-old/@*,$title-old/node(),' [deprecated]'}
    let $publication-idno-old := $tei-root/teiHeader/fileDesc/publicationStmt/idno
    let $publication-idno := 
        (element idno {$publication-idno-old/@*,$change-attribute,$publication-idno-old/node()},
        element idno {attribute type {'redirect'},$change-attribute,concat($redirect-uri,'/tei')})
    let $revisionDesc-old := $tei-root/teiHeader/revisionDesc
    let $revisionDesc := element revisionDesc {
        syriaca:update-attribute($revisionDesc-old, 'status', 'deprecated')/@*,
        $change,
        $revisionDesc-old/node()}
    let $body-old := $tei-root/text/body
    let $body-text := 
            element desc {
                $change-attribute,
                attribute type {'deprecation'},
                concat('This record has been deprecated and merged into ',$redirect-uri,'.')}
    let $body := element body {$body-old/@*,$body-text,$body-old/node()}
    let $idno-old := $tei-root/text/body/listPerson/person/idno[text()=$secondary-uri]
    let $idno := 
        (element idno {$idno-old/@*,$change-attribute,$idno-old/node()},
        element idno {attribute type {'redirect'},$change-attribute,$redirect-uri})
    
    return 
        (update replace $title-old with $title,
        update insert $publication-idno following $publication-idno-old, update delete $publication-idno-old,
        update replace $revisionDesc-old with $revisionDesc,
        update insert $idno following $idno-old, update delete $idno-old,
        update replace $body-old with $body)
};

declare function syriaca:write-new-header ($header as node()*, $header-master as node()*) {
 (update insert $header following $header-master, update delete $header-master)
};

declare function syriaca:write-new-person ($person as node()*, $master-person as node()*) {
 (update insert $person following $master-person[last()], update delete $master-person)
};

declare function syriaca:write-new-relations ($relations as node()*, $relations-master as node()*, $master-person as node()*) {
 
     if ($relations) then 
        (update insert $relations following $master-person,
        if ($relations-master) then 
            update delete $relations-master
            else ())
        else ()
};

(: ------------------------------------------------------------------------ :)
(: MERGE SCRIPT BODY :)
let $persons := collection('/db/apps/srophe-data/data/persons/tei/')/TEI

(: VARIABLES TO EDIT FOR EACH RUN :)
(: Record that will be kept :)
let $master-uri := 'http://syriaca.org/person/530'

(: Record that will be deprecated :)
let $secondary-uri := 'http://syriaca.org/person/530'

(: Your user id in http://syriaca.org/documentation/editors.xml :)
let $user := 'ngibson'


let $master-id := replace($master-uri,'http://syriaca.org/person/','')
let $master-record := $persons[text/body/listPerson/person/idno=$master-uri]

let $secondary-id := replace($secondary-uri,'http://syriaca.org/person/','')
(: ADAPTED for merging in overlapping saint records :)
let $overlapping-saints := collection('/db/apps/srophe-data/data/overlapping-saints/')/TEI
let $secondary-record := $overlapping-saints[text/body/listPerson/person/idno=$secondary-uri]
(:original:)
(:let $secondary-record := $persons[text/body/listPerson/person/idno=$secondary-uri]:)

let $titles-master := $master-record/teiHeader/fileDesc/titleStmt/title
let $titles-secondary := $secondary-record/teiHeader/fileDesc/titleStmt/title
let $titles := 
    ($titles-master,
    $titles-secondary[not(.=$titles-master/*) and @level=('m','s')])

let $respStmts-master := $master-record/teiHeader/fileDesc/titleStmt/respStmt
let $respStmts-secondary := $secondary-record/teiHeader/fileDesc/titleStmt/respStmt
let $respStmts := 
    functx:distinct-deep(($respStmts-secondary,$respStmts-master))
  
let $secondary-uri-description := if ($master-uri=$secondary-uri) then 'duplicate record with same URI' else $secondary-uri
    
let $changes-secondary := 
    for $change in $secondary-record//revisionDesc/change
    return element change {$change/@*,$change/node(), concat(' [',$secondary-uri-description,']')}
let $changes-master := $master-record//revisionDesc/change

let $changes-merged := 
    for $change in ($changes-master,$changes-secondary)
    order by $change/@when descending
    return $change
    
let $change-new-id := syriaca:next-id($changes-merged/@xml:id, concat('change',$master-id,'-'), 1)
let $change-new := <change who="http://syriaca.org/documentation/editors.xml#{$user}" when="{current-date()}" xml:id="{$change-new-id}">Merged in data from [{$secondary-uri-description}].</change>

let $changes := ($change-new,$changes-merged)

let $master-person := $master-record/text/body/listPerson/person
let $secondary-person := $secondary-record/text/body/listPerson/person
let $person-combined := ($master-person,$secondary-person)

let $bibl-matching-test := '.[ptr/@target]/ptr/@target=$node/ptr/@target or .[not(ptr/@target)]/node()[name()!=("citedRange","note")]=$node/node()[name()!=("citedRange","note")]'
let $bibls := 
    syriaca:merge-nodes($master-person/bibl,$secondary-person/bibl, $bibl-matching-test, ('citedRange','note'), (), $master-person/bibl)

let $test-deep-equal := './idno=$node/idno'

let $seriesStmts-master := $master-record/teiHeader/fileDesc/seriesStmt
let $seriesStmts-secondary := $secondary-record/teiHeader/fileDesc/seriesStmt

(: for merges other than saint-author merges :)
(:let $seriesStmts := :)
(:    syriaca:merge-nodes($seriesStmts-master, $seriesStmts-secondary, $test-deep-equal, 'biblScope', $secondary-person/bibl, :)
(:            $bibls):)
            
(: for author-saint merges only :)
let $seriesStmts :=
    (<seriesStmt>
        <title level="s">The Syriac Biographical Dictionary</title>
        <editor role="general" ref="http://syriaca.org/documentation/editors.xml#dmichelson">David A. Michelson</editor>
        <editor role="associate" ref="http://syriaca.org/documentation/editors.xml#tcarlson">Thomas A. Carlson</editor>
        <editor role="associate" ref="http://syriaca.org/documentation/editors.xml#ngibson">Nathan P. Gibson</editor>
        <editor role="associate" ref="http://syriaca.org/documentation/editors.xml#jnmsaintlaurent">Jeanne-Nicole Mellon Saint-Laurent</editor>
        <respStmt>
            <resp>Edited by</resp>
            <name type="person" ref="http://syriaca.org/documentation/editors.xml#dmichelson">David A. Michelson</name>
        </respStmt>
        <respStmt>
            <resp>Edited by</resp>
            <name type="person" ref="http://syriaca.org/documentation/editors.xml#tcarlson">Thomas A. Carlson</name>
        </respStmt>
        <respStmt>
            <resp>Edited by</resp>
            <name type="person" ref="http://syriaca.org/documentation/editors.xml#ngibson">Nathan P.  Gibson</name>
        </respStmt>
        <respStmt>
            <resp>Edited by</resp>
            <name type="person" ref="http://syriaca.org/documentation/editors.xml#jnmsaintlaurent">Jeanne-Nicole Mellon Saint-Laurent</name>
        </respStmt>
        <idno type="URI">http://syriaca.org/persons</idno>
        <biblScope unit="vol" from="1" to="1">
            <title level="m">Qadishe: A Guide to the Syriac Saints</title>
            <idno type="URI">http://syriaca.org/q</idno>
        </biblScope>
        <biblScope unit="vol" from="2" to="2">
            <title level="m">A Guide to Syriac Authors</title>
            <idno type="URI">http://syriaca.org/authors</idno>
        </biblScope>
    </seriesStmt>,
    <seriesStmt>
        <title level="s">Gateway to the Syriac Saints</title>
        <editor role="general" ref="http://syriaca.org/documentation/editors.xml#jnmsaintlaurent">Jeanne-Nicole Mellon Saint-Laurent</editor>
        <editor role="general" ref="http://syriaca.org/documentation/editors.xml#dmichelson">David A.
                Michelson</editor>
        <respStmt>
            <resp>Edited by</resp>
            <name type="person" ref="http://syriaca.org/documentation/editors.xml#jnmsaintlaurent">Jeanne-Nicole Mellon Saint-Laurent</name>
        </respStmt>
        <respStmt>
            <resp>Edited by</resp>
            <name type="person" ref="http://syriaca.org/documentation/editors.xml#dmichelson">David A.
                    Michelson</name>
        </respStmt>
        <idno type="URI">http://syriaca.org/saints</idno>
        <biblScope unit="vol" from="2" to="2">
            <title level="m">Qadishe: A Guide to the Syriac Saints</title>
            <idno type="URI">http://syriaca.org/q</idno>
        </biblScope>
    </seriesStmt>)

let $persNames := 
    syriaca:merge-nodes($master-person/persName, 
        $secondary-person/persName, 
        'string-join(descendant-or-self::*)=tokenize(string-join($node,","),",")', 
        (), 
        $secondary-person/bibl, 
        $bibls)
        
let $test-deep-equal-no-ids-or-sources := 'functx:is-node-in-sequence-deep-equal(syriaca:remove-extra-attributes(., ("xml:id","source")), syriaca:remove-extra-attributes($node, ("xml:id","source")))'

let $editors-master := $master-record/teiHeader/fileDesc/titleStmt/editor
let $editors-secondary := $secondary-record/teiHeader/fileDesc/titleStmt/editor

let $editors := 
    syriaca:merge-nodes($editors-master, 
        $editors-secondary, 
        $test-deep-equal-no-ids-or-sources, 
        (), 
        $secondary-person/bibl, 
        $bibls)
        
(: for merges other than saint-author merges :)
(:let $titleStmt := :)
(:    ($titles,:)
(:    $master-record/teiHeader/fileDesc/titleStmt/(sponsor|funder|principal),:)
(:    $editors,:)
(:    $respStmts):)

(: adapted for saints-author merges only:)
let $titleStmt :=
    <titleStmt>
        {$titles-master[@level='a']}
        <sponsor>Syriaca.org: The Syriac Reference Portal</sponsor>
        <funder>The Andrew W. Mellon Foundation</funder>
        <funder>The National Endowment for the Humanities</funder>
        <funder>The International Balzan Prize Foundation</funder>
        <principal>David A. Michelson</principal>
        <editor role="general" ref="http://syriaca.org/documentation/editors.xml#jnmsaintlaurent">Jeanne-Nicole Mellon Saint-Laurent</editor>
        <editor role="general" ref="http://syriaca.org/documentation/editors.xml#dmichelson">David A. Michelson</editor>
        <editor role="general" ref="http://syriaca.org/documentation/editors.xml#ngibson">Nathan P. Gibson</editor>
        <editor role="general" ref="http://syriaca.org/documentation/editors.xml#tcarlson">Thomas A. Carlson</editor>
        <editor role="creator" ref="http://syriaca.org/documentation/editors.xml#jnmsaintlaurent">Jeanne-Nicole Mellon Saint-Laurent</editor>
        <editor role="creator" ref="http://syriaca.org/documentation/editors.xml#dmichelson">David A. Michelson</editor>
        <editor role="creator" ref="http://syriaca.org/documentation/editors.xml#ngibson">Nathan P. Gibson</editor>
        <editor role="creator" ref="http://syriaca.org/documentation/editors.xml#jwalters">James E. Walters</editor>
        <editor role="creator" ref="http://syriaca.org/documentation/editors.xml#tcarlson">Thomas A. Carlson</editor>
        <respStmt>
            <resp>Editing, proofreading, data entry and revision by</resp>
            <name type="person" ref="http://syriaca.org/documentation/editors.xml#jnmsaintlaurent">Jeanne-Nicole Mellon Saint-Laurent</name>
        </respStmt>
        <respStmt>
            <resp>Editing, document design, data architecture, encoding, proofreading, data entry by</resp>
            <name type="person" ref="http://syriaca.org/documentation/editors.xml#dmichelson">David A. Michelson</name>
        </respStmt>
        <respStmt>
            <resp>Proofreading of GEDSH abstracts, addition of confessions and alternate names from GEDSH, matching with viaf.org records, data entry, data transformation, data merging, conversion to XML by</resp>
            <name type="person" ref="http://syriaca.org/documentation/editors.xml#ngibson">Nathan P. Gibson</name>
        </respStmt>
        <respStmt>
            <resp>GEDSH and Barsoum English name entry, matching with viaf.org records by</resp>
            <name type="person" ref="http://syriaca.org/documentation/editors.xml#jwalters">James E. Walters</name>
        </respStmt>
        <respStmt>
            <resp>Editing, Syriac name entry, disambiguation research, conversion to XML by</resp>
            <name type="person" ref="http://syriaca.org/documentation/editors.xml#tcarlson">Thomas A. Carlson</name>
        </respStmt>
        <respStmt>
            <resp>Editing, Syriac data conversion, data entry, and reconciling by</resp>
            <name ref="http://syriaca.org/documentation/editors.xml#akane">Adam P. Kane</name>
        </respStmt>
        <respStmt>
            <resp>Editing and Syriac data proofreading by</resp>
            <name ref="http://syriaca.org/documentation/editors.xml#abarschabo">Aram Bar Schabo</name>
        </respStmt>
        <respStmt>
            <resp>Syriac name entry by</resp>
            <name type="person" ref="http://syriaca.org/documentation/editors.xml#raydin">Robert Aydin</name>
        </respStmt>
        {$master-record/teiHeader/fileDesc/titleStmt/respStmt[contains(.,'Arabic name entry')]}
        <respStmt>
            <resp>Normalization of GEDSH dates and entry matching with viaf.org records by</resp>
            <name type="person" ref="http://syriaca.org/documentation/editors.xml#avawter">Alex Vawter</name>
        </respStmt>
        <respStmt>
            <resp>Editorial oversight for GEDSH and Barsoum English text entry, and proofreading by</resp>
            <name type="person" ref="http://syriaca.org/documentation/editors.xml#cjohnson">Christopher Johnson</name>
        </respStmt>
        <respStmt>
            <resp>GEDSH and Barsoum English text entry and proofreading by</resp>
            <name type="org" ref="http://syriaca.org/documentation/editors.xml#uasyriacresearchgroup">the Syriac Research Group, University of Alabama</name>
        </respStmt>
        <respStmt>
            <resp>Entries adapted from the work of</resp>
            <name type="person" ref="http://syriaca.org/documentation/editors.xml#jmfiey">Jean Maurice Fiey</name>
        </respStmt>
        <respStmt>
            <resp>Entries adapted from the work of</resp>
            <name type="person" ref="http://syriaca.org/documentation/editors.xml#uzanetti">Ugo Zanetti</name>
        </respStmt>
        <respStmt>
            <resp>Entries adapted from the work of</resp>
            <name type="person" ref="http://syriaca.org/documentation/editors.xml#cdetienne">Claude Detienne</name>
        </respStmt>
    </titleStmt>

let $idnos := 
    (if ($master-uri=$secondary-uri) then
        $master-person/idno[matches(.,'http://syriaca.org')]
    else
        (syriaca:update-attribute($master-person/idno[matches(.,'http://syriaca.org')],'change',concat('#',$change-new-id)),
        syriaca:update-attribute(
            syriaca:update-attribute($secondary-person/idno[matches(.,'http://syriaca.org')],'change',concat('#',$change-new-id)),
            'type',
            'deprecated'
    )),
    syriaca:merge-nodes($master-person/idno[not(matches(.,'http://syriaca.org'))], 
        $secondary-person/idno[not(matches(.,'http://syriaca.org'))], 
        $test-deep-equal-no-ids-or-sources, 
        (), 
        $secondary-person/bibl, 
        $bibls))
        
let $publication-idnos-master := $master-record//publicationStmt/idno
let $publication-idnos-secondary := $secondary-record//publicationStmt/idno

let $publication-idnos := 
    if ($publication-idnos-master=$publication-idnos-secondary) then
        $publication-idnos-master
    else
        (syriaca:update-attribute($publication-idnos-master,'change',concat('#',$change-new-id)),
        syriaca:update-attribute(
            syriaca:update-attribute($publication-idnos-secondary,'change',concat('#',$change-new-id)),
            'type',
            'deprecated'
        ))
        
let $header-master := $master-record/teiHeader
        
let $header := 
    <teiHeader>
        <fileDesc>
            {$titleStmt}
            {($master-record/teiHeader/fileDesc/(editionStmt|publicationStmt),
            $seriesStmts,
            $master-record/teiHeader/fileDesc/sourceDesc)}
        </fileDesc>
        {($master-record/teiHeader/encodingDesc,
        $master-record/teiHeader/profileDesc,
        element revisionDesc 
            {$master-record/teiHeader/revisionDesc/@*,
            $changes})}
    </teiHeader>

(:let $abstract := syriaca:preserve-master($master-person/note[@type='abstract'], $secondary-person/note[@type='abstract'], $secondary-person/bibl, $bibls):)

(: adapted for authors-saints merge :)
let $abstract := $master-person/note[@type='abstract']
let $desc-hagio-secondary := $secondary-person/note[@type='abstract']
let $desc-hagio-updated := element note {$desc-hagio-secondary/@*, 'In hagiography: ', $desc-hagio-secondary/node()}
let $desc-hagio := 
    syriaca:update-attribute(
        syriaca:update-sources(
            syriaca:remove-extra-attributes($desc-hagio-updated, 'xml:id'), 
            $secondary-person/bibl, 
            $bibls),
        'type',
        'description')
let $sex := syriaca:preserve-master($master-person/sex[1], $secondary-person/sex[1], $secondary-person/bibl, $bibls)
let $floruit := syriaca:combine-dates(
    syriaca:merge-nodes(
        $master-person/floruit, 
        $secondary-person/floruit, 
        $test-deep-equal-no-ids-or-sources, 
        (),$secondary-person/bibl, $bibls))
let $birth := syriaca:combine-dates(
    syriaca:merge-nodes(
        $master-person/birth, 
        $secondary-person/birth, 
        $test-deep-equal-no-ids-or-sources, 
        (),$secondary-person/bibl, $bibls))
let $death := syriaca:combine-dates(
    syriaca:merge-nodes(
        $master-person/death, 
        $secondary-person/death, 
        $test-deep-equal-no-ids-or-sources, 
        (), 
        $secondary-person/bibl, 
        $bibls))

let $notes := syriaca:merge-nodes($master-person/note[not(@type='abstract')], 
    $secondary-person/note[not(@type='abstract')], 
    $test-deep-equal-no-ids-or-sources, 
    (), 
    $secondary-person/bibl, 
    $bibls)
    
let $states := syriaca:merge-nodes($master-person/state, 
    $secondary-person/state, 
    $test-deep-equal-no-ids-or-sources, 
    (), 
    $secondary-person/bibl, 
    $bibls)
    
let $traits := syriaca:merge-nodes($master-person/trait, 
    $secondary-person/trait, 
    $test-deep-equal-no-ids-or-sources, 
    (), 
    $secondary-person/bibl, 
    $bibls)

let $events := syriaca:merge-nodes($master-person/event, 
    $secondary-person/event,
    $test-deep-equal-no-ids-or-sources, 
    (), 
    $secondary-person/bibl, 
    $bibls)
    
let $links := syriaca:merge-nodes($master-person/link, 
    $secondary-person/link, 
    $test-deep-equal-no-ids-or-sources, 
    (), 
    $secondary-person/bibl, 
    $bibls)
    
let $relations-secondary := syriaca:update-relation-attributes($secondary-person/(relation|../relation), $master-id, $secondary-id)
let $relations-master := syriaca:update-relation-attributes($master-person/(relation|../relation), $master-id, $secondary-id)
    
let $relations := syriaca:merge-nodes($relations-master, 
    $relations-secondary, 
    $test-deep-equal-no-ids-or-sources, 
    (), 
    $secondary-person/bibl, 
    $bibls)
    
let $person := <person>
    {$master-person/@*}
    {($persNames,
    $idnos,
    $abstract,
(:    adapted for authors-saints merge :)
    $desc-hagio,
    $sex,
    $floruit,
    $birth,
    $death,
    $notes,
    $states,
    $traits,
    $events,
    $links,
    $bibls)}
    </person>

(: Having trouble finding the right formula for matching events, etc. across records :)
(: Also need to get headword selection working :)
return 
    (syriaca:write-new-header($header, $header-master),
    syriaca:write-new-person($person, $master-person),
    syriaca:write-new-relations($relations, $relations-master, $master-person),
    syriaca:deprecate-merge-redirect($secondary-record, $master-uri, $user))