xquery version "3.0";
declare namespace tei="http://www.tei-c.org/ns/1.0";
(: 
 : Works -> NHSL queries in order 
 : Run one FLWOR at a time. Check data, run the next... 
:)

(: 1.
Remove from /TEI/teiHeader/fileDesc/titleStmt
<title level="m">Bibliotheca Hagiographica Syriaca Electronica</title>
<title level="s">Gateway to the Syriac Saints</title>
<title level="s">New Handbook of Syriac Literature</title>
:)
for $r in collection('/db/apps/srophe-data/data/works/tei')//tei:TEI
return
    (
    update delete $r/descendant::tei:fileDesc/tei:titleStmt/tei:title[@level='m'][. = 'Bibliotheca Hagiographica Syriaca Electronica'],
    update delete $r/descendant::tei:fileDesc/tei:titleStmt/tei:title[@level='s'][. = 'Gateway to the Syriac Saints'],
    update delete $r/descendant::tei:fileDesc/tei:titleStmt/tei:title[@level='s'][. = 'New Handbook of Syriac Literature']
    )

(: 2.
 : Replace /TEI/teiHeader/fileDesc/seriesStmt[title='Gateway to the Syriac Saints']/biblScope with
    <biblScope unit="vol" from="2" to="2">
        <title level="m">Bibliotheca Hagiographica Syriaca Electronica</title>
        <idno type="URI">http://syriaca.org/bhse</idno>
    </biblScope>
 :)
for $r in collection('/db/apps/srophe-data/data/works/tei')//tei:TEI[descendant::tei:seriesStmt[tei:title = 'Gateway to the Syriac Saints']]
let $biblScope := $r/descendant::tei:seriesStmt[tei:title = 'Gateway to the Syriac Saints']/tei:biblScope
let $newbiblScope := 
    <biblScope unit="vol" from="2" to="2" xmlns="http://www.tei-c.org/ns/1.0">
        <title level="m">Bibliotheca Hagiographica Syriaca Electronica</title>
        <idno type="URI">http://syriaca.org/bhse</idno>
    </biblScope>
return update replace $biblScope with $newbiblScope

(: 3.
 : Replace /TEI/teiHeader/fileDesc/seriesStmt/idno[.='http://syriaca.org/q'] with
    <idno type="URI">http://syriaca.org/saints</idno>
 :)
for $r in collection('/db/apps/srophe-data/data/works/tei')//tei:TEI[descendant::tei:seriesStmt[tei:idno = 'http://syriaca.org/q']]
let $idno := $r/descendant::tei:seriesStmt/tei:idno[. = 'http://syriaca.org/q']
return update value $idno with 'http://syriaca.org/saints'

(: 4. 
 Replace /TEI/teiHeader/fileDesc/seriesStmt[title='New Handbook of Syriac Literature']/biblScope with
<biblScope unit="vol" from="1" to="1">
    <title level="m">Bibliotheca Hagiographica Syriaca Electronica</title>
    <idno type="URI">http://syriaca.org/bhse</idno>
</biblScope>
:)
for $r in collection('/db/apps/srophe-data/data/works/tei')//tei:TEI[descendant::tei:seriesStmt[tei:title = 'New Handbook of Syriac Literature']]
let $biblScope := $r/descendant::tei:seriesStmt[tei:title = 'New Handbook of Syriac Literature']/tei:biblScope
let $newbiblScope := 
                <biblScope unit="vol" from="1" to="1" xmlns="http://www.tei-c.org/ns/1.0">
                    <title level="m">Bibliotheca Hagiographica Syriaca Electronica</title>
                    <idno type="URI">http://syriaca.org/bhse</idno>
                </biblScope>
return update replace $biblScope with $newbiblScope

(: 5.
Replace /TEI/teiHeader/fileDesc/seriesStmt/idno[.='http://syriaca.org/works'] with
<idno type="URI">http://syriaca.org/nhsl</idno>
 :)
for $r in collection('/db/apps/srophe-data/data/works/tei')//tei:TEI[descendant::tei:seriesStmt[tei:idno = 'http://syriaca.org/works']]
let $idno := $r/descendant::tei:seriesStmt/tei:idno[. = 'http://syriaca.org/works']
return update value $idno with 'http://syriaca.org/nhsl'

(: 6.
    Move all idno elements immediately after editor|author|title 
    After these idnos insert 
    <textLang mainLang="syr"/>
    NOTE: it is necessary to construct an in memory idno for inserting before deleting the existing idnos
:)
for $r in collection('/db/apps/srophe-data/data/works/tei')//tei:TEI/descendant::tei:body
let $newIds := <id>{(
        for $id in $r/descendant::tei:idno
        return 
            element { QName(namespace-uri($id), local-name($id)) } 
            { $id/@*, string($id/text()) }
            ,
        <textLang mainLang="syr"xmlns="http://www.tei-c.org/ns/1.0" />
)}</id>
let $last := 
        if($r/tei:bibl/tei:author) then 
            if($r/tei:bibl/tei:author/following-sibling::tei:editor) then 
                $r/tei:bibl/tei:editor[last()]
            else $r/tei:bibl/tei:author[last()]
        else if($r/tei:bibl/tei:editor) then 
            if($r/tei:bibl/tei:editor/following-sibling::tei:author) then 
                $r/tei:bibl/tei:author[last()]
            else $r/tei:bibl/tei:editor[last()]
        else $r/tei:bibl/tei:title[last()]
return 
    (
     update delete $r/tei:bibl/tei:idno,    
     update insert $newIds/child::* following $last
    )

(: 7.
    For note[@type='editions'] ...
    Keep bibl inside note but remove note tag
    Add @type='lawd:Edition' to bibl
    For the $bibl inside the note, insert the following inside the bibl (at the end):
    <listRelation>
        <relation type="mssWitnesses" active="#{$bibl/@xml:id}" ref="dct:source" passive="{$bibl/@corresp}" source="{$bibl/@source}"/>
        <relation active="#{$bibl/@xml:id}" ref="lawd:embodies" passive="{$work-uri}"/>
    </listRelation>
    Remove bibl/@corresp and bibl/@n
:)
for $r in collection('/db/apps/srophe-data/data/works/tei')//tei:TEI/descendant::tei:note[@type='editions']
let $work-uri := $r/parent::*[1]/tei:idno[@type='URI'][starts-with(., 'http://syriaca.org/')]/text()
let $bibl := $r/tei:bibl
let $new-element := 
        <bibl xmlns="http://www.tei-c.org/ns/1.0" type="lawd:Edition">
            {$bibl/@*[not(name() ='corresp') and not(name() ='n')],
            $bibl/child::*,
            <listRelation>
                <relation type="mssWitnesses" active="#{$bibl/@xml:id}" ref="dct:source" passive="{$bibl/@corresp}" source="{$bibl/@source}"/>
                <relation active="#{$bibl/@xml:id}" ref="lawd:embodies" passive="{$work-uri}"/>
            </listRelation>
            }
        </bibl>
        
return update replace $r with $new-element

(: 8.
For note[@type='MSS'] ... 
Move @xml:lang and @source to the bibl inside it.
Keep bibl inside note but remove note tag
Add @type='syriaca:Manuscript' to bibl
Insert the following at the end of the bibl
<listRelation>
    <relation active="#{$bibl/@xml:id}" ref="lawd:embodies" passive="{$work-uri}"/>
</listRelation>
:)

for $r in collection('/db/apps/srophe-data/data/works/tei')//tei:TEI/descendant::tei:note[@type='MSS']
let $work-uri := $r/parent::*[1]/tei:idno[@type='URI'][starts-with(., 'http://syriaca.org/')]/text()
let $bibl := $r/tei:bibl
let $new-element := 
        <bibl xmlns="http://www.tei-c.org/ns/1.0" type="syriaca:Manuscript">
            {$bibl/@*[not(name() ='corresp') and not(name() ='n')],
            $bibl/node(),
            <listRelation>
                <relation active="#{$bibl/@xml:id}" ref="lawd:embodies" passive="{$work-uri}"/>
            </listRelation>
            }
        </bibl>
        
return update replace $r with $new-element

(: 9.
For note[@type='ancientVersion'] ... 
Move @xml:lang and @source to the bibl inside it.
Keep bibl inside note but remove note tag
Add @type='syriaca:AncientVersion' to bibl
Move bibl/lang to first child of bibl
Insert the following at the end of the bibl
<listRelation>
    <relation active="#{$bibl/@xml:id}" ref="lawd:embodies" passive="{$work-uri}"/>
</listRelation>
:)

for $r in collection('/db/apps/srophe-data/data/works/tei')//tei:TEI/descendant::tei:note[@type='ancientVersion']
let $work-uri := $r/parent::*[1]/tei:idno[@type='URI'][starts-with(., 'http://syriaca.org/')]/text()
let $bibl := $r/tei:bibl
let $new-element := 
        <bibl xmlns="http://www.tei-c.org/ns/1.0" type="syriaca:AncientVersion">
            {$bibl/@*[not(name() ='corresp') and not(name() ='n')],
            <lang>{$bibl/tei:lang/text()}</lang>,
            $bibl/node()[not(name() = 'lang')],
            <listRelation>
                <relation active="#{$bibl/@xml:id}" ref="lawd:embodies" passive="{$work-uri}"/>
            </listRelation>
            }
        </bibl>
        
return update replace $r with $new-element (:($new-element,$bibl):)

(: 10.
For note[@type='modernTranslation'] ... 
Move @xml:lang and @source to the bibl inside it.
Keep bibl inside note but remove note tag
Add @type='syriaca:ModernTranslation' to bibl
Move bibl/lang to first child of bibl
Insert the following at the end of the bibl
<listRelation>
    <relation active="#{$bibl/@xml:id}" ref="lawd:embodies" passive="{$work-uri}"/>
</listRelation>
:)

for $r in collection('/db/apps/srophe-data/data/works/tei')//tei:TEI/descendant::tei:note[@type='modernTranslation']
let $work-uri := $r/parent::*[1]/tei:idno[@type='URI'][starts-with(., 'http://syriaca.org/')]/text()
let $bibl := $r/tei:bibl
let $new-element := 
        <bibl xmlns="http://www.tei-c.org/ns/1.0" type="syriaca:ModernTranslation">
            {$bibl/@*[not(name() ='corresp') and not(name() ='n')],
            <lang>{$bibl/tei:lang/text()}</lang>,
            $bibl/node()[not(name() = 'lang')],
            <listRelation>
                <relation active="#{$bibl/@xml:id}" ref="lawd:embodies" passive="{$work-uri}"/>
            </listRelation>
            }
        </bibl>
        
return update replace $r with $new-element (:($new-element,$bibl):)

(: 11.
Main bibl[not(@type)] add @type="lawd:ConceptualWork"
:)
for $r in collection('/db/apps/srophe-data/data/works/tei')//tei:TEI/descendant::tei:text/tei:body/tei:bibl
return 
    update insert attribute type {'lawd:ConceptualWork'} into $r


(: 12.
For bibl[not(@type)] add @type="lawd:Citation"
:)
for $r in collection('/db/apps/srophe-data/data/works/tei')//tei:TEI/descendant::tei:bibl[not(@type)]
return 
    update insert attribute type {'lawd:Citation'} into $r


(: 13.
 For listRelation/relation[@name='syriaca:commemorated'] …
 Remove @name
 Add @ref='syriaca:commemorated'
 :)
for $r in collection('/db/apps/srophe-data/data/works/tei')//tei:TEI/descendant::tei:listRelation/tei:relation[@name='syriaca:commemorated']
return 
    (
    update insert attribute ref {'syriaca:commemorated'} into $r,
    update delete $r/@name
    )

(: 14.
 Add change element
 :)
for $r in collection('/db/apps/srophe-data/data/works/tei')//tei:TEI
return 
    (
        update insert 
        <change xmlns="http://www.tei-c.org/ns/1.0" who="http://syriaca.org/documentation/editors.xml#ngibson" when="{current-date()}">Updated to match new NHSL format.</change>
          preceding $r/descendant::tei:teiHeader/tei:revisionDesc/tei:change[1],
    update value $r/descendant::tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:date with current-date()
        )
