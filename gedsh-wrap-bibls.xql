xquery version "3.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
(: Run first :)
declare function local:build-listBibl($l, $nl, $s){
    <listBibl xmlns="http://www.tei-c.org/ns/1.0">
        {
            (
                <head>{$l/node()}</head>,
                    if($l[@type='subsection'] and $nl[@type='subsubsection']) then 
                        for $sl in $l/following-sibling::tei:label[@type='subsubsection']
                        [preceding-sibling::tei:label[@type='subsection'][1][normalize-space(string-join(text(),' ')) = normalize-space(string-join($l/text(),' '))]]
                        let $nsl := $sl/following-sibling::tei:label[1]
                        return local:build-listBibl($sl, $nsl, $s)
                    else if($l[not(following-sibling::tei:label)]) then 
                        for $b in $s/child::*[preceding-sibling::tei:p[not(following-sibling::tei:p[1])]]
                            [following-sibling::tei:byline]
                            [preceding-sibling::tei:label[normalize-space(string-join(text(),' ')) = normalize-space(string-join($l/text(),' '))]]
                        return $b 
                    else 
                        for $b in $s/child::*[preceding-sibling::tei:p[not(following-sibling::tei:p[1])]]
                            [following-sibling::tei:byline]
                            [preceding-sibling::tei:label[normalize-space(string-join(text(),' ')) = normalize-space(string-join($l/text(),' '))]]
                            [following-sibling::tei:label[normalize-space(string-join(text(),' ')) = normalize-space(string-join($nl/text(),' '))]]
                        return $b 
            )
        }
    </listBibl>
};

for $s in collection('/db/apps/e-gedesh-data')//tei:div[@type ="entry"]
let $listBibl := 
            if($s/tei:bibl) then
                if(count($s/tei:label[@type='subsection'][not(following-sibling::tei:p)]) gt 1) then 
                    <listBibl xmlns="http://www.tei-c.org/ns/1.0">
                    {
                        for $l in $s/tei:label[@type='subsection'][not(following-sibling::tei:p)]
                        let $nl := $l/following-sibling::tei:label[1]
                        return 
                            local:build-listBibl($l, $nl, $s)
                    }
                    </listBibl>
                else if(count($s/tei:label[@type='subsection'][not(following-sibling::tei:p)]) eq 1) then
                    for $l in $s/tei:label[@type='subsection'][not(following-sibling::tei:p)]
                    let $nl := $l/following-sibling::tei:label[1]
                    return 
                        local:build-listBibl($l, $nl, $s)
                else 
                    <listBibl xmlns="http://www.tei-c.org/ns/1.0">
                    {
                        for $b in $s/child::*[preceding-sibling::tei:p[not(following-sibling::tei:p[1])]][following-sibling::tei:byline]
                        return $b
                    }
                   </listBibl>
            else ()   
return 
    if(empty($listBibl)) then ()
    else 
    (
        update insert $listBibl preceding $s/tei:byline,
        update delete $s/child::*[preceding-sibling::tei:p[not(following-sibling::tei:p[1])]][following-sibling::tei:byline][not(self::tei:listBibl)]
    )
