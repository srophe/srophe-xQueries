xquery version "3.0";
import module namespace functx = "http://www.functx.com";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare default element namespace "http://www.oxygenxml.com/ns/report";
declare option output:method "csv";
declare option output:csv "header=yes, separator=comma, quotes=yes";

let $csv := <csv>
{
  for $error in doc("C:\Users\anoni\Documents\GitHub\miscellaneous-util-scripts\Syriaca-Places-Schema-Testing-Util\validation-errors-places-production-2020-06-16.xml")/report/incident
  let $startString := "line: "||$error/location/start/line/text()||"; column: "||$error/location/start/column/text()
  let $endString := "line: "||$error/location/end/line/text()||"; column: "||$error/location/end/column/text()
  let $start := <start>{$startString}</start>
  let $end := <end>{$endString}</end>
  return <record>{$error/*[not(operationDescription) and not(location)], $start, $end}</record>
}
  </csv>
return $csv