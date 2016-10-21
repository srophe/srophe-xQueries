xquery version "3.0";
declare namespace tei="http://www.tei-c.org/ns/1.0";

for $e at $ei in doc('/db/apps/e-gedesh-data/egesdh-version-0-1.xml')//tei:div[@type ="entry"][tei:head[contains(.,', ')]]
let $head := $e/tei:head
let $althead := 
    <idno type="althead" subtype="altorder" xmlns="http://www.tei-c.org/ns/1.0">{
        concat(normalize-space(tokenize($head,',')[2]),' ',tokenize($head,',')[1])
    }</idno>
return 
    if(count(tokenize($head,',')) gt 2) then ()
    else 
        update insert $althead following $e/tei:ab[@type="idnos"]/tei:milestone[1]
