xquery version "3.1";
(:~ 
 : Srophe utility function to add relationship text to SPEAR relationships.
 : See: https://github.com/srophe/srophe-app-data/issues/783
 :   
 : @author Winona Salesky
 : @version 1.0 
 : 
 :) 
import module namespace functx="http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace file="http://exist-db.org/xquery/file";

(:
 : Global variables, change for each use case
:)
declare variable $data-root := '/db/apps/srophe-data/data';
declare variable $editor := 'srophe-util';
declare variable $changeLog := 'CHANGED: Add a human readable version or the tei:relation element in a tei:desc.';

(:~ 
 : Add desc, construct human readable text.
 : @param  $relation tei:relation element
:)
declare function local:relation-text($rec as item()*){
    for $relation in $rec/descendant::tei:div/descendant::tei:relation
    let $desc :=
        <desc xmlns="http://www.tei-c.org/ns/1.0">{local:decode-relationship($relation)}</desc>
    return 
        update insert $desc into $relation
      
};

declare function local:get-name($uris as xs:string*){
    let $uris := tokenize($uris,' ')
    let $count := count($uris)
    for $uri at $i in $uris
    let $rec :=  collection($data-root)//tei:TEI[.//tei:idno[@type='URI'][. = concat($uri,'/tei')]][1]
    let $name := $rec/descendant::tei:titleStmt[1]/tei:title[1]/text()[1]
    let $name := if(contains($name, '—')) then substring-before($name,'—') else $name
    let $name := if($name = ('',' ')) then string-join($rec/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][starts-with(@xml:lang,'en')]/text(),' ') else $name
    return
        (
        if($i = 1) then ()
        else if($i != $count and $count gt 1) then  
            ', '
        else if($i = $count and $count gt 1) then  
            ' and '
        else (),
        <persName xmlns="http://www.tei-c.org/ns/1.0" ref="{$uri}">{if($name != '') then normalize-space($name) else ()}</persName>
        )
};

declare function local:decode-relationship($relationship as item()*){ 
    let $relationship-name := $relationship/@ref
    return 
    switch ($relationship-name)
        case "snap:AllianceWith" return 
            (local:get-name($relationship/@mutual), " formed an alliance.")
        case "snap:AncestorOf" return 
            if(count(local:get-name($relationship/@active)) gt 1) then
                (local:get-name($relationship/@active), " were the ancestors of ", local:get-name($relationship/@passive),'.')
            else (local:get-name($relationship/@active), " was the ancestor of ", local:get-name($relationship/@passive),'.')
        case "snap:CasualIntimateRelationshipWith" return 
            (local:get-name($relationship/@mutual), " had a casual intimate relationship.")
        case "snap:ChildOf" return 
            if(count(local:get-name($relationship/@active)) gt 1) then
                (local:get-name($relationship/@active), " were the children of ", local:get-name($relationship/@passive),'.')
            else (local:get-name($relationship/@active), " was the child of ", local:get-name($relationship/@passive),'.')
        case "snap:ChildOfSiblingOf" return 
            (local:get-name($relationship/@active), " was the child of a sibling of ", local:get-name($relationship/@passive),'.')            
        case "snap:CousinOf" return 
            (local:get-name($relationship/@mutual), " were cousins.")            
        case "snap:DescendantOf" return 
            (local:get-name($relationship/@active), " descended from ", local:get-name($relationship/@passive),'.')
        case "snap:EnmityFor" return
            (local:get-name($relationship/@active), " had enmity for ", local:get-name($relationship/@passive),'.')
        case "snap:ExtendedFamilyOf" return
            (local:get-name($relationship/@mutual), " were part of the same extended family.")
        case "snap:ExtendedHouseholdOf" return
            (local:get-name($relationship/@mutual), " were part of the same extended household.")
        case "snap:FreedSlaveOf" return
            if(count(local:get-name($relationship/@active)) gt 1) then
                (local:get-name($relationship/@active), " were freed slaves of ", local:get-name($relationship/@passive),'.')
            else (local:get-name($relationship/@active), " was a freed slave of ", local:get-name($relationship/@passive),'.') 
        case "snap:FriendshipFor" return
            (local:get-name($relationship/@mutual), " were friends.")
        case "snap:GrandparentOf" return
            if(count(local:get-name($relationship/@active)) gt 1) then
                (local:get-name($relationship/@active), " were the grandparents of ", local:get-name($relationship/@passive),'.')
            else (local:get-name($relationship/@active), " was the grandparent of ", local:get-name($relationship/@passive),'.')        
        case "snap:GreatGrandparentOf" return
            if(count(local:get-name($relationship/@active)) gt 1) then
                (local:get-name($relationship/@active), " were the great grandparents of ", local:get-name($relationship/@passive),'.')
            else (local:get-name($relationship/@active), " was the great grandparent of ", local:get-name($relationship/@passive),'.')         
        case "snap:HouseholdOf" return
            (local:get-name($relationship/@mutual), " were part of the same household.")        
        case "snap:HouseSlaveOf" return
            (local:get-name($relationship/@passive), " held ", local:get-name($relationship/@active),' as a house slave.')        
        case "snap:IntimateRelationshipWith" return
            (local:get-name($relationship/@mutual), " had an intimate relationship.")       
        case "snap:KinOf" return
            (local:get-name($relationship/@mutual), " were kin.")        
        case "snap:LegallyRecognisedRelationshipWith" return
            (local:get-name($relationship/@mutual), " were part of a legally recognized relationship.")        
        case "snap:ParentOf" return
            if(count(local:get-name($relationship/@active)) gt 1) then
                (local:get-name($relationship/@active), " were the parents of ", local:get-name($relationship/@passive),'.')
            else (local:get-name($relationship/@active), " was the parent of ", local:get-name($relationship/@passive),'.') 
        case "snap:ProfessionalRelationship" return
            (local:get-name($relationship/@mutual), " had a professional relationship.")        
        case "snap:SeriousIntimateRelationshipWith" return
            (local:get-name($relationship/@mutual), " had a serious intimate relationship.")
        case "snap:SiblingOf" return
            (local:get-name($relationship/@mutual), " were siblings.")
        case "snap:SiblingOfParentOf" return
            (local:get-name($relationship/@active), " was the sibling of the parent of ", local:get-name($relationship/@passive),'.')        
        case "snap:SlaveOf" return
            (local:get-name($relationship/@passive), " enslaved ", local:get-name($relationship/@active),'.')        
        case "snap:SpouseOf" return
            (local:get-name($relationship/@mutual), " were spouses.")
        case "syriaca:Baptism" return
            (local:get-name($relationship/@active), " baptized ", local:get-name($relationship/@passive),'.') 
        case "syriaca:BishopOver" return
            (local:get-name($relationship/@active), " had ecclesiastical authority over ", local:get-name($relationship/@passive),'.') 
        case "syriaca:BishopOverBishop" return
            (local:get-name($relationship/@active), " had ecclesiastical authority over the bishop(s) ", local:get-name($relationship/@passive),'.')
        case "syriaca:BishopOverClergy" return
            (local:get-name($relationship/@active), " had ecclesiastical authority over ", local:get-name($relationship/@passive),'.') 
        case "syriaca:BishopOverMonk" return
            (local:get-name($relationship/@active), " had ecclesiastical authority over ", local:get-name($relationship/@passive),'.') 
        case "syriaca:CarrierOfLetterBetween" return
            (local:get-name($relationship/@active), " carried a letter between ", local:get-name($relationship/@passive),'.') 
        case "syriaca:Citation" return
            (local:get-name($relationship/@active), " refered to the writings of ", local:get-name($relationship/@passive),'.')
        case "syriaca:ClergyFor" return
            if(count(local:get-name($relationship/@active)) gt 1) then
                (local:get-name($relationship/@active), " were a clergy for ", local:get-name($relationship/@passive),'.')
            else (local:get-name($relationship/@active), " was a clergy for ", local:get-name($relationship/@passive),'.') 
        case "syriaca:CommandOver" return
            (local:get-name($relationship/@active), " had military command over ", local:get-name($relationship/@passive),'.')
        case "syriaca:Commemoration" return
            (local:get-name($relationship/@active), " commemorated ", local:get-name($relationship/@passive),'.')
        case "syriaca:CommuneTogether" return
            (local:get-name($relationship/@mutual), " shared the Eucharist.")
        case "syriaca:Epistolary" return
            (local:get-name($relationship/@active), " sent a letter to ", local:get-name($relationship/@passive),'.')
        case "syriaca:EpistolaryReferenceTo" return
            ('A letter between ',local:get-name($relationship/@active), " referenced ", local:get-name($relationship/@active),'.')
        case "syriaca:FellowClergy" return
            (local:get-name($relationship/@mutual), " were fellow clergy.")
        case "syriaca:FellowMonastics" return
            (local:get-name($relationship/@mutual), " were monks at the same monastery.") 
        case "syriaca:FollowerOf" return
            if(count(local:get-name($relationship/@active)) gt 1) then
                (local:get-name($relationship/@active), " were followers of ", local:get-name($relationship/@passive),'.')
            else (local:get-name($relationship/@active), " was a follower of ", local:get-name($relationship/@passive),'.') 
        case "syriaca:Judged" return
            (local:get-name($relationship/@active), " heard a legal case against ", local:get-name($relationship/@passive),'.') 
        case "syriaca:LegalChargesAgainst" return
            (local:get-name($relationship/@active), " brought legal charges or a petition against ", local:get-name($relationship/@passive),'.') 
        case "syriaca:MemberOfGroup" return
        if(count(local:get-name($relationship/@active)) gt 1) then
            (local:get-name($relationship/@active), " were part of ", local:get-name($relationship/@passive),'.')
        else (local:get-name($relationship/@active), " was part of ", local:get-name($relationship/@passive),'.') 
        case "syriaca:MonasticHeadOver" return
            (local:get-name($relationship/@active), " was a monastic authority over ", local:get-name($relationship/@passive),'.')
        case "syriaca:Ordination" return
            (local:get-name($relationship/@active), " ordained ", local:get-name($relationship/@passive),'.') 
        case "syriaca:PatronOf" return
            (local:get-name($relationship/@active), " acted as patron of ", local:get-name($relationship/@passive),'.')
        case "syriaca:Petitioned" return
            (local:get-name($relationship/@active), " made a petition to or sought a legal ruling from ", local:get-name($relationship/@passive),'.') 
        case "syriaca:StudentOf" return
            (local:get-name($relationship/@active), " studied under ", local:get-name($relationship/@passive),'.')
        case "syriaca:SenderOfLetterTo" return
            (local:get-name($relationship/@active), " sent a letter to ", local:get-name($relationship/@passive),'.')
        default return 
           let $default-name := 
                if(contains($relationship-name,':')) then 
                    substring-after($relationship-name,':')
                else $relationship-name
            let $name := functx:camel-case-to-words(replace($default-name,'-',' '),' ')
            return (local:get-name($relationship/@active)," ", $name," " , local:get-name($relationship/@passive),'.')
};
    
for $rec in collection('/db/apps/srophe-data/data/spear')//tei:TEI[descendant::tei:relation]
let $change :=             
        <change xmlns="http://www.tei-c.org/ns/1.0" who="http://syriaca.org/documentation/editors.xml#{$editor}" when="{current-date()}">{$changeLog}</change>
return
    (update insert $change
          preceding $rec/descendant::tei:revisionDesc/tei:change[1],
          update value $rec/descendant::tei:fileDesc/tei:publicationStmt/tei:date with current-date(),
        local:relation-text($rec))
    