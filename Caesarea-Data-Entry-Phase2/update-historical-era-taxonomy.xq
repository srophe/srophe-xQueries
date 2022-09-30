xquery version "3.0";

import module namespace cmproc="http://wlpotter.github.io/ns/cmproc" at "cmproc.xqm";
import module namespace config="http://wlpotter.github.io/ns/cm/config" at "config.xqm";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace csv = "http://basex.org/modules/csv";

for $doc in $config:input-collection
return  cmproc:update-historical-era-taxonomy($doc)