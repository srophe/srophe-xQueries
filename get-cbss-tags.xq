xquery version "3.1";

import module namespace functx="http://www.functx.com";


declare variable $directory-of-json := "/home/arren/Downloads/data";

(: get tag keyword strings from the Zotero JSON data :)
let $tags :=
  for $file in file:children($directory-of-json)
  let $json := file:read-text($file) => json:parse()
  return $json/json/_/data/tags/_/tag/text()

(: filter distinct values :)
let $distinctTags := distinct-values($tags)


(: ensure whitespace cleanup didn't result in additional duplicates :)
(: include hit count :)
for $dt in $distinctTags
let $hits := for $t in $tags where $t = $dt return $t
order by count($hits) descending
return normalize-space($dt)||","||count($hits)