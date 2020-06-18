xquery version "3.0";
declare namespace tei="http://www.tei-c.org/ns/1.0";

for $e at $ei in doc('/db/apps/e-gedesh-data/egesdh-version-0-1.xml')//tei:div[@type ="entry"]
let $eh := normalize-space(string-join($e/tei:head[1]/text(),' '))
let $ea := normalize-space($e/tei:byline/descendant-or-self::text())
let $idnos-rec := 
    for $r at $ri in doc('/db/apps/e-gedesh-data/gedsh-toc-and-idnos.xml')//*:row
    where $ei = $ri
    return $r
let $rh := normalize-space(string-join($idnos-rec/*:head[1]/text(),' '))   
let $ra := normalize-space(string-join($idnos-rec/*:author[1]/text(),' '))  
let $sy-bib := if($idnos-rec/*:bibl/text() != '') then
                    <idno type="syriaca-bibl" xmlns="http://www.tei-c.org/ns/1.0">{$idnos-rec/*:bibl/text()}</idno>
               else ()
let $entry-id := if($idnos-rec/*:entry != '') then 
                    <idno type="entry" xmlns="http://www.tei-c.org/ns/1.0">{$idnos-rec/*:entry/text()}</idno>
                else ()
let $pages := if($idnos-rec/*:pages != '') then
                <milestone unit="pages" n="{$idnos-rec/*:pages/text()}" xmlns="http://www.tei-c.org/ns/1.0"/>
              else ()    
let $alt-head := (
                if($eh != $rh) then 
                    <idno type="althead" xmlns="http://www.tei-c.org/ns/1.0">{$rh}</idno>
                else (),
                for $an in $idnos-rec/*:Alternate_Name[. != '']
                return 
                  <idno type="althead" xmlns="http://www.tei-c.org/ns/1.0">{$an/node()}</idno>
                )    
let $r-subject := 
                if($idnos-rec/*:subject != '') then
                    <idno type="subject" xmlns="http://www.tei-c.org/ns/1.0">{$idnos-rec/*:subject/text()}</idno>
                else ()
let $r-type := 
                if($idnos-rec/*:type != '') then
                    <note type="type" xmlns="http://www.tei-c.org/ns/1.0">{$idnos-rec/*:type/text()}</note>
                else ()
let $r-abstract := 
                if(not(empty($idnos-rec/*:abstract))) then 
                    <note type="abstract" xmlns="http://www.tei-c.org/ns/1.0">
                        {(
                            $idnos-rec/*:abstract/node(),
                            if(not(empty($idnos-rec/*:Not_Useful))) then 
                                <note >{$idnos-rec/*:Not_Useful/node()}</note>
                            else()
                        )}
                    </note>
                else()
let $r-affiliation := 
                if(not(empty($idnos-rec/*:affiliation))) then 
                    <note type="affiliation" xmlns="http://www.tei-c.org/ns/1.0">
                        {$idnos-rec/*:affiliation/node()}
                    </note>
                else()
return 
            if($eh != $rh) then 
                update value $e/tei:head[1] with $rh
            else ()
