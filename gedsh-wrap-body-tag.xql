xquery version "3.0";
declare namespace tei="http://www.tei-c.org/ns/1.0";

(: Run second :)
for $s in collection('/db/apps/e-gedesh-data')//tei:div[@type ="entry"]
let $body := 
        <div type="body" xmlns="http://www.tei-c.org/ns/1.0">
            {
                for $p in $s/child::*[following-sibling::tei:listBibl][preceding-sibling::tei:head][not(self::tei:ab)]
                return $p
            }  
        </div>    
return 
    if(empty($body)) then ()
    else 
    (
        update insert $body preceding $s/tei:listBibl,
        update delete $s/child::*[following-sibling::tei:listBibl][preceding-sibling::tei:head][not(self::tei:ab)][not(self::tei:div)]
    )
