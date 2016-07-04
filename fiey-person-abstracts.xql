xquery version "3.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace syriaca = "http://syriaca.org";
declare namespace functx = "http://www.functx.com";

let $uri := '/db/apps/srophe-data/data/persons/tei/saints/tei'
let $collection := collection($uri)
let $new-doc := doc('/db/apps/srophe-data/data/persons/fiey-person-abstracts.xml')

let $list := 
    for $person in $collection/TEI/text/body/listPerson/person
        let $row :=
            concat($person/idno[@type="URI" and contains(.,'syriaca.org')],'***',$person/persName[@xml:lang='en'][1],'***',$person/note[@type='abstract'],'***',string-join($person/note[@type='abstract']/*/@ref|$person/note[@type='abstract']/quote/*/@ref,'***'))
        return <item>{$row}</item>
return 
    update value $new-doc/TEI with $list