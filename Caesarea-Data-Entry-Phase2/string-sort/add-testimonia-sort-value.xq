xquery version "3.1";

import module namespace functx="http://www.functx.com";
import module namespace config="http://wlpotter.github.io/ns/cm/config" at "../config.xqm";
import module namespace sort="http://wlpotter.github.io/ns/sort" at "/home/arren/Documents/GitHub/xquery-utility-modules/sort.xqm";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:numeric-separator := ".";
declare variable $local:string-order-sequence :=
let $alpha := ("a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z")
let $layerOne := for $l in $alpha return "z"||$l
let $layerTwo := for $l in $alpha return "zz"||$l
return ($alpha, $layerOne, $layerTwo);

(: This is a specialization of sort:merge-sort, which uses a merging function that use
the sort:numeric-compare-deep function to make the ordering comparison :)
declare function local:merge-sort-numeric-deep($toSort as item()+, $length as xs:integer)
as item()+
{
  if ($length = 1) then
    $toSort
  else
    let $mid := xs:integer($length div 2)
    let $left := $toSort[position() = (1 to $mid)]
    let $right := $toSort[position() = (($mid + 1) to $length)]
    
    let $left := local:merge-sort-numeric-deep($left, count($left))
    let $right := local:merge-sort-numeric-deep($right, count($right))
    return local:merge-numeric-deep($left, $right, ())
};

declare function local:merge-numeric-deep($left as item()*, $right as item()*, $ordered as item()*)
as item()+
{
  (: base case, no items left to merge :)
  if(empty($left) and empty($right)) then
    $ordered
  (: if one of the two arrays is empty, add the remaining items from the non-empty
     array as these will all be greater than what's in ordered :)
  else if(empty($left)) then
    ($ordered, $right)
  else if (empty($right)) then
    ($ordered, $left)
  (: otherwise, compare the first element of the left and right arrays
     'pop' the lower one and append it to the ordered array :)
  else
    if(sort:numeric-le-deep($left[1], $right[1], $local:numeric-separator)) then
      let $ordered := ($ordered, $left[1])
      let $left := subsequence($left, 2, count($left))
      return local:merge-numeric-deep($left, $right, $ordered)
    else
      let $ordered := ($ordered, $right[1])
      let $right := subsequence($right, 2, count($right))
      return local:merge-numeric-deep($left, $right, $ordered)
};
(: Group ref elements by work :)
let $authorWorkIndex :=
  for $doc in $config:input-collection
  let $author := string-join($doc//profileDesc/creation/persName[@role="author"]/text(), "; ")
  let $author := normalize-space($author)
  let $work := normalize-space(string-join($doc//profileDesc/creation/title//text(), " "))
  return $author||". "||$work
let $authorWorkIndex := distinct-values($authorWorkIndex)

let $perWorkRefs := 
  for $aw in $authorWorkIndex
    let $ranges :=
      for $doc in $config:input-collection
      let $author := string-join($doc//profileDesc/creation/persName[@role="author"]/text(), "; ")
      let $author := normalize-space($author)
      let $work := normalize-space(string-join($doc//profileDesc/creation/title//text(), " "))
      return if($aw = $author||". "||$work) then $doc//profileDesc/creation/ref else()
  return element {"work"} {attribute {"id"} {$aw}, $ranges}

(: For each work, sort the values :)
let $sortedPerWorkRefs :=
  for $work in $perWorkRefs
  return try {
    element {"work"} {$work/@*, local:merge-sort-numeric-deep($work/*, count($work/*))}
  }
  catch * {
        let $failure :=
        element {"failure"} {
          element {"code"} {$err:code},
          element {"description"} {$err:description},
          element {"value"} {$err:value},
          element {"module"} {$err:module},
          element {"location"} {$err:line-number||": "||$err:column-number},
          element {"additional"} {$err:additional},
          $work
        }
        return $failure
  }
let $orderedPerWorkRefs :=
  for $work in $sortedPerWorkRefs
  return
  if(name($work) = "failure") then $work
  else 
    element {"work"} {$work/@*,
    for $ref at $i in $work/*
    return functx:add-attributes($ref, QName("", "n"), $local:string-order-sequence[$i])
  }
for $work in $orderedPerWorkRefs
return if(name($work) = "failure") then update:output($work)
else
  for $ref in $work/*
  for $doc in $config:input-collection
  where $doc//profileDesc/creation/ref/@target = $ref/@target
  return replace node $doc//profileDesc/creation/ref with $ref
  (: return $local:string-order-sequence :)