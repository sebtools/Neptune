<cfcomponent displayname="AWS" output="false">

<cffunction name="init" access="public" returntype="any" output="false" hint="I initialize and return the component.">
	<cfargument name="Credentials" type="any" required="true" hint="AWS Credentials.">
	<cfargument name="region" type="string" required="false" hint="The AWS region.">

	<cfset var key = "">

	<cfloop collection="#Arguments#" item="key">
		<cfset Variables[key] = Arguments[key]>
		<cfif isObject(Arguments[key])>
			<cfset This[key] = Arguments[key]>
		</cfif>
	</cfloop>

	<!--- If region is not explicitely set, use the region from the credentials (if there is one). --->
	<cfif NOT StructKeyExists(Variables,"region")>
		<cfif Variables.Credentials.has("region")>
			<cfset Variables.region = Variables.Credentials.get("region")>
		</cfif>
	</cfif>

	<!--- Make sure needed credentials exist. --->
	<cfif NOT ( Variables.Credentials.has("AccessKey") AND Variables.Credentials.has("SecretKey") )>
		<cfthrow message="AWS requires AWS credentials (AccessKey,SecretKey)." type="AWS">
	</cfif>

	<!--- Make sure region is set. --->
	<cfif NOT Variables.Credentials.has("region")>
		<cfthrow message="AWS region has not been indicated." type="AWS">
	</cfif>

	<cfset Variables.LockID = Hash(getAccessKey())>

	<cfset Variables.MrECache = CreateObject("component","MrECache").init("AWS:#Variables.LockID#")>
	<cfset This.MrECache = Variables.MrECache>

	<cfset Variables.RateLimiter = CreateObject("component","RateLimiter").init("AWS:#Variables.LockID#")>
	<cfset This.RateLimiter = Variables.RateLimiter>

	<cfset Variables.sServices = StructNew()>

	<cfreturn This>
</cffunction>

<cffunction name="getService" access="public" returntype="any" output="false" hint="I get the requested AWS service.">
	<cfargument name="service" type="string" required="true">

	<cfif NOT StructKeyExists(Variables.sServices,Arguments.service)>
		<cfset Variables.sServices[Arguments.service] = CreateObject("component","aws.#LCase(Arguments.service)#").init(This)>
	</cfif>

	 <cfreturn Variables.sServices[Arguments.service]>
</cffunction>

<cffunction name="getLockID" access="public" returntype="any" output="false" hint="I get the LockID used by this instance of AWS.">
	 <cfreturn Variables.LockID>
</cffunction>

<cffunction name="getCredentials" access="public" returntype="any" output="false" hint="I get the Amazon credentials.">
	 <cfreturn Variables.Credentials>
</cffunction>

<cffunction name="getAccessKey" access="public" returntype="string" output="false" hint="I get the Amazon access key.">
	 <cfreturn Variables.Credentials.get("AccessKey")>
</cffunction>

<cffunction name="getSecretKey" access="public" returntype="string" output="false" hint="I get the Amazon secret key.">
	 <cfreturn Variables.Credentials.get("SecretKey")>
</cffunction>

<cffunction name="getEndPointUrl" access="public" returntype="string" output="false" hint="I get the endpoint for AWS Service.">
	<cfargument name="subdomain" type="string" required="true" hint="The subdomain for the AWS service being used.">

	<cfreturn "https://#getHost(Arguments.subdomain)#/">
</cffunction>

<cffunction name="getHost" access="public" returntype="string" output="false" hint="I get the host for AWS Service.">
	<cfargument name="subdomain" type="string" required="true" hint="The subdomain for the AWS service being used.">

	<cfreturn "#Arguments.subdomain#.#Variables.region#.amazonaws.com">
</cffunction>

<cffunction name="getRegion" access="public" returntype="string" output="false" hint="I get the region for AWS Service.">

	<cfreturn Variables.region>
</cffunction>

<cffunction name="isCallable" access="public" returntype="boolean" output="false" hint="I determine if the action can be called.">
	<cfargument name="subdomain" type="string" required="true" hint="The subdomain for the AWS service being used.">
	<cfargument name="Action" type="string" required="true" hint="The AWS API action being called.">

	<cfreturn Variables.RateLimiter.isCallable("#Arguments.subdomain#_#Arguments.Action#")>
</cffunction>

<cffunction name="callLimitedAPI" access="public" returntype="any" output="false" hint="I return the results of Amazon REST Call in the form easiest to use.">
	<cfargument name="subdomain" type="string" required="true" hint="The subdomain for the AWS service being used.">
	<cfargument name="Action" type="string" required="true" hint="The AWS API action being called.">
	<cfargument name="default" type="any" required="false" hint="The value to return if within the rate limit.">
	<cfargument name="method" type="string" default="GET" hint="The HTTP method to invoke.">
	<cfargument name="parameters" type="struct" default="#structNew()#" hint="An struct of HTTP URL parameters to send in the request.">
	<cfargument name="timeout" type="numeric" default="20" hint="The default call timeout.">
	<cfargument name="timeSpan" type="string" required="false">
	<cfargument name="idleTime" type="string" required="false">

	<cfset var sArgs = {
		id="#Arguments.subdomain#_#Arguments.Action#",
		Component=This,
		MethodName="callAPI",
		Args=Arguments
	}>

	<cfif StructKeyExists(Arguments,"default")>
		<cfset sArgs["default"] = Arguments.default>
	</cfif>
	<cfif StructKeyExists(Arguments,"timeSpan")>
		<cfset sArgs["timeSpan"] = Arguments.timeSpan>
	</cfif>
	<cfif StructKeyExists(Arguments,"idleTime")>
		<cfset sArgs["idleTime"] = Arguments.idleTime>
	</cfif>

	<cfif StructKeyExists(Arguments,"timeSpan")>
		<cfreturn Variables.RateLimiter.cached(ArgumentCollection=sArgs)>
	<cfelse>
		<cfreturn Variables.RateLimiter.method(ArgumentCollection=sArgs)>
	</cfif>
</cffunction>

<cffunction name="callAPI" access="public" returntype="any" output="false" hint="I return the results of Amazon REST Call in the form easiest to use.">
	<cfargument name="subdomain" type="string" required="true" hint="The subdomain for the AWS service being used.">
	<cfargument name="Action" type="string" required="true" hint="The AWS API action being called.">
	<cfargument name="method" type="string" default="GET" hint="The HTTP method to invoke.">
	<cfargument name="parameters" type="struct" default="#structNew()#" hint="An struct of HTTP URL parameters to send in the request.">
	<cfargument name="timeout" type="numeric" default="20" hint="The default call timeout.">

	<cfset var response = _callAPI(ArgumentCollection=Arguments)>
	<cfset var response_result = 0>
	<cfset var result = 0>
	<cfset var ii = 0>

	<cfscript>
	// Traverse down the response tree to get the most accurate result possible.
	if ( StructKeyExists(response,"RESPONSE") ) {
		if ( isSimpleValue(response["RESPONSE"]) ) {
			response_result = response["RESPONSE"];
		} else if ( StructKeyExists(response["RESPONSE"],"#Arguments.Action#Response") ) {
			if ( StructKeyExists(response["RESPONSE"]["#Arguments.Action#Response"],"#Arguments.Action#Result") ) {
				response_result = response["RESPONSE"]["#Arguments.Action#Response"]["#Arguments.Action#Result"];
				//If the result has no attributes or text and just one child, return that.
				if ( ArrayLen(response_result.XmlChildren) EQ 1 AND NOT Len(Trim(response_result.XmlText)) AND NOT StructCount(response_result.XmlAttributes) ) {
					response_result = response_result.XmlChildren[1];
				}
			} else {
				if ( isXml(response["RESPONSE"]["#Arguments.Action#Response"]) AND response["RESPONSE"]["#Arguments.Action#Response"].XmlName EQ "#Arguments.Action#Result" ) {
					response_result = response["RESPONSE"]["#Arguments.Action#Response"].XmlChildren;
				} else {
					response_result = response["RESPONSE"]["#Arguments.Action#Response"];
				}	
			}
		} else {
			response_result = response["RESPONSE"];
		}
	} else {
		response_result = response;
	}

	if ( isSimpleValue(response_result) ) {
		return response_result;
	}
	
	//If we get an error response from AWS, throw that as an exception.
	if ( StructKeyExists(response_result,"ErrorResponse") ) {
		throwError(Message=response_result.ErrorResponse.Error.Message.XmlText,errorcode=response_result.ErrorResponse.Error.Code.XmlText);
	}
	
	//If the XML response has children, but no attributes then we can safely return the children as a struct.
	if (
				isXml(response_result)
			AND	StructKeyExists(response_result,"XmlChildren")
			AND	ArrayLen(response_result.XmlChildren)
			AND	NOT StructCount(response_result.XmlAttributes)
			AND	Len(Trim(response_result.XmlChildren[1].XmlText))
			AND	NOT StructCount(response_result.XmlChildren[1].XmlAttributes)
		) {
			//One element, return the string. Otherwise: If every element is the same, then make an array. Otherwise, a structure.
			if ( ArrayLen(response_result.XmlChildren) EQ 1 ) {
				result = response_result.XmlChildren[1].XmlText;
			} else if ( ArrayLen(response_result.XmlChildren) EQ ArrayLen(response_result[response_result.XmlChildren[1].XmlName]) ) {
				result = [];
				ArrayResize(result, ArrayLen(response_result.XmlChildren));
				for ( ii=1; ii <= ArrayLen(response_result.XmlChildren); ii=ii+1 ) {
					result[ii] = response_result.XmlChildren[ii].XmlText;
				}
			} else {
				result = {};
				for ( ii=1; ii <= ArrayLen(response_result.XmlChildren); ii=ii+1 ) {
					result[response_result.XmlChildren[ii].XmlName] = response_result.XmlChildren[ii].XmlText;
				}
			}
	} else {
		result = response_result;
	}
	</cfscript>

	<cfreturn result>
</cffunction>

<cffunction name="_callAPI" access="public" returntype="struct" output="false" hint="I return the raw(ish) results of Amazon REST Call.">
	<cfargument name="subdomain" type="string" required="true" hint="The subdomain for the AWS service being used.">
	<cfargument name="Action" type="string" required="true" hint="The AWS API action being called.">
	<cfargument name="method" type="string" default="GET" hint="The HTTP method to invoke.">
	<cfargument name="parameters" type="struct" default="#structNew()#" hint="An struct of HTTP URL parameters to send in the request.">
	<cfargument name="timeout" type="numeric" default="20" hint="The default call timeout.">
	
	<cfscript>
	var results = {};
	var HTTPResults = "";
	var timestamp = GetHTTPTimeString(Now());
	var paramtype = "URL";
	var sortedParams = "";
	var EndPointURL = getEndPointUrl(Arguments.subdomain);
	var NamedArgs = "subdomain,Action,method,parameters,timeout";
	var arg = "";

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
	
	results.error = false;
	results.response = {};
	results.message ="";
	results.responseheader = {};
	</cfscript>
	
	<cf_http
		method="#arguments.method#"
		url="#EndPointURL#"
		charset="utf-8"
		result="HTTPResults"
		timeout="#arguments.timeout#"
	>
		<cf_httpparam type="header" name="Date" value="#timestamp#" />
		<cf_httpparam type="header" name="Host" value="#getHost(Arguments.subdomain)#" />
		<cf_httpparam type="header" name="X-Amzn-Authorization" value="AWS3-HTTPS AWSAccessKeyId=#getAccessKey()#,Algorithm=HmacSHA256,Signature=#createSignature(timestamp)#" />

		<cfloop list="#sortedParams#" index="param">
			<cf_httpparam type="#paramType#" name="#param#" value="#trim(arguments.parameters[param])#" />
		</cfloop>
	</cf_http>
	
	<cfscript>
	results["Method"] = Arguments.method;
	results["URL"] = EndPointURL;
	results["Host"] = getHost(Arguments.subdomain);
	if ( StructKeyExists(HTTPResults,"fileContent") ) {
		results.response = HTTPResults.fileContent;
	} else {
		results.response = "";
	}
	results.responseHeader = HTTPResults.responseHeader;
	results.message = HTTPResults.errorDetail;
	if( Len(HTTPResults.errorDetail) ) {
		results.error = true;
	}
	
	if (
				StructKeyExists(HTTPResults.responseHeader, "content-type")
			AND	HTTPResults.responseHeader["content-type"] EQ "text/xml"
			AND	isXML(HTTPResults.fileContent)
		) {
		results.response = XMLParse(HTTPResults.fileContent);
		// Check for Errors
		if( NOT listFindNoCase("200,204",HTTPResults.responseHeader.status_code) ) {
			// check error xml
			results.error = true;
			results.message = "Type:#results.response.errorresponse.error.Type.XMLText# Code: #results.response.errorresponse.error.code.XMLText#. Message: #results.response.errorresponse.error.message.XMLText#";
		}
	}

	if(
			NOT results.error
		AND structKeyExists(HTTPResults,"responseHeader")
		AND structKeyExists(HTTPResults.responseHeader,"status_code")
		AND NOT listFindNoCase("200,204",HTTPResults.responseHeader.status_code)
	) {
		results.error = true;
		if ( isXML(HTTPResults.fileContent) ) {
			results.response = XMLParse(HTTPResults.fileContent);
			results.aMessage = XmlSearch(results.response,"//Message");
			if ( ArrayLen(results.aMessage) ) {
				results.message = results.aMessage[1].XmlText;
			}
			StructDelete(results,"aMessage");
		} else {
			results.message = HTTPResults.fileContent;
		}
		throwError(results.message);
	}

	return results;
	</cfscript>
</cffunction>

<cffunction name="createSignature" returntype="any" access="public" output="false" hint="Create request signature according to AWS standards">
	<cfargument name="string" type="any" required="true" />

	<cfset var fixedData = Replace(Arguments.string,"\n","#chr(10)#","all")>
	
	<cfreturn toBase64(HMAC_SHA256(getSecretKey(),fixedData) )>
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

<cffunction name="throwError" access="public" returntype="void" output="false" hint="">
	<cfargument name="message" type="string" required="yes">
	<cfargument name="errorcode" type="string" default="">
	<cfargument name="detail" type="string" default="">
	<cfargument name="extendedinfo" type="string" default="">
	
	<cfthrow
		type="AWS"
		message="#Arguments.message#"
		errorcode="#Arguments.errorcode#"
		detail="#Arguments.detail#"
		extendedinfo="#Arguments.extendedinfo#"
	>
	
</cffunction>

<cffunction name="onMissingMethod" access="public" returntype="any" output="false" hint="">
	<cfif ListLen(Arguments["missingMethodName"],"_") EQ 2>
		<cfreturn callAPI(
			subdomain=ListFirst(Arguments["missingMethodName"],"_"),
			Action=ListLast(Arguments["missingMethodName"],"_"),
			parameters=Arguments.missingMethodArguments
		)>
	<cfelse>
		<cfthrow message="The method #Arguments.missingMethodName# was not found in component." detail="Ensure that the method is defined, and that it is spelled correctly." type="Application">
	</cfif>
</cffunction>

<!---
Like anything worthwhile, this has had lots of influence:
https://github.com/anujgakhar/AmazonSESCFC/blob/master/com/anujgakhar/AmazonSES.cfc
http://webdeveloperpadawan.blogspot.com/2012/02/coldfusion-and-amazon-aws-ses-simple.html
http://cflove.org/2013/02/using-amazon-ses-api-sendrawemail-with-coldfusion.cfm
https://gist.github.com/cflove/4716338

More recent finds:
** https://github.com/jcberquist/aws-cfml
** https://github.com/simonfree/cfAWSWrapper
http://www.codegist.net/snippet/coldfusion-cfc/s3wrappercfc_shtakai_coldfusion-cfc
http://amazonsnscfc.riaforge.org/
https://www.snip2code.com/Snippet/1180201/Amazon-Web-Services-(AWS)-S3-Wrapper-for
https://codegists.com/snippet/coldfusion-cfc/s3wrappercfc_malpaso_coldfusion-cfc
https://www.petefreitag.com/item/833.cfm
--->
</cfcomponent>