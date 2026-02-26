xquery version "3.1";

(:
: Module Name: The Syriac Gazeteer Export to Linked Places JSON-LD Format
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 21 March 2017
: Module Overview: This library module contains functions for transforming TEI XML 
:                  files from The Syriac Gazeteer (http://syriaca.org/geo) to 
:                  the Linked Places JSON-LD format
:)

(:~
: This module provides functions for exporting Linked Place JSON-LD
: 
:
: @author William L. Potter
: @since February 26, 2026
: @version 1.0
:)
module namespace lpjson="http://syriaca.org/ns/lpjson";

import module namespace lpcore="http://syriaca.org/ns/lpcore" at "lpcore.xqm";

import module namespace functx="http://www.functx.com";


declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace srophe = "https://srophe.app";


declare variable $lpjson:context-uri := "https://raw.githubusercontent.com/LinkedPasts/linked-places/master/linkedplaces-context-v1.1.jsonld";

(: TODO: should this export a string and use json:serialize? :)
declare function lpjson:create-jsonld-from-collection($collection as node()+)
as xs:string {
  let $features := 
    for $doc in $collection
    return lpjson:create-feature-from-doc($doc)
  let $jsonld := {
    "type": "FeatureCollection",
    "@context": $lpjson:context-uri,
    "features": array:build($features)
  }
  return json:serialize($jsonld, map{"indent": "yes", "escape": "no"})
};

declare function lpjson:create-feature-from-doc($doc as node())
as map(*) {
  let $place := $doc/TEI/text/body/listPlace/place
  let $uri := $place/idno[@type="URI"][starts-with(./text(), $lpcore:base-uri)]/text()
  let $id := $uri
  
  let $placeType := $place/@type/string()
  let $crosswalkedTypes := lpcore:get-place-type-crosswalks($placeType, $place/@ana/string())
  
  (: WHEN TBD :)
  
  (: NAMES :)
  let $names := lpjson:get-name-variants-sourced($place) => array:build()
  
  (: GEOMETRY TBD :)
  
  (: LINKS TBD -- The URIs :)
  
  (: RELATIONS -- the relation elements :)
  
  (: DESCRIPTIONS -- abstract(s), with sources :)
  
  return {
    "@id": $id,
    "type": "Feature",
    "properties": {
      "title": lpcore:get-english-headword($place),
      "fclasses": array:build($crosswalkedTypes?fclasses
                                => tokenize(";"))
    },
    "when": {},
    "names": $names,
    "gemetry": {}
  }
};


declare function lpjson:get-name-variants-sourced($place as node())
as map(*)* {
  for $name in $place/placeName
  let $toponym := $name//text()
                    => string-join(" ")
                    => normalize-space()
  let $lang := lpcore:get-place-name-lang-code($name)
  
  let $citations := lpjson:get-citations-for-element($name, true()) => array:build()

  return map {
    "toponym": $toponym,
    "lang": $lang,
    "citations": $citations
  }
};

declare function lpjson:get-citations-for-element($element as node(),
                                                  $allowResp as xs:boolean)
as map(*)* {
  let $bibls := lpcore:get-bibl-sources($element)
  return 
    if($bibls) then
      for $bibl in $bibls
      return map {
        "@id": $bibl/ptr/@target/string()
      }
   else if($allowResp) then
     map {
       "@id": $element/@resp/string()
     }
  else ()
  (:
  TODO: add the Year and Label fields (maybe with a lookup to CBSS or something? There's no guidelines for these in LP...)
:)
};