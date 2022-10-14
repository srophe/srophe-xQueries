xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $in-doc :=
  collection("/home/arren/Documents/GitHub/fixing-testimonia-string-sort-by-hand.xml");
  
declare variable $testimonia-coll :=
  collection("/home/arren/Documents/GitHub/caesarea-data/data/testimonia/tei/");
  
for $ref in $in-doc/*:root/*:failure/*:work/*:ref
for $doc in $testimonia-coll
  where $ref/@target/string() = $doc//profileDesc/creation/ref/@target/string()
  return replace node $doc//profileDesc/creation/ref with $ref