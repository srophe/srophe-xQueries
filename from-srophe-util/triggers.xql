xquery version "3.0";

module namespace trigger="http://exist-db.org/xquery/trigger";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";

declare function trigger:after-create-document($uri as xs:anyURI)
{
    (
        sm:chmod($uri, 'rwxrwxr-x'),
        sm:chgrp($uri, 'srophe'), 
        srophe-util:add-custom-dates($uri, 'ADDED: syriaca-computed-start and syriaca-computed-end attributes for searching','wsalesky'),
        srophe-util:add-alt-names($uri,'ADDED: Add alternate names for search functionality.','wsalesky')
    ) 
};

declare function trigger:after-update-document($uri as xs:anyURI) {
    (
        srophe-util:add-custom-dates($uri, 'ADDED: syriaca-computed-start and syriaca-computed-end attributes for searching','wsalesky'),
        srophe-util:add-alt-names($uri,'ADDED: Add alternate names for search functionality.','wsalesky')
      )  
};