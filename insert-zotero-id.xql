xquery version "3.0";

(: NAMESPACES:)
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace syriaca = "http://syriaca.org";
declare namespace functx = "http://www.functx.com";

let $works := collection('/db/apps/srophe-data/data/works/tei')/TEI
let $spreadsheet := doc('/db/apps/srophe-data/data/bibl/hagiography-editions-translations.xml')/root

for $bibl in $works//bibl/note[not(@type='MSS')]/bibl[not(ptr) and not(idno)][position() < 10]
    let $matching-row := $spreadsheet/row[Author=$bibl/(author|editor) and Title=$bibl/title][1]
    let $id-syriaca-matching := $matching-row/Syriaca_ID[1]
    let $id-zotero-matching := $matching-row/Zotero_ID[1]
    let $idno := 
        if ($id-syriaca-matching!='') then
            let $URI := concat('http://syriaca.org/bibl/',$id-syriaca-matching/text())
            return element ptr {attribute target {$URI}}
        else if ($id-zotero-matching!='') then
            element idno {attribute type {'zotero'},$id-zotero-matching/text()}
        else ()
    let $vol := if ($matching-row/Volume_No.[.!='']) then <citedRange unit='vol'>{$matching-row/Volume_No./text()}</citedRange> else ()
    let $new-bibl :=
        element bibl {$bibl/@*, $bibl/node()[name()!='citedRange'], $idno, $vol, $bibl/citedRange}


return 
    if ($idno) then 
        (update insert $new-bibl following $bibl,
        update delete $bibl)
    else ()