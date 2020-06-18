xquery version "3.0";
(:~ 
 : Srophe utility function to add new bibl records to existing Srophe records.
 : See: https://github.com/srophe/srophe-app-data/issues/778 
 : The scripts works on TSV files or THREE columns
 : 
 : Example 
 :   Column 1 | Column 2 | Column 3
 :   BQURI | Lat/Long | BiblURI
 :   
 : @author Winona Salesky
 : @version 1.0 
 : 
 :)
 
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace file="http://exist-db.org/xquery/file";

(:
 : Global variables, change for each use case
:)
declare variable $data-root := '/db/apps/bethqatraye-data/data';
declare variable $baseURI := 'http://bqgazetteer.bethmardutho.org/place/';
declare variable $editor := 'srophe-util';
declare variable $changeLog := 'CHANGED: Insert new location element and add bibl reference';

(:~ 
 : Add new bibl element and new location elements based on external data table
 : @param  $recURI existing Srophe record URI
 : @param $newURI URI to insert into bibl record
 : @param $location geographic coordinates. 
:)
declare function local:add-bibl($recURI as xs:string?, $location as xs:string?, $newURI as xs:string?){
    let $recURI := if(ends-with($recURI,'/tei')) then $recURI else concat($recURI,'/tei')
    let $rec := root(collection($data-root)//tei:idno[. = $recURI])
    for $bibl in $rec/descendant::tei:bibl[last()]
    let $biblId := substring-before($bibl/@xml:id,'-')
    let $id := substring-after($bibl/@xml:id,'-')
    let $newBiblId:= concat($biblId,'-',xs:integer($id) + 1)
    let $newBibl := 
            <bibl xml:id="{$newBiblId}" xmlns="http://www.tei-c.org/ns/1.0">
                <ptr target="{$newURI}"/>
            </bibl>
    let $abstract := $rec/descendant::tei:desc[@type='abstract']
    let $change :=             
    <change xmlns="http://www.tei-c.org/ns/1.0" who="http://syriaca.org/documentation/editors.xml#{$editor}" when="{current-date()}">{$changeLog}</change>
    return 
        (update insert $newBibl following $bibl,
        if($location != '') then 
            let $newlocation := 
                <location type="gps" source="#{$newBiblId}" xmlns="http://www.tei-c.org/ns/1.0">
                    <geo>{$location}</geo>
                </location>
            return  
                update insert $newlocation preceding $rec/descendant::tei:body/descendant::tei:idno[1]
        else (),
        update insert $change
          preceding $rec/descendant::tei:revisionDesc/tei:change[1],
          update value $rec/descendant::tei:fileDesc/tei:publicationStmt/tei:date with current-date()
        )
};

(: 
 : Ways to access TSV:
 : paste into input variable as plain text. 
 : retrieve from local file $TSVDoc. See example  
:)
(:
let $filePath := 'file:///Users/wsalesky/Downloads/sources.csv'
let $TSVDoc := file:read($filePath)
let $input := $TSVDoc
:)
let $input := 
"10	36.200663 36.165318	https://pleiades.stoa.org/places/658381
105	31.870028 35.443871	http://pleiades.stoa.org/places/687917
109	35.972501 39.08287	http://pleiades.stoa.org/places/668318
111	32.5 46.5	http://pleiades.stoa.org/places/912880
122	36.526118 37.954539	http://pleiades.stoa.org/places/658480
129	37.39206 46.23909	http://gazetteer.dainst.org/place/2733333
136	38.382217 38.361152	http://pleiades.stoa.org/places/629040
139	36.335572 43.13713	http://pleiades.stoa.org/places/874609
142	37.067234 41.215055	http://pleiades.stoa.org/places/874623
143	34.025421 36.73461199999997	http://pleiades.stoa.org/places/678085"
let $lines := tokenize($input, '\n')
for $l in $lines
let $fields := tokenize($l, '\t') 
let $count := count($fields)
let $f1 := if($baseURI != '') then concat($baseURI,$fields[1]) else $fields[1]
let $f2 := $fields[2]
let $f3 := $fields[3]
return 
    try { local:add-location($f1, $f2, $f3) } catch * {concat($err:code, ": ", $err:description)}