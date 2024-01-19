declare variable $punctuation := ".,-();'""'':";

(:
Takes an element as input, returns all descendants with normalized whitespace
:)
declare function local:normalize-mixed-content-whitespace($element as node())
as node()+
{
  let $nodeCount := count($element/node())
  let $nodes :=
  for $node at $i in $element/node()
  return 
    if($node instance of element()) then
      local:normalize-mixed-content-whitespace($node)
    else if($node instance of text()) then
      (: first normalize space for the text node, getting rid of any leading and trailing space. :)
      let $normSpace := normalize-space($node)
      let $firstChar := substring($normSpace, 1)
      let $lastChar := substring($node, string-length($node))
      (: adds an extra space to the front and back of the text node unless the leading/trailing character(s) are punctuation or it is the first or last node in the sequence :)
      (:NOTE: this needs more work as doesn't handle this pattern <el>Text string. <child>more text</child></el> (it will collapse the space "string.") :)
      let $normSpace := if(contains($punctuation, $lastChar) or $i = $nodeCount) then $normSpace else $normSpace||" "
      let $normSpace := if(contains($punctuation, $firstChar) or $i = 1) then $normSpace else " "||$normSpace
      return $normSpace
    else ()
  return element {$element/name()} {$element/@*, $nodes}
};

let $el :=
<msItem xml:id="b2" n="3" defective="false">
                <locus from="3a" to="5">Fol. 3a-5</locus>
                <author/>
                <title ref="http://syriaca.org/work/270" type="supplied">The martyrdom of.<persName>Mīles</persName>, Abrūsīm, and Sīnī</title>
                <rubric xml:lang="syr">ܣܗܕܘܬܐ ܕܡܝܠܣ ܐܦܣܩܘܦܐ ܘܕܐܒܪܘܣܝܡ ܩܫܝܫܐ ܘܕܣܝܢܝ ܡܫܡܫܢܐ ܒܫܘܪܝܗ ܕܪܕܘܦܝܢ 
                  	<locus from="3a" to="3a"/>
                  </rubric>
                <note>See Assemani, Acta Martt., pars 1, p. 66.</note>
              </msItem>
return  local:normalize-mixed-content-whitespace($el)