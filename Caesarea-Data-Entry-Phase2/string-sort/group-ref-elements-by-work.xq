xquery version "3.1";
declare default element namespace "http://www.tei-c.org/ns/1.0";

let $authorWorkIndex :=
  for $doc in collection("/home/arren/Documents/GitHub/caesarea-data/data/testimonia/tei/")
  let $author := string-join($doc//profileDesc/creation/persName[@role="author"]/text(), "; ")
  let $author := normalize-space($author)
  let $work := normalize-space(string-join($doc//profileDesc/creation/title//text(), " "))
  return $author||". "||$work
let $authorWorkIndex := distinct-values($authorWorkIndex)

for $aw in $authorWorkIndex
  let $ranges :=
    for $doc in collection("/home/arren/Documents/GitHub/caesarea-data/data/testimonia/tei/")
    let $author := string-join($doc//profileDesc/creation/persName[@role="author"]/text(), "; ")
    let $author := normalize-space($author)
    let $work := normalize-space(string-join($doc//profileDesc/creation/title//text(), " "))
    return if($aw = $author||". "||$work) then $doc//profileDesc/creation/ref else()
return element {"work"} {attribute {"id"} {$aw}, $ranges}
  

(: return $authorWorkIndex :)

(: for $doc in collection("/home/arren/Documents/GitHub/caesarea-data/data/testimonia/tei/")
return $doc//profileDesc/creation/title[hi]/../../../.. :)