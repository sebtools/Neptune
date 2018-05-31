<cfcomponent output="false">

<cffunction name="init" access="public" returntype="any" output="false" hint="I initialize and return the component.">
	<cfargument name="AWS" type="any" required="true">
	<cfargument name="subdomain" type="string" required="true">
	
	<cfset initInternal(ArgumentCollection=Arguments)>

	<cfreturn This>
</cffunction>

<cffunction name="initInternal" access="public" returntype="any" output="false" hint="I initialize and return the component.">
	<cfargument name="AWS" type="any" required="true">
	<cfargument name="subdomain" type="string" required="true">
	
	<cfset Variables.AWS = Arguments.AWS>
	<cfset Variables.subdomain = Arguments.subdomain>

	<cfset Variables.MrECache = Variables.AWS.MrECache>
	<cfset Variables.RateLimiter = Variables.AWS.RateLimiter>

	<cfset Variables.LockID = Variables.AWS.getLockID()>

</cffunction>

<cffunction name="onMissingMethod" access="public" returntype="any" output="false" hint="">
	<cfreturn Variables.AWS.callAPI(
		subdomain=Variables.subdomain,
		Action=Arguments["missingMethodName"],
		parameters=Arguments.missingMethodArguments
	)>
</cffunction>

<cffunction name="callAPI" access="private" returntype="any" output="false" hint="I invoke an Amazon REST Call.">
	<cfargument name="Action" type="string" required="true" hint="The AWS API action being called.">
	<cfargument name="method" type="string" default="GET" hint="The HTTP method to invoke.">
	<cfargument name="parameters" type="struct" default="#structNew()#" hint="An struct of HTTP URL parameters to send in the request.">

	<cfset Arguments.subdomain = Variables.subdomain>

	<cfreturn Variables.AWS.callAPI(ArgumentCollection=Arguments)>
</cffunction>

<cffunction name="callLimitedAPI" access="private" returntype="struct" output="false" hint="I invoke an Amazon REST Call.">
	<cfargument name="Action" type="string" required="true" hint="The AWS API action being called.">
	<cfargument name="method" type="string" default="GET" hint="The HTTP method to invoke.">
	<cfargument name="parameters" type="struct" default="#structNew()#" hint="An struct of HTTP URL parameters to send in the request.">

	<cfset Arguments.subdomain = Variables.subdomain>

	<cfreturn Variables.AWS.callLimitedAPI(ArgumentCollection=Arguments)>
</cffunction>

<cfscript>
function AWSTime2CFTime(str) {
	if ( REFindNoCase("^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z",str) ) {
		return DateAdd("d",0,Trim(REReplaceNoCase(str,"(T|Z)"," ","ALL")));
	} else {
		return Trim(str);
	}
}
</cfscript>

</cfcomponent>