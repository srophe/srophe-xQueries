xquery version "3.1";
import module namespace functx="http://www.functx.com";


declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace srophe = "https://srophe.app";

declare variable $path-to-articles := "/home/arren/Documents/GitHub/e-gedsh/data/tei/articles/tei/";
declare variable $articles := collection($path-to-articles);

declare variable $path-to-stylesheet := "/home/arren/Documents/GitHub/srophe-xQueries/gedsh-oai/gedsh-oai-dcunqualified.xsl";
declare variable $stylesheet := doc($path-to-stylesheet);



for $article in $articles
return xslt:transform($article, $stylesheet)
(:
TODO:
- handle I/O and save to a file for review
:)