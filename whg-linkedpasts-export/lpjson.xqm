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
  
  (: WHEN :)
  (: TODO: all recs require a date, what do we do with the ones that don't have one? :)
  let $existenceState := $place/state[@type="existence"][@from or @to] (: using only dated existence states :)
  let $dates := lpjson:get-when-from-state-sourced($existenceState) => array:build()
  
  (: NAMES :)
  let $names := lpjson:get-name-variants-sourced($place) => array:build()
  
  (: GEOMETRY :)
  let $locations := lpcore:get-gps-locations($place)
  let $geometry := lpjson:get-geometry-from-locations($locations)
  
  (: LINKS -- The URIs :)
  let $links := lpjson:get-links-from-idnos($place/idno[@type="URI"][not(@subtype="deprecated")])
                => array:build()
  
  (: RELATIONS -- the relation elements :)
  let $relationElements := $doc/TEI/text/body/listPlace/listRelation/relation
  let $relations := lpjson:get-relations-from-relation-elements($relationElements, $uri) => array:build()
  
  (: DESCRIPTIONS -- desc, with sources :)
  let $descriptions := lpjson:get-descriptions-from-desc-sourced($place/desc) => array:build()
  
  let $entry := map {
    "@id": $id,
    "type": "Feature",
    "properties": {
      "title": lpcore:get-english-headword($place),
      "fclasses": array:build($crosswalkedTypes?fclasses
                                => tokenize(";"))
    },
    "when": $dates,
    "names": $names,
    "geometry": $geometry,
    "links": $links,
    "relations": $relations,
    "descriptions": $descriptions
  }
  return $entry (: TODO: figure out how to drop null, map:filter and map:empty not wholly successful, but a combo might be :)
};


declare function lpjson:get-name-variants-sourced($place as node())
as map(*)* {
  for $name in $place/placeName
  let $toponym := $name//text()
                    => string-join(" ")
                    => normalize-space()
  let $lang := lpcore:get-place-name-lang-code($name)
  
  let $citations := lpjson:get-citations-for-element($name, true())
  
  (: Merge in temporal and citation data from the attestations of a given name form :)
  let $nameId := $name/@xml:id/string()
  let $attestations := $place/event[@type="attestation"][string-join(./link/@target/string()) => contains($nameId)]
  let $attestationCitations := 
    for $attest in $attestations 
    let $source := lpjson:get-citations-for-element($attest, true())
    where not(functx:is-value-in-sequence($source?"@id",$citations?"@id")) (: ignore any that are already in the citations list :)
    return $source
    
  let $citations := array:build(($citations, $attestationCitations))
  
  let $timespans := lpjson:get-timespans-from-attestations($attestations) => array:build()

  return map {
    "toponym": $toponym,
    "lang": $lang,
    "citations": $citations,
    "when": map {"timespans": $timespans}
  }
};

declare function lpjson:get-geometry-from-locations($locations as node()*)
as map(*)? {
  let $locCount := count($locations)
  return if($locCount = 0) then ()
  else if($locCount > 1) then map {
    "type": "GeometryCollection",
    "geometries": array:build(for $loc in $locations return lpjson:create-geometry-from-location-sourced($loc))
  }
  else lpjson:create-geometry-from-location-sourced($locations)
};

declare function lpjson:create-geometry-from-location-sourced($location as node())
as map(*) {
  let $coord := $location/geo/text() 
          => normalize-space()
          => tokenize(" ")
  let $lat := $coord[1]
  let $long := $coord[2]
  
  let $citations := lpjson:get-citations-for-element($location, true()) => array:build()

  return map {
    "type": "Point",
    "coordinates": [$long, $lat],
    "citations": $citations
  }
};

declare function lpjson:get-timespans-from-attestations($attestations as node()*)
as map(*)* {
  
  for $attest in $attestations
  let $start := if($attest/@when) then $attest/@when/string() else $attest/@notBefore/string()
  let $end := if($attest/@when) then $attest/@when/string() else $attest/@notAfter/string()
  (: TODO: use the precision matching to make a better timespan element? :)
  
  return map {
      "start": {"earliest": $start},
      "end": {"latest": $end}
    }
};

declare function lpjson:get-when-from-state-sourced($existenceStates as node()*)
as map(*)? {
  for $state in $existenceStates
  let $start := $state/@from/string()
  let $end := $state/@to/string()
  (: TODO: use the precision matching to make a better timespan element? :)
  
  let $timespans := array:build(
    map {
      "start": {"earliest": $start},
      "end": {"latest": $end}
    }
  )
  let $citations := lpjson:get-citations-for-element($state, true ()) => array:build()
  return map {
    "timespans": $timespans,
    "citations": $citations
  }
};

declare function lpjson:get-links-from-idnos($uris as node()+)
as map(*)* {
  let $uriList := for $uri in $uris return $uri//text() => string-join(" ") => normalize-space()
  
  for $uri in $uriList
  let $source := lpcore:get-entity-source-from-uri($uri)
  
  let $identifier := if($source?shortcode) then $source?shortcode||":"||substring-after($uri, $source?base) else $uri
  return if($source?base) then map {
    "type": $source?type,
    "identifier": $identifier
  }
  else ()
};

declare function lpjson:get-relations-from-relation-elements($relations as node()*,
                                                             $selfUri as xs:string)
as map(*)* {
  for $rel in $relations
  let $type := $rel/@ref/string()
  let $label := $rel/desc//text() => string-join(" ") => normalize-space()
  let $citations := lpjson:get-citations-for-element($rel, true ()) => array:build()
  
  let $relAttr := if($rel/@mutual) then $rel/@mutual else $rel/@passive
  (: create a links map for every case of space-separated place URIs :)
  for $related in tokenize($relAttr/string(), " ")
  where $related != $selfUri (: ignore the self, for mutual attributes :)
  return map {
    "relationType": $type,
    "relationTo": $related,
    "label": $label,
    "citations": $citations
  }
};

declare function lpjson:get-descriptions-from-desc-sourced($descs as node()*)
as map(*)* {
  for $desc in $descs
  let $value := $desc//text() => string-join(" ") => normalize-space()
  let $lang := $desc/@xml:lang/string()
  
  let $source := lpjson:get-source-for-desc($desc)
  
  return map {
    "value": $value,
    "lang": $lang,
    "source": $source
  }
};

(: Returns the resp, or the first bibl URI :)
declare function lpjson:get-source-for-desc($desc as node())
as xs:string? {
  (:
  TODO: descriptions have source rather than citations, so just using the first source bibl (from quote or desc) as a hack
  :)
  let $descBibls := lpcore:get-bibl-sources($desc)
  let $quoteBibls := if($desc/quote) then lpcore:get-bibl-sources($desc/quote) else ()
  let $bibls := ($quoteBibls, $descBibls) (: prioritize bibls that are for a direct quote :)
  
  return if(count($bibls) > 0) then $bibls[1]/ptr/@target/string() else $desc/@resp/string()
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
(:
TODO: ask how to give cited ranges?
:)
};