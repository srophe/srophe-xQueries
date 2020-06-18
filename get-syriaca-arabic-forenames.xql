xquery version "3.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace syriaca = "http://syriaca.org";
declare namespace functx = "http://www.functx.com";
declare namespace fn = "http://www.w3.org/2005/xpath-functions";

let $persons := collection("/db/apps/srophe-data/data/persons/tei")

let $filtered-persons := 
    for $person in $persons[descendant::persName[starts-with(@xml:lang,'ar')]/forename]/TEI/text/body/listPerson/person
        let $persNames := $person/persName[starts-with(@xml:lang,'ar')]/forename
        let $idno := $person/idno[matches(.,'http://syriaca.org/person') and @type='URI']
        let $confessions := $person/state[@type='confession']
        let $faiths :=
            for $confession in $confessions
            let $key := 
                if (matches($confession,'Syr.+Orth|Melk|Ch.+of.+E|Chald|Maron|Syr.+Cath|Miaphysite')) then 
                    'Christian'
                else ()
             return element faith {attribute key {$key},$confession/desc/node()}
        let $death := $person/death
    
        return
            <person>
                {for $persName in $persNames
                 return element persName {attribute type {'ISM'},$persName/node()}}
                 {$idno}
                 {$faiths}
                 {$death}
            </person>
            
let $xml-doc :=
<TEI xmlns="http://www.tei-c.org/ns/1.0"
     xmlns:scholarnet="http://scholarnet.org"
     xmlns:functx="http://www.functx.com">
   <teiHeader>
      <fileDesc>
         <titleStmt>
            <title>Arabic Forenames from Syriaca.org</title>
         </titleStmt>
         <publicationStmt>
            <p>Publication Information</p>
         </publicationStmt>
         <sourceDesc>
            <p>Information about the source</p>
         </sourceDesc>
      </fileDesc>
   </teiHeader>
   <text>
      <body>
         <listPerson>
             {$filtered-persons}
         </listPerson>
     </body>
    </text>
</TEI>
        
return xmldb:store('/db/apps/scholarnet/data/','arabic-forenames-syriaca.xml',$xml-doc)
        