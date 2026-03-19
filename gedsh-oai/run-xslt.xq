xquery version "3.1";
import module namespace functx="http://www.functx.com";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace srophe = "https://srophe.app";

declare variable $path-to-articles := "/home/arren/Documents/GitHub/e-gedsh/data/tei/articles/tei/";
declare variable $articles := collection($path-to-articles);

declare variable $path-to-stylesheet := "/home/arren/Documents/GitHub/srophe-xQueries/gedsh-oai/gedsh-oai-dcunqualified.xsl";
declare variable $stylesheet := doc($path-to-stylesheet);

(: OAI PMH Configuration Variables :)
declare variable $request-verb external := "ListRecords";

declare variable $metadata-format external := "oai_dc";

declare variable $request-base-url external := "https://gedsh.bethmardutho.org/oai";

<OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/" 
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/
    http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd">
    <responseDate>{current-dateTime()}</responseDate>
    <request verb="{$request-verb}"
             metadataPrefix="{$metadata-format}">{$request-base-url}</request>
    {
      element {$request-verb} {
        for $article in $articles
        return xslt:transform($article, $stylesheet)
      }
    }
</OAI-PMH>

(:
TODO:
- handle I/O and save to a file for review
:)