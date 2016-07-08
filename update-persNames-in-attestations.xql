
xquery version "3.0";
import module namespace functx="http://www.functx.com";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare function local:parse-name($name){
if($name/child::*) then 
    string-join(for $part in $name/child::*
    order by $part/@sort ascending, string-join($part/descendant-or-self::text(),' ') descending
    return $part/text(),' ')
else $name/text()
};
for $r in collection('/db/apps/srophe-data/data/persons/tei')//tei:event[@type="attestation"]
let $id := $r/ancestor::tei:person/tei:idno[@type='URI'][starts-with(.,'http://syriaca.org')]
let $original := $r
let $title := $r/descendant::tei:title
let $author := 
        <persName ref="{$id}">{local:parse-name($r/ancestor::tei:person/tei:persName[@syriaca-tags='#syriaca-headword'][@xml:lang='en'][1])}</persName>
let $new-content := 
<p xml:lang="en" xmlns="http://www.tei-c.org/ns/1.0">
    {($author, ' is commemorated in ', $title,'.')} 
</p>
return update replace $r/child::* with $new-content
