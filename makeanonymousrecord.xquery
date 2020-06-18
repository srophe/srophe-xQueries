xquery version "3.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

let $list := ("http://syriaca.org/person/1210", "http://syriaca.org/person/1211", "http://syriaca.org/person/1212", "http://syriaca.org/person/1899", "http://syriaca.org/person/1900", "http://syriaca.org/person/1901", "http://syriaca.org/person/1902", "http://syriaca.org/person/1904", "http://syriaca.org/person/1905", "http://syriaca.org/person/1744", "http://syriaca.org/person/1936", "http://syriaca.org/person/1934", "http://syriaca.org/person/1659", "http://syriaca.org/person/1442", "http://syriaca.org/person/1441", "http://syriaca.org/person/1216", "http://syriaca.org/person/1970", "http://syriaca.org/person/1971", "http://syriaca.org/person/1972", "http://syriaca.org/person/2028", "http://syriaca.org/person/2029", "http://syriaca.org/person/2030", "http://syriaca.org/person/1992", "http://syriaca.org/person/1993", "http://syriaca.org/person/1994", "http://syriaca.org/person/2035", "http://syriaca.org/person/2056", "http://syriaca.org/person/2057", "http://syriaca.org/person/2058", "http://syriaca.org/person/2168")

for $uri in $list

return
    for $person in fn:collection('/db/apps/srophe-data/data/persons/tei')//tei:person[tei:idno/text()[.=$uri]]
    let $name := $person/tei:persName[@xml:lang="en"][contains(@syriaca-tags,"#syriaca-headword")]
    let $bibl := $person/tei:bibl[1]
    let $newName :=
        <persName xmlns="http://www.tei-c.org/ns/1.0" xml:id="{concat('name',substring-after($uri,'/person/'),'-a')}" 
        xml:lang="en" syriaca-tags="#syriaca-headword">Anonymi {substring-after($uri,'/person/')}</persName>
    let $newbio :=
        <state xmlns="http://www.tei-c.org/ns/1.0" type="group" source="#bib{substring-after($uri,'/person/')}-1"/>
    let $newtrait :=
        <trait xmlns="http://www.tei-c.org/ns/1.0" xml:lang="en"><label>anonymous</label></trait> 
        
    return 
        (
        update value $name/@syriaca-tags with '#anonymous-description',
        update insert $newName preceding $name,
        update insert $newbio preceding $bibl,
        update insert $newtrait preceding $bibl
        )
        