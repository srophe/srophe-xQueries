xquery version "3.0";

module namespace srophe-util="http://srophe.org/ns/srophe-util";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";

declare variable $srophe-util:resource-uri {request:get-parameter('resource', '')};
declare variable $srophe-util:option {request:get-parameter('option', '')};
declare variable $srophe-util:editor {request:get-parameter('editor', '')};
declare variable $srophe-util:comment {request:get-parameter('comment', '')};

(:~
 : Insert custom generated dates
 : Takes @notBefore, @notAfter, @to, @from, and @when and adds a syriaca computed date attribute for searching.
 : @param $resource-uri path to resource or collection  
 :)                       
declare function srophe-util:add-custom-dates($resource-uri,$comment, $editor){
   if(ends-with($resource-uri),'.xml') then srophe-util:custom-dates-doc($resource-uri)
   else srophe-util:custom-dates-coll($resource-uri)
                            
};

declare function srophe-util:custom-dates-coll($resource-uri,$comment, $editor){
for $doc in collection($resource-uri)//tei:body 
return 
    (
            srophe-util:notAfter($doc),
            srophe-util:notBefore($doc),
            srophe-util:to($doc),
            srophe-util:from($doc),
            srophe-util:when($doc),
            if((srophe-util:notAfter($doc),) = 'success')
                srophe-util:add-change-log($doc,$comment, $editor)
            else if((srophe-util:notBefore($doc),) = 'success')
                srophe-util:add-change-log($doc,$comment, $editor)
            else if((srophe-util:to($doc),) = 'success')
                srophe-util:add-change-log($doc,$comment, $editor)
            else if((srophe-util:from($doc),) = 'success')
                srophe-util:add-change-log($doc,$comment, $editor)
            else if((srophe-util:when($doc),) = 'success')
                srophe-util:add-change-log($doc,$comment, $editor)
            else () 
    ) 
};

declare function srophe-util:custom-dates-doc($resource-uri,$comment, $editor){
for $doc in doc($resource-uri)//tei:body 
return 
    (
            srophe-util:notAfter($doc),
            srophe-util:notBefore($doc),
            srophe-util:to($doc),
            srophe-util:from($doc),
            srophe-util:when($doc),
            if((srophe-util:notAfter($doc),) = 'success')
                srophe-util:add-change-log($doc,$comment, $editor)
            else if((srophe-util:notBefore($doc),) = 'success')
                srophe-util:add-change-log($doc,$comment, $editor)
            else if((srophe-util:to($doc),) = 'success')
                srophe-util:add-change-log($doc,$comment, $editor)
            else if((srophe-util:from($doc),) = 'success')
                srophe-util:add-change-log($doc,$comment, $editor)
            else if((srophe-util:when($doc),) = 'success')
                srophe-util:add-change-log($doc,$comment, $editor)
            else ()    
    ) 
};

(:~
 : Take data from @notAfter, check for existing @syriaca-computed-end
 : if none, format date and add @syriaca-computed-end as xs:date
 : @param $doc document node
:)
declare function srophe-util:notAfter($doc){
    for $date in $doc/descendant-or-self::*/@notAfter
    let $date-norm := if(starts-with($date,'0000') and string-length($date) eq 4) then '0001-01-01'
                          else if(string-length($date) eq 4) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 7) then concat(string($date),'-01')
                          else string($date)
    return 
        if($date[@syriaca-computed-end]) then 'exists'
        else   
            try {
                    (update insert attribute syriaca-computed-end {xs:date($date-norm)} into $date/parent::*,'success')
                } 
            catch * 
                {
                    <date place="{$doc/@xml:id}">{(string($date-norm), "Error:", $err:code)}</date>
                }     
};

(:~
 : Take data from @notBefore, check for existing @syriaca-computed-start
 : if none, format date and add @syriaca-computed-start as xs:date
 : @param $doc document node
:)
declare function srophe-util:notBefore($doc){
    for $date in $doc/descendant-or-self::*/@notBefore
    let $date-norm := if(starts-with($date,'0000') and string-length($date) eq 4) then '0001-01-01'
                          else if(string-length($date) eq 4) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 7) then concat(string($date),'-01')
                          else string($date)
    return 
        if($date[@syriaca-computed-start]) then 'exists'
        else   try {
                        (update insert attribute syriaca-computed-start {xs:date($date-norm)} into $date/parent::*,'success')
                     } catch * {
                         <date place="{$doc/@xml:id}">{
                             (string($date-norm), "Error:", $err:code)
                         }</date>
                     }
};

(:~
 : Take data from @to, check for existing @syriaca-computed-end
 : if none, format date and add @syriaca-computed-end as xs:date
 : @param $doc document node
:)
declare function srophe-util:to($doc){
    for $date in $doc/descendant-or-self::*/@to
    let $date-norm := if(starts-with($date,'0000') and string-length($date) eq 4) then '0001-01-01'
                          else if(string-length($date) eq 4) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 7) then concat(string($date),'-01')
                          else string($date)
    return 
        if($date[@syriaca-computed-end]) then 'exists'
        else   try {
                        (update insert attribute syriaca-computed-end {xs:date($date-norm)} into $date/parent::*,'success')
                     } catch * {
                         <date place="{$doc/@xml:id}">{
                             (string($date-norm), "Error:", $err:code)
                         }</date>
                     }
};

(:~
 : Take data from @from, check for existing @syriaca-computed-start
 : if none, format date and add @syriaca-computed-start as xs:date
 : @param $doc document node
:)
declare function srophe-util:from($doc){
    for $date in $doc/descendant-or-self::*/@from
    let $date-norm := if(starts-with($date,'0000') and string-length($date) eq 4) then '0001-01-01'
                          else if(string-length($date) eq 4) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 7) then concat(string($date),'-01')
                          else string($date)
    return 
        if($date[@syriaca-computed-start]) then 'exists'
        else   try {
                        (update insert attribute syriaca-computed-start {xs:date($date-norm)} into $date/parent::*,'success')
                     } catch * {
                         <date place="{$doc/@xml:id}">{
                             (string($date-norm), "Error:", $err:code)
                         }</date>
                     }
};

(:~
 : Take data from @when, check for existing @syriaca-computed-start
 : if none, format date and add @syriaca-computed-start as xs:date
:)
declare function srophe-util:when($doc){
    for $date in $doc/descendant-or-self::*/@when
    let $date-norm := if(starts-with($date,'0000') and string-length($date) eq 4) then '0001-01-01'
                          else if(string-length($date) eq 4) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 7) then concat(string($date),'-01')
                          else string($date)
    return 
        if($date[@syriaca-computed-start]) then 'exists'
        else   try {
                        (update insert attribute syriaca-computed-start {xs:date($date-norm)} into $date/parent::*, 'success')
                     } catch * {
                         <date place="{$doc/@xml:id}">{
                             (string($date-norm), "Error:", $err:code)
                         }</date>
                     }
};

(:~
 : Insert new change element and change publication date
 : @param $editor from form and $comment from form
 : ADDED: syriaca-computed-start and syriaca-computed-end attributes for searching
 : ADDED: latitude and longitude from Pleiades
:)
declare function srophe-util:add-change-log($doc, $comment, $editor){
       (update insert 
            <change xmlns="http://www.tei-c.org/ns/1.0" who="http://syriaca.org/documentation/editors.xml#{$editor}" when="{current-date()}">
                {$comment}
            </change>
          preceding $doc/ancestor::*//tei:teiHeader/tei:revisionDesc/tei:change[1],
          update value $doc/ancestor::*//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:date with current-date()
          )
};

(: Need to add a sucess message if no error codes.
add admin user and precomputed comment if run by admin module. 

(session:create(),
xmldb:login('/db/apps/srophe/', 'admin', '', true()))
xmldb:get-current-user() 
srophe-util:add-custom-dates()
ADDED: syriaca-computed-start and syriaca-computed-end attributes for searching
:)

(:<div>You do not have permission to run this query</div>
(xmldb:login('/db/apps/srophe/', 'admin', '', true()),srophe-util:add-custom-dates()):)
