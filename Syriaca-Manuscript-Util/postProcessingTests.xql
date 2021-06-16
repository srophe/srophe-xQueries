xquery version "3.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare default element namespace "http://www.tei-c.org/ns/1.0";


(: 

This script adds and cleans up data for manuscript records using the stripped template found here: https://github.com/srophe/wright-catalogue/blob/master/data/3_drafts/wright-ms-template.xml 
The repository, https://github.com/srophe/wright-catalogue, contains an oXygen XML Project file and a CSS file to create an oXygen Author Mode form for ease of encoding manuscripts.

This script will convert those files into TEI records that conform to the Syriaca.org schema as well as to the project guidelines for Syriaca's manuscript encoding project. (See https://github.com/srophe/wright-catalogue/issues/3).

This project makes use of the Wright Decoder (https://docs.google.com/spreadsheets/d/183Sm8nyRtlE2Ucl5JyLg4_RvXSgTF-xB0ceacj2n3BY/edit#gid=0) for looking up page number and catalog information based on the URI of the manuscript.

@author: William L. Potter
@version 1.0
:)
import module namespace functx = "http://www.functx.com";
 declare option output:omit-xml-declaration "no";
 declare option file:omit-xml-declaration "no";
(: Custom function declarations :)

declare function local:createTaxonomyTable($tableUri as xs:string){
  let $wrightTaxonomyCsv := file:read-text($tableUri)
let $lines := fn:tokenize($wrightTaxonomyCsv, "\n")
let $table := <table>{
  for $l in $lines 
    return <line n="{fn:index-of($lines, $l)}">
    {
      let $fields:= fn:tokenize($l, "\t")
      for $f in $fields
      (: return element {fn:concat("f", fn:index-of($fields, $f))} {$f} :)
      return <field>{$f}</field>
}</line>
  
}
</table>
return $table
};

declare function local:add-title($doc as node()) {
  let $blShelfMark := $doc//msIdentifier/altIdentifier/idno[@type="BL-Shelfmark"]/text()
  let $blShelfMarkClean := if (fn:contains($blShelfMark, "foll")) then fn:replace(fn:substring($blShelfMark, functx:index-of-match-first($blShelfMark, "\d"), 1)||functx:substring-after-match($blShelfMark, "\d"), ",", "") else fn:replace($blShelfMark, "[\D*]", "")
  let $title := <title level="a" xml:lang="en">{fn:concat("BL Add MS ", $blShelfMarkClean)}</title>
  (: insert node $title into $doc//titleStmt/ :)
  return $title  (:This should instead update the title of the original document:)
};

declare function local:editorIdLookup($editorUri as xs:string?) {
  let $editorId := if(fn:starts-with($editorUri, "http://syriaca.org/documentation/editors.xml#")) then fn:substring-after($editorUri, "#")
  else $editorUri
  return if ($editorId = "wpotter") then "William L. Potter"
  else if ($editorId = "dmichelson") then "David A. Michelson"
  else if($editorId = "akelly") then "Anna Kelly"
  else if ($editorId = "jpagan") then "Jessica Pagan"
  else if ($editorId = "lruth") then "Lindsay Ruth" else if ($editorId = "eyonan") then "Eliana Yonan" else if ($editorId = "rbrasoveanu") then "Roman Brasoveanu" else if ($editorId = "ecgeitner") then "Emma Claire Geitner"
  else () (:Note: the above line is structured as such to prevent line number references in the instructions from breaking. This is a change among many for refactoring. :)
};

declare function local:updateTitleStmt($doc as node()) {
  let $title := local:add-title($doc)
  let $editorUri := xs:string($doc//revisionDesc/change[not(@subtype) and contains(text(), "Initial")]/@who)
  let $editorString := local:editorIdLookup($editorUri)
  let $creator := <editor role="creator" ref="{$editorUri}">{$editorString}</editor>
  let $creatorRespStmt := <respStmt><resp>Created by</resp><name type="person" ref="{$editorUri}">{$editorString}</name></respStmt>
  let $titleStmt := <titleStmt xmlns="http://www.tei-c.org/ns/1.0">{
    $title,
    <title xml:lang="en" level="m">A Digital Catalogue of Syriac Manuscripts in the British Library</title>,
    <sponsor>Syriaca.org: The Syriac Reference Portal</sponsor>,
    <funder>The National Endowment for the Humanities</funder>,
        <funder>The Andrew W. Mellon Foundation</funder>,
        <principal>David A. Michelson</principal>,
        <editor role="general-editor" ref="http://syriaca.org/documentation/editors.xml#dmichelson">David A. Michelson</editor>,
        <editor role="creator" ref="http://syriaca.org/documentation/editors.xml#wwright">William Wright</editor>,
        <editor role="creator" ref="http://syriaca.org/documentation/editors.xml#dmichelson">David A. Michelson</editor>,
        <editor role="creator" ref="http://syriaca.org/documentation/editors.xml#raydin">Robert Aydin</editor>,
        $creator,
        $creatorRespStmt,
        <respStmt>
          <resp>Based on the work of</resp>
          <name type="person" ref="http://syriaca.org/documentation/editors.xml#wwright">William Wright</name>
        </respStmt>,
        <respStmt>
          <resp>Edited by</resp>
          <name type="person" ref="http://syriaca.org/documentation/editors.xml#"/>
        </respStmt>,
        <respStmt>
          <resp>Syriac text entered by</resp>
          <name type="person" ref="http://syriaca.org/documentation/editors.xml#raydin">Robert Aydin</name>
        </respStmt>,
        <respStmt>
          <resp>Greek and coptic text entry and proofreading by</resp>
          <name type="person" ref="http://syriaca.org/documentation/editors.xml#rstitt">Ryan Stitt</name>
        </respStmt>,
        <respStmt>
          <resp>Project management by</resp>
          <name type="person" ref="http://syriaca.org/documentation/editors.xml#wpotter">William L. Potter</name>
        </respStmt>,
        <respStmt>
          <resp>English text entry and proofreading by</resp>
          <name type="org" ref="http://syriaca.org/documentation/editors.xml#uasyriacaresearchgroup">Syriac Research Group, University of Alabama</name>
        </respStmt>
  }
  </titleStmt>
        
  return $titleStmt
};

declare function local:updatePublicationStmt($doc as node(), $docUri as xs:string){
      let $pubStmt := 
      <publicationStmt>
        <authority>Syriaca.org: The Syriac Reference Portal</authority>
        <idno type="URI">{$docUri}/tei</idno>
        <availability>
          <p/>
          <licence target="http://creativecommons.org/licenses/by/3.0/">
            <p>Distributed under a Creative Commons Attribution 3.0 Unported License</p>
          </licence>
        </availability>
        <date calendar="Gregorian">
        </date>
      </publicationStmt>
     return $pubStmt
};

declare function local:updateMsIdentifier($doc as node(), $docUri as xs:string, $lookupData) {
  let $blShelfMark := $doc//msIdentifier/altIdentifier/idno[@type="BL-Shelfmark"]/text()
  let $blShelfMarkClean := if (fn:contains($blShelfMark, "foll")) then fn:replace(fn:substring($blShelfMark, functx:index-of-match-first($blShelfMark, "\d"), 1)||functx:substring-after-match($blShelfMark, "\d"), ",", "") else fn:replace($blShelfMark, "[\D*]", "")
  let $arabicNumber := $lookupData[4]
  let $romanNumeral := $lookupData[3]
  let $msIdentifier := <msIdentifier>
            <country>United Kingdom</country>
            <settlement>London</settlement>
            <repository>British Library</repository>
            <collection>Oriental Manuscripts</collection>
            <idno type="URI">{$docUri}</idno>
            <altIdentifier>
              <idno type="BL-Shelfmark">{fn:concat("Add MS ", $blShelfMarkClean)}</idno>
            </altIdentifier>
            <altIdentifier>
              <collection>William Wright, Catalogue of the Syriac Manuscripts in the British Museum Acquired since the Year 1838</collection>
              <idno type="Wright-BL-Arabic">{$arabicNumber}</idno>
            </altIdentifier>
            <altIdentifier>
              <collection>William Wright, Catalogue of the Syriac Manuscripts in the British Museum Acquired since the Year 1838</collection>
              <idno type="Wright-BL-Roman">{$romanNumeral}</idno>
              </altIdentifier>
           </msIdentifier>
  return $msIdentifier
};

declare function local:updateExtent($extent as node()*) {
  let $unit := xs:string($extent/measure/@unit)
  return if($unit = "content_pending") then ()
  else $extent
};

declare function local:updateContentPending($nodes as element()*){
  let $returnItems := for $n in $nodes
    return if ($n/p/text()="Content pending") then ()
    else $n
    return $returnItems
};
declare function local:updateHandDesc($doc as node()){
  let $oldHandDesc := $doc//handDesc
  let $handNoteCount := count($oldHandDesc/handNote)
  let $newHandDesc := <handDesc hands="{$handNoteCount}">
  {
    for $handNote in $oldHandDesc/handNote
      let $newHandNote := functx:add-or-update-attributes($handNote, xs:QName('xml:id'), fn:concat("handNote", functx:index-of-deep-equal-node($oldHandDesc/handNote, $handNote)))
      return if ($newHandNote/@medium != '') then $newHandNote else functx:add-or-update-attributes($newHandNote, fn:QName("", 'medium'), "unknown")
  }
  </handDesc>
  return $newHandDesc
};

declare function local:updateAdditions($doc as node()){
  let $oldAdditions := $doc//additions
  let $newAdditions := <additions>
    <p/>
    <list>
  {
    for $item in $oldAdditions/list/item
      let $index := functx:index-of-deep-equal-node($oldAdditions/list/item, $item)
      let $newItem := functx:add-or-update-attributes($item, (xs:QName('xml:id'), fn:QName("", 'n')), (fn:concat("addition", $index), $index))
      return $newItem
  }
  </list>
  </additions>
  return $newAdditions
};

declare function local:updateAdditional($doc as node(), $lookupData) {
  let $adminInfo := <adminInfo>
              <recordHist>
                <source>Manuscript description based on<bibl>
                    <ref target="#Wright">Wright&apos;s
                      Catalogue</ref>
                  </bibl>. abbreviated by the Syriaca.org editors.</source>
              </recordHist>
              <note/>
            </adminInfo>
   let $citedEntry := $lookupData[3]
   let $citedPages := fn:replace($lookupData[2], "#", ":")
   let $listBibl := <listBibl>
              <bibl xml:id="Wright">
                <author>William Wright</author>
                <title xml:lang="en">Catalogue of Syriac Manuscripts in the British Museum Acquired
                  since the Year 1838</title>
                <pubPlace>London</pubPlace>
                <date>1870</date>
                <ptr target="http://syriaca.org/bibl/8"/>
                <citedRange unit="entry">{$citedEntry}</citedRange>
                <citedRange unit="pp">{$citedPages}</citedRange>
              </bibl>
            </listBibl>
   let $newAdditional := <additional>{$adminInfo, $listBibl}</additional>
   return $newAdditional
};

declare function local:updateEncodingDesc($doc as node()){
  let $editorialDecl := <editorialDecl>
        <interpretation>
          <p>Description is based on Wright&apos;s Catalogue without consultation of physical
            manuscripts. Foliation is approximate. Wright often does not indicate ending folia so
            those have been assumed based on beginning folia.</p>
          <p>Scribal notes which could not be more clearly classified based on Wright&apos;s descriptions
            have been identified as &lt;addition&gt;s whether they occur in the margins or the body
            of the manuscript.</p>
          <p>In general, we have classified as an &lt;msItem&gt; as much of the manuscript contents
            as possible, including tables of contents and indices.</p>
        </interpretation>
      </editorialDecl>
   let $classDecl := <classDecl>
        <taxonomy xml:id="Wright-BL-Taxonomy">
          <bibl>
            <ref target="#Wright"/>
            <ptr target="http://syriaca.org/documentation/Wright-BL-Taxonomy.html"/>
          </bibl>
          <category xml:id="biblical-manuscripts">
            <category xml:id="bible-ot"><catDesc>Old Testament</catDesc></category>
            <category xml:id="bible-nt"><catDesc>New Testament</catDesc></category>
            <category xml:id="bible-apocrypha"><catDesc>Apocrypha</catDesc></category>
            <category xml:id="bible-punctuation"><catDesc>Punctuation</catDesc></category>
          </category>
          <category xml:id="service-books">
            <category xml:id="psalter"><catDesc>Psalters</catDesc></category>
            <category xml:id="lectionaries"><catDesc>Lectionaries</catDesc></category>
            <category xml:id="missals"><catDesc>Missals</catDesc></category>
            <category xml:id="sacerdotals"><catDesc>Sacerdotals</catDesc></category>
            <category xml:id="choral"><catDesc>Choral Books</catDesc></category>
            <category xml:id="hymns"><catDesc>Hymns</catDesc></category>
            <category xml:id="prayers"><catDesc>Prayers</catDesc></category>
            <category xml:id="funerals"><catDesc>Funeral Services</catDesc></category>
          </category>
          <category xml:id="theology">
            <category xml:id="theo-single"><catDesc>Individual Authors</catDesc></category>
            <category xml:id="theo-collected"><catDesc>Collected Authors</catDesc></category>
            <category xml:id="theo-catenae"><catDesc>Catenae Patrum and Demonstrations against Heresies</catDesc></category>
            <category xml:id="theo-anonymous"><catDesc>Anonymous Works</catDesc></category>
            <category xml:id="theo-council"><catDesc>Councils of the Church and Ecclesioastical Canons</catDesc></category>
          </category>
          <category xml:id="wright-history">
            <category xml:id="history"><catDesc>History</catDesc></category>
          </category>
          <category xml:id="lives">
            <category xml:id="lives-collect"><catDesc>Collected Lives</catDesc></category>
            <category xml:id="lives-single"><catDesc>Single Lives</catDesc></category>
          </category>
          <category xml:id="scientific-lit">
            <category xml:id="sci-logic"><catDesc>Logic and Rhetoric</catDesc></category>
            <category xml:id="sci-grammar"><catDesc>Grammar and Lexicography</catDesc></category>
            <category xml:id="sci-ethics"><catDesc>Ethics</catDesc></category>
            <category xml:id="sci-medicine"><catDesc>Medicine</catDesc></category>
            <category xml:id="sci-agriculture"><catDesc>Agriculture</catDesc></category>
            <category xml:id="sci-chemistry"><catDesc>Chemistry</catDesc></category>
            <category xml:id="sci-natural-history"><catDesc>Natural History</catDesc></category>
          </category>
          <category xml:id="wright-fly-leaves">
            <category xml:id="fly-leaves"><catDesc>Fly Leaves</catDesc></category>
          </category>
          <category xml:id="appendices">
            <category xml:id="appendix-a"><catDesc>Appendix A</catDesc></category>
            <category xml:id="appendix-b"><catDesc>Appendix B</catDesc></category>
          </category>
        </taxonomy>
      </classDecl>
   let $newEncodingDesc := <encodingDesc>{$editorialDecl, $classDecl}</encodingDesc>
   return $newEncodingDesc
};

declare function local:updateProfileDesc($doc as node(), $lookupData, $table){
  let $langUsage := <langUsage>
        <language ident="syr">Unvocalized Syriac of any variety or period</language>
        <language ident="syr-Syre">Syriac in Estrangela</language>
        <language ident="syr-Syrj">Vocalized West Syriac</language>
        <language ident="syr-Syrn">Vocalized East Syriac</language>
        <language ident="syr-x-syrm">Melkite Syriac</language>
        <language ident="syr-x-syrp">Palestinian Syriac</language>
        <language ident="ar-Syrc">Unvocalized or Undetermined Arabic Garshuni</language>
        <language ident="ar-Syrj">Arabic Garshuni in Vocalized West Syriac Script</language>
        <language ident="ar-Syrn">Arabic Garshuni in Vocalized East Syriac Script</language>
        <language ident="en">English</language>
        <language ident="ar">Arabic</language>
        <language ident="fr">French</language>
        <language ident="de">German</language>
        <language ident="la">Latin</language>
        <language ident="grc">Ancient Greek</language>
        <language ident="cop">Coptic</language>
      </langUsage>
  let $arabicNumeral := xs:integer($lookupData[4])
  let $taxonomyId := for $line in $table/line[@n>1]
    let $lineNum := $line/@n
    where $arabicNumeral ge xs:integer($line/field[4]/text()) and $arabicNumeral lt xs:integer($table/line[@n=$lineNum+1]/field[4]/text())
    return $line/field[1]/text()
  let $taxonomyIdValue := fn:replace($taxonomyId, '"', "")
  let $textClass := <textClass>
        <keywords scheme="#Wright-BL-Taxonomy">
          <list>
            <item>
              <ref target="#{$taxonomyIdValue}"/>
            </item>
          </list>
        </keywords>
      </textClass>
return <profileDesc>{$langUsage, $textClass}</profileDesc>
};

(: DEALING WITH ADDING @xml:id AND @n ATTRIBUTES TO <msItem> ELEMENTS :)
 
declare function local:addMsItemLevel($seq as element()+) {
  (: This function adds an alphabetic character as the @xml:id attribute to each msItem depending on its level in the nested tree. E.g., "a" for first-level elements, "b" for their immediate children, and so on.:)
  let $refCode := 97
  
  let $newEls := for $el in $seq
    let $ancestorCount := count($el/ancestor::msItem)
    let $nonMsItemChildren := $el/*[not(name()='msItem')]
    let $updatedChildren := if ($el/msItem) then element {node-name($el)}{$el/@*, $nonMsItemChildren, local:addMsItemLevel($el/msItem)} else $el
    let $newEl := functx:add-or-update-attributes($updatedChildren, xs:QName('xml:id'), fn:codepoints-to-string($refCode + $ancestorCount))
    return $newEl
  return $newEls
};
declare function local:createLinearMsItemSequence($msItems) {
  (: Generates a sequence of sibling msItem elements through depth-first tree traversal. That is, the sequence of msItems does not follow document order but instead places children and grandchildren of a given element before the following sibling. This enables the desired enumeration for the msItems :)
  for $msItem in $msItems
    let $nonMsItemChildren := $msItem/*[not(name()='msItem')]
    let $noChildMsItem := element {node-name($msItem)}
      {$msItem/@*, $nonMsItemChildren,
      functx:remove-elements-deep($msItem, "msItem")}
    return if ($msItem/msItem) then ($noChildMsItem, local:createLinearMsItemSequence($msItem/msItem)) else $msItem
};

declare function local:addMsItemSequence($msItems) {
  (:This function carries out the actual enumeration of the msItems, relying on "createLinearMsItemSequence" to generate the ordered list:)
  let $linearMsItems := local:createLinearMsItemSequence($msItems)
  for $msItem at $count in $linearMsItems
    let $newMsItem := functx:add-or-update-attributes($msItem, fn:QName('', 'n'), $count)
    return $newMsItem
};

declare function local:addXmlId($msItems) {
  (:This function generates a sequence of msItems with correct xml:id made up of level indicator and sequence within that level (e.g, "a4"):)
  let $linearEnumItems := local:addMsItemSequence($msItems)
  let $totalLevels := fn:distinct-values($linearEnumItems/descendant-or-self::msItem/@xml:id)
  let $elementsByLevel := for $level in $totalLevels
    return <level id="{$level}">{$linearEnumItems[@xml:id=$level]}</level>
  let $elementsWithId := for $level in $totalLevels
    return <level id="{$level}">{for $item at $count in $elementsByLevel[@id=$level]/msItem
      let $idMsItem := functx:update-attributes($item, xs:QName('xml:id'), fn:concat($level, $count))
      return $idMsItem}
      </level>
  let $nestedElements := local:buildMsItems($linearEnumItems, "a", $elementsWithId)
  return $nestedElements
};
declare function local:buildMsItems($linearMsItems, $refLevel, $idTree) {
    (:This function builds the msItems from an enumerated list by properly nesting them based on their order in the sequence and the level indicated by the @xml:id attribute. The xml:id attribute is updated using the reference tree. :)
    
    for $item in $linearMsItems[@xml:id=$refLevel]
      let $nLow := xs:string($item/@n)
      let $nHigh := 
        if(fn:deep-equal($item, $linearMsItems[@xml:id=$refLevel][last()])) 
          then 
            (if (fn:deep-equal($item,$linearMsItems[last()])) then xs:integer($linearMsItems[last()]/@n)+1 else xs:integer($linearMsItems[last()]/@n))
          else xs:string($linearMsItems[@xml:id=$refLevel][functx:index-of-deep-equal-node($linearMsItems[@xml:id=$refLevel], $item) + 1]/@n)
      let $children := $linearMsItems[xs:integer($nLow) < xs:integer(./@n) and xs:integer(./@n) <= xs:integer($nHigh)]
      let $nonMsItemChildren := $item/*[not(name() = "msItem")]
      let $processedChildren := local:buildMsItems($children, fn:codepoints-to-string(fn:string-to-codepoints($refLevel)+1), $idTree)
      let $newElement := element {node-name($item)}{$item/@*, $nonMsItemChildren, $processedChildren}
      let $xmlId := xs:string($idTree//msItem[./@n=$newElement/@n]/@xml:id)
      let $updatedIdElement := functx:update-attributes($newElement, xs:QName("xml:id"), $xmlId)
      return $updatedIdElement
};

declare function local:updateMsContents($oldMsContents) {
  let $textLang := xs:string($oldMsContents/textLang/@mainLang)
  let $newMsContents := 
<msContents>
    <summary/>
    <textLang mainLang="{$textLang}"/>{
  let $levelMsItem := local:addMsItemLevel($oldMsContents/msItem)
  let $processedMsItems := local:addXmlId($levelMsItem)
  return $processedMsItems
  }
</msContents>
return $newMsContents
};

(: START MAIN UPDATE SCRIPT:)
let $editor := "srophe-util"
let $changeLog := "CHANGED: Added project metadata; metadata from Wright Decoder; msItem, handDesc, and additions enumeration; Wright Taxonomy designation"
let $change := <change xmlns="http://www.tei-c.org/ns/1.0" who="http://syriaca.org/documentation/editors.xml#{$editor}" when="{fn:current-date()}">{$changeLog}</change>
let $inputDirectory := "C:/Users/anoni/Documents/GitHub/srophe/wright-catalogue/data/3_drafts/ElianaYonan/"
let $outputFilePath := "C:/Users/anoni/Documents/GitHub/srophe/wright-catalogue/data/4_to_be_checked/postProcessingOutputs/"
let $empty := file:create-dir($outputFilePath)
let $wrightDecoderCsv := file:read-text("C:\Users\anoni\Documents\GitHub\srophe\srophe-xQueries\Syriaca-Manuscript-Util\wrightDecoderSimple.csv")
let $wrightTaxonomyCsvUri := "C:\Users\anoni\Documents\GitHub\srophe\srophe-xQueries\Syriaca-Manuscript-Util\wrightTaxonomyTable.csv"
let $wrightTaxonomyTable := local:createTaxonomyTable($wrightTaxonomyCsvUri)
let $lookupLines := tokenize($wrightDecoderCsv, "\n")
(:The following lines enable the script to verify if a record has already been generated and placed in one of the folders specified :)
let $existingRecordPathList := ("C:/Users/anoni/Documents/GitHub/srophe/wright-catalogue/data/4_to_be_checked/postProcessingOutputs/", "C:/Users/anoni/Documents/GitHub/srophe/wright-catalogue/data/4_to_be_checked/", "C:/Users/anoni/Documents/GitHub/srophe/wright-catalogue/data/5_finalized/", "C:/Users/anoni/Documents/GitHub/srophe/wright-catalogue/data/5_finalized/TransferredToDevServer/")
let $existingDocUris := 
fn:distinct-values(for $coll in $existingRecordPathList
  for $doc in fn:collection($coll)
    return fn:substring-before(fn:substring-after(fn:document-uri($doc), $coll), ".xml"))
let $editionStmt := <editionStmt>
        <edition n="1.0"/>
      </editionStmt>
let $newSchema := <?oxygen RNGSchema="http://syriaca.org/documentation/syriaca-tei-main.rnc" type="compact"?>
let $newStylesheet := <?xml-stylesheet type="text/css" href="https://raw.githubusercontent.com/srophe/wright-catalogue/master/parameters/tei.css"?>

for $doc in fn:collection($inputDirectory)
  
  let $recordExists := for $id in $existingDocUris
    where $id = $doc/TEI/teiHeader/fileDesc/sourceDesc/msDesc/msIdentifier/idno[@type="URI"]/text()
    return "true"
  (: where $recordExists = "true" :)
  let $docPath := fn:document-uri($doc)
  let $fileName := fn:substring-after($docPath, $inputDirectory)
  let $docId := $doc//msDesc/msIdentifier/idno[@type="URI"]/text()
  let $docUri := if(fn:starts-with($docId, "http://syriaca.org/manuscript/")) then $docId else fn:concat("http://syriaca.org/manuscript/", $docId)
  let $lookupData := for $l in $lookupLines
    let $lookupFields := tokenize($l, "\t")
    where (fn:normalize-space($lookupFields[6]) = fn:substring-after($docUri, "http://syriaca.org/manuscript/"))
    return $lookupFields
  return if ($docId != '' and not($recordExists)) then (
    replace node $doc//titleStmt with local:updateTitleStmt($doc), 
    replace node $doc//editionStmt with $editionStmt, 
    replace node $doc//publicationStmt with local:updatePublicationStmt($doc, $docUri),
    if ($doc//msDesc/@xml:id) then replace value of node $doc//msDesc/@xml:id with fn:concat("manuscript-", fn:substring-after($docUri, "http://syriaca.org/manuscript/")) else insert node attribute xml:id {fn:concat("manuscript-", fn:substring-after($docUri, "http://syriaca.org/manuscript/"))} into $doc//msDesc,
    replace node $doc//msDesc/msIdentifier with local:updateMsIdentifier($doc, $docUri, $lookupData),
    replace node $doc//msDesc/msContents with local:updateMsContents($doc//msDesc/msContents),
    (: replace node $doc//supportDesc/extent with local:updateExtent($doc//supportDesc/extent), :)
    if (not(empty(local:updateContentPending($doc//objectDesc/layoutDesc)))) then replace node $doc//objectDesc/layoutDesc with local:updateContentPending($doc//objectDesc/layoutDesc),
    replace node $doc//handDesc with local:updateHandDesc($doc),
    if ($doc//additions) then replace node $doc//additions with local:updateAdditions($doc),
    if (not(empty(local:updateContentPending($doc//msDesc/physDesc/bindingDesc)))) then replace node $doc//msDesc/physDesc/bindingDesc with local:updateContentPending($doc//msDesc/physDesc/bindingDesc),
    if (not(empty(local:updateContentPending($doc//msDesc/physDesc/sealDesc)))) then replace node  $doc//msDesc/physDesc/sealDesc with local:updateContentPending($doc//msDesc/physDesc/sealDesc),
    replace node $doc//additional with local:updateAdditional($doc, $lookupData),
    replace node $doc//encodingDesc with local:updateEncodingDesc($doc),
    replace node $doc//profileDesc with local:updateProfileDesc($doc, $lookupData, $wrightTaxonomyTable),
    insert node $change before $doc//revisionDesc/change[1],
    delete node $doc//processing-instruction(),
    insert node ($newSchema, $newStylesheet) before $doc/TEI,
    
    fn:put($doc, fn:concat($outputFilePath, $fileName), map{'omit-xml-declaration': 'no'})
  )