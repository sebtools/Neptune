<cfcomponent displayname="Amazon Signature Version 4" extends="base" output="false">
<!---
The underscores before a method name indicate how close they are to that which should be called externally
Method order and indention should reflect the order of events for the process, not alphabetical as usual
--->
<cffunction name="init" access="public" returntype="any" output="false" hint="I initialize and return the component.">
	<cfargument name="AWS" type="any" required="true">

	<cfset Super.init(ArgumentCollection=Arguments)>

	<cfreturn This>
</cffunction>

<cffunction name="getCommonParameters" access="public" returntype="string" output="false">
	<cfreturn "Action,Version,X-Amz-Algorithm,X-Amz-Credential,X-Amz-Date,X-Amz-Security-Token,X-Amz-Signature,X-Amz-SignedHeaders">
</cffunction>

<cffunction name="getRequest" access="public" returntype="struct" output="false" hint="I return the raw(ish) results of Amazon REST Call.">
	<cfargument name="subdomain" type="string" required="true" hint="The subdomain for the AWS service being used.">
	<cfargument name="Action" type="string" required="true" hint="The AWS API action being called.">
	<cfargument name="method" type="string" default="GET" hint="The HTTP method to invoke.">
	<cfargument name="parameters" type="struct" default="#structNew()#" hint="An struct of HTTP URL parameters to send in the request.">
	<cfargument name="timeout" type="numeric" default="20" hint="The default call timeout.">

	<cfscript>
	var CommmonParameters = getCommonParameters();
	var sRequest = Super.getRequest(ArgumentCollection=Arguments);
	var timestamp = sRequest.headers["Date"];
	var sHeaders = {
		"host":Variables.AWS.getHost(Arguments.subdomain),
		"x-amz-date":getStringToSignDateFormat(timestamp)
	};
	var sAuthArgs = {
		Method=sRequest.method,
		URI=sRequest.URL,
		Headers=sHeaders,
		FormStruct={},
		Payload="",
		AccessKey=getAccessKey(),
		SecretKey=getSecretKey(),
		Region=getRegion(),
		Service=Arguments.subdomain,
		RequestDateTime=timestamp
	};
	CommmonParameters = "none";
	//Make sure URL parameters are in the URL for the request in the query string.
	sRequest.params.each(function(struct){
		if ( Arguments.struct["type"] EQ "URL" ) {
			if ( ListLen(sRequest["URL"],"?") EQ 1 ) {
				sRequest["URL"] &= "?";
			} else {
				sRequest["URL"] &= "&";
			}
			sRequest["URL"] &= Arguments.struct["name"] & "=" & Arguments.struct["value"];
		}
		if ( Arguments.struct["type"] EQ "FORMFIELD" ) {
			sAuthArgs["FormStruct"][Arguments.struct["name"]] = Arguments.struct["value"];
		}
	});
	sAuthArgs["URI"] = sRequest["URL"];// = sAuthArgs["URI"];
	sRequest.params = [];
	if ( StructCount(sAuthArgs["FormStruct"]) AND NOT Len(Trim(sAuthArgs.Payload)) ) {
		sAuthArgs.Payload = __buildCanonicalQueryString(sAuthArgs.FormStruct);
		sHeaders["Content-Type"] = "application/x-www-form-urlencoded";
		sHeaders["Content-Length"] = Len(sAuthArgs.Payload);
		sRequest.Payload = sAuthArgs.Payload;
	}
	sAuthArgs.Headers = sHeaders;

	sHeaders["Authorization"] = getAuthorizationString(ArgumentCollection=sAuthArgs);

	//StructDelete(sRequest["Headers"],"Date");
	StructAppend(sRequest["Headers"],sHeaders);
	</cfscript>


	<cfreturn sRequest>
</cffunction>

<cffunction name="getAuthorizationString" access="public" returntype="string" output="false" hint="I return the authorization string.">
	<cfargument name="Method" type="string" required="true">
	<cfargument name="URI" type="string" required="true">
	<cfargument name="Headers" type="struct" required="false">
	<cfargument name="FormStruct" type="struct" default="#{}#">
	<cfargument name="Payload" type="string" default="">
	<cfargument name="AccessKey" type="string" required="true">
	<cfargument name="SecretKey" type="string" required="true">
	<cfargument name="Region" type="string" required="true">
	<cfargument name="Service" type="string" required="true">
	<cfargument name="RequestDateTime" type="date" default="#now()#">

	<cfscript>
	var sLoc = {};

	StructAppend(Arguments.Headers,{"x-amz-date":getStringToSignDateFormat(Arguments.RequestDateTime)});

	sLoc.T1_1_Method = UCase(Arguments.Method);

	sLoc.T1_2_CanonicalURI = __buildCanonicalURI(Arguments.URI);
	sLoc.T1_3_CanonicalQueryString = __buildCanonicalQueryString(Arguments.URI,false);
	sLoc.T1_4_CanonicalHeaders = __buildCanonicalHeaders(Arguments.Headers);
	sLoc.T1_5_SignedHeaders = __buildSignedHeaders(Arguments.Headers);
	//Payload is form structure if a form is passed in. Need to cross-check to method=POST?
	if ( StructCount(Arguments.FormStruct) AND NOT Len(Trim(Arguments.Payload)) ) {
		sLoc.CanonicalPayload = __buildCanonicalQueryString(Arguments.FormStruct);
		Arguments.Payload = sLoc.CanonicalPayload;
	}
	sLoc.T1_6_PayloadHash = __buildPayloadHash(Arguments.Payload);
	sLoc.T1_7_CanonicalRequest = (
			""
		&	sLoc.T1_1_Method & chr(10)
		&	sLoc.T1_2_CanonicalURI & chr(10)
		&	sLoc.T1_3_CanonicalQueryString & chr(10)
		&	sLoc.T1_4_CanonicalHeaders & chr(10)
		&	sLoc.T1_5_SignedHeaders & chr(10)
		&	sLoc.T1_6_PayloadHash
	);
	</cfscript>
	<cfscript>
	sLoc.T1_8_HashedCanonicalRequest = hashy(sLoc.T1_7_CanonicalRequest);
	sLoc.T2_1_Algorithm = "AWS4-HMAC-SHA256";
	sLoc.T2_2_DateTimeISO = getStringToSignDateFormat(Arguments.RequestDateTime);
	sLoc.T2_3_CredentialScope = "#DateFormat(Arguments.RequestDateTime,'yyyymmdd')#/#LCase(Arguments.Region)#/#Arguments.Service#/aws4_request";
	sLoc.T2_4_CanonicalRequestHash = sLoc.T1_8_HashedCanonicalRequest;
	sLoc.T2_5_StringToSign = _createSigningString(
		ServiceName=Arguments.Service,
		Region=Arguments.Region,
		CanonicalRequestHash=sLoc.T1_8_HashedCanonicalRequest,
		RequestDateTime=Arguments.RequestDateTime
	);

	sLoc.T3_1_SigningKey = __buildSigningKey(
		SecretKey=Arguments.SecretKey,
		Region=Arguments.Region,
		Service=Arguments.Service,
		RequestDateTime=Arguments.RequestDateTime
	);
	sLoc.T3_1_SigningKeyString = BinaryEncode( sLoc.T3_1_SigningKey, "hex" );
	sLoc.T3_2_Signature = _createSignature(
		StringToSign=sLoc.T2_5_StringToSign,
		SecretKey=Arguments.SecretKey,
		Region=Arguments.Region,
		Service=Arguments.Service,
		RequestDateTime=Arguments.RequestDateTime
	);
	sLoc.Credential = "#Arguments.AccessKey#/#sLoc.T2_3_CredentialScope#";
	sLoc.T4_AuthHeader = "#sLoc.T2_1_Algorithm# Credential=#sLoc.Credential#, SignedHeaders=#sLoc.T1_5_SignedHeaders#, Signature=#sLoc.T3_2_Signature#";
	</cfscript>
	<!---
	<cfdump var="#Arguments#">
	<cfdump var="#sLoc#">
	<cfabort>
	--->
	<cfreturn sLoc.T4_AuthHeader>
</cffunction>

<cffunction name="getSignature" access="public" returntype="string" output="false" hint="I get the signature for the given request.">
	<cfargument name="Method" type="string" required="true">
	<cfargument name="URI" type="string" required="true">
	<cfargument name="Headers" type="struct" required="false">
	<cfargument name="Payload" type="string" default="">
	<cfargument name="SecretKey" type="string" required="true">
	<cfargument name="Region" type="string" required="true">
	<cfargument name="Service" type="string" required="true">
	<cfargument name="RequestDateTime" type="date" default="#now()#">

	<cfscript>
	var HashedCanonicalRequest = _createCanonicalRequestHash(
		Method=Arguments.Method,
		URI=Arguments.URI,
		Headers=Arguments.Headers,
		Payload=Arguments.Payload
	);
	var StringToSign = _createSigningString(
		ServiceName=Arguments.Service,
		Region=Arguments.Region,
		CanonicalRequestHash=HashedCanonicalRequest,
		RequestDateTime=Arguments.RequestDateTime
	);
	var Signature = _createSignature(
		StringToSign=StringToSign,
		SecretKey=Arguments.SecretKey,
		Region=Arguments.Region,
		Service=Arguments.Service,
		RequestDateTime=Arguments.RequestDateTime
	);
	</cfscript>

	<cfreturn Signature>
</cffunction>

	<cffunction name="_createCanonicalRequestHash" access="public" returntype="string" output="false" hint="Step 1: Task 1">
		<cfargument name="Method" type="string" required="true">
		<cfargument name="URI" type="string" required="true">
		<cfargument name="Headers" type="struct" required="false">
		<cfargument name="Payload" type="string" default="">

		<cfreturn hashy(_createCanonicalRequest(ArgumentCollection=Arguments))>
	</cffunction>

	<cffunction name="_createCanonicalRequest" access="public" returntype="string" output="false" hint="Step 1: Task 1">
		<cfargument name="Method" type="string" required="true">
		<cfargument name="URI" type="string" required="true">
		<cfargument name="Headers" type="struct" required="false">
		<cfargument name="Payload" type="string" default="">

		<cfset var result = "">

		<cfscript>
		result = (
				""
			&	UCase(Arguments.Method) & chr(10)
			&	__buildCanonicalURI(Arguments.URI) & chr(10)
			&	__buildCanonicalQueryString(Arguments.URI) & chr(10)
			&	__buildCanonicalHeaders(Arguments.Headers) & chr(10)
			&	__buildSignedHeaders(Arguments.Headers) & chr(10)
			&	__buildPayloadHash(Arguments.Payload)
		);
		</cfscript>

		<cfreturn result>
	</cffunction>

		<cffunction name="__buildCanonicalURI" access="public" returntype="string" output="false" hint="Step 1: Task 1: Part 1: Canonical URI.">
			<cfargument name="URI" type="string" required="true">

			<cfset var result = ListFirst(Arguments.URI,"?")>

			<cfset result = REReplaceNoCase(result, "^\w+://", "", "ONE")>
			<cfset result = ListDeleteAt(result,1,"/")>

			<cfset result = "/#result#">

			<cfset result = replace( urlEncode( result ), "%2F", "/", "all")>
			<!--- Double-encode (except S3) --->
			<cfset result = replace( urlEncode( result ), "%2F", "/", "all")>

			<cfreturn result>
		</cffunction>

		<cffunction name="__buildCanonicalQueryString" access="public" returntype="string" output="false" hint="Step 1: Task 1: Part 2: Canonical Query String.">
			<cfargument name="parameters" type="any" required="true">
			<cfargument name="isEncoded" type="boolean" default="true">

			<cfset var sParams = {}>
			<cfset var param = "">
			<cfset var aParams = []>
			<cfset var aResults = []>

			<!--- Make sure parameters are a struct. --->
			<cfif isStruct(Arguments.parameters)>
				<cfset sParams = Arguments.parameters>
			<cfelseif isSimpleValue(Arguments.parameters)>
				<cfset Arguments.parameters = ListRest(Arguments.parameters,"?")>
				<cfloop list="#Arguments.parameters#" index="param" delimiters="&">
					<cfset sParams[ListFirst(param,"=")] = ListRest(param,"=")>
				</cfloop>
			<cfelse>
				<cfthrow message="parameters must be either a query string or a structure.">
			</cfif>

			<cfscript>
			sParams = isEncoded ? sParams : encodeQueryParams( sParams );

			// Sort parameters
			aParams = StructKeyArray( sParams );
			ArraySort( aParams, "text", "asc" );

			arrayEach( aParams, function(string param) {
				ArrayAppend( aResults, Arguments.param & "=" & sParams[ Arguments.param ] );
			});
			</cfscript>

			<cfreturn ArrayToList(aResults, "&")>
		</cffunction>

		<cffunction name="__buildCanonicalHeaders" access="public" returntype="string" output="false" hint="Step 1: Task 1: Part 3: Canonical Headers.">
			<cfargument name="sHeaders" type="struct" required="true">

			<cfscript>
			var aPairs = "";
			var aHeaders = "";
			// Scrub the header names and values first
			var sCleanHeaders = cleanHeaders( Arguments.sHeaders );


			// Sort header names in ASCII order
			aHeaders = StructKeyArray( sCleanHeaders );
			ArraySort( aHeaders, "text", "asc" );

			// Build array of sorted header name and value pairs
			aPairs = [];
			aHeaders.each(function(string key) {
				ArrayAppend( aPairs, arguments.key & ":" & sCleanHeaders[ arguments.key ] );
			});

			// Generate list. Note: List must END WITH a new line character
			return ArrayToList( aPairs, chr(10)) & chr(10);
			</cfscript>

		</cffunction>

		<cffunction name="__buildSignedHeaders" access="public" returntype="string" output="false" hint="Step 1: Task 1: Part 4: Signed Headers.">
			<cfargument name="sHeaders" type="struct" required="true">

			<cfscript>
			var aPairs = "";
			var aHeaders = "";
			// Scrub the header names and values first
			var sCleanHeaders = cleanHeaders( Arguments.sHeaders );


			// Sort header names in ASCII order
			aHeaders = StructKeyArray( sCleanHeaders );
			ArraySort( aHeaders, "text", "asc" );

			// Build array of sorted header name and value pairs
			aPairs = [];
			aHeaders.each(function(string key) {
				ArrayAppend( aPairs, arguments.key );
			});

			// Generate list.
			return ArrayToList( aPairs, ";");
			</cfscript>

		</cffunction>

		<cffunction name="__buildPayloadHash" access="public" returntype="string" output="false" hint="Step 1: Task 1: Part 4: Payload Hash.">
			<cfargument name="Payload" type="string" default="">

			<cfreturn hashy(Arguments.Payload)>
		</cffunction>


	<cffunction name="_createSigningString" access="public" returntype="string" output="false" hint="Step 1: Task 2">
		<cfargument name="ServiceName" type="string" required="true">
		<cfargument name="Region" type="string" required="true">
		<cfargument name="CanonicalRequestHash" type="string" required="true">
		<cfargument name="RequestDateTime" type="date" default="#now()#">

		<cfset var result = "">

		<cfscript>
		result = (
				""
			&	"AWS4-HMAC-SHA256" & chr(10)
			&	getStringToSignDateFormat(Arguments.RequestDateTime) & chr(10)
			&	"#DateFormat(Arguments.RequestDateTime,'yyyymmdd')#/#LCase(Arguments.Region)#/#LCase(Arguments.ServiceName)#/aws4_request" & chr(10)
			&	Arguments.CanonicalRequestHash
		);
		</cfscript>

		<cfreturn result>
	</cffunction>

	<cffunction name="_createSignature" access="public" returntype="string" output="false" hint="Step 1: Task 3">
		<cfargument name="StringToSign" type="string" required="true">
		<cfargument name="SecretKey" type="string" required="true">
		<cfargument name="Region" type="string" required="true">
		<cfargument name="Service" type="string" required="true">
		<cfargument name="RequestDateTime" type="date" default="#now()#">

		<cfset var key = __buildSigningKey(ArgumentCollection=Arguments)>

		<cfreturn LCase( BinaryEncode( HMAC_SHA256_bin( Arguments.StringToSign, key), "hex") )>
	</cffunction>

		<cffunction name="__buildSigningKey" access="public" returntype="binary" output="false" hint="Step 1: Task 3: Part 1">
			<cfargument name="SecretKey" type="string" required="true">
			<cfargument name="Region" type="string" required="true">
			<cfargument name="Service" type="string" required="true">
			<cfargument name="RequestDateTime" type="date" default="#now()#">

			<cfscript>
			var DateStamp = DateFormat(Arguments.RequestDateTime,"yyyymmdd");
			/*
			var kSecret = charsetDecode("AWS4" & Arguments.SecretKey, "UTF-8");
			var kDate = hmacBinary( DateStamp, kSecret  );
			// Region information as a lowercase alphanumeric string
			var kRegion = hmacBinary( LCase(Arguments.Region), kDate  );
			// Service name information as a lowercase alphanumeric string
			var kService = hmacBinary( LCase(Arguments.Service), kRegion  );
			// A special termination string: aws4_request
			var kSigning = hmacBinary( "aws4_request", kService  );
			*/

			var kSecret        = JavaCast("string","AWS4" & Arguments.SecretKey).getBytes("UTF8");
			var kDate        = HMAC_SHA256_bin(DateStamp, kSecret);
			var kRegion        = HMAC_SHA256_bin(arguments.Region, kDate);
			var kService    = HMAC_SHA256_bin(arguments.Service, kRegion);
			var kSigning    = HMAC_SHA256_bin("aws4_request", kService);

			//return kSigning;
			</cfscript>

			<cfreturn kSigning>
		</cffunction>

		<cffunction name="__buildSigningKeyString" access="public" returntype="string" output="false" hint="Step 1: Task 3: Part 1">
			<cfargument name="SecretKey" type="string" required="true">
			<cfargument name="Region" type="string" required="true">
			<cfargument name="Service" type="string" required="true">
			<cfargument name="RequestDateTime" type="date" default="#now()#">

			<cfreturn BinaryEncode( __buildSigningKey(ArgumentCollection=Arguments), "hex" )>
		</cffunction>


			<cffunction name="getStringToSignDateFormat" access="private" returntype="string" output="false" hint="I return a formatted date time for the string to sign section">
				<cfargument name="date" type="date" required="true">

				<cfreturn "#Dateformat(Arguments.date, 'yyyymmdd')#T#TimeFormat(Arguments.date, 'HHmmss')#Z">
			</cffunction>

			<cffunction name="hashy" access="private" returntype="string" output="false">
				<cfargument name="string" type="string" default="">

				<cfreturn LCase(Hash(Arguments.string, "SHA-256"))>
			</cffunction>

			<cfscript>
			/**
			 * Scrubs header names and values:
			 * <ul>
			 *    <li>Removes leading and trailing spaces from names and values</li>
			 *	  <li>Converts sequential spaces to single space in names and values</li>
			 *	  <li>Converts all header names to lower case</li>
			 * </ul>
			 * @headers Header names and values to scrub
			 * @returns structure of parsed header names and values
			 */
			private struct function cleanHeaders(required struct headers) {
				var key  = "";
				var sResult  = {};

				for ( key in Arguments.Headers ) {
					sResult[ LCase(TrimAll(key)) ] = TrimAll( Arguments.Headers[key] );
				}

				return sResult;
			}

			/**
			 * URL encode query parameters and names
			 * @params Structure containing all query parameters for the request
			 * @returns new structure with all parameter names and values encoded
			 */
			private struct function encodeQueryParams(required struct sParams) {
				// First encode parameter names and values
				var sResult = {};
				sParams.each( function(string key, string value) {
					sResult[ urlEncode(arguments.key) ] = urlEncode( arguments.value );
				});
				return sResult;
			}

			/**
			 * Convenience method which generates a (binary) HMAC code for the specified message
			 *
			 * @message Message to sign
			 * @key HMAC key in binary form
			 * @algorithm Signing algorithm. [ Default is "HMACSHA256" ]
			 * @encoding Character encoding of message string. [ Default is UTF-8 ]
			 * @returns HMAC value for the specified message as binary (currently unsupported in CF11)
			*/
			private binary function hmacBinary (
				required string message
				, required binary key
				, string algorithm = "HMACSHA256"
				, string encoding = "UTF-8"
			){
				// Generate HMAC and decode result into binary
				return binaryDecode( HMAC( Arguments.message, Arguments.key, Arguments.algorithm, Arguments.encoding), "hex" );
			}

			private string function TrimAll(required string str) {
				return ReReplace( Trim( Arguments.str ), "\s+", chr(32), "ALL" );
			}

			/**
			 * URL encodes the supplied string per RFC 3986, which defines the following as
			 * unreserved characters that should NOT be encoded:
			 *
			 * A-Z, a-z, 0-9, hyphen ( - ), underscore ( _ ), period ( . ), and tilde ( ~ ).
			 *
			 * @value string to encode
			 * @returns URI encoded string
			 */
			private string function urlEncode( string value ) {
				var result = encodeForURL(Arguments.value);
				// Reverse encoding of tilde "~"
				result = replace( result, encodeForURL("~"), "~", "all" );
				// Fix encoding of spaces, ie replace '+' into "%20"
				result = replace( result, "+", "%20", "all" );
				// Asterisk "*" should be encoded
				result = replace( result, "*", "%2A", "all" );

				return result;
			}
			</cfscript>

<!---
https://gist.github.com/Leigh-/a2798584b79fd9072605a4cc7ff60df4
https://webdeveloperpadawan.blogspot.com/2013/07/amazon-aws-signature-version-4.html
--->
</cfcomponent>
