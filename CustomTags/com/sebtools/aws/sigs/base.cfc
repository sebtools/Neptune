<cfcomponent displayname="Amazon Signature Version Base Component" output="false">

<cffunction name="init" access="public" returntype="any" output="false" hint="I initialize and return the component.">
	<cfargument name="AWS" type="any" required="true">

	<cfset var key = "">

	<cfloop collection="#Arguments#" item="key">
		<cfset Variables[key] = Arguments[key]>
		<cfif isObject(Arguments[key])>
			<cfset This[key] = Arguments[key]>
		</cfif>
	</cfloop>

	<cfreturn This>
</cffunction>

<cffunction name="getRequest" access="public" returntype="struct" output="false" hint="I return the raw(ish) results of Amazon REST Call.">
	<cfargument name="subdomain" type="string" required="true" hint="The subdomain for the AWS service being used.">
	<cfargument name="Action" type="string" required="true" hint="The AWS API action being called.">
	<cfargument name="method" type="string" default="GET" hint="The HTTP method to invoke.">
	<cfargument name="parameters" type="struct" default="#structNew()#" hint="An struct of HTTP URL parameters to send in the request.">
	<cfargument name="timeout" type="numeric" default="20" hint="The default call timeout.">

	<cfscript>
	var timestamp = makeTimeStamp();
	var paramtype = "URL";
	var sortedParams = "";
	var EndPointURL = Variables.AWS.getEndPointUrl(Arguments.subdomain);
	var NamedArgs = "subdomain,Action,method,parameters,timeout";
	var arg = "";
	var param = "";
	var sRequest = {};

	for (arg in Arguments) {
		if ( isSimpleValue(Arguments[arg]) AND Len(Trim(Arguments[arg])) AND NOT ListFindNoCase(NamedArgs,arg) ) {
			if ( ListLen(EndPointURL,"?") EQ 1 ) {
				EndPointURL &= "?";
			} else {
				EndPointURL &= "&";
			}
			EndPointURL &= "#arg#=#Trim(Arguments[arg])#";
		}
	}

	Arguments.parameters["Action"] = Arguments.Action;

	sortedParams = ListSort(StructKeyList(Arguments.parameters), "textnocase");

	if( Arguments.method IS "POST" ) {
		paramtype = "FORMFIELD";
	}

	sRequest = {
		method="#arguments.method#",
		url="#EndPointURL#",
		charset="utf-8",
		timeout="#arguments.timeout#",
		headers = {
			"Date":timestamp,
			"host":Variables.AWS.getHost(Arguments.subdomain)
		},
		params=[]
	};
	</cfscript>
	<cfloop list="#sortedParams#" index="param">
		<cfset ArrayAppend(
			sRequest.params,
			{type="#paramType#",name="#param#",value="#trim(arguments.parameters[param])#"}
		)>
	</cfloop>

	<cfreturn sRequest>
</cffunction>

<cffunction name="createSignature" access="public" returntype="any" output="false" hint="Create request signature according to AWS standards">
	<cfargument name="string" type="any" required="true" />

	<cfthrow message="Method must be created in the signature component.">
</cffunction>

<cffunction name="getAccessKey" access="public" returntype="string" output="false" hint="I get the Amazon access key.">
	 <cfreturn Variables.AWS.getAccessKey()>
</cffunction>

<cffunction name="getRegion" access="public" returntype="string" output="false" hint="I get the region for AWS Service.">

	<cfreturn Variables.AWS.getRegion()>
</cffunction>

<cffunction name="getSecretKey" access="public" returntype="string" output="false" hint="I get the Amazon access key.">
	 <cfreturn Variables.AWS.getSecretKey()>
</cffunction>

<cffunction name="getAuthorizationString" access="public" returntype="string" output="false" hint="I return the authorization string.">
	<cfargument name="timestamp" type="string" required="false">

	<cfthrow message="Method must be created in the signature component.">
</cffunction>

<cffunction name="makeTimeStamp" access="public" returntype="string" output="false">
	<cfreturn GetHTTPTimeString(Now())>
</cffunction>

<cffunction name="HMAC_SHA256" access="private" returntype="binary" output="false" hint="">
	<cfargument name="signKey" type="string" required="true">
	<cfargument name="signMessage" type="string" required="true">

	<cfscript>
	var jMsg = JavaCast("string",Arguments.signMessage).getBytes("utf-8");
	var jKey = JavaCast("string",Arguments.signKey).getBytes("utf-8");
	var key = createObject("java","javax.crypto.spec.SecretKeySpec").init(jKey,"HmacSHA256");
	var mac = createObject("java","javax.crypto.Mac").getInstance(key.getAlgorithm());
	mac.init(key);
	mac.update(jMsg);

	return mac.doFinal();
	</cfscript>
</cffunction>

<!---
<OWNER> = James Solo
<YEAR> = 2013

In the original BSD license, both occurrences of the phrase "COPYRIGHT HOLDERS AND CONTRIBUTORS" in the disclaimer read "REGENTS AND CONTRIBUTORS".

Here is the license template:

Copyright (c) 2013, James Solo
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

--->
<cffunction name="HMAC_SHA256_bin" access="public" returntype="binary" output="false" hint="THIS WORKS DO NOT FUCK WITH IT.">
	<cfargument name="signMessage"    type="string" required="true" />
	<cfargument name="signKey"        type="binary" required="true" />

	<cfset var jMsg = JavaCast("string",arguments.signMessage).getBytes("UTF8") />
	<cfset var jKey = arguments.signKey />

	<cfset var key = createObject("java","javax.crypto.spec.SecretKeySpec") />
	<cfset var mac = createObject("java","javax.crypto.Mac") />

	<cfset key = key.init(jKey,"HmacSHA256") />

	<cfset mac = mac.getInstance(key.getAlgorithm()) />
	<cfset mac.init(key) />
	<cfset mac.update(jMsg) />

	<cfreturn mac.doFinal() />
</cffunction>

</cfcomponent>
