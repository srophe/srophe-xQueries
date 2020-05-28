xquery version "3.0";
declare namespace tei="http://www.tei-c.org/ns/1.0";

(: 
 :One time function to add location data from Pleiades.xml 
:)
(:~ Test data, uncomment to test
        <div>
             <location type="gps" source="#bib{$doc-id}-{$bibNo}">
                    <geo>{concat($lat,' ',$long)}</geo>
             </location>
             <bibl xml:id="bib{$doc-id}-{$bibNo}">
                  <title>http://pleiades.stoa.org/places/{$pleiades-id}</title>
                  <ptr target="http://pleiades.stoa.org/places/{$pleiades-id}"/>
             </bibl>
             <change who="http://syriaca.org/editors.xml#{$editor}" when="{current-dateTime()}">ADDED: latitude and longitude from Pleiades</change>
        </div>
:)
declare function local:add-bibl($rec, $newUri){
    for $bibl in $rec/descendant::tei:bibl[last()]
    let $biblId := substring-before($bibl/@xml:id,'-')
    let $id := substring-after($bibl/@xml:id,'-')
    let $newBiblId:= concat($biblId,'-',xs:integer($id) + 1)
    let $newBibl := 
            <bibl xml:id="{$newBiblId}">
                <ptr target="{$newUri}"/>
            </bibl>
            (:update value $doc/ancestor::*//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:date with current-date():)
    let $abstract := $rec/descendant::tei:desc[@type='abstract']
    return 
        (update insert $newBibl following $bibl,
        if($abstract/@source) then
            update value $abstract with concat('#',$newBiblId)
        else update insert attribute source {concat('#',$newBiblId)} into $abstract
        )
        

};

declare function local:update-locations(){
    for $places in doc('/db/apps/srophe/data/places/Pleiades-Grabber-Results-Edited.xml')//row[Match='UPDATED']
    let $id := concat('place-',$places/Place_ID)
    return 
        for $doc in collection('/db/apps/srophe/data/places/tei')/id($id)[1]
        let $doc-id := substring-after($id,'place-')
        let $bibNo := count($doc//tei:bibl) + 1
        let $lat := $places/Latitude
        let $long := $places/Longitude
        let $pleiades-id := string($places/Pleiades_ID)
        return (
             try {
                   (update insert 
                           <location xmlns="http://www.tei-c.org/ns/1.0" type="gps" source="#bib{$doc-id}-{$bibNo}">
                             <geo>{concat($lat,' ',$long)}</geo>
                           </location>
                   following $doc//tei:desc[last()],
                   update insert
                         <bibl xmlns="http://www.tei-c.org/ns/1.0" xml:id="bib{$doc-id}-{$bibNo}">
                           <title>http://pleiades.stoa.org/places/{$pleiades-id}</title>
                           <ptr target="http://pleiades.stoa.org/places/{$pleiades-id}"/>
                      </bibl>
                   following $doc//tei:bibl[last()]
                   )
                 } catch * {
                     <p>{
                         (string($id), "Error:", $err:code)
                     }</p>
                 },
                local:add-change-log($doc),<p>{$doc-id}</p>)
                
};

declare function local:related-data($doc-id,$doc-name){
    for $doc-rel in collection('/db/apps/srophe/data/places/tei')//tei:place[tei:placeName[@syriaca-tags='#syriaca-headword'] = $doc-name]
    let $doc-rel-id := $doc-rel/@xml:id
    let $doc-rel-name := $doc-rel/text()
    where not($doc-rel-id = $doc-id)
    return 
        concat(' http://syriaca.org/place/',substring-after($doc-rel-id,'place-')) 
};

declare function local:link-related-names(){
    let $docs-all := for $docs in collection('/db/apps/srophe/data/places/tei')//tei:place[tei:placeName[@syriaca-tags='#syriaca-headword']] return $docs
    for $doc at $p in subsequence($docs-all, 2600, 100)
    let $doc-name := $doc/tei:placeName[@syriaca-tags='#syriaca-headword'][1]/text()
    let $doc-id := $doc/@xml:id
    return 
        if(count(local:related-data($doc-id,$doc-name)) gt 0) then 
            (update insert 
                <relation xmlns="http://www.tei-c.org/ns/1.0" name="shares-name-with" mutual="#place{(substring-after($doc-id,'place-'), local:related-data($doc-id,$doc-name))}"/>
            following $doc, local:add-change-log($doc),<p>{$doc-id}</p>)       
         else ''
};

(:~
 : Insert new change element and change publication date
 : @param $editor from form and $comment from form
 : ADDED: syriaca-computed-start and syriaca-computed-end attributes for searching
 : ADDED: latitude and longitude from Pleiades
:)
declare function local:add-change-log($doc){
       (update insert 
            <change xmlns="http://www.tei-c.org/ns/1.0" who="http://syriaca.org/documentation/editors.xml#{$editor}" when="{current-date()}">
                {$comment}
            </change>
          preceding $doc/ancestor::*//tei:teiHeader/tei:revisionDesc/tei:change[1],
          update value $doc/ancestor::*//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:date with current-date()
          )
};

declare function local:remove-mutual(){
   for $doc in collection('/db/apps/srophe/data/places/tei')//tei:relation
   let $mutual := string($doc/@mutual)
   let $new-mutual-end := substring-after($mutual,' ')
   let $new-mutual-beging := substring-before(substring-after($mutual,'place'),' ')
   let $new-mutual := concat('#place-',$new-mutual-beging,' ',$new-mutual-end)
   where $doc[@name='shares-name-with']
   return
    (update value $doc/@name with 'share-a-name', update value $doc/@mutual with $new-mutual)

   
};
(:~ 
 : General function to remove attributes. 
 : Edit as needed, no public interface for this function 
:)
declare function local:remove-attributes(){
   for $doc in collection('/db/apps/srophe/data/places/tei')//tei:place
   return 
   (:add test for when-custom so I don't add it repeatedly:)
        for $date in $doc/descendant-or-self::*/@from-custom
        return update delete $date
};