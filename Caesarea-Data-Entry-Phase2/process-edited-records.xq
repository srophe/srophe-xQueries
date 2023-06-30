xquery version "3.1";

(:
: Processing script that takes edited records, prepared using the
: process-records-for-editing.xq script. This script is its inverse,
: and removes empty elements, etc. to prepare the edited records for
: publication on Caesarea-Maritima.org
: 
: @author William L. Potter
: @version 0.1
:)

import module namespace functx="http://www.functx.com";
import module namespace cmproc="http://wlpotter.github.io/ns/cmproc" at "cmproc.xqm";
import module namespace config="http://wlpotter.github.io/ns/cm/config" at "config.xqm";


declare default element namespace "http://www.tei-c.org/ns/1.0";


declare variable $local:current-testimonia :=
  collection("/home/arren/Documents/GitHub/caesarea-data/data/testimonia/tei/");

declare variable $local:records-to-merge :=
  collection("/home/arren/Documents/caesarea_2023-06-23_EDITED");

declare variable $local:editor-id := "jrife";

declare variable $local:change-log-message := "CHANGED: Proofreading and general edits";

declare variable $local:change-log :=
element {"change"} {
  attribute {"who"} {$config:editor-uri-base||$local:editor-id},
  attribute {"when"} {current-date()},
  $local:change-log-message
};

declare function local:merge-related-subject-notes($mergeNotes as node()*, $targetNotes as node()*)
as node()*
{
  for $note in $mergeNotes
  let $combinedSubjects := ($note/p, $targetNotes[@type/string() = $note/@type/string()]/p)
  let $combinedSubjects := functx:distinct-deep($combinedSubjects)
  let $combinedSubjects :=
    for $subj in $combinedSubjects
    order by $subj
    return $subj
  return element {"note"} {
    $note/@type,
    $combinedSubjects
  }
};


for $mergeDoc in $local:records-to-merge

(: get and process the merge doc URI, handling if it's just the numeric ID in the publicationStmt/idno :)
let $mergeUri := $mergeDoc//publicationStmt/idno[@type="URI"]/text()
let $mergeUri := functx:substring-after-if-contains($mergeUri, $config:testimonia-uri-base)
let $mergeUri := functx:substring-before-if-contains($mergeUri, "/tei")
(: restor uri base :)
let $mergeUri := $config:testimonia-uri-base||$mergeUri

(: match the target document in the current testimonia :)
let $targetDoc := $local:current-testimonia[descendant::body/ab[@type="identifier"]/idno[./text() = $mergeUri]]
let $targetUri := $targetDoc//body/ab[@type="identifier"]/idno/text()


let $respStmtDataToMerge := cmproc:collate-record-resp-data($mergeDoc)

let $newLicenseText := $targetDoc//publicationStmt/availability/licence/p[1]/text()
let $licenseTextToMerge := functx:substring-before-match($newLicenseText, "this entry is copyright [\d+|DATE]")||"this entry is copyright "||substring-before(string(current-date()), "-")||functx:substring-after-match($newLicenseText,  "this entry is copyright [\d+|DATE]")
(: need to replace the name of the person in the "by the contributors (Joseph L. Rife, et al.)" section with the first creator editor? :)

let $editionToMerge := cmproc:create-edition($mergeDoc, $mergeUri)
let $translationToMerge := cmproc:create-translation($mergeDoc, $mergeUri)

let $mergedRelatedSubjectNotes := local:merge-related-subject-notes(cmproc:normalize-related-subjects-notes($mergeDoc), $targetDoc//body/note)


return 
  try {
    (
  replace node $targetDoc//titleStmt/title[@level="a"] with cmproc:create-record-title($mergeDoc), (: update record title from edited doc :)
  cmproc:update-respStmt-list($targetDoc, $respStmtDataToMerge, true ()),
  replace value of node $targetDoc//publicationStmt/availability/licence/p[1] with $licenseTextToMerge,
  replace value of node $targetDoc//publicationStmt/date with current-date(),
  for $child in $targetDoc//profileDesc/creation/*   (: replace each child element in the target doc with the edited verion from the merge doc :)
    return replace node $child with $mergeDoc//profileDesc/creation/*[name() = $child/name()],
  replace node $targetDoc//profileDesc/langUsage with cmproc:post-process-langUsage($mergeDoc//profileDesc/langUsage),
  replace node $targetDoc//profileDesc/textClass with $mergeDoc//profileDesc/textClass,
  replace value of node $targetDoc//revisionDesc/@status with "published",
  insert node $local:change-log as first into $targetDoc//revisionDesc,
  replace node $targetDoc//body/desc[@type="abstract"] with cmproc:create-abstract(
      $mergeDoc//profileDesc/creation,
      $mergeDoc//body/ab//placeName,
      $mergeDoc//profileDesc/textClass/catRef[@scheme = "#CM-Testimonia-Type"]/@target/string(),
      substring-after($mergeUri, $config:testimonia-uri-base)),
  if($targetDoc//body/desc[@type="context"]) then
    replace node $targetDoc//body/desc[@type="context"] with $mergeDoc//body/desc[@type="context"]
  else
    insert node $mergeDoc//body/desc[@type="context"] after $targetDoc//body/desc[@type="abstract"],
  replace node $targetDoc//body/ab[@type="edition"] with $editionToMerge,
  replace node $targetDoc//body/ab[@type="translation"] with $translationToMerge,
  replace node $targetDoc//body/listBibl[head/text() = $config:works-cited-listBibl-label] with cmproc:post-process-bibls($mergeDoc//body/listBibl[head/text() = $config:works-cited-listBibl-label], substring-after($mergeUri, $config:testimonia-uri-base), true ()),
  (: either replace the additional bibl listBibl or insert the new one following the works cited listBibl :)
  if($targetDoc//body/listBibl[head/text() = $config:additional-bibls-listBibl-label]) then
    replace node $targetDoc//body/listBibl[head/text() = $config:additional-bibls-listBibl-label] with cmproc:post-process-bibls($mergeDoc//body/listBibl[head/text() = $config:additional-bibls-listBibl-label], substring-after($mergeUri, $config:testimonia-uri-base), false ())
  else
    insert node  cmproc:post-process-bibls($mergeDoc//body/listBibl[head/text() = $config:additional-bibls-listBibl-label], substring-after($mergeUri, $config:testimonia-uri-base), false ()) after $targetDoc//body/listBibl[head/text() = $config:works-cited-listBibl-label],
  delete node $targetDoc//body/note,
  insert node $mergedRelatedSubjectNotes as last into $targetDoc//body
)
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
        cmproc:get-record-context($mergeDoc, "Failure: file not written to disk")
      }
    return update:output($failure)
  }