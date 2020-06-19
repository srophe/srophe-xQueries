xquery version "3.1";

(: Merges content from rows with the same identifiers :)

let $uri := "C:\Users\anoni\Box\Syriac World Maps\Routledge Syriac World Places April 2020.csv"
let $csv := fetch:text($uri) => csv:parse(map{"header":fn:true()})
let $ids := fn:distinct-values($csv/csv/record/Syriaca_URI)
let $rows :=  fn:distinct-values($csv/csv/record/* ! fn:node-name(.))
return <list>{for $id in $ids
return
  element record {
    for $cell in $rows
    return element {$cell} {
      let $contents := $csv/csv/record[Syriaca_URI = $id]/*[fn:name(.) = fn:string($cell)]/text()
      return
        if (count($contents) ne count(fn:distinct-values($contents)))
        then <label>{$contents[1]}</label>
        else for $content in $contents return <label>{$content}</label>
      }
  }}</list>