import module namespace config="http://wlpotter.github.io/ns/cm/config" at "config.xqm";
import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:empty-editor-respStmt :=
  element {"respStmt"} {
    element {"resp"} {"Testimonium edited by"},
    element {"name"} {
      attribute {"ref"} {}
    }
  };
  
declare variable $local:empty-context-desc := 
  element {"desc"} {
    attribute {"type"} {"context"}
  };

declare variable $local:empty-textual-note :=
  element {"note"} {
    attribute {"xml:lang"} {"en"},
    attribute {"type"} {"textual"}
  };
  
declare variable $local:empty-translation-note :=
element {"note"} {
  attribute {"xml:lang"} {"en"},
  attribute {"type"} {"translation"},
  "Trans. {Source}"
};

declare variable $local:empty-corrigenda-note :=
element {"note"} {
  attribute {"xml:lang"} {"en"},
  attribute {"type"} {"corrigenda"}
};

declare variable $local:empty-discussion-note :=
  element {"note"} {
    attribute {"xml:lang"} {"en"},
    attribute {"type"} {"discussion"}
  };

declare variable $local:empty-translation :=
 element {"ab"} {
   attribute {"type"} {"translation"},
   $local:empty-translation-note,
   $local:empty-discussion-note,
   $local:empty-corrigenda-note,
   element {"idno"} {
     attribute {"type"} {"CTS-URN"}
   },
   element {"ref"} {attribute {"target"} {}}
 };
 
declare variable $local:empty-bibl :=
  element {"bibl"} {
    element {"ptr"} {attribute {"target"} {}},
    element {"citedRange"} {attribute {"unit"} {}},
    element {"citedRange"} {attribute {"unit"} {}}
  };

declare function local:process-notes($currentNotes as node()*, $editionOrTranslation as xs:string)
as node()
{
  let $textualNotes := $currentNotes[@type="textual"]
  let $textualNotes := if(count($textualNotes) < 2) then ($textualNotes, $local:empty-textual-note) else $textualNotes
  let $textualNotes := if(count($textualNotes) < 2) then ($textualNotes, $local:empty-textual-note) else $textualNotes
  
  let $translationNote := if($currentNotes[@type="translation"]) then $currentNotes[@type="translation"] else $local:empty-translation-note
  
  let $corrigendaNote := if($currentNotes[@type="corrigenda"]) then $currentNotes[@type="corrigenda"] else $local:empty-corrigenda-note
  let $discussionNote := if($currentNotes[@type="discussion"]) then $currentNotes[@type="discussion"] else $local:empty-discussion-note
  
  return 
  <listNote>
    {
      (
        if($editionOrTranslation = "edition") then $textualNotes
        else if($editionOrTranslation = "translation") then $translationNote
        else (),
        $discussionNote,
        $corrigendaNote
      )
    }
  </listNote>
};

declare function local:add-placeholder-notes-to-excerpt($excerpt as node())
as node()
{
  let $children :=
  for $ch in $excerpt/node()
  return if(name($ch) = "note") then local:process-notes($excerpt/note, $excerpt/@type/string())
  else $ch
let $notes := $children[name() = "listNote"]
let $children := $children[name() != "listNote"]

let $notes := if(count($notes) > 0) then $notes[1]/* else local:process-notes((), $excerpt/@type/string())/*

let $index := 
  if($excerpt/ab[@type="source"]) then 
    functx:index-of-node($children, $excerpt/ab[@type="source"])
  else
    functx:index-of-node($children, $excerpt/text()[last()])
return
  element {"ab"} {
    $excerpt/@*,
    for $ch at $i in $children
    return if($index = $i) then ($ch, $notes)
    else $ch
  }
};

for $doc in $config:input-collection
let $docUri := $doc//ab[@type="identifier"]/idno/text()
let $docId := substring-after($docUri, $config:testimonia-uri-base)
let $biblCount := count($doc//listBibl[2]/bibl)
let $additionalBiblsToAdd := 
  for $num in (1, 2, 3, 4, 5, 6, 7, 8)
  where $num > $biblCount
  return $local:empty-bibl
let $listBiblForAdditionalBibls :=
  element {"listBibl"} {
    element {"head"} {"Additional Bibliography"},
    $doc//listBibl[2]/bibl,
    $additionalBiblsToAdd
  }
return 
  (
   if($doc//titleStmt/respStmt/resp[text() = "Testimonium edited by"]) then 
     insert node $local:empty-editor-respStmt after $doc//titleStmt/respStmt[resp[text() = "Testimonium edited by"]][last()]
   else if($doc//titleStmt/respStmt/resp[text() = "TEI encoding by" or text() = "TEI record created by"]) then
     insert node $local:empty-editor-respStmt after $doc//titleStmt/respStmt[resp[text() = "TEI encoding by" or text() = "TEI record created by"]][last()]
   else
     insert node $local:empty-editor-respStmt after $doc//titleStmt/editor[last()],     
   if(not($doc//desc[@type="context"])) then 
     insert node $local:empty-context-desc after $doc//desc[@type="abstract"] 
   else (),
   replace node $doc//ab[@type="edition"] with local:add-placeholder-notes-to-excerpt($doc//ab[@type="edition"]),
   if($doc//ab[@type="translation"]) then 
     replace node $doc//ab[@type="translation"] with local:add-placeholder-notes-to-excerpt($doc//ab[@type="translation"])
   else insert node $local:empty-translation after $doc//ab[@type="edition"],
   if($doc//listBibl[1]/bibl[2]) then ()
   else
     insert node $local:empty-bibl as last into $doc//listBibl[1],
   if($doc//listBibl[2]) then
     replace node $doc//listBibl[2] with $listBiblForAdditionalBibls
   else
     insert node $listBiblForAdditionalBibls after $doc//listBibl[1]
 )