xquery version "3.0";


(: NAMESPACES:)
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace syriaca = "http://syriaca.org";
declare namespace functx = "http://www.functx.com";

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

let $works := collection('/db/apps/srophe-data/data/works/tei')/TEI/text/body/bibl


for $work in $works
    let $editions := $work/note[@type='editions']/bibl
    let $translations := $work/note[@type='modernTranslation']/bibl
    for $translation in $translations[not(idno) and not(ptr) and matches(title,'ibid')]
        let $translation-title := if ($translation/title) then replace($translation/title[1], '[\s\n\t]{2,}',' ') else ()
        let $translation-title-element := if ($translation-title) then element title {$translation/title[1]/@*,$translation-title} else ()
        let $translator-surname := analyze-string($translation/(author|editor)[1]/text(),'(([A-Za-zÀ-ž\-]+?),)|([A-Za-zÀ-ž\-]+?$)')/fn:match/fn:group[@nr='2' or @nr='3']/text()
        let $matching-edition := 
(:            if ($translation-title and $editions[title[1]/text()=$translation-title and (author|editor)=$translation/(author|editor)]) then :)
(:                $editions[title[1]/text()=$translation-title and (author|editor)=$translation/(author|editor)]:)
(:            else if ($translator-surname and $editions[title[1]=$translation-title-element and matches((author|editor)[1],$translator-surname)]) then:)
(:                $editions[title[1]=$translation-title-element and matches((author|editor)[1],$translator-surname)]:)
            if ($editions[(author|editor)=$translation/(author|editor) and (idno|ptr)]) then
                $editions[(author|editor)=$translation/(author|editor) and (idno|ptr)]
            else if ($translator-surname and $editions[matches((author|editor)[1],$translator-surname) and (idno|ptr)]) then
                $editions[matches((author|editor)[1],$translator-surname) and (idno|ptr)]
            else()
        let $elements-to-copy := 
            ($matching-edition[1]/ptr, 
            $matching-edition[1]/idno, 
            if ($translation/citedRange[@unit='vol']) then () else $matching-edition[1]/citedRange[@unit='vol'],
            if ($translation/citedRange[not(@unit='vol')]) then () else $matching-edition[1]/citedRange[not(@unit='vol')])
        let $translation-new := element bibl {
            $translation/@*, 
            $translation/node()[name()!='citedRange'],
            $elements-to-copy,
            $translation/citedRange}
    
return 
    if ($matching-edition) then 
        (update insert $translation-new following $translation,
        update delete $translation)
    else ()