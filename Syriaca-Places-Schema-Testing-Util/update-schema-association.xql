xquery version "3.0";
import module namespace functx = "http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare option output:omit-xml-declaration "no";
declare option output "indent=no";


let $newSchemaAssociations := (processing-instruction xml-model {
        'href="https://raw.githubusercontent.com/srophe/srophe-eXist-app/master/documentation/schemas/out/syriacaAll.compiled.rng" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"'
    }, processing-instruction xml-model {
        'href="https://raw.githubusercontent.com/srophe/srophe-eXist-app/master/documentation/schemas/out/syriacaAll.compiled.rng" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"'
    })
    
let $inputCollectionUri := "C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\bibl\tei\"
for $doc in collection($inputCollectionUri)
  (: where $doc//listPlace/place/idno[1]/text() = "http://syriaca.org/place/78" :)
  return (delete node $doc//processing-instruction(),
    insert node $newSchemaAssociations before $doc/TEI)