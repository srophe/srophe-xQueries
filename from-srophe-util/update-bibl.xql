xquery version "3.0";
(:~ 
 : Srophe utility function to update bibl elements with full bibl entry from syriaca.org bibl module
 : See: https://github.com/srophe/bethqatraye-data/issues/50 
 :   
 : @author Winona Salesky
 : @version 1.0 
 : 
 :) 
import module namespace http="http://expath.org/ns/http-client";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace file="http://exist-db.org/xquery/file";

(:
 : Global variables, change for each use case
:)
(: Set $web to true() to access via Syriaca.org production server, flase() to run locally, this will require having srophe-app-data installed on your local version of eXist:)
declare variable $web := false();
declare variable $data-root := '/db/apps/bethqatraye-data/data';
declare variable $biblURI := '/db/apps/srophe-data/data';
declare variable $baseURI := 'http://bqgazetteer.bethmardutho.org/place/';
declare variable $editor := 'srophe-util';
declare variable $changeLog := 'CHANGED: Update bibl elements with full citation information from Syriaca.org entry.';

declare function local:transform($nodes as node()*) as item()* {
  for $node in $nodes
  return 
    typeswitch($node)
        case processing-instruction() return $node 
        case comment() return $node 
        case text() return parse-xml-fragment($node)                  
        case element() return local:passthru($node)
        default return local:transform($node/node())
};

(: Recurse through child nodes :)
declare function local:passthru($node as node()*) as item()* { 
    element {local-name($node)} {($node/@*[. != ''], local:transform($node/node()))}
};

declare function local:update-bibl($record as item()*){
    let $change :=             
        <change xmlns="http://www.tei-c.org/ns/1.0" who="http://syriaca.org/documentation/editors.xml#{$editor}" when="{current-date()}">{$changeLog}</change>
    return
    (
    for $bibl in $record//tei:bibl[tei:ptr[starts-with(@target,'http://syriaca.org/bibl')]]
    let $ptr := $bibl/tei:ptr[starts-with(@target,'http://syriaca.org/bibl')]/@target
    let $biblRec := 
        if($web = true()) then 
            http:send-request(<http:request http-version="1.1" href="{xs:anyURI(concat($ptr,'/tei'))}" method="get">
                                <http:header name="Connection" value="close"/>
                               </http:request>)[2]
        else collection($biblURI)//tei:TEI[descendant::tei:idno[. = concat($ptr,'/tei')]]
    let $biblStruct := $biblRec/descendant::tei:biblStruct    
    let $title := local:transform($biblStruct/descendant::tei:title)
    let $author := local:transform($biblStruct/descendant::tei:author) 
    let $editor := local:transform($biblStruct/descendant::tei:editor)
    return  
        (if($bibl/tei:title and $title != '') then 
            update replace $bibl/tei:title with $title
         else if($title != '') then
            update insert $title into $bibl
         else (),
         if($bibl/tei:author and $author != '') then  
            update replace $bibl/tei:author with $author
         else if($author) then  
            update insert $author into $bibl
         else (),
         if($bibl/tei:editor and $editor != '') then
            update replace $bibl/tei:editor with $editor
         else if($editor) then   
            update insert $editor into $bibl
         else ()   
            ),
    update insert $change
          preceding $record/descendant::tei:revisionDesc/tei:change[1],
          update value $record/descendant::tei:fileDesc/tei:publicationStmt/tei:date with current-date() )          
};

let $recs := collection($data-root)//tei:TEI[descendant::tei:bibl[tei:ptr[starts-with(@target,'http://syriaca.org/bibl')]]]
let $count := count($recs)
for $bibl in subsequence($recs,1,10)
return 
    try {
            (local:update-bibl($bibl)) 
        } catch * {concat($err:code, ": ", $err:description)}