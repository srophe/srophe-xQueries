xquery version "3.0";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace syriaca = "http://syriaca.org";
declare namespace functx = "http://www.functx.com";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";

let $doc := doc('/db/apps/srophe-data/data/persons/authors-from-lah.xml')
(:let $doc := doc('/Users/nathan/Documents/Employment/Syriaca/srophe/persons/working-files/Gent-Late-Antique-Historiography/authors.xml'):)
let $new-doc := doc('/db/apps/srophe-data/data/persons/authors-from-lah-tei.xml')
for $person in $doc/root/ul/li
    let $person-link := $person/descendant::a[contains(@href,'authors')]
    let $person-id := replace($person-link/@href,'http://www.late-antique-historiography.ugent.be/database/authors/','')
    let $person-element := $new-doc//person[idno=$person-id]
    let $person-doc := http:send-request(
<http:request href="{$person-link/@href}" method="get">
</http:request>)//*:div[@id='content']
    let $persNames := 
        for $name in $person//div[@class='field field-other-names' or @class='field field-name']//span
        return <persName xml:lang="{$name/@class}">{$name/text()}</persName>
    let $date := 
        for $item in $person-doc//xhtml:div[@class='field field-date']/xhtml:div[@class='field-items']/text()
        return <note><date>{$item}</date></note>
    let $social-status := 
        for $item in $person-doc//xhtml:div[@class='field field-socialstatus']/xhtml:div[@class='field-items']/xhtml:ul/xhtml:li
        return <state><desc>{$item/text()}</desc></state>
    let $confession := 
        for $item in $person-doc//xhtml:div[@class='field field-confession']/xhtml:div[@class='field-items']/xhtml:ul/xhtml:li
        return <state type="confession"><desc>{$item/text()}</desc></state>
    let $works := 
        for $work in $person//div[@class='field field-works']//a/@href
        return <relation name="dc:creator" active="{$person-link/@href}" passive="{$work}"/>
    let $items-to-insert := ($date,$social-status,$confession)
return 
    if ($items-to-insert) then 
    update insert $items-to-insert into $person-element
    else ()
    
(:    <tei:person>:)
(:    {$persNames}:)
(:    <idno type="LAH">{$person-id}</idno>:)
(:    <idno type="URI"/>:)
(:    {$date}:)
(:    {$social-status}:)
(:    {$confession}:)
(:    {if ($works) then $works else ()}:)
(:    </tei:person>:)
    