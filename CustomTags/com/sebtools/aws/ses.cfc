<cfcomponent extends="service" output="false">

<cffunction name="init" access="public" returntype="any" output="false" hint="I initialize and return the component.">
	<cfargument name="AWS" type="any" required="true">
	
	<cfset Arguments.subdomain = "email">

	<cfset initInternal(ArgumentCollection=Arguments)>

	<cfreturn This>
</cffunction>

<cffunction name="GetAPIReferenceURL" access="public" returntype="string" output="no" hint="I return the URL to the API reference.">
	<cfreturn "http://docs.aws.amazon.com/ses/latest/APIReference/">
</cffunction>

<cffunction name="GetIdentities" access="public" returntype="string" output="no" hint="I get a list of identies from which email can be sent on SES.">

	<cfreturn Variables.MrECache.method(
		id="identities",
		Component=This,
		MethodName="_GetIdentities",
		timeSpan=CreateTimeSpan(0,1,0,0)
	)>
</cffunction>

<cffunction name="_GetIdentities" access="public" returntype="string" output="no">
	
	<cfset var aIdentities = Variables.AWS.callLimitedAPI(
		subdomain="email",
		Action="ListIdentities",
		Parameters={"IdentityType":"Domain"}
	)>

	<cfreturn ArrayToList(aIdentities)>
</cffunction>

<cffunction name="GetIdentity" access="public" returntype="string" output="no" hint="I get the identity for the given value.">
	<cfargument name="Sender" type="string" required="true">

	<cfset var Identities = GetIdentities()>
	<cfset var email = Arguments.Sender>
	<cfset var domain = ListLast(email,"@")>
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

	<cfreturn Variables.MrECache.method(
		id=Variables.MrECache.id("isverified",Arguments),
		Component=This,
		MethodName="_isVerified",
		Args=Arguments,
		timeSpan=CreateTimeSpan(0,0,3,0)
	)>
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
			Args={Identity=identity},
			default=true
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
			StructKeyExists(xResponse,"entry")
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

<cffunction name="VerifyDomainIdentity" access="public" returntype="string" output="no">
	<cfargument name="Domain" type="string" required="true">

	<cfset var xResult = callAPI(Action="VerifyDomainIdentity",parameters={"Domain":Arguments.Domain})>
	<cfset var VerificationToken = xResult["VerifyDomainIdentityResponse"]["VerifyDomainIdentityResult"]["VerificationToken"].XmlText>

	<cfreturn VerificationToken>
</cffunction>

<cffunction name="_GetSendQuota" access="private" returntype="struct" output="no">
	
	<cfreturn callLimitedAPI("GetSendQuota")>
</cffunction>

</cfcomponent>