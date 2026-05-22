xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace output = 'http://www.w3.org/2010/xslt-xquery-serialization';

declare option output:omit-xml-declaration 'no';
declare option output:indent 'yes';

declare variable $path-to-repo := "/home/arren/Documents/GitHub/syriaca-data/";
declare variable $works := collection($path-to-repo||"data/works/tei/nhsl/tei/");

declare variable $bibl-groupings := map {
  "editions": {
    "biblTypes": ("lawd:Edition", "syriaca:Apparatus", "syriaca:OriginalWithSyriacEvidence"),
    "label": "Editions",
    "desc": "This is not a comprehensive list of editions related to this work. Further citations maybe available through Syriac.Nexus."
  },
  "manuscripts": {
    "biblTypes": ("syriaca:Manuscript", "lawd:WrittenWork"),
    "label": "Manuscripts",
    "desc": "This is not a comprehensive list of manuscripts related to this work. Further citations maybe available through Syriac.Nexus."
  },
  "translations": {
    "biblTypes": ("syriaca:ModernTranslation", "lawd:Translation"),
    "label": "Modern Translations",
    "desc": "This is not a comprehensive list of modern translations related to this work. Further citations maybe available through Syriac.Nexus."
  },
"versions": {
    "biblTypes": ("syriaca:AncientVersion"),
    "label": "Ancient Versions",
    "desc": "This is not a comprehensive list of ancient versions related to this work. Further citations maybe available through Syriac.Nexus."
  },
"secondary-literature": {
    "biblTypes": ("syriaca:DigitalCatalogue", "syriaca:PrintCatalogue", "lawd:Citation", "lawd:citation", "syriaca:Glossary", "syriaca:Literature", "syriaca:ReferenceWork"),
    "label": "Secondary Literature",
    "desc": "This is not a comprehensive list of secondary literature related to this work. Further citations maybe available through Syriac.Nexus."
  }
};

declare function local:reorder-work($work as node())
as node()
{
  element {$work/name()} {
    $work/@*,
    $work/title,
    $work/author,
    $work/editor,
    local:reorder-idnos($work/idno),
    $work/textLang,
    $work/date,
    $work/extent,
    local:group-all-notes($work/note),
    $work/listRelation,
    local:group-all-bibls($work/bibl)
  }
};

declare function local:reorder-idnos($idnos as node()+)
as node()+ {
  let $uris := $idnos[@type="URI"]
  let $nonUris := $idnos[@type!="URI"]
  
  return (
    $uris[starts-with(normalize-space(./text()), "http://syriaca.org/work/")],
    $uris[not(starts-with(normalize-space(./text()), "http://syriaca.org/work/"))],
    $nonUris
  )
};


declare function local:group-all-notes($notes as node()*)
as node()* {
  (
    (: Description Notes :)
    local:group-notes($notes[@type="abstract"], "abstract", "Abstract"),
    local:group-notes($notes[@type="scope"], "scope", "Scope"),
    local:group-notes($notes[@type="versions"], "versions", "Ancient Versions"),
    local:group-notes($notes[@type="content" or @type="content-description"], "content", "Contents"),
    local:group-notes($notes[@type="disambiguation"], "disambiguation", "Disambiguation"),
    (: Excerpt Notes :)
    local:group-notes($notes[@type="prologue"], "prologue", "Prologue"),
    local:group-notes($notes[@type="incipit"], "incipit", "Incipit"),
    local:group-notes($notes[@type="excerpt"], "excerpt", "Excerpt"),
    local:group-notes($notes[@type="explicit"], "explicit", "Explicit")
  )
};

(: Generic function for creating noteGrps based on passed contexts :)
(: @param $notes should be pre-filtered to notes of the given type, see group-all-notes above :)
declare function local:group-notes($notes as node()*, $type as xs:string, $label as xs:string)
as node()* {
  let $noteGrp := 
    element {"noteGrp"} {
      attribute {"type"} {$type},
      element {"desc"} {
        attribute {"xml:lang"} {"en"},
        $label
      },
      $notes
    }
  return $noteGrp[note] (: return only if there are any notes of that type :)
};

declare function local:group-all-bibls($bibls as node()*)
as node()* {
  for $type in ("editions", "manuscripts", "translations", "versions", "secondary-literature")
  let $filteredBibls := $bibls[functx:is-value-in-sequence(./@type/string(), $bibl-groupings?$type?biblTypes)]
  return local:group-bibls-into-listBibls($filteredBibls, $type, $bibl-groupings?$type?label, $bibl-groupings?$type?desc)
};

(: Generic function for creating listBibls based on passed contexts :)
(: @param $bibls should be pre-filtered to bibl elements of the given type, see group-all-bibls above :)
declare function local:group-bibls-into-listBibls($bibls as node()*, $type as xs:string, $label as xs:string, $desc as xs:string)
as node()* {
  
  let $listBibl := 
    element {"listBibl"} {
      attribute {"type"} {$type},
      element {"head"} {$label},
      element {"desc"} {
        attribute {"xml:lang"} {"en"},
        $desc
      },
      $bibls
    }
  return $listBibl[bibl]
};

for $doc in $works
return local:reorder-work($doc//body/bibl)

