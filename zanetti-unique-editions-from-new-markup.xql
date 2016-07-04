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
let $uri := "/db/apps/srophe-data/data/bibl/Zanetti-and-Fiey-Abbreviations.xml"
let $abbreviations := doc($uri)/root
let $source-doc := doc("/db/apps/srophe-data/data/bibl/zanetti-edition-new-markup.xml")/TEI
let $new-doc := doc("/db/apps/srophe-data/data/bibl/zanetti-unique-editions-from-new-markup.xml")/TEI
(: Run on all works :)
let $work := $source-doc
(:let $work := collection('/db/apps/srophe-data/data/works/tei')//body/bibl:)
let $editions := 
    for $edition in $work/note[@type='editions' or @type='ancientVersion' or @type='modernTranslation']/bibl
    let $no-citedRange := functx:remove-elements($edition,'citedRange')
    let $no-notes := functx:remove-elements($no-citedRange, 'note')
    return functx:remove-attributes($no-notes,'xml:id')
(:    <bibl>{$edition/*[not(name(.)='citedRange')]}</bibl>:)


let $unique-editions := functx:distinct-deep($editions)
(:let $unique-editions-w-id := :)
(:    for $edition in $unique-editions:)
(:    let $normalized-title := replace(replace(normalize-space($edition/title/text()),'\s*[0-9]+$',''),'\([0-9]+\)\s*',''):)
(:    let $abbreviation-match := $abbreviations/row[Abbreviated_Title/text()=$normalized-title]:)
(:    return:)
(:        if ($abbreviation-match) then:)
(:            element bibl {$edition/*, element idno {$abbreviation-match/Reference_Number/text()}}:)
(:        else $edition:)
        
return 
(:    $unique-editions-w-id:)
    update insert $unique-editions into $new-doc