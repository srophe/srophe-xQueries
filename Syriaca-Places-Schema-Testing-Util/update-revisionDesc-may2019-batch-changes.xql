xquery version "3.0";
import module namespace functx = "http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare option output:omit-xml-declaration "no";
declare option output "indent=no";

let $newRevChange := <change who="http://syriaca.org/documentation/editors.xml#wpotter" when="{fn:current-date()}">CHANGED: Implemented May 2019 batch changes, see <ref target="https://github.com/srophe/srophe-app-data/issues?q=is%3Aissue+label%3A2019-May-Batch-Changes">https://github.com/srophe/srophe-app-data/issues?q=is%3Aissue+label%3A2019-May-Batch-Changes</ref>. The issues labeled were #742, #743, #746, #747, #749, #752, #754, #757, #759, #761, #763, #765, #766, #767, #768, #769, #770, #771, #772, #773, #774, #792, #793, #794, #797, #802, #803, #804, #806, #807, #815, #816, #817, #818, #819, #820, #821, #822, #823, #824, #825, #826, #827, #829, #831, #832, #833, #834, #836, #843, #847, #848, #849, #850, #851, #852, #853</change>

let $inputCollectionUri := "C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\places\tei\"
for $doc in collection($inputCollectionUri)
  return insert node $newRevChange as first into $doc//revisionDesc