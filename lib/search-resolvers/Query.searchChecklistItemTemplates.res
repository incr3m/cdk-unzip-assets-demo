
#set( $es_items = [] )
#foreach( $entry in $context.result.hits.hits )
  #if( !$foreach.hasNext )
    #set( $nextToken = $entry.sort.get(0) )
  #end
  $util.qr($es_items.add($entry.get("_source")))
#end

## [Start] Determine request authentication mode **
#if( $util.isNullOrEmpty($authMode) && !$util.isNull($ctx.identity) && !$util.isNull($ctx.identity.sub) && !$util.isNull($ctx.identity.issuer) && !$util.isNull($ctx.identity.username) && !$util.isNull($ctx.identity.claims) && !$util.isNull($ctx.identity.sourceIp) && !$util.isNull($ctx.identity.defaultAuthStrategy) )
  #set( $authMode = "userPools" )
#end
## [End] Determine request authentication mode **
## [Start] Check authMode and execute owner/group checks **
#if( $authMode == "userPools" )
  ## [Start] Static Group Authorization Checks **
  #set($isStaticGroupAuthorized = $util.defaultIfNull(
            $isStaticGroupAuthorized, false))
  ## Authorization rule: { allow: groups, groups: ["admin","editor"], groupClaim: "cognito:groups" } **
  #set( $userGroups = $util.defaultIfNull($ctx.identity.claims.get("cognito:groups"), []) )
  #set( $allowedGroups = ["admin", "editor"] )
  #foreach( $userGroup in $userGroups )
    #if( $allowedGroups.contains($userGroup) )
      #set( $isStaticGroupAuthorized = true )
      #break
    #end
  #end
  ## Authorization rule: { allow: groups, groups: ["checklist.*"], groupClaim: "cognito:groups" } **
  #set( $userGroups = $util.defaultIfNull($ctx.identity.claims.get("cognito:groups"), []) )
  #set( $allowedGroups = ["checklist.*"] )
  #foreach( $userGroup in $userGroups )
    #if( $allowedGroups.contains($userGroup) )
      #set( $isStaticGroupAuthorized = true )
      #break
    #end
  #end
  ## Authorization rule: { allow: groups, groups: ["checklist.read"], groupClaim: "cognito:groups" } **
  #set( $userGroups = $util.defaultIfNull($ctx.identity.claims.get("cognito:groups"), []) )
  #set( $allowedGroups = ["checklist.read"] )
  #foreach( $userGroup in $userGroups )
    #if( $allowedGroups.contains($userGroup) )
      #set( $isStaticGroupAuthorized = true )
      #break
    #end
  #end
  ## Authorization rule: { allow: groups, groups: ["checklist.checklistitemtemplate.*"], groupClaim: "cognito:groups" } **
  #set( $userGroups = $util.defaultIfNull($ctx.identity.claims.get("cognito:groups"), []) )
  #set( $allowedGroups = ["checklist.checklistitemtemplate.*"] )
  #foreach( $userGroup in $userGroups )
    #if( $allowedGroups.contains($userGroup) )
      #set( $isStaticGroupAuthorized = true )
      #break
    #end
  #end
  ## Authorization rule: { allow: groups, groups: ["checklist.checklistitemtemplate.read"], groupClaim: "cognito:groups" } **
  #set( $userGroups = $util.defaultIfNull($ctx.identity.claims.get("cognito:groups"), []) )
  #set( $allowedGroups = ["checklist.checklistitemtemplate.read"] )
  #foreach( $userGroup in $userGroups )
    #if( $allowedGroups.contains($userGroup) )
      #set( $isStaticGroupAuthorized = true )
      #break
    #end
  #end
  ## [End] Static Group Authorization Checks **


  ## [Start] If not static group authorized, filter items **
  #if( !$isStaticGroupAuthorized )
    #set( $items = [] )
    #foreach( $item in $es_items )
      ## No Dynamic Group Authorization Rules **


      ## No Owner Authorization Rules **


      #if( ($isLocalDynamicGroupAuthorized == true || $isLocalOwnerAuthorized == true) )
        $util.qr($items.add($item))
      #end
    #end
    #set( $es_items = $items )
  #end
  ## [End] If not static group authorized, filter items **
#end
## [End] Check authMode and execute owner/group checks **



#set( $es_response = {
  "items": $es_items
} )
#if( $es_items.size() > 0 )
  $util.qr($es_response.put("nextToken", $nextToken))
  $util.qr($es_response.put("total", $es_items.size()))
#end
$util.toJson($es_response)