xquery version "3.1";

(:
: Takes two XML data dumps from CBSS's EndNote library,
: compares them, and determines which records don't match.
: These non-matches are used to identify record edits from
: EndNote that need to be propagated to the CBSS Zotero library
:
: @author William L. Potter
: @version 1.0
: @date 2023-08-18
:)

import module namespace functx = 'http://www.functx.com';

(: these variables should be moved to be set either by an input field or by a command script :)
(:~ $base
 : a collction of record elements from an EndNote dump
 :)
declare variable $base := 
    doc("/home/arren/Downloads/SyriacBibliography20-12-2021.xml")/xml/records/record;

(:~ $to-compare
 : a collction of record elements from an EndNote dump
 :)
declare variable $to-compare := 
    doc("/home/arren/Downloads/csbc-dump_2023-08-01/SyriacBibliography 01-08-23.xml")/xml/records/record;

(:~ local:pre-process-records
: Takes a sequence of nodes, $recs
: Removes the following db-specific attributes and elements:
: - database
: - source-app
: - rec-number
: - foreign-keys
: :)
declare function local:pre-process-records($recs as node()*)
as node()*
{
    for $r in $recs
    (: return only children without db-specific info :)
    let $children :=
        for $el in $r/*
        return 
            switch($el/name())
            case "database" return ()
            case "source-app" return ()
            case "rec-number" return ()
            case "foreign-keys" return ()
            case "label" return ()
            default return $el
    return element {$r/name()} { $children }
};

let $processedBase := local:pre-process-records($base)
let $processedCompare := local:pre-process-records($to-compare)

for $rec in $processedBase
return if(functx:is-node-in-sequence-deep-equal($rec, $processedCompare)) then
    ()
    else $rec