xquery version "3.0";
import module namespace functx = "http://www.functx.com";

declare function local:remove-blockquote($el)
 {
   for $sub in $el/*
     return $sub
 };
 
for $doc in db:open("WrightHtml")
  let $paragraphs := for $p in $doc//*:body/*
      return if(name($p) = "p") then $p else if (name($p) = "blockquote") then local:remove-blockquote($p) else <p>{$p}</p>
  (: return $paragraphs :)
  let $indexes := for $p in $paragraphs
    return if(fn:matches(fn:string-join($p/text(), "\n"), "^\[.+? (\d+)[,]?(\d+)[\.|,]\s*(.+\.)?\s*(\d+-?\d*)?")) then functx:index-of-node($paragraphs, $p) else()
  for $index at $i in $indexes
    let $match := functx:get-matches(fn:string-join($paragraphs[position() = $index]/text(), "\n"), "^\[\S+? (\d+)[,]?(\d+)[\.|,]\s*(.+\.)?\s*(\d+-?\d*)?")[1]
    let $divId := fn:replace(fn:replace(fn:substring-after($match, "["), " ", ""), ",", "-")
    let $lowerBound := $indexes[$i - 1] + 1 
    return if ($i = 1) then 
    <div xml:id="{$divId}">
      {
        $paragraphs[position() <= $index]
      }
      </div>
    else if ($i = fn:count($indexes)) then
      (<div xml:id="{$divId}">
      {
        $paragraphs[position() <= $index and position() >= $lowerBound]
      }
      </div>,
      if (not(empty($paragraphs[position() > $index]))) then
       <div xml:id="endMatter-{$index}">
       {$paragraphs[position() > $index]}
      </div>)
    else
    <div xml:id="{$divId}">
    {
      $paragraphs[position() <= $index and position() >= $lowerBound]
    }</div>