xquery version "3.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace syriaca = "http://syriaca.org";
declare namespace functx = "http://www.functx.com";

(: Compares the input string to a list of abbreviations and expands it, if found. :)
declare function syriaca:expand-abbreviations($abbreviation as xs:string?)
as element()*
{
    let $abb-uri :=
        "https://raw.githubusercontent.com/srophe/draft-data/master/data/works/Zanetti_XSL_Conversion/Zanetti-and-Fiey-Abbreviations.xml"
    let $abbreviations := fn:doc($abb-uri)
    return (: If there's a row with an abbreviation that matches the input string ... :)
<abbreviation>
        {
            if ($abbreviations//row[Abbreviated_Title = $abbreviation]) then
                let $row := $abbreviations//row[Abbreviated_Title = $abbreviation]
                return
                    ( (: grab the expanded version :) <expanded>{ $row/Expanded_Title/text() }</expanded>, (: and
                                                                                                            : provide
                                                                                                            : the zotero
                                                                                                            : id if
                                                                                                            : there is
                                                                                                            : one :)
                    if ($row/Reference_Number != '') then
<idno type="zotero">{ $row/Reference_Number/text() }</idno>
                    else
                        ()
                    )
            (: otherwise just return the input string :) else
     <expanded>{ $abbreviation }</expanded>
        }
</abbreviation>
};

declare function syriaca:nodes-from-regex($input-string as xs:string*, $pattern as xs:string, $element as xs:string,
                                          $regex-group as xs:integer, $expand-abbreviation as xs:boolean)
as element()*
{
    for $string in $input-string
    return
        for $part in analyze-string($string, $pattern)/node()
        let $correct-part-text := $part/fn:group[@nr = $regex-group]/text()
        let $abbreviation :=
            if ($expand-abbreviation) then
                syriaca:expand-abbreviations(syriaca:trim($correct-part-text))
            else
                ()
        return
<bibl>
            {
                if ($part instance of element(fn:match)) then
                    if ($correct-part-text) then
                        if (syriaca:trim($correct-part-text) != '') then
                            element { $element } {
                                if ($abbreviation) then
                                    $abbreviation/expanded/text()
                                else
                                    syriaca:trim($correct-part-text)
                            }
                        else
                            ()
                    else
                        ()
                else
     <p>{ $part/text() }</p>
            }
            {
                if ($abbreviation/idno) then
                    $abbreviation/idno
                else
                    ()
            }

</bibl>
};

declare function syriaca:trim($text-to-trim as xs:string*)
as xs:string*
{
    for $text in $text-to-trim
    return replace($text, ('^\s+|^[,]+|\s+$|[,]+$'), '')
};

declare function syriaca:add-lang($text-to-identify as element()*)
as element()*
{
    for $text in $text-to-identify
    let $lang :=
        if (matches($text, '([\s]|^)([Tt]he|[Aa]nd|[Aa]s|[Oo]f)[\s]')) then
            'en'
        else if (matches($text, '([\s]|^)([Dd](er|en|em|as|ie|esser)|[Uu]nd|[Ff]ür)[\s]|lich[a-z]{1,2}|isch[a-z]{1,2}'))
            then
            'de'
        else if (matches($text, "([\s]|^)(([Dd](’|u|')|[Ll]es|[Ll]e|[Ss]ur|[Uu]n[e]{1})[\s]|[Ll](’|'))|ique([\s]|$)"))
            then
            'fr'
        else if (matches($text, '(([\s]|^)[Ii]|ski[a-z]{1})[\s]')) then
            'ru'
        else if (matches($text, '([\s]|^)(e|[Dd]el|[Dd]i)[\s]')) then
            'it'
        else if (matches($text, '((([\s]|^)[Aa]l\-)|iyya)([\s]|$)')) then
            'ar'
        else
            ()
    return
        if ($lang != '') then
            functx:add-attributes($text, 'xml:lang', $lang)
        else
            $text
};

declare function syriaca:add-from-to-attributes($node-to-parse as element()*)
as element()*
{
    for $node in $node-to-parse
    return
        let $node-text := $node/text()
        let $range-test :=
            if (contains($node-text, '-')) then
                analyze-string($node-text, '^([\d]+)\-([\d,\s]+).*$')/node()
            else
                analyze-string($node-text, '^([\d]+)')/node()
        let $from := $range-test/fn:group[@nr = 1]
        let $to := if ($range-test/fn:group[@nr = 2]) then syriaca:trim($range-test/fn:group[@nr = 2]) else $from
        return functx:add-attributes($node, ('from', 'to'), ($from, $to))
};




(:declare function syriaca:remove-element :)
(:($context as element()*, $element-name as xs:string*, $iterate as xs:boolean*) as element()* {:)
(:    let $iterated-context :=:)
(:        if ($iterate=false()) then:)
(:            for $name in $element-name:)
(:            return:)
(:                syriaca:remove-element($context,$name,true()):)
(:        else ():)
(:    for $item in $iterated-context:)
(:            let $element-pos := :)
(:                for $child at $pos in $item/*:)
(:                return:)
(:                    if(name($child)=$element-name) then:)
(:                        $pos:)
(:                    else ():)
(:        return :)
(:            syriaca:remove-element-by-pos($item,$element-pos):)
(:};:)

declare function syriaca:remove-element-by-pos
($context as element()*, $pos-of-element as xs:integer*) as element()* {
if (count($pos-of-element)>0) then
for $parent-element in $context
(: the recursion messes up the numbering, since once an element is removed the other's are no longer in the same position :)
let $new-element := element {name($parent-element)} {$parent-element/@*, $parent-element/*[position()<$pos-of-element[1]],$parent-element/*[position()>$pos-of-element[1]]}
return syriaca:remove-element-by-pos($new-element,remove($pos-of-element,1))
else $context
};

declare function functx:add-attributes($elements as element()*, (: changed $attrNames from xs:QName* to xs:string* since
                                                                 : it was creating namespace problems I was having
                                                                 : trouble resolving :) $attrNames as xs:string*,
                                       $attrValues as xs:anyAtomicType*)
as element()?
{
    for $element in $elements
    return
        element { node-name($element) } {
            for $attrName at $seq in $attrNames
            return
                if ($element/@*[string(node-name(.)) = $attrName]) then
                    ()
                else
                    attribute { $attrName } { $attrValues[$seq] }
            ,
            $element/@*,
            $element/node()
        }
};

declare function functx:escape-for-regex($arg as xs:string?)
as xs:string
{
    replace($arg, '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))', '\\$1')
};

declare function functx:remove-elements($elements as element()*, $names as xs:string*)
as element()*
{
    for $element in $elements
    return
        element { node-name($element) } {
            $element/@*,
            $element/node()[not(functx:name-test(name(), $names))]
        }
};

declare function functx:name-test($testname as xs:string?, $names as xs:string*)
as xs:boolean
{
    $testname = $names or $names = '*' or functx:substring-after-if-contains($testname, ':') = (for $name in $names
    return substring-after($name, '*:')) or substring-before($testname, ':') = (for $name in $names[contains(., ':*')]
    return substring-before($name, ':*'))
};

declare function functx:substring-after-if-contains($arg as xs:string?, $delim as xs:string)
as xs:string?
{
    if (contains($arg, $delim)) then
        substring-after($arg, $delim)
    else
        $arg
};

declare function functx:index-of-node($nodes as node()*, $nodeToFind as node())
as xs:integer*
{
    for $seq in (1 to count($nodes))
    return $seq[$nodes[$seq] is $nodeToFind]
};

declare function functx:distinct-deep($nodes as node()*)
as node()*
{
    for $seq in (1 to count($nodes))
    return
        $nodes[$seq][not(functx:is-node-in-sequence-deep-equal(., $nodes[position() < $seq]))]
};

declare function functx:is-node-in-sequence-deep-equal($node as node()?, $seq as node()*)
as xs:boolean
{
    some $nodeInSeq in $seq satisfies deep-equal($nodeInSeq, $node)
};




let $uri := '/db/apps/srophe-data/data/ZanettiBiblConverted.xml'
let $biblStructs := doc($uri)//tei:biblStruct

let $add-idnos-to-remaining-monogr := 
(: :also need to include series where relevant :)
    let $biblStructs-missing-idnos := $biblStructs[monogr[empty(idno)]]
    for $biblStruct in $biblStructs-missing-idnos
    let $monogr := $biblStruct/monogr[empty(idno)]
    return
        if($monogr/title[@level='j']) then
            let $monogr-minus-biblScope := 
                for $this-monogr in $monogr
                    let $biblScope-pos := 
                        for $child at $pos in $this-monogr/*
                        return
                            if(name($child)='biblScope') then
                                $pos
                            else ()
                return 
                    syriaca:remove-element-by-pos($this-monogr,$biblScope-pos)
            for $this-monogr in $monogr-minus-biblScope
                    let $imprint-pos := 
                        for $child at $pos in $this-monogr/*
                        return
                            if(name($child)='imprint') then
                                $pos
                            else ()
                return 
                    syriaca:remove-element-by-pos($this-monogr,$imprint-pos)
        else
            for $this-monogr in $monogr
                let $biblScope-pos := 
                    for $child at $pos in $this-monogr/*
                    return
                        if(name($child)='biblScope' and $child/@unit="pp") then
                            $pos
                        else ()
            return 
                syriaca:remove-element-by-pos($this-monogr,$biblScope-pos)
    
(:    let $biblStructs-missing-idnos := :)
(:        let $biblStructs-minus-pgs :=:)
(:            for $monogr in $biblStructs/monogr[empty(idno)]:)
(:                let $biblScope-pos := :)
(:                    for $child at $pos in $monogr/*:)
(:                    return:)
(:                        if(name($child)='biblScope' and $child/@unit="pp") then:)
(:                            $pos:)
(:                        else ():)
(:            return :)
(:                syriaca:remove-element-by-pos($monogr,$biblScope-pos):)
(:        for $monogr in $biblStructs-minus-pgs:)
(:            let $imprint-pos := :)
(:                for $child at $pos in $monogr/*:)
(:                return:)
(:                    if(name($child)='imprint') then:)
(:                        $pos:)
(:                    else ():)
(:        return :)
(:            syriaca:remove-element-by-pos($monogr,$imprint-pos):)
(:    return $biblStructs-missing-idnos:)
    
    
    
 (:for $biblStruct-missing-idnos at $pos in:)
(:functx:distinct-deep(functx:remove-elements($biblStructs/monogr[empty(idno)], 'biblScope')):)
(:let $idno := <idno type="URI">{concat('http://syriaca.org/bibl/',1200 + $pos)}</idno>:)
(:let $title-pos := $biblStruct-missing-idnos//title/position():)
(:return <biblStruct><monogr>{$biblStruct-missing-idnos/*[position()<=$title-pos],$idno,$biblStruct-missing-idnos/*[position()>$title-pos]}:)
(:</monogr></biblStruct>:)
return $add-idnos-to-remaining-monogr