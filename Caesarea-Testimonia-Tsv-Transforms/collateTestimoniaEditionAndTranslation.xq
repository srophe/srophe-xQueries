xquery version "3.0";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "csv";
declare option output:csv "header=yes, separator=tab";

(:
This script merges data about the edition and translation of a set of Caesarea-Maritima.org Testimonia. 
It merges rows of TSV data into a single row of TSV data for each testimonia record for subsequent transformation into TEI XML records.

@author: William L. Potter
@version 1.0
:)

declare function local:collate-tsv-record($edition, $translation){
  let $workUrnDelete := fn:replace($edition/Citation_URN, "urn:cts:.+?:.*?\..*?\.", '')
  let $workUrn := fn:replace($edition/Citation_URN, $workUrnDelete, '')
  let $addedEdition := tokenize($edition/added_by/text(), "#")
  let $addedTranslation := tokenize($translation/added_by/text(), "#")
  let $allAdded := ($addedEdition, $addedTranslation)
  let $addedBy := fn:string-join(fn:distinct-values($allAdded), "#")
  let $newRecord := <record>
  <uri>{$edition/testimoniaID/text()}</uri>
  <workAuthor>{$edition/Author/text()}</workAuthor>
  <sourceUriWorkAuthor></sourceUriWorkAuthor>
  <work>{$edition/Work_Title/text()}</work>
  <workUrn>{fn:substring($workUrn, 1, fn:string-length($workUrn)-1)}</workUrn>
  <workUriBase>{fn:substring-before($edition/Citation_Link/text(), "urn:cts")}</workUriBase>
  <citedRangeWork>{$edition/Source_Cited_Range/text()}</citedRangeWork>
  <creationDate></creationDate>
  <creationLocation></creationLocation>
  <creationLocationUri></creationLocationUri>
  <workLang>{$edition/Language/text()}</workLang>
  <catRef></catRef>
  <isContainer>{$edition/isContainer/text()}</isContainer>
  <isIndirectReference>{$edition/indirectReference/text()}</isIndirectReference>
  <edition1>{$edition/Full_Text/text()}</edition1>
  <edition1_typosCorrected>{$edition/typosCorrected/text()}</edition1_typosCorrected>
  <edition1SourceUri>{fn:concat('https://caesarea-maritima.org/bibl/', $edition/Zotero_ID_Machine-Readable/text())}</edition1SourceUri>
  <edition1CitedRange>{$edition/Source_Cited_Range/text()}</edition1CitedRange>
  <edition1Link>{$edition/Citation_Link/text()}</edition1Link>
  <edition1Lang>{$edition/Language/text()}</edition1Lang>
  <printedEdition1Uri>{fn:concat('https://caesarea-maritima.org/bibl/', $edition/Zotero_ID_Print/text())}</printedEdition1Uri>
  <translation1>{$translation/Full_Text/text()}</translation1>
  <translation1_typosCorrected>{$translation/typosCorrected/text()}</translation1_typosCorrected>
  <translation1SourceUri>{fn:concat('https://caesarea-maritima.org/bibl/', $translation/Zotero_ID_Machine-Readable/text())}</translation1SourceUri>
  <translation1CitedRange>{$translation/Source_Cited_Range/text()}</translation1CitedRange>
  <translation1Link>{$translation/Citation_Link/text()}</translation1Link>
  <translation1Lang>{$translation/Language/text()}</translation1Lang>
  <printedTranslation1Uri>{fn:concat('https://caesarea-maritima.org/bibl/', $translation/Zotero_ID_Print/text())}</printedTranslation1Uri>
  <added_by>{$addedBy}</added_by>
</record>
return $newRecord
(: return $edition, $translation :)
};
let $options := map {'header': true(), 'separator': 'tab', 'quotes': 'no'}
let $input := file:read-text("C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Caesarea-Testimonia-Tsv-Transforms\tsvSources\testimoniaTsvInput-2020-06-10.csv")
let $inputXml := csv:parse($input, $options)
let $editions :=
   for $rec in $inputXml/csv/record
  where $rec/Language != "English"
  return $rec
return <csv>
{
  for $ed in $editions
  let $testimoniaUri := $ed/testimoniaID/text()
  let $translationRec := $inputXml//record[./testimoniaID/text() = $testimoniaUri and ./Language = "English"]
return local:collate-tsv-record($ed, $translationRec)
}
</csv>