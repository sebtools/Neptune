<cfcomponent extends="service" output="false">

<cffunction name="init" access="public" returntype="any" output="false" hint="I initialize and return the component.">
	<cfargument name="AWS" type="any" required="true">

	<cfset Arguments.service = "ses">
	<cfset Arguments.subdomain = "email">

	<cfset initInternal(ArgumentCollection=Arguments)>

	<cfreturn This>
</cffunction>

<cffunction name="GetAPIReferenceURL" access="public" returntype="string" output="no" hint="I return the URL to the API reference.">
	<cfreturn "http://docs.aws.amazon.com/ses/latest/APIReference/">
</cffunction>

<cffunction name="GetIdentities" access="public" returntype="string" output="no">

	<cfset var aIdentities = Variables.AWS.callLimitedAPI(
		subdomain="email",
		Action="ListIdentities",
		timeSpan=CreateTimeSpan(0,3,0,0),
		waitlimit=300
	)>

	<!--- Handle failure to retrieve identies with as much grace as possible. --->
	<cfif isArray(aIdentities)>
		<!--- Save latest identies in case they fail later --->
		<cfset Variables.aSafetyIdentities = aIdentities>
	<cfelseif StructKeyExists(Variables,"aSafetyIdentities")>
		<!--- If identities isn't retrieved, but the safety value is availablem then use that and alert devs. --->
		<cf_scaledAlert message="Unable to retrieve AWS Email Identities.">
		<cfset aIdentities = Variables.aSafetyIdentities>
	<cfelse>
		<!--- If identities isn't retrieved and safety value is unavailable, then throw an error. --->
		<cfset throwError("Unable to retrieve AWS Email Identities.")>
	</cfif>

	<cfreturn ArrayToList(aIdentities)>
</cffunction>

<cffunction name="GetIdentityNotificationAttributes" access="public" returntype="any" output="no">
	<cfargument name="Members" type="string" required="true">

	<cfset var result = Variables.AWS.callLimitedAPI(
		subdomain="email",
		Action="GetIdentityNotificationAttributes",
		Parameters={"Identities.member.1"=Arguments.Members},
		timeSpan=CreateTimeSpan(0,0,1,0)
	)>

	<cfreturn result>
</cffunction>

<cffunction name="GetBounceRate" access="public" returntype="numeric" output="no">
	<cfset var qSendStatistics = GetSendStatistics()>
	<cfset var qTotals = 0>
	<cfset var result = 0>

	<cfquery name="qTotals" dbtype="query">
	SELECT		SUM(Complaints) AS Complaints,
				SUM(Bounces) AS Bounces,
				SUM(DeliveryAttempts) AS DeliveryAttempts
	FROM		qSendStatistics
	WHERE		[Timestamp] >= #DateAdd("d",-7,now())#
	</cfquery>

	<cfif qTotals.DeliveryAttempts>
		<cfset result = (qTotals.Bounces / qTotals.DeliveryAttempts) * 100>
	</cfif>

	<cfreturn result>
</cffunction>

<cffunction name="GetSendStatistics" access="public" returntype="query" output="no">
	<cfreturn Variables.MrECache.method(
		id="SendStatistics",
		Component=This,
		MethodName="_GetSendStatistics",
		timeSpan=CreateTimeSpan(0,0,15,0)
	)>
</cffunction>

<cffunction name="_GetSendStatistics" access="public" returntype="query" output="no">

	<cfscript>
	var columns = "Complaints,Rejects,Bounces,DeliveryAttempts,Timestamp";
	var xStatistics = Variables.AWS.callLimitedAPI(
		subdomain="email",
		Action="GetSendStatistics"
	);
	var xaMembers = xStatistics.XmlChildren;
	var qSendStatistics = QueryNew(columns);
	var ii = 0;
	var jj = 0;

	QueryAddRow(qSendStatistics,ArrayLen(xaMembers));
	//Loop through member elements. Each member element represents 15 minutes of send data.
	for ( ii=1; ii LTE ArrayLen(xaMembers); ii=ii+1 ) {
		//Loop through elements within member. Each of these is basically a column of data.
		for (jj=1; jj LTE ArrayLen(xaMembers[ii].XmlChildren); jj=jj+1) {
			//Make sure only to use elements that we have in our query. As of 2017-06-08 this isn't needed, but they could add more elements.
			if ( ListFindNoCase(columns,xaMembers[ii].XmlChildren[jj].XmlName) ) {
				//Populate the cell with this data. Convert dates where needed.
				QuerySetCell(qSendStatistics,xaMembers[ii].XmlChildren[jj].XmlName,AWSTime2CFTime(xaMembers[ii].XmlChildren[jj].XmlText),ii);
			}
		}
	}
	</cfscript>
	<cfquery name="qSendStatistics" dbtype="query">
	SELECT		*
	FROM		qSendStatistics
	ORDER BY	[Timestamp]
	</cfquery>

	<cfreturn qSendStatistics>
</cffunction>

<cffunction name="SetIdentityNotificationTopic" access="public" returntype="any" output="no">
	<cfargument name="Identity" type="string" required="true">
	<cfargument name="NotificationType" type="string" required="true">
	<cfargument name="SnsTopic" type="string" required="true">

	<cfset var result = callAPI(
		Action="SetIdentityNotificationTopic",
		Parameters={"Identity"=Arguments.Identity,"NotificationType"=Arguments.NotificationType,"SnsTopic"=Arguments.SnsTopic}
	)>

	<cfreturn result>
</cffunction>

<cffunction name="SetIdentityNotificationTopics" access="public" returntype="any" output="no">
	<cfargument name="Identity" type="string" required="true">
	<cfargument name="SnsTopic" type="string" required="true">
	<cfargument name="NotificationTypes" type="string" default="Bounce,Complaint">

	<cfset var type = "">

	<cfloop list="#Arguments.NotificationTypes#" index="type">
		<cfset SetIdentityNotificationTopic(Identity=Arguments.Identity,NotificationType=type,SnsTopic=Arguments.SnsTopic)>
	</cfloop>

</cffunction>

<cffunction name="GetIdentity" access="public" returntype="string" output="no" hint="I get the identity for the given value.">
	<cfargument name="Sender" type="string" required="true">

	<cfset var Identities = GetIdentities()>
	<cfset var email = Arguments.Sender>
	<cfset var domain = getPrimaryDomain(email)>
	<cfset var result = "">

	<cfif ListFindNoCase(Identities,email)>
		<cfset result = email>
	</cfif>

	<cfif ListFindNoCase(Identities,domain)>
		<cfset result = domain>
	</cfif>

	<cfreturn result>
</cffunction>

<cffunction name="isIdentity" access="public" returntype="boolean" output="no" hint="I determine if the sender is a valid SES sender.">
	<cfargument name="Sender" type="string" required="true">

	<cfreturn Variables.MrECache.method(
		id=Variables.MrECache.id("isidentity",Arguments),
		Component=This,
		MethodName="_isIdentity",
		Args=Arguments,
		timeSpan=CreateTimeSpan(0,0,1,0)
	)>
</cffunction>

<cffunction name="_isIdentity" access="public" returntype="boolean" output="no" hint="I determine if the sender is a valid SES sender.">
	<cfargument name="Sender" type="string" required="true">

	<cfset var Identities = GetIdentities()>
	<cfset var email = Arguments.Sender>
	<cfset var domain = ListLast(email,"@")>

	<cfreturn ( ListFindNoCase(Identities,domain) OR ListFindNoCase(Identities,email) ) GT 0>
</cffunction>

<cffunction name="isUnderSESLimit" access="public" returntype="boolean" output="no">

	<cfset var sSendQuota = GetSendQuota()>
	<cfset var PercentOfQuota = sSendQuota["SentLast24Hours"] / sSendQuota["Max24HourSend"]>
	<cfset var result = true>

	<!--- We don't want to exceed 90% of the limit, before we switch to standard sending. --->
	<cfif PercentOfQuota GTE 0.9>
		<cfset result = false>
	</cfif>

	<cfreturn result>
</cffunction>

<cffunction name="isVerified" access="public" returntype="boolean" output="false" hint="I determine if the sender is verified on SES.">
	<cfargument name="Sender" type="string" required="true">

	<cfset var result = Variables.MrECache.method(
		id=Variables.MrECache.id("isverified",Arguments),
		Component=This,
		MethodName="_isVerified",
		Args=Arguments,
		timeSpan=CreateTimeSpan(0,3,0,0)
	)>

	<!--- Sometimes unable to get a response, so try just one more time directlyish. --->
	<cfif NOT isBoolean(result)>
		<cfset result = _isVerified(Arguments.Sender)>
	</cfif>

	<cfreturn result>
</cffunction>

<cffunction name="_isVerified" access="public" returntype="boolean" output="false" hint="I determine if the sender is verified on SES.">
	<cfargument name="Sender" type="string" required="true">

	<cfset var identity = GetIdentity(Arguments.Sender)>
	<cfset var xResponse = 0>
	<cfset var result = false>

	<cfif Len(identity)>
		<cfset result = Variables.RateLimiter.method(
			id="isVerifiedIdentity",
			Component=This,
			MethodName="isVerifiedIdentity",
			Args={Identity=identity}
		)>
	</cfif>

	<cfreturn result>
</cffunction>

<cffunction name="isVerifiedIdentity" access="public" returntype="boolean" output="false" hint="I determine if the identity is verified on SES.">
	<cfargument name="Identity" type="string" required="true">

	<cfset var xResponse = 0>
	<cfset var result = false>

	<cfset xResponse = Variables.AWS.email_GetIdentityVerificationAttributes(
		Identities.member.1=Arguments.Identity
	)>
	<cfif
			isXML(xResponse)
		AND	StructKeyExists(xResponse,"entry")
		AND	StructKeyExists(xResponse.entry,"key")
		AND	StructKeyExists(xResponse.entry,"value")
		AND	StructKeyExists(xResponse.entry.value,"VerificationStatus")
		AND	xResponse.entry.key.XmlText EQ Arguments.Identity
		AND	xResponse.entry.value.VerificationStatus.XmlText EQ "Success"
	>
		<cfset result = true>
	</cfif>

	<cfreturn result>
</cffunction>

<cffunction name="GetSendQuota" access="public" returntype="struct" output="no">

	<!--- Make sure that the variables that we need exist. --->
	<cfif NOT StructKeyExists(Variables,"sSendQuotaCallData")>
		<cfset Variables.sSendQuotaCallData = StructNew()>
		<cfset Variables.sSendQuotaCallData["meta"] = StructNew()>
		<cfset Variables.sSendQuotaCallData["results"] = StructNew()>
	</cfif>

	<!---
	Rules on calling AWS API "GetSendQuota":
	-- Any time we have no data.
	-- Any time we haven't called it in half a day.
	-- No more than once per second. (going to ignore this one, however, as it should be safely covered by the next one)
	-- No more than once per every 10% of quota.
	--->

	<cfif
			NOT	StructCount(Variables.sSendQuotaCallData["results"])
		OR	DateDiff("h",Variables.sSendQuotaCallData["meta"]["LastCalled"],now()) GTE 12
		OR	(
					DateDiff("s",Variables.sSendQuotaCallData["meta"]["LastCalled"],now()) GTE 1
				AND	(Variables.sSendQuotaCallData["meta"]["NumCachedCalls"] * 10) GTE Variables.sSendQuotaCallData["results"]["Max24HourSend"]
			)
	>
		<!--- Get the data and record metadata about it for future caching. --->
		<cflock name="Mailer:GetSendQuota:#Variables.LockID#" type="exclusive" timeout="3" throwontimeout="false">
			<cfset Variables.sSendQuotaCallData["results"] = _GetSendQuota()>
			<cfset Variables.sSendQuotaCallData["meta"]["LastCalled"] = now()>
			<cfset Variables.sSendQuotaCallData["meta"]["NumCachedCalls"] = 0>
		</cflock>
		<!---
		We don't need any other conditions for the lock, because if it was locked then the data was retrieved in the locking request.
		In the unlikely event that the locking request failed then this one would as well.
		--->
	<cfelse>
		<!---
		This number determines how often we actually call out to the AWS API for quota data.
		No need for locking here because this is really just a rough number anyway.
		--->
		<cfset Variables.sSendQuotaCallData["meta"]["NumCachedCalls"] = Variables.sSendQuotaCallData["meta"]["NumCachedCalls"] + 1>
	</cfif>

	<cfreturn Variables.sSendQuotaCallData["results"]>
</cffunction>

<cffunction name="emailarray" access="public" returntype="array" output="false">
	<cfargument name="recipients" type="any" required="true">

	<cfscript>
	var key = "";
	var result = [];

	if ( isArray(Arguments.recipients) ) {
		return Arguments.recipients;
	}

	if ( isStruct(Arguments.recipients) ) {
		for (key in Arguments.recipients) {
			ArrayAppend(result,Arguments.recipients[key]);
		}
	}

	if ( isSimpleValue(Arguments.recipients) ) {
		Arguments.recipients = ReplaceNoCase(Arguments.recipients,";",",","ALL");
		result = ListToArray(Arguments.recipients);
	}
	</cfscript>

	<cfreturn result>
</cffunction>

<!--- Borrowed *heavily* from: https://github.com/anujgakhar/AmazonSESCFC/blob/master/com/anujgakhar/AmazonSES.cfc --->
<cffunction name="sendEmail" output="false" access="public" returntype="any" hint="I send an email message.">
	<cfargument name="from" 			 	type="string"	required="true">
	<cfargument name="to" 				 	type="any"		required="true">
	<cfargument name="text"		 		 	type="string"	required="true" 	hint="message of the email" />
	<cfargument name="cc" 				 	type="any"		required="false">
	<cfargument name="bcc" 				 	type="any"		required="false">
	<cfargument name="replyto" 			 	type="any"		required="false">
	<cfargument name="subject" 			 	type="string"	required="false">
	<cfargument name="html" 			 	type="string"	required="false" 	hint="html message">
	<cfargument name="subject_charset" 	 	type="string"	required="false" 	hint="Charset of the subject" default="utf-8">
	<cfargument name="returnpath" 	 		type="string"	required="false" 	hint="The email address to which bounce notifications are to be forwarded. If the message cannot be delivered to the recipient, then an error message will be returned from the recipient's ISP; this message will then be forwarded to the email address specified by the ReturnPath parameter">
	<cfargument name="text_charset"  	type="string"	required="false" 	hint="message of the email">
	<cfargument name="html_charset" 	type="string" 	required="false" 	hint="Charset of the html message">

	<cfscript>
	var sParams = {};
	var result = 0;
	var ii = 0;
	var emailfields = "to,cc,bcc,replyto";
	var emailfield = "";

	//This allows us to pass email fields in as strings, structs or arrays and have any converted to arrays.
	for ( ii=1; ii lte ListLen(emailfields); ii++ ) {
		emailfield = ListGetAt(emailfields,ii);
		if ( StructKeyExists(Arguments,emailfield) ) {
			Arguments[emailfield] = emailarray(Arguments[emailfield]);
		}
	}

	for (ii=1; ii lte arraylen(arguments.to); ii++){
		sParams['Destination.ToAddresses.member.#ii#'] = trim(arguments.to[ii]);
	}

	if (structKeyExists(arguments,"cc") and IsArray(arguments.cc)) {
		for (ii=1; ii lte arraylen(arguments.cc); ii++){
			sParams['Destination.CcAddresses.member.#ii#'] = trim(arguments.cc[ii]);
		}
	}

	if (structKeyExists(arguments,"bcc") and IsArray(arguments.bcc)) {
		for (ii=1; ii lte arraylen(arguments.bcc); ii++){
			sParams['Destination.BccAddresses.member.#ii#'] = trim(arguments.bcc[ii]);
		}
	}

	if (structKeyExists(arguments,"replyto") and IsArray(arguments.replyto)) {
		for (ii=1; ii lte arraylen(arguments.replyto); ii++){
			sParams['ReplyToAddresses.member.#ii#'] = trim(arguments.replyto[ii]);
		}
	}

	sParams['Source'] = trim(arguments.from);

	if (structKeyExists(arguments,"returnpath") and len(trim(arguments.returnpath))) {
		sParams['ReturnPath'] = trim(arguments.returnpath);
	}

	if (structKeyExists(arguments,"subject") and len(trim(arguments.subject))) {
		sParams['Message.Subject.Data'] = urlEncodedFormat(trim(arguments.subject));
		if(structKeyExists(arguments,"subject_charset") and len(trim(arguments.subject_charset))){
			sParams['Message.Subject.Charset'] = trim(arguments.subject_charset);
		}
	}

	if (structKeyExists(arguments,"text") and len(trim(arguments.text))) {
		sParams['Message.Body.Text.Data'] = urlEncodedFormat(trim(arguments.text));
		if (structKeyExists(arguments,"text_charset") and len(trim(arguments.text_charset))){
			sParams['Message.Body.Text.Charset'] = trim(arguments.text_charset);
		}
	}

	if (structKeyExists(arguments,"html") and len(trim(arguments.html))) {
		sParams['Message.Body.Html.Data'] = urlEncodedFormat(trim(arguments.html));
		if (structKeyExists(arguments,"html_charset") and len(trim(arguments.html_charset))){
			sParams['Message.Body.Html.Charset'] = trim(arguments.html_charset);
		}
	}

	result = callAPI(
		method="POST",
		Action="SendEmail",
		parameters=sParams
	);

	if ( isXml(result) AND StructKeyExists(result,"MessageId") ) {
		return result["MessageId"].XmlText;
	}

	return result;
	</cfscript>
</cffunction>

<cffunction name="VerifyDomainIdentity" access="public" returntype="string" output="no">
	<cfargument name="Domain" type="string" required="true">

	<cfset var xResult = callAPI(Action="VerifyDomainIdentity",parameters={"Domain"=Arguments.Domain})>
	<cfset var VerificationToken = xResult["VerifyDomainIdentityResponse"]["VerifyDomainIdentityResult"]["VerificationToken"].XmlText>

	<cfreturn VerificationToken>
</cffunction>

<cffunction name="VerifyEmailIdentity" access="public" returntype="void" output="no">
	<cfargument name="EmailAddress" type="string" required="true">

	<cfset callAPI(Action="VerifyEmailIdentity",parameters={"EmailAddress"=Arguments.EmailAddress})>

</cffunction>

<cffunction name="callAPI" access="private" returntype="any" output="false" hint="I invoke an Amazon REST Call.">
	<cfargument name="Action" type="string" required="false" hint="The AWS API action being called.">
	<cfargument name="method" type="string" default="GET" hint="The HTTP method to invoke.">
	<cfargument name="parameters" type="struct" default="#structNew()#" hint="An struct of HTTP URL parameters to send in the request.">

	<cfset Arguments.parameters["Version"] = "2010-12-01">

	<cfreturn Super.callAPI(ArgumentCollection=Arguments)>
</cffunction>

<cffunction name="_GetSendQuota" access="private" returntype="struct" output="no">

	<cfreturn callLimitedAPI("GetSendQuota")>
</cffunction>

<cffunction name="getPrimaryDomain" access="public" returntype="string" output="false" hint="I return the primary domain name for any given valid email address or proper URL.">
	<cfargument name="string" type="string" required="true">

	<cfset var result = Arguments.string>
	<cfset var parts = 2>

	<cfscript>
	// First ditch any protocal information.
	result = REReplaceNoCase(result,"^\w+://","");

	// Second ditch any pathing information from a URL.
	result = ListFirst(result,"/");

	// Third ditch any user information from a URL or email address
	result = ListLast(result,"@");

	// Ditch any port information, if it is provided with something else.
	if ( ListLen(result,":") GT 1 ) {
		result = ListFirst(result,":");
	}

	// Handle IP addresses.
	if ( REFindNoCase("^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$",result) ) {
		return result;
	}

	// Handle country codes.
	if ( REFindNoCase("\.\w{2,3}\.\w{2}$",result) ) {
		parts = 3;
	}

	// Peel off all of the subdomains.
	while ( ListLen(result,".") GT parts ) {
		result = listDeleteAt(result,1,".");
	}

	return result;
	</cfscript>
</cffunction>

</cfcomponent>
