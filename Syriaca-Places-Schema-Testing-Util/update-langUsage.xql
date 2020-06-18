xquery version "3.0";
import module namespace functx = "http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare option output:omit-xml-declaration "no";
declare option output "indent=no";

let $newLangUsage := <langUsage>
                <p>
                    Languages codes used in this record follow the Syriaca.org guidelines. Documentation available at: 
                    <ref target="http://syriaca.org/documentation/langusage.xml">http://syriaca.org/documentation/langusage.xml</ref>
                </p>
            </langUsage>
let $inputCollectionUri := "C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\"
for $doc in collection($inputCollectionUri)
  return if(empty($doc//profileDesc/langUsage)) then () else replace node $doc//profileDesc/langUsage with $newLangUsage