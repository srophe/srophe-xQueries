xquery version "3.0";

(:Trying to fix duplicate subject tags.:)

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace syriaca = "http://syriaca.org";
declare namespace functx = "http://www.functx.com";

declare function functx:is-node-in-sequence-deep-equal
  ( $node as node()? ,
    $seq as node()* )  as xs:boolean {

   some $nodeInSeq in $seq satisfies deep-equal($nodeInSeq,$node)
 } ;
 
declare function functx:distinct-deep
  ( $nodes as node()* )  as node()* {

    for $seq in (1 to count($nodes))
    return $nodes[$seq][not(functx:is-node-in-sequence-deep-equal(
                          .,$nodes[position() < $seq]))]
 } ;

let $bibls := collection("/db/apps/srophe-data/data/bibl/tei/")/TEI/text/body/biblStruct

for $bibl in $bibls[note[@type='tag' and matches(.,'^\s*Subject:\s*')]]
    let $subject-old := $bibl/note[@type='tag' and matches(.,'^\s*Subject:\s*')]
    let $subject-new := 
        functx:distinct-deep($bibl/note[@type='tag' and matches(.,'^\s*Subject:\s*')])
    let $has-duplicate-subjects := count($subject-old) > count($subject-new)
    
    return 
        if($has-duplicate-subjects) then 
            $bibl/*[1]/idno[matches(.,'syriaca')]
(:        (update delete $subject-old,:)
(:        update insert $subject-new into $bibl):)
        else ()