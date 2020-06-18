xquery version "3.0";
(:~ 
 : Utility function to collate returned MARCXML Records from Worldcat API into a single file, a marc:collection containing several marc:record nodes
 : 
 : @author William Potter
 : @version 1.0 
 : 
 :)
 declare namespace marc="http://www.loc.gov/MARC21/slim";
 declare option output:omit-xml-declaration "no";
 declare option file:omit-xml-declaration "no";
 
 let $inputUri := 'file:///Users/dhlab/Documents/GitHub/miscellaneous-util-scripts/Caesarea-Biblio-Api/MARCXMLOutputs-3/'
 let $recs := for $doc in fn:collection($inputUri)
  return $doc/*:collection/*:record
 let $collection := <collection xmlns="http://www.loc.gov/MARC21/slim">{$recs}</collection>
 return file:write($inputUri || 'collectedOutputs' || current-date() || '.xml', $collection, map{'omit-xml-declaration': 'no'})
 