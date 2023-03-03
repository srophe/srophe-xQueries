(: Group ref elements by work :)
import module namespace functx="http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:input-collection := collection("/home/arren/Documents/GitHub/caesarea-data/data/testimonia/tei/");

declare variable $local:search-url-base := "https://caesarea-maritima.org/testimonia/search.html?";
declare variable $local:author-parameter-base := "author=";
declare variable $local:title-parameter-base := "title=";

declare function local:generate-author-title-search-url($author as xs:string?, $title as xs:string?)
as xs:string?
{
  if(string-length($author) = 0 and string-length($title) = 0) then ()
  else
    let $authorParam :=
      if(string-length($author) > 0) then $local:author-parameter-base||web:encode-url($author)
      else ()
    let $titleParam :=
      if(string-length($title) > 0) then $local:title-parameter-base||web:encode-url($title)
      else()
    let $parameters := ($titleParam, $authorParam)
    let $parameters := string-join($parameters, "&amp;")
    return $local:search-url-base||$parameters
    
};

let $authorWorkIndex :=
  for $doc in $local:input-collection
  let $author := string-join($doc//profileDesc/creation/persName[@role="author"]/text(), "; ")
  let $author := normalize-space($author)
  let $work := normalize-space(string-join($doc//profileDesc/creation/title//text(), " "))
  let $searchUrl := local:generate-author-title-search-url($author, $work)
  return 
    <rec>
      <author>{$author}</author>
      <work>{$work}</work>
      <searchUrl>{$searchUrl}</searchUrl>
    </rec>

let $distinctAuthorWorkIndex := functx:distinct-deep($authorWorkIndex)
return csv:serialize(<csv>{$distinctAuthorWorkIndex}</csv>, map {"header": "yes"})