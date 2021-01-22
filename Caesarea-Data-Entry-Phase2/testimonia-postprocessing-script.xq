xquery version "3.0";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";
declare namespace csv = "http://basex.org/modules/csv";

(:
To do:

- add a-level title
- add editor[@role="creator"] and respStmts for person who created doc based on /TEI/teiHeader/revisionDesc/change/@who
  - note: both data and metadata input people are creators but give each a unique respStmt
    - TEI encoding by me I think?
    - metadata: URNs and other metadata added by
    - data: Electronic text added by
- construct full publicationStmt/idno
- add publicationStmt/date 
- add @target attribute to ref "#bib\d+-1"
- add surrounding prose for creation elements
- add attributes for period date
- create the human-readable version (add error handling for these dates?)
- add human-readable language to langUsage/language from language table
- add URN for section of work to classCode/idno = creation/title/@ref||":"||creation/title/ref/text()
- and update change/@when attributes using the current date
- add abstract, compiled from creation elements with xml:id and type, etc.
- add attributes to ab for edition and translation
  - xml:lang (en for translation; from langUsage/lang/@ident for edition)
  - xml:id of form "quote\d+-1" or "-2" for second quote.
  - source referring sequentially to the first two bibls
- add anchor elements as first child below ab with edition and translation referring to each other
- bibls
  - add xml:id attributes to the first two (under Works Cited)
  - Replace Zotero URIs in bibls with C-M.org bibl module URIs
  - refs to bibls in creation/ref/@target; and the two testimonia quotes
  - replace Zotero URIs with C-M.org ones
  - deal with note elements in bibls if we add those
  - add title and author/editors based on Zotero records?? (this was a previous functionality)  
- are we doing anything with empty elements?
- are we doing anything with the notes under body?
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