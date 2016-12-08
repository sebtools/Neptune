<cfcomponent displayname="Mailer for Amazon SES" extends="Mailer" hint="I send email through Amazon SES.">

<cffunction name="init" access="public" returntype="Mailer" output="no" hint="I instantiate and return this object.">
	<cfargument name="MailServer" type="string" default="">
	<cfargument name="From" type="string" default="">
	<cfargument name="To" type="string" default="">
	<cfargument name="username" type="string" default="">
	<cfargument name="password" type="string" default="">
	<cfargument name="RootData" type="struct" default="#StructNew()#">
	<cfargument name="ReplyTo" type="string" default="">
	<cfargument name="Sender" type="string" default="">
	<cfargument name="logtable" type="string" default="mailerLogs">
	<cfargument name="mode" type="string" required="false">
	<cfargument name="log" type="boolean" default="false">
	<cfargument name="port" type="string" default="587">
	<cfargument name="useTLS" type="boolean" default="true">
	<cfargument name="ErrorTo" type="string" default="">
	<cfargument name="verify" type="boolean" default="false">
	<cfargument name="Scheduler" type="any" required="false">
	<cfargument name="Observer" type="any" required="false">
	<cfargument name="AWS" type="any" required="true" hint="The com.sebtools.AWS component that manages interactions with AWS.">
	<cfargument name="Mailer" type="any" required="false" hint="The Mailer to use as back-up for when the AWS SES quota is met.">

	<!--- Better to let AWS figure the mail server, but will use an incoming one if it is set. --->
	<cfif NOT Len(Arguments.MailServer)>
		<cfset Arguments.MailServer = "email-smtp.#Arguments.AWS.getRegion()#.amazonaws.com">
	</cfif>
	<!---
	Get username and password from AWS Credentials if they aren't passed in.
	Using Credentials is safer as you can keep that file out of source control.
	--->
	<cfif NOT Len(Arguments.username)>
		<cfset Arguments.username = Arguments.AWS.Credentials.get("SMTP_username")>
	</cfif>
	<cfif NOT Len(Arguments.password)>
		<cfset Arguments.password = Arguments.AWS.Credentials.get("SMTP_password")>
	</cfif>

	<cfset setUpVariables(ArgumentCollection=Arguments)>

	<!--- To make sure that we are locking on the same AWS credentials only. --->
	<cfset Variables.LockID = Hash(Variables.AWS.getAccessKey())>
	
	<cfreturn This>
</cffunction>

<cffunction name="checkMailService" access="public" returntype="void" output="no">

	<!--- No need to check the Mail Service when using SES. --->

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
	-- No more than once per every 10% of quote.
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

<cffunction name="sendEmail" access="private" returntype="boolean" output="no">
	
	<cfset var sent = false>

	<!---
	Here is one of the key pieces of functionality for Mailer SES.
	It checks the quota and won't send if the threshold has been it.
	If it can, it will revert to sending out via the traditional Mailer.
	--->
	<cfif isUnderSESLimit()>
		<!---
		Since this extends com.sebtools.Mailer, the sendMail method there will do what we need.
		We could have had our own call to the API here, but using cfmail does everything we need without having to recreate it here.
		One advantage to switching to an API call later, however, would be getting data back about the send.
		http://docs.aws.amazon.com/ses/latest/APIReference/API_SendEmail.html
		--->
		<cfset sent = Super.sendEmail(ArgumentCollection=Arguments)>
	<cfelseif StructKeyExists(Variables,"Mailer")>
		<!--- If available, send mail out using the backup Mailer after the quota is met. --->
		<cfset sent = Variables.Mailer.sendEmail(ArgumentCollection=Arguments)>
	<cfelse>
		<cfthrow message="Message will exceed SES limit." type="Mailer" errorcode="SESLimit">
	</cfif>
	
	<cfreturn sent>
</cffunction>

<cffunction name="_GetSendQuota" access="private" returntype="struct" output="no">
	
	<cfreturn callAPI("GetSendQuota")>
</cffunction>

<cffunction name="callAPI" access="private" returntype="struct" output="false" hint="I invoke an Amazon REST Call.">
	<cfargument name="Action" type="string" required="true" hint="The AWS API action being called.">
	<cfargument name="method" type="string" default="GET" hint="The HTTP method to invoke.">
	<cfargument name="parameters" type="struct" default="#structNew()#" hint="An struct of HTTP URL parameters to send in the request.">

	<cfset Arguments.subdomain = "email">

	<cfreturn Variables.AWS.callAPI(ArgumentCollection=Arguments)>
</cffunction>

</cfcomponent>