xquery version "3.0";

(: SCRIPT FOR DEPRECATING PERSON RECORDS by ngibson :)
 
(:  INSTRUCTIONS: :)
(:  - Run this script on your local eXist-db installation. :)
(:  - You will need to scroll down to the VARIABLES section:)
(:  and change the $uri to the URI of the record you want to deprecate. Also change the username. :)
(:  - If the deprecated record should redirect to another record, put the new URI in the $uri-redirect variable. Otherwise leave it blank  :)
  
(: NAMESPACES:)
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace syriaca = "http://syriaca.org";
declare namespace functx = "http://www.functx.com";


(: CUSTOM FUNCTIONS :)

(: ATTRIBUTE UPDATING FUNCTIONS :)
declare function syriaca:next-id($ids as xs:string*,$prefix as xs:string*,$i as xs:double*)
as xs:string*
{
    let $offset := if ($i) then $i else 1
    return 
        if (count($ids) > 0) then
            let $id-nums := 
                for $id in $ids
                return number(replace($id,$prefix,''))
            return concat($prefix,($i+max($id-nums)))
        else concat($prefix,$i)
};

declare function syriaca:update-attribute($input-node as node()*,$attribute as xs:string,$attribute-value as xs:string)
as node()*
{
    for $node in $input-node
        return
            element {xs:QName(name($node))} {
                        $node/@*[name()!=$attribute], 
                        attribute {$attribute} {$attribute-value}, 
                        $node/node()}
};

(: RECORD REWRITING FUNCTIONS :)
declare function syriaca:deprecate-merge-redirect($tei-root as node(),$redirect-uri as xs:string,$user as xs:string)

{
    let $uri := 
        replace($tei-root/teiHeader/fileDesc/publicationStmt/idno[@type='URI'][1], '/tei','')
    let $deprecated-id := replace($uri,'http://syriaca.org/person/','')
    let $changes-old := $tei-root/teiHeader/revisionDesc/change
    let $change-id := syriaca:next-id($changes-old/@xml:id, concat('change',$deprecated-id,'-'), 1)
    let $change-attribute := attribute change {concat('#',$change-id)}
    let $change-message := 
        if ($redirect-uri) then
            concat('Merged into [',$redirect-uri,'] and deprecated.')
        else
            'Deprecated record.'
    let $change :=
        element change 
            {attribute who {concat('http://syriaca.org/documentation/editors.xml#',$user)},
            attribute when {current-date()},
            attribute xml:id {$change-id},
            $change-message
            }
            
    let $title-old := $tei-root/teiHeader/fileDesc/titleStmt/title[@level='a']
    let $title := element title {$title-old/@*,$title-old/node(),' [deprecated]'}
    let $publication-idno-old := $tei-root/teiHeader/fileDesc/publicationStmt/idno[@type='URI']
    let $publication-idno := 
        (element idno {$publication-idno-old/@*,$change-attribute,$publication-idno-old/node()},
        if ($redirect-uri) then
            element idno {attribute type {'redirect'},$change-attribute,concat($redirect-uri,'/tei')}
        else ()
            )
    let $revisionDesc-old := $tei-root/teiHeader/revisionDesc
    let $revisionDesc := element revisionDesc {
        syriaca:update-attribute($revisionDesc-old, 'status', 'deprecated')/@*,
        $change,
        $revisionDesc-old/node()}
    let $body-old := $tei-root/text/body
    let $body-text := 
            element desc {
                $change-attribute,
                attribute type {'deprecation'},
                if ($redirect-uri) then
                    concat('This record has been deprecated and merged into ',$redirect-uri,'.')
                else
                    'This record has been deprecated.'
            }
    let $body := element body {$body-old/@*,$body-text,$body-old/node()}
    let $idno-old := $tei-root/text/body/listPerson/person/idno[@type='URI' and text()=$uri]
    let $idno := 
        (element idno {$idno-old/@*,$change-attribute,$idno-old/node()},
        if ($redirect-uri) then
            element idno {attribute type {'redirect'},$change-attribute,$redirect-uri}
        else ()
        )
    
    return 
        (update replace $title-old with $title,
        update insert $publication-idno following $publication-idno-old, update delete $publication-idno-old,
        update replace $revisionDesc-old with $revisionDesc,
        update insert $idno following $idno-old, update delete $idno-old,
        update replace $body-old with $body)
};


(: ------------------------------------------------------------------------ :)
(: DEPRECATE SCRIPT BODY :)
let $persons := collection('/db/apps/srophe-data/data/persons/tei/')/TEI

(: VARIABLES TO EDIT FOR EACH RUN :)
(: Record that will be deprecated :)
let $uri := 'http://syriaca.org/person/2091'

(: URI of record where visitors to the deprecated URI will be redirected :)
let $uri-redirect := ''

(: Your user id in http://syriaca.org/documentation/editors.xml :)
let $user := 'ngibson'

let $deprecated-id := replace($uri,'http://syriaca.org/person/','')
let $deprecated-record := $persons[text/body/listPerson/person/idno[@type='URI']=$uri]

return 
    syriaca:deprecate-merge-redirect($deprecated-record, $uri-redirect, $user)