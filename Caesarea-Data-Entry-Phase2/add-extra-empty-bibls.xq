xquery version "3.0";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";
(: Script to add extra empty bibls to ensure there are four extra "Additional Bibliography" slots for C-M testimonia :)

let $inputDirectoryUri := "C:\Users\anoni\Documents\GitHub\srophe\caesarea-data\data"
for $doc in fn:collection($inputDirectoryUri)
  let $newBibls := for $i in (1, 2, 3, 4, 5, 6, 7, 8)
    return if ($i > fn:count($doc//listBibl[2]/bibl)) then <bibl><ptr target=""/><citedRange unit=""/><citedRange unit=""/></bibl>
    else $doc//listBibl[2]/bibl[$i]
  let $newListBibl := <listBibl>{$doc//listBibl[2]/head, $newBibls}</listBibl>
  return replace node $doc//listBibl[2] with $newListBibl