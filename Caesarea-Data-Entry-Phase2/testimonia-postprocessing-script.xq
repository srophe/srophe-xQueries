xquery version "3.0";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";

(: NOTE: I think we only want one script, so we should have instead a separate CSS that enables the student RA to input the data that we aren't having the editors input. I believe this will include the following:
- testimonia ID (numeric string portion of URI) --> put it in the ab[@type="identifier"]/idno/text() and post-process from there
- creation/title/@ref attribute with the work-level URN
- ab/idno for testimonia edition and translation that has the expression-level (e.g. the translation or ) URN referencing the citedRange and potentially having an xml:base value if applicable. This will be difficult once we get to ones where we need to mint new URNs
- ref/@target for an electronic version of the text if available.
- adding Zotero record URIs (after having added Zotero records and tagging them properly) for the bibls added by the editors
- (not sure how to do the respStmts and editor strings...)

:)
(:
To do:

- add editor[@role="creator"] and respStmts for person who created doc based on /TEI/teiHeader/revisionDesc/change/@who
- add publicationStmt/date and update change/@when attribute using the date
- add prose to profileDesc/creation that surrounds the sub-elements (to create a mixed content tei:creation element)
- correctly style origDate, add attributes, and @period attribute. Add error handling for this to flag if incorrect
- lookup table for language to add human-readable
- add abstract, compiled from creation elements
- bibls??
  - bibl IDs
  - refs to bibls in creation/ref/@target; and the two testimonia quotes
  - replace Zotero URIs with C-M.org ones
  - deal with note elements in bibls if we add those
- anchor elements in testimonia quotes
- idno and ref elements in testimonia??
- classCode/idno. Needs xml:base, if available and the work-level URN with citation-range appended

  

:)
(: GLOBAL PARAMETERS :)
(:
- C-M URI base
- C-M editors URI base
- C-M editors.xml for lookup for editors string
:)

(: START MAIN SCRIPT :)
let $docUri := "testimonia-template.xml"
return fn:doc($docUri)