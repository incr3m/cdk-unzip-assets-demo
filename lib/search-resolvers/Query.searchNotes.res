
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
  ## Authorization rule: { allow: groups, groups: ["common.*"], groupClaim: "cognito:groups" } **
  #set( $userGroups = $util.defaultIfNull($ctx.identity.claims.get("cognito:groups"), []) )
  #set( $allowedGroups = ["common.*"] )
  #foreach( $userGroup in $userGroups )
    #if( $allowedGroups.contains($userGroup) )
      #set( $isStaticGroupAuthorized = true )
      #break
    #end
  #end
  ## Authorization rule: { allow: groups, groups: ["common.read"], groupClaim: "cognito:groups" } **
  #set( $userGroups = $util.defaultIfNull($ctx.identity.claims.get("cognito:groups"), []) )
  #set( $allowedGroups = ["common.read"] )
  #foreach( $userGroup in $userGroups )
    #if( $allowedGroups.contains($userGroup) )
      #set( $isStaticGroupAuthorized = true )
      #break
    #end
  #end
  ## Authorization rule: { allow: groups, groups: ["common.note.*"], groupClaim: "cognito:groups" } **
  #set( $userGroups = $util.defaultIfNull($ctx.identity.claims.get("cognito:groups"), []) )
  #set( $allowedGroups = ["common.note.*"] )
  #foreach( $userGroup in $userGroups )
    #if( $allowedGroups.contains($userGroup) )
      #set( $isStaticGroupAuthorized = true )
      #break
    #end
  #end
  ## Authorization rule: { allow: groups, groups: ["common.note.read"], groupClaim: "cognito:groups" } **
  #set( $userGroups = $util.defaultIfNull($ctx.identity.claims.get("cognito:groups"), []) )
  #set( $allowedGroups = ["common.note.read"] )
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
      ## [Start] Dynamic Group Authorization Checks **
      #set( $isLocalDynamicGroupAuthorized = false )
      ## Authorization rule: { allow: groups, groupsField: "recGroupEditors", groupClaim: "cognito:groups" } **
      #set( $allowedGroups = $util.defaultIfNull($item.recGroupEditors, []) )
      #set( $userGroups = $util.defaultIfNull($ctx.identity.claims.get("cognito:groups"), []) )
      #foreach( $userGroup in $userGroups )
        #if( $util.isList($allowedGroups) )
          #if( $allowedGroups.contains($userGroup) )
            #set( $isLocalDynamicGroupAuthorized = true )
          #end
        #end
        #if( $util.isString($allowedGroups) )
          #if( $allowedGroups == $userGroup )
            #set( $isLocalDynamicGroupAuthorized = true )
          #end
        #end
      #end
      ## Authorization rule: { allow: groups, groupsField: "recGroupViewers", groupClaim: "cognito:groups" } **
      #set( $allowedGroups = $util.defaultIfNull($item.recGroupViewers, []) )
      #set( $userGroups = $util.defaultIfNull($ctx.identity.claims.get("cognito:groups"), []) )
      #foreach( $userGroup in $userGroups )
        #if( $util.isList($allowedGroups) )
          #if( $allowedGroups.contains($userGroup) )
            #set( $isLocalDynamicGroupAuthorized = true )
          #end
        #end
        #if( $util.isString($allowedGroups) )
          #if( $allowedGroups == $userGroup )
            #set( $isLocalDynamicGroupAuthorized = true )
          #end
        #end
      #end
      ## [End] Dynamic Group Authorization Checks **


      ## [Start] Owner Authorization Checks **
      #set( $isLocalOwnerAuthorized = false )
      ## Authorization rule: { allow: owner, ownerField: "recOwner", identityClaim: "custom:id" } **
      #set( $allowedOwners0 = $util.defaultIfNull($item.recOwner, []) )
      #set( $identityValue = $util.defaultIfNull($ctx.identity.claims.get("custom:id"), "___xamznone____") )
      #if( $util.isList($allowedOwners0) )
        #foreach( $allowedOwner in $allowedOwners0 )
          #if( $allowedOwner == $identityValue )
            #set( $isLocalOwnerAuthorized = true )
          #end
        #end
      #end
      #if( $util.isString($allowedOwners0) )
        #if( $allowedOwners0 == $identityValue )
          #set( $isLocalOwnerAuthorized = true )
        #end
      #end
      ## Authorization rule: { allow: owner, ownerField: "recEditors", identityClaim: "custom:id" } **
      #set( $allowedOwners1 = $util.defaultIfNull($item.recEditors, []) )
      #set( $identityValue = $util.defaultIfNull($ctx.identity.claims.get("custom:id"), "___xamznone____") )
      #if( $util.isList($allowedOwners1) )
        #foreach( $allowedOwner in $allowedOwners1 )
          #if( $allowedOwner == $identityValue )
            #set( $isLocalOwnerAuthorized = true )
          #end
        #end
      #end
      #if( $util.isString($allowedOwners1) )
        #if( $allowedOwners1 == $identityValue )
          #set( $isLocalOwnerAuthorized = true )
        #end
      #end
      ## Authorization rule: { allow: owner, ownerField: "recViewers", identityClaim: "custom:id" } **
      #set( $allowedOwners2 = $util.defaultIfNull($item.recViewers, []) )
      #set( $identityValue = $util.defaultIfNull($ctx.identity.claims.get("custom:id"), "___xamznone____") )
      #if( $util.isList($allowedOwners2) )
        #foreach( $allowedOwner in $allowedOwners2 )
          #if( $allowedOwner == $identityValue )
            #set( $isLocalOwnerAuthorized = true )
          #end
        #end
      #end
      #if( $util.isString($allowedOwners2) )
        #if( $allowedOwners2 == $identityValue )
          #set( $isLocalOwnerAuthorized = true )
        #end
      #end
      ## Authorization rule: { allow: owner, ownerField: "recOwner", identityClaim: "custom:id" } **
      #set( $allowedOwners3 = $util.defaultIfNull($item.recOwner, []) )
      #set( $identityValue = $util.defaultIfNull($ctx.identity.claims.get("custom:id"), "___xamznone____") )
      #if( $util.isList($allowedOwners3) )
        #foreach( $allowedOwner in $allowedOwners3 )
          #if( $allowedOwner == $identityValue )
            #set( $isLocalOwnerAuthorized = true )
          #end
        #end
      #end
      #if( $util.isString($allowedOwners3) )
        #if( $allowedOwners3 == $identityValue )
          #set( $isLocalOwnerAuthorized = true )
        #end
      #end
      ## Authorization rule: { allow: owner, ownerField: "recEditors", identityClaim: "custom:id" } **
      #set( $allowedOwners4 = $util.defaultIfNull($item.recEditors, []) )
      #set( $identityValue = $util.defaultIfNull($ctx.identity.claims.get("custom:id"), "___xamznone____") )
      #if( $util.isList($allowedOwners4) )
        #foreach( $allowedOwner in $allowedOwners4 )
          #if( $allowedOwner == $identityValue )
            #set( $isLocalOwnerAuthorized = true )
          #end
        #end
      #end
      #if( $util.isString($allowedOwners4) )
        #if( $allowedOwners4 == $identityValue )
          #set( $isLocalOwnerAuthorized = true )
        #end
      #end
      ## Authorization rule: { allow: owner, ownerField: "recViewers", identityClaim: "custom:id" } **
      #set( $allowedOwners5 = $util.defaultIfNull($item.recViewers, []) )
      #set( $identityValue = $util.defaultIfNull($ctx.identity.claims.get("custom:id"), "___xamznone____") )
      #if( $util.isList($allowedOwners5) )
        #foreach( $allowedOwner in $allowedOwners5 )
          #if( $allowedOwner == $identityValue )
            #set( $isLocalOwnerAuthorized = true )
          #end
        #end
      #end
      #if( $util.isString($allowedOwners5) )
        #if( $allowedOwners5 == $identityValue )
          #set( $isLocalOwnerAuthorized = true )
        #end
      #end
      ## [End] Owner Authorization Checks **


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