xquery version "3.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";

let $uri := '/db/apps/srophe-data/data/works/tei'
let $collection := collection($uri)
let $new-doc := doc('/db/apps/srophe-data/data/works/title-list-for-translit.xml')

let $list :=
for $work in $collection/TEI/text/body/bibl[title[@xml:lang="syr" and contains(@syriaca-tags,'#syriaca-headword')]]
    return 
      <item>{concat($work/idno[@type='URI' and contains(.,'syriaca.org')],'***',$work/title[@xml:lang="syr" and contains(@syriaca-tags,'#syriaca-headword')])}</item>
return
    update value $new-doc/TEI with $list
    
