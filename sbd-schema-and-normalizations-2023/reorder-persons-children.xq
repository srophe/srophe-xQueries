xquery version "3.1";

declare default element namespace "http://www.tei-c.org/ns/1.0";

(:
Reorders child elements in the person or personGrp elements in SBD based on the following:
    <elementRef key="persName" minOccurs="1" maxOccurs="unbounded"/>
    <elementRef key="link" minOccurs="0" maxOccurs="unbounded"/>
    <elementRef key="idno" minOccurs="1" maxOccurs="unbounded"/>
    <elementRef key="note" minOccurs="1" maxOccurs="unbounded"/>
    <elementRef key="floruit" minOccurs="0" maxOccurs="unbounded"/>
    <elementRef key="birth" minOccurs="0" maxOccurs="unbounded"/>
    <elementRef key="death" minOccurs="0" maxOccurs="unbounded"/>
    <elementRef key="gender" minOccurs="0" maxOccurs="unbounded"/>
    <elementRef key="state" minOccurs="0" maxOccurs="unbounded"/>
    <elementRef key="trait" minOccurs="0" maxOccurs="unbounded"/>
    <elementRef key="event" minOccurs="0" maxOccurs="unbounded"/>
    <elementRef key="bibl" minOccurs="1" maxOccurs="unbounded"/>
:)

declare variable $in-coll := collection("/home/arren/Documents/GitHub/srophe-app-data/data/persons/tei/");

for $doc in $in-coll
for $pers in $doc//listPerson/*[name() = "person" or name() = "personGrp"]
let $persName := $pers/persName
let $link := $pers/link
let $idno := $pers/idno
let $note := $pers/note
let $floruit := $pers/floruit
let $birth := $pers/birth
let $death := $pers/death
let $gender := $pers/gender
let $state := $pers/state
let $trait := $pers/trait
let $event := $pers/event
let $bibl := $pers/bibl

let $newEl := 
    element {$pers/name()} {
        $pers/@*,
        $persName,
        $link,
        $idno,
        $note,
        $floruit,
        $birth,
        $death,
        $gender,
        $state,
        $trait,
        $event,
        $bibl
    }
return replace node $pers with $newEl