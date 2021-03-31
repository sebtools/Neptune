<cfcomponent displayname="Amazon Signature Version 3" extends="base" output="false">

<cffunction name="getRequest" access="public" returntype="struct" output="false" hint="I return the raw(ish) results of Amazon REST Call.">
	<cfargument name="subdomain" type="string" required="true" hint="The subdomain for the AWS service being used.">
	<cfargument name="Action" type="string" required="true" hint="The AWS API action being called.">
	<cfargument name="method" type="string" default="GET" hint="The HTTP method to invoke.">
	<cfargument name="parameters" type="struct" default="#structNew()#" hint="An struct of HTTP URL parameters to send in the request.">
	<cfargument name="timeout" type="numeric" default="20" hint="The default call timeout.">

	<cfscript>
	var sRequest = Super.getRequest(ArgumentCollection=Arguments);
	var timestamp = sRequest.headers["Date"];

	sRequest["Headers"]["X-Amzn-Authorization"] = getAuthorizationString(timestamp);
	</cfscript>

	<cfreturn sRequest>
</cffunction>

<cffunction name="getAuthorizationString" access="public" returntype="string" output="false" hint="I return the authorization string.">
	<cfargument name="timestamp" type="string" required="false">

	<cfif NOT StructKeyExists(Arguments,"timestamp")>
		<cfset Arguments.timestamp = makeTimeStamp()>
	</cfif>

	<cfreturn "AWS3-HTTPS AWSAccessKeyId=#getAccessKey()#,Algorithm=HmacSHA256,Signature=#createSignature(Arguments.timestamp)#">
</cffunction>

<cffunction name="createSignature" access="public" returntype="any" output="false" hint="Create request signature according to AWS standards">
	<cfargument name="string" type="any" required="true" />

	<cfset var fixedData = Replace(Arguments.string,"\n","#chr(10)#","all")>

	<cfreturn toBase64(HMAC_SHA256(getSecretKey(),fixedData) )>
</cffunction>

<cffunction name="makeTimeStamp" access="public" returntype="string" output="false">
	<cfreturn GetHTTPTimeString(Now())>
</cffunction>

</cfcomponent>
