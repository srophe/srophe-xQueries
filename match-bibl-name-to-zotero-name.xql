declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: for each row/record in the zoteroid file where there is no text node for the element uritype :)
for $row in fn:doc("/db/apps/bug-test/zoteroid.xml")/root/row[not(uritype/text())]
let $author := normalize-space($row/authorabbr/text())
let $title := normalize-space($row/titleabbr/text())
let $zoteroid := $row/zotero/text()

(: for each zotero idno in Syriaca.org bibl records:)
(: Get bibl uri:)
let $biblURI := 
              for $biblfile in fn:collection("/db/apps/srophe-data/data/bibl/tei")//tei:idno[@type="zotero"][. = $zoteroid]
              let $uri := replace($biblfile/ancestor::tei:TEI/descendant::tei:publicationStmt/descendant::tei:idno[@type="URI"][starts-with(.,'http://syriaca.org/')]/text(),'/tei','')
              return $uri
return    
  if(count($biblURI) gt 1) then (<zotero-id>{$zoteroid}</zotero-id>, <bibl-id>{$biblURI}</bibl-id>) 
  else 
    (: for bibl nodes in each person record without a bibl URI :)
    for $bibl in fn:collection("/db/apps/srophe-data/data/persons/tei")//tei:person/tei:bibl[not(tei:ptr)]
    let $bibltitle := normalize-space($bibl/tei:title[1]/text())
    let $biblauthor := normalize-space($bibl/tei:author[1]/tei:persName/tei:surname/text())
    (: text() was causing the ptr to be inserted in the citedRange element, before the text node :)
    let $biblcitedrange := $bibl/tei:citedRange
  
   where 
    ($bibltitle = $title and $biblauthor = $author) 
    or ($bibltitle = $title and $biblauthor = '') 
    or ($biblauthor = $author and $bibltitle = '')
  
return 
  (: if you do not include the tei namespace the new element will be inserted with a blank namespace. :)
 (if($biblcitedrange) then 
     update insert <ptr xmlns="http://www.tei-c.org/ns/1.0" target="{$biblURI}"/> preceding $biblcitedrange
  else      
      update insert <ptr xmlns="http://www.tei-c.org/ns/1.0" target="{$biblURI}"/> into $bibl,
 if($bibl/ancestor::tei:TEI/descendant::tei:teiHeader/tei:revisionDesc/tei:change[. = 'Add bibl ptr elements.']) then ()
    else
    update insert 
        <change xmlns="http://www.tei-c.org/ns/1.0" who="http://syriaca.org/documentation/editors.xml#wsalesky" when="{current-date()}">Add bibl ptr elements.</change>
          preceding $bibl/ancestor::tei:TEI/descendant::tei:teiHeader/tei:revisionDesc/tei:change[1],
    update value $bibl/ancestor::tei:TEI/descendant::tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:date with current-date()
    )
