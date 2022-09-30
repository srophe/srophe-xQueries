xquery version "3.0";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";
(: Script to add extra empty bibls to ensure there are four extra "Additional Bibliography" slots for C-M testimonia :)

let $inputDirectoryUri := "/home/arren/Documents/GitHub/caesarea-data/data/testimonia/tei/"
for $doc in fn:collection($inputDirectoryUri)
  let $newBibls := for $i in (1, 2, 3, 4, 5, 6, 7, 8)
    return if ($i > fn:count($doc//body//listBibl[2]/bibl)) then <bibl><ptr target=""/><citedRange unit=""/><citedRange unit=""/></bibl>
    else $doc//listBibl[2]/bibl[$i]
  let $newListBibl := <listBibl><head>Additional Bibliography</head>{$newBibls}</listBibl>
  return if($doc//body//listBibl[2]) then replace node $doc//body//listBibl[2] with $newListBibl
  else insert node $newListBibl after $doc//body//listBibl[1]