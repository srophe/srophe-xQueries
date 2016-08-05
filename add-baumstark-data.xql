xquery version "3.0";

(:Add data from Baumstark authors spreadsheet to authors records.:)
 
(: NAMESPACES:)
(:declare default element namespace "http://www.tei-c.org/ns/1.0";:)
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

declare function syriaca:create-citation($xml-ids-of-existing-citations as xs:string*,$person-id as xs:string*,$i as xs:double*,$syriaca-bibl-uri as xs:string*,$citedRange as xs:string*, $citedRange-unit as xs:string*)
as node()*
{
    let $xml-id := syriaca:next-id($xml-ids-of-existing-citations, concat('bib',$person-id,'-'), $i)
    let $bibls := collection('/db/apps/srophe-data/data/bibl/tei')/tei:TEI
    let $bibl := $bibls/tei:text/tei:body/tei:biblStruct[descendant-or-self::tei:idno[1]=$syriaca-bibl-uri]
    return 
        <tei:bibl xml:id='{$xml-id}'>
            {$bibl/*/tei:title}
            <ptr target='{$syriaca-bibl-uri}'/>
            <citedRange unit='{$citedRange-unit}'>{$citedRange}</citedRange>
        </tei:bibl>
};


let $persons := collection('/db/apps/srophe-data/data/persons/tei')/tei:TEI
let $spreadsheet := doc('/db/apps/srophe-data/data/persons/baumstark-authors1.xml')/root


(:for each row in spreadsheet :)
for $row in $spreadsheet/row[30]
(:    get person in database:)
    let $id := $row/Syriaca_ID
    let $uri := concat('http://syriaca.org/person/',$id)
    let $person-record := $persons[tei:text/tei:body/tei:listPerson/tei:person/tei:idno=$uri]
    let $person := $person-record/tei:text/tei:body/tei:listPerson/tei:person
(:    create resps:)
    let $editor := <tei:editor role="creator" ref="http://syriaca.org/documentation/editors.xml#kheal">Kristian Heal</tei:editor>
    let $respStmts := 
        (<tei:respStmt>
            <resp>German data entry by</resp>
            <name type="person" ref="http://syriaca.org/documentation/editors.xml#kheal">Kristian Heal</name>
        </tei:respStmt>,
        <tei:respStmt>
            <resp>German data entry by</resp>
            <name type="person" ref="http://syriaca.org/documentation/editors.xml#skhader">Samer Khader</name>
        </tei:respStmt>)
(:    add resps to record:)
(:    create citations with xml:ids that continue from record:)
    let $citations := 
        for $citation at $i in $row/(Baumstark__p_|Macuch|Abuna__p__1st_ed.|Duval__p_|Chabot__p_|Wright__p_|Brock__p__Rev._ed.|Pat_Syr__|BO__vol_p_)[.!='']
            let $bibl-uri := 
                if ($citation/name()='Baumstark__p_') then 'http://syriaca.org/bibl/638'
                else if ($citation/name()='Macuch') then 'http://syriaca.org/bibl/642'
                else if ($citation/name()='Abuna__p__1st_ed.') then 'http://syriaca.org/bibl/643'
                else if ($citation/name()='Duval__p_') then 'http://syriaca.org/bibl/644'
                else if ($citation/name()='Chabot__p_') then 'http://syriaca.org/bibl/640'
                else if ($citation/name()='Wright__p_') then 'http://syriaca.org/bibl/639'
                else if ($citation/name()='Brock__p__Rev._ed.') then 'http://syriaca.org/bibl/645'
                else if ($citation/name()='Pat_Syr__') then 'http://syriaca.org/bibl/641'
                (: Or this could select the bibl based on the volume # :)
                else if ($citation/name()='BO__vol_p_') then 
                    if (matches($citation,'^\s*I\.')) then 'http://syriaca.org/bibl/709'
                    else if (matches($citation,'^\s*II\.')) then 'http://syriaca.org/bibl/1700'
                    else ()
                else()
            let $unit := 
                if ($citation/name()=('Baumstark__p_','Macuch','Abuna__p__1st_ed.','Duval__p_','Chabot__p_','Wright__p_','Brock__p__Rev._ed.','BO__vol_p_')) then 'pp'
                else if ($citation/name()='Pat_Syr__') then 'section'
                else()
        return syriaca:create-citation(
            $person/tei:bibl/@xml:id, 
            $id, 
            $i, 
            $bibl-uri, 
            normalize-space(replace(replace($citation,'(^0|\-0)',''),'^\s*II?\.','')), 
            $unit)
(:    add citations to record:)
(:    create names (variables based on specific column - maybe create a persName function?):)
    let $persNames := 
(:    add names to record:)
(:    create URIs:)
(:    add URIs to record:)
return $citations