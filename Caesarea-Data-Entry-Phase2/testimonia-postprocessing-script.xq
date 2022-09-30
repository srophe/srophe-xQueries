xquery version "3.0";

import module namespace cmproc="http://wlpotter.github.io/ns/cmproc" at "cmproc.xqm";
import module namespace config="http://wlpotter.github.io/ns/cm/config" at "config.xqm";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace csv = "http://basex.org/modules/csv";

(: START MAIN SCRIPT :)

(: initialize runtime :)
let $nothing := file:create-dir($config:output-directory)

(: Main Loop through Folder of Records to Process :)
for $doc in $config:input-collection
  return cmproc:post-process-testimonia-record($doc)
  
  