xquery version "3.0";
import module namespace functx="http://www.functx.com";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare function local:parseName($names as xs:string*){
  if(contains($names,'.')) then 
      <author xmlns="http://www.tei-c.org/ns/1.0">
        <persName>
            <forename>{concat(functx:substring-before-last($names, '.'),'.')}</forename>
            <surname>{normalize-space(functx:substring-after-last($names, '.'))}</surname>
        </persName>
       </author>
    else <author xmlns="http://www.tei-c.org/ns/1.0"><persName><surname>{normalize-space($names)}</surname></persName></author>
};

for $b in collection('/db/apps/srophe-data/data/persons/tei')//tei:bibl[parent::tei:person]/tei:author
let $names :=
    if(contains($b/text(),'/')) then
        for $np in tokenize($b/text(),'/')
        return local:parseName($np)
    else local:parseName($b/text())
return 
    (update replace $b with $names,
    if($b/ancestor::tei:TEI/descendant::tei:teiHeader/tei:revisionDesc/tei:change[. = 'Split names in authors into forename and surname.']) then ()
    else
    update insert 
        <change xmlns="http://www.tei-c.org/ns/1.0" who="http://syriaca.org/documentation/editors.xml#wsalesky" when="{current-date()}">Split names in authors into forename and surname.</change>
          preceding $b/ancestor::tei:TEI/descendant::tei:teiHeader/tei:revisionDesc/tei:change[1],
    update value $b/ancestor::tei:TEI/descendant::tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:date with current-date())
