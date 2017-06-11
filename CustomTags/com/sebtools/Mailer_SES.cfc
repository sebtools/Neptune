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

	<cfset Variables.SES = Variables.AWS.getService("SES")>

	<cfreturn This>
</cffunction>

<cffunction name="checkMailService" access="public" returntype="void" output="no">

	<!--- No need to check the Mail Service when using SES. --->

</cffunction>

<cffunction name="sendEmail" access="package" returntype="boolean" output="no">
	
	<cfset var sent = false>
	<cfset var isWithinLimit = Variables.SES.isUnderSESLimit()>
	<cfset var isFromVerified = Variables.SES.isVerified(getEmailAddress(Arguments.From))>

	<!---
	Here is one of the key pieces of functionality for Mailer SES.
	It checks the quota and won't send if the threshold has been it.
	If it can, it will revert to sending out via the traditional Mailer.
	--->
	<cfif isWithinLimit AND isFromVerified>
		<cfif NOT ( StructKeyExists(Arguments,"mailerID") AND NOT Arguments.mailerID CONTAINS "ColdFusion" )>
			<cfset Arguments.mailerID = "Amazon SES (SMTP)">
		</cfif>
		<!--- For now, we're doing a simple shield against an external process setting the mail server wrong. Need a better permanent fix here. --->
		<cfset Arguments.MailServer = Variables.MailServer>
		<!---
		Since this extends com.sebtools.Mailer, the sendMail method there will do what we need.
		We could have had our own call to the API here, but using cfmail does everything we need without having to recreate it here.
		One advantage to switching to an API call later, however, would be getting data back about the send.
		http://docs.aws.amazon.com/ses/latest/APIReference/API_SendEmail.html
		--->
		<cfset sent = Super.sendEmail(ArgumentCollection=Arguments)>
	<cfelseif StructKeyExists(Variables,"Mailer")>
		<!--- If available, send mail out using the backup Mailer after the quota is met or for from addresses that cannot sent through SES. --->
		<cfset sent = Variables.Mailer.sendEmail(ArgumentCollection=Arguments)>
	<cfelse>
		<cfif NOT isFromVerified>
			<cfthrow message="#Arguments.From# is not a verified sender for SES." type="Mailer" errorcode="SESNotVerified">	
		</cfif>
		<cfif NOT isWithinLimit>
			<cfthrow message="Message will exceed SES limit." type="Mailer" errorcode="SESLimit">	
		</cfif>
	</cfif>
	
	<cfreturn sent>
</cffunction>

</cfcomponent>