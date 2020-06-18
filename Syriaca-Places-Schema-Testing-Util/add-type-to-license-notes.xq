xquery version "3.0";
import module namespace functx = "http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare option output:omit-xml-declaration "no";
declare option output "indent=no";



    
let $inputCollectionUri := "C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\"
for $doc in collection($inputCollectionUri)
  where $doc/TEI/teiHeader/fileDesc/publicationStmt/availability/licence/p/note
  let $note := $doc/TEI/teiHeader/fileDesc/publicationStmt/availability/licence/p/note
  let $newNote := functx:add-attributes($note, QName("", "type"), "license")
  return replace node $doc/TEI/teiHeader/fileDesc/publicationStmt/availability/licence/p/note with $newNote