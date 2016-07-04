xquery version "3.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace syriaca = "http://syriaca.org";
declare namespace functx = "http://www.functx.com";

declare function syriaca:replace-ids($node as xs:string*, $old-ids as xs:string*,$new-ids as xs:string*) as node()* {
    let $result :=  
        if(count($old-ids)>1) then
            let $new-node := syriaca:replace-ids($node,remove($old-ids,1),remove($new-ids,1))
            return $new-node
        else
            replace($node,$old-ids,$new-ids)
    return $result
};

declare function functx:add-attributes
  ( $elements as element()* ,
    $attrNames as xs:QName* ,
    $attrValues as xs:anyAtomicType* )  as element()? {

   for $element in $elements
   return element { node-name($element)}
                  { for $attrName at $seq in $attrNames
                    return if ($element/@*[node-name(.) = $attrName])
                           then ()
                           else attribute {$attrName}
                                          {$attrValues[$seq]},
                    $element/@*,
                    $element/node() }
 } ;

declare function functx:update-attributes
  ( $elements as element()* ,
    $attrNames as xs:QName* ,
    $attrValues as xs:anyAtomicType* )  as element()? {

   for $element in $elements
   return element { node-name($element)}
                  { for $attrName at $seq in $attrNames
                    return if ($element/@*[node-name(.) = $attrName])
                           then attribute {$attrName}
                                     {$attrValues[$seq]}
                           else (),
                    $element/@*[not(node-name(.) = $attrNames)],
                    $element/node() }
 } ;

let $uri := '/db/apps/srophe-data/data/works/tei'
let $collection := collection($uri)

for $work in $collection/TEI/text/body/bibl[bibl[matches(@xml:id,'bib[0-9]+\-[0-9]+[a-z]$')]]
    let $old-bibl-ids := $work//bibl/@xml:id
    let $ids-for-sorting := 
        for $id in $old-bibl-ids
        return replace($id,'\-([0-9][a-z]?$)','-0$1')
    let $sorted-ids :=
        for $id in $ids-for-sorting
        order by $id
        return replace($id,'\-0','-')
    let $old-bibls-sorted :=
        for $id in $sorted-ids
        return $work//bibl[@xml:id=$id]
    let $new-ids := 
        for $id at $pos in $sorted-ids
        return replace($id,'\-[0-9]+[a-z]?$',concat('-',$pos))
    let $new-bibls := 
        for $bibl at $pos in $old-bibls-sorted
        let $new-id := $new-ids[$pos]
        (: this is working correctly except that the @id attribute below needs to be @xml:id, but it's throwing an error when I try that. :)
        let $new-bibl := element bibl {attribute id {$new-id},$bibl/@*[not(name()='xml:id')], $bibl/node()}
        return $new-bibl
return $new-bibls