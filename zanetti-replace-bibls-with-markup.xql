xquery version "3.0";
(: 
 : Add/replace new bibl elements with ptr elements to newly created bibl TEI records 
 : Save changes to db, must be logged into eXist as admin/with admin privileges
 : :)

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace syriaca = "http://syriaca.org";
declare namespace functx = "http://www.functx.com";

(: Find matching biblStruct. Match bibl id against @corresp list. Match ids with optional 'a' or 'b' at the end as well :)
declare function syriaca:create-new-bibl($id, $node) {
    for $bibl in $node//tei:biblStruct[matches(@corresp, concat('(^|\W)',$id,'[a-z]?(\W|$)'))]
    let $bibl-id := analyze-string($bibl/@corresp, concat('(^|\W)',$id,'[a-z]?(\W|$)'))/fn:match/text()
    let $new-bibl := 
            <bibl xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$bibl-id}">
                {(  
                    $bibl/descendant::tei:title,
                    <ptr target="{$bibl//tei:idno[contains(.,'syriaca')]/text()}"/>,
                    functx:remove-attributes($bibl/tei:citedRange[@corresp = $bibl-id],'corresp')
                )}
            </bibl>
    return $new-bibl
};

declare function syriaca:extract-entity-id($xml-id-of-node) {
    replace(
        replace($xml-id-of-node, "^[a-z#]+",""),
        "\-[0-9a-z]+$",
        ""
    )
};

declare function functx:distinct-deep
  ( $nodes as node()* )  as node()* {

    for $seq in (1 to count($nodes))
    return $nodes[$seq][not(functx:is-node-in-sequence-deep-equal(
                          .,$nodes[position() < $seq]))]
 } ;
 
 declare function functx:is-node-in-sequence-deep-equal
  ( $node as node()? ,
    $seq as node()* )  as xs:boolean {

   some $nodeInSeq in $seq satisfies deep-equal($nodeInSeq,$node)
 } ;

declare function functx:remove-attributes
  ( $elements as element()* ,
    $names as xs:string* )  as element()* {

   for $element in $elements
   return element
     {node-name($element)}
     {$element/@*[not(functx:name-test(name(),$names))],
      $element/node() }
 } ;
 
 declare function functx:name-test
  ( $testname as xs:string? ,
    $names as xs:string* )  as xs:boolean {

$testname = $names
or
$names = '*'
or
functx:substring-after-if-contains($testname,':') =
   (for $name in $names
   return substring-after($name,'*:'))
or
substring-before($testname,':') =
   (for $name in $names[contains(.,':*')]
   return substring-before($name,':*'))
 } ;
 
 declare function functx:substring-after-if-contains
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string? {

   if (contains($arg,$delim))
   then substring-after($arg,$delim)
   else $arg
 } ;
 declare function functx:remove-elements
  ( $elements as element()* ,
    $names as xs:string* )  as element()* {

   for $element in $elements
   return element
     {node-name($element)}
     {$element/@*,
      $element/node()[not(functx:name-test(name(),$names))] }
 } ;

(: Copy of latest xml data to be converted. This is my local path :)
let $source-doc := doc("/db/apps/srophe-data/data/bibl/zanetti-edition-new-markup.xml")/TEI
for $new-bibl in $source-doc/note/bibl
    let $bibl-id := $new-bibl/@xml:id
    let $work-id := syriaca:extract-entity-id($bibl-id)
    let $work-doc := doc(concat("/db/apps/srophe-data/data/works/tei/",$work-id,".xml"))/TEI
    let $target-bibl := $work-doc//bibl[@xml:id=$bibl-id]
    return 
        update replace $target-bibl with $new-bibl
