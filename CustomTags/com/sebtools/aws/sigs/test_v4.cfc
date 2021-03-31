<cfcomponent displayname="AWS Signature 4" extends="mxunit.framework.TestCase" output="no">

<cffunction name="beforeTests" access="public" returntype="void" output="no">

	<cf_service name="AWS">

	<cfset Variables.aws_sig4 = CreateObject("component","v4").init(Variables.AWS)>

</cffunction>

<cffunction name="shouldBuildCanonicalURL" access="public" returntype="void" output="no"
	hint="Signature 4 should build a canonical URL. Step 1: Task 1: Part 1"
>

	<cfset assertEquals(
		"/",
		Variables.aws_sig4.__buildCanonicalURI("https://iam.amazonaws.com/?Action=ListUsers&Version=2010-05-08"),
		"Failed to correctly build a canonical URL."
	)>
	<cfset assertEquals(
		"/documents%2520and%2520settings/",
		Variables.aws_sig4.__buildCanonicalURI("https://iam.amazonaws.com/Documents and settings/?Action=ListUsers&Version=2010-05-08"),
		"Failed to correctly build a canonical URL."
	)>

</cffunction>

<cffunction name="shouldBuildCanonicalQueryString" access="public" returntype="void" output="no"
	hint="Signature 4 should build a canonical QueryString. Step 1: Task 1: Part 2"
>

	<cfset assertEquals(
		"Action=ListUsers&Version=2010-05-08",
		Variables.aws_sig4.__buildCanonicalQueryString("https://iam.amazonaws.com/?Action=ListUsers&Version=2010-05-08"),
		"Failed to correctly build a canonical QueryString."
	)>
	<cfset assertEquals(
		"Action=ListUsers&Version=2010-05-08",
		Variables.aws_sig4.__buildCanonicalQueryString("https://iam.amazonaws.com/?Version=2010-05-08&Action=ListUsers"),
		"Failed to correctly build a canonical QueryString."
	)>

</cffunction>

<cffunction name="shouldBuildCanonicalHeaders" access="public" returntype="void" output="no"
	hint="Signature 4 should build a canonical Headers string. Step 1: Task 1: Part 3"
>

	<cfset assertEquals(
		'my-header1:a b c#chr(10)#my-header2:"a b c"#chr(10)#x-amz-date:20150830T123600Z#chr(10)#',
		Variables.aws_sig4.__buildCanonicalHeaders(
			{
				"My-header1":"    a   b   c  ",
				"X-Amz-Date":"20150830T123600Z",
				"My-Header2":"    ""a   b   c""  "
			}
		),
		"Failed to correctly build a canonical Headers."
	)>

</cffunction>

<cffunction name="shouldBuildSignedHeaders" access="public" returntype="void" output="no"
	hint="Signature 4 should build a signed Headers string. Step 1: Task 1: Part 4"
>

	<cfset assertEquals(
		'my-header1;my-header2;x-amz-date',
		Variables.aws_sig4.__buildSignedHeaders(
			{
				"My-header1":"    a   b   c  ",
				"X-Amz-Date":"20150830T123600Z",
				"My-Header2":"    ""a   b   c""  "
			}
		),
		"Failed to correctly build a signed Headers."
	)>

</cffunction>

<cffunction name="shouldBuildPayloadHash" access="public" returntype="void" output="no"
	hint="Signature 4 should build a signed Headers string. Step 1: Task 1: Part 5"
>

	<cfset assertEquals(
		'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
		Variables.aws_sig4.__buildPayloadHash(""),
		"Failed to correctly build a payload hash."
	)>

</cffunction>

<cffunction name="shouldBuildCanonicalRequest" access="public" returntype="void" output="no"
	hint="Signature 4 should build a signed Headers string. Step 1: Task 1"
>

	<cfset assertEquals(
		'GET#chr(10)#/#chr(10)#Action=ListUsers&Version=2010-05-08#chr(10)#content-type:application/x-www-form-urlencoded; charset=utf-8#chr(10)#host:iam.amazonaws.com#chr(10)#x-amz-date:20150830T123600Z#chr(10)##chr(10)#content-type;host;x-amz-date#chr(10)#e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
		Variables.aws_sig4._createCanonicalRequest(
			Method="get",
			URI="https://iam.amazonaws.com/?Action=ListUsers&Version=2010-05-08",
			Headers={
				"content-type":"application/x-www-form-urlencoded; charset=utf-8",
				"host":"iam.amazonaws.com",
				"x-amz-date":"20150830T123600Z"
			}
		),
		"Failed to correctly build the canonical request."
	)>

</cffunction>

<cffunction name="shouldBuildCanonicalRequestHash" access="public" returntype="void" output="no"
	hint="Signature 4 should build a signed Headers string. Step 1: Task 1"
>

	<cfset assertEquals(
		'f536975d06c0309214f805bb90ccff089219ecd68b2577efef23edd43b7e1a59',
		Variables.aws_sig4._createCanonicalRequestHash(
			Method="get",
			URI="https://iam.amazonaws.com/?Action=ListUsers&Version=2010-05-08",
			Headers={
				"content-type":"application/x-www-form-urlencoded; charset=utf-8",
				"host":"iam.amazonaws.com",
				"x-amz-date":"20150830T123600Z"
			}
		),
		"Failed to correctly build the canonical request."
	)>

</cffunction>

<cffunction name="shouldCreateSigningString" access="public" returntype="void" output="no"
	hint="Signature 4 should build a signing string. Step 1: Task 2"
>

	<cfset assertEquals(
		'AWS4-HMAC-SHA256#chr(10)#20150830T123600Z#chr(10)#20150830/us-east-1/iam/aws4_request#chr(10)#f536975d06c0309214f805bb90ccff089219ecd68b2577efef23edd43b7e1a59',
		Variables.aws_sig4._createSigningString(
			ServiceName="iam",
			Region="us-east-1",
			CanonicalRequestHash="f536975d06c0309214f805bb90ccff089219ecd68b2577efef23edd43b7e1a59",
			RequestDateTime="2015-08-30 12:36"
		),
		"Failed to correctly build the signing string."
	)>

</cffunction>

<cffunction name="shouldCreateSigningKey" access="public" returntype="void" output="no"
	hint="Signature 4 should build a signing key. Step 1: Task 3: Part 1"
>

	<cfset assertEquals(
		'c4afb1cc5771d871763a393e44b703571b55cc28424d1a5e86da6ed3c154a4b9',
		Variables.aws_sig4.__buildSigningKeyString(
			SecretKey="wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY",
			Service="iam",
			Region="us-east-1",
			RequestDateTime="2015-08-30 12:36"
		),
		"Failed to correctly build the signature."
	)>

</cffunction>

<cffunction name="shouldCreateSignature" access="public" returntype="void" output="no"
	hint="Signature 4 should build a signature. Step 1: Task 3"
>

	<cfset assertEquals(
		'5d672d79c15b13162d9279b0855cfba6789a8edb4c82c400e06b5924a6f2b5d7',
		Variables.aws_sig4._createSignature(
			StringToSign='AWS4-HMAC-SHA256#chr(10)#20150830T123600Z#chr(10)#20150830/us-east-1/iam/aws4_request#chr(10)#f536975d06c0309214f805bb90ccff089219ecd68b2577efef23edd43b7e1a59',
			SecretKey="wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY",
			Service="iam",
			Region="us-east-1",
			RequestDateTime="2015-08-30 12:36"
		),
		"Failed to correctly build the signature."
	)>

</cffunction>

<cffunction name="shouldGetSignature" access="public" returntype="void" output="no"
	hint="Signature 4 should build a signature."
>

	<cfset assertEquals(
		'5d672d79c15b13162d9279b0855cfba6789a8edb4c82c400e06b5924a6f2b5d7',
		Variables.aws_sig4.getSignature(
			Method="get",
			URI="https://iam.amazonaws.com/?Action=ListUsers&Version=2010-05-08",
			Headers={
				"content-type":"application/x-www-form-urlencoded; charset=utf-8",
				"host":"iam.amazonaws.com",
				"x-amz-date":"20150830T123600Z"
			},
			AccessKey="AKIDEXAMPLE",
			SecretKey="wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY",
			Service="iam",
			Region="us-east-1",
			RequestDateTime="2015-08-30 12:36"
		),
		"Failed to correctly build the signature."
	)>

</cffunction>

<cffunction name="shouldAuthorization" access="public" returntype="void" output="no"
	hint="Signature 4 should build an Authorization header string."
>

	<cfset assertEquals(
		'AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/iam/aws4_request, SignedHeaders=content-type;host;x-amz-date, Signature=5d672d79c15b13162d9279b0855cfba6789a8edb4c82c400e06b5924a6f2b5d7',
		Variables.aws_sig4.getAuthorizationString(
			Method="get",
			URI="https://iam.amazonaws.com/?Action=ListUsers&Version=2010-05-08",
			Headers={
				"content-type":"application/x-www-form-urlencoded; charset=utf-8",
				"host":"iam.amazonaws.com"
			},
			AccessKey="AKIDEXAMPLE",
			SecretKey="wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY",
			Service="iam",
			Region="us-east-1",
			RequestDateTime="2015-08-30 12:36"
		),
		"Failed to correctly build the signature."
	)>
	<cfset assertEquals(
		'AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/iam/aws4_request, SignedHeaders=content-type;host;x-amz-date, Signature=f547bbfb9841d3d1477f36d746d8d5ebe4bc113fecd11ec483363bd2bfcb4164',
		Variables.aws_sig4.getAuthorizationString(
			Method="post",
			URI="https://iam.amazonaws.com/?Action=ListUsers&Version=2010-05-08",
			Headers={
				"content-type":"application/x-www-form-urlencoded; charset=utf-8",
				"host":"iam.amazonaws.com"
			},
			AccessKey="AKIDEXAMPLE",
			SecretKey="wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY",
			Service="iam",
			Region="us-east-1",
			RequestDateTime="2015-08-30 12:36"
		),
		"Failed to correctly build the signature for a post."
	)>
	<cfset assertEquals(
		'AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/iam/aws4_request, SignedHeaders=content-type;host;x-amz-date, Signature=6118d33fb13cefba9b9c4fe4cfb5166a429697196f689f720b458945ae472db6',
		Variables.aws_sig4.getAuthorizationString(
			Method="post",
			URI="https://iam.amazonaws.com/?Action=ListUsers&Version=2010-05-08",
			Headers={
				"content-type":"application/x-www-form-urlencoded; charset=utf-8",
				"host":"iam.amazonaws.com"
			},
			FormStruct={"color":"red"},
			AccessKey="AKIDEXAMPLE",
			SecretKey="wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY",
			Service="iam",
			Region="us-east-1",
			RequestDateTime="2015-08-30 12:36"
		),
		"Failed to correctly build the signature for a post."
	)>

</cffunction>


</cfcomponent>
