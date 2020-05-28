xquery version "3.1";
(:~ 
 : Srophe utility to merge duplicate placeNames with duplicate xml:lang attributes.
 : See: https://github.com/srophe/bethqatraye-data/issues/10 
 :   
 : @author Winona Salesky
 : @version 1.0 
 : 
 :) 
import module namespace http="http://expath.org/ns/http-client";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace srophe="https://srophe.app";
declare namespace file="http://exist-db.org/xquery/file";

(:
 : Global variables, change for each use case
:)
declare variable $data-root := '/db/apps/bethqatraye-data/data';
declare variable $editor := 'srophe-util';
declare variable $changeLog := 'CHANGED: merge duplicate names.';

let $recs := collection($data-root)//tei:TEI
for $r in $recs             
let $id := $r//tei:idno[1]
let $names := $r/descendant::tei:place/tei:placeName
let $updates := 
        for $name in $names
        let $lang := $name/@xml:lang
        return 
            if($name/following-sibling::tei:placeName[. = $name][@xml:lang = $lang]) then 
                let $duplicate := $name/following-sibling::tei:placeName[. = $name]
                let $attrnames := for $n in $name/@* return name($n)
                let $allattrs := ($name/@*, $duplicate/@*[not(name(.) = $attrnames)])
                let $allattrnames := for $n in $allattrs return name($n)
                let $mergedName := 
                    try {
                        <placeName xmlns="http://www.tei-c.org/ns/1.0">{
                            ($name/@*, $duplicate/@*[not(name(.) = $attrnames)])
                        }{$name/text()}
                        </placeName> 
                    } catch * {concat('Error: ',$err:code, ": ", $err:description, ' name: ', $name)}
                return 
                    if($mergedName != '' and not(starts-with($mergedName,'Error:'))) then 
                        try { 
                            (update replace $name with $mergedName, update delete $duplicate, $id)
                        } catch * {concat('Error: ',$err:code, ": ", $err:description, ' name: ', $name)}     
                    else ()
            else ()
return 
    if($updates != '' and not(starts-with($updates,'Error:'))) then
        (update insert <change xmlns="http://www.tei-c.org/ns/1.0" who="http://syriaca.org/documentation/editors.xml#{$editor}" when="{current-date()}">{$changeLog}</change>
          preceding $r/descendant::tei:revisionDesc/tei:change[1],
          update value $r/descendant::tei:fileDesc/tei:publicationStmt/tei:date with current-date(),
          $id
          )
    else ()