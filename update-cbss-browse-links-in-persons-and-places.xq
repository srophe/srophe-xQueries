

(:
: Given an input CSV and a directory of TEI files,
: inserts editor, respStmt, and/or change log messages
: for work done based on the file name and editor info
: supplied in the CSV
:
:
:)
(:
BASEX OPTIONS (pre v.10, whitespace handling has since changed):
- set writeback true
- set chop off
- set exporter omit-xml-declaration=no

:)
import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare option output:omit-xml-declaration "no";


declare variable $path-to-repo := "/home/arren/Documents/GitHub/syriaca-data";

declare variable $collections := 
  map {
    "persons": collection($path-to-repo||"/data/persons/tei/"),
    "places": collection($path-to-repo||"/data/places/tei/")
  };

declare variable $xpaths := 
  map {
    "persons": map {
      "idnos": "TEI/text/body/listPerson/person/idno",
      "bibls": "TEI/text/body/listPerson/person/bibl"
    },
    "places": map {
      "idnos": "TEI/text/body/listPlace/place/idno",
      "bibls": "TEI/text/body/listPlace/place/bibl"
    }
  };
  
declare variable $cbss-zotero-tag-uri-base := "https://www.zotero.org/groups/4861694/tags/";
declare variable $cbss-zotero-tag-uri-postfix := "/library";

declare variable $cbss-syriaca-browse-facet-url-base := "https://dev.syriaca.org/cbss/search.html?facet-cbssKeywords=";

declare function local:update-cbsc-idno($idnos as element()+, $uriPrefix as xs:string?, $uriPostfix as xs:string?) 
as element() + {
  for $id in $idnos
  let $newUri := local:update-cbsc-uri($id/text(), $uriPrefix, $uriPostfix) 
  return element {node-name($id)} {$id/@*, $newUri}
};

declare function local:update-cbsc-bibl($bibls as element()+, $uriPrefix as xs:string?, $uriPostfix as xs:string?) 
as element() + {
  for $bib in $bibls
  return element {node-name($bib)} {
    $bib/@*,
    $bib/title,
    $bib/ptr,
    for $cRange in $bib/citedRange
    return 
    if($cRange[@unit="entry"]) then
      let $newUri := local:update-cbsc-uri($cRange/@target/string(), $uriPrefix, $uriPostfix)
      return
        element {node-name($cRange)} {
          $cRange/@unit,
          attribute {"target"} {$newUri},
          $cRange/text()
    }
    else $cRange
  }
};

(:
Format of an old URI: http://www.csc.org.il/db/browse.aspx?db=SB&amp;sL=T&amp;sK=Theodore bar Zarudi&amp;sT=keywords
Extracts the keyword (beetween '&amp;sK=' and the following '&amp;')
Adds the prefix and postfix for the new uri
:)
declare function local:update-cbsc-uri($oldUri as xs:string?, $newUriPrefix as xs:string?, $newUriPostfix as xs:string?)
as xs:string
{
  if($oldUri = "") then ()
  else
    let $newUri := $oldUri
      => normalize-space()
      => substring-after("&amp;sK=")
      => substring-before("&amp;")
    return $newUriPrefix||$newUri||$newUriPostfix
};


(:~ ~~~~~~~~~~~~~~~~ ~:)

(: OPTION TO RUN ON PERSONS OR PLACES 
Value must be either the string "persons" or "places"
:)
let $personOrPlace := "persons"

for $doc in $collections($personOrPlace)
where contains($doc, "csc.org")
(: let $idnos := functx:dynamic-path($doc, $xpaths($personOrPlace)("idnos"))
let $oldCbscIdnos := $idnos[contains(text(), "csc.org")]

let $newCbssZoteroTagIdnos := local:update-cbsc-idno($oldCbscIdnos, $cbss-zotero-tag-uri-base, $cbss-zotero-tag-uri-postfix)
let $newCbssFacetedBrowseIdnos := local:update-cbsc-idno($oldCbscIdnos, $cbss-syriaca-browse-facet-url-base, ())

let $bibls := functx:dynamic-path($doc, $xpaths($personOrPlace)("bibls"))
let $oldCbscBibls := $bibls[ptr[@target="http://syriaca.org/bibl/5"]]

let $newCbssZoteroTagBibls := local:update-cbsc-bibl($oldCbscBibls, $cbss-zotero-tag-uri-base, $cbss-zotero-tag-uri-postfix)
let $newCbssFacetedBrowseBibls := local:update-cbsc-bibl($oldCbscBibls, $cbss-syriaca-browse-facet-url-base, ()) :)


return (
  for $idno in functx:dynamic-path($doc, $xpaths($personOrPlace)("idnos"))[contains(text(), "csc.org")]
  return replace node $idno with local:update-cbsc-idno($idno, $cbss-zotero-tag-uri-base, $cbss-zotero-tag-uri-postfix),
  for $bibl in functx:dynamic-path($doc, $xpaths($personOrPlace)("bibls"))[ptr[@target="http://syriaca.org/bibl/5"]]
  return replace node $bibl with local:update-cbsc-bibl($bibl, $cbss-zotero-tag-uri-base, $cbss-zotero-tag-uri-postfix)
)
        
