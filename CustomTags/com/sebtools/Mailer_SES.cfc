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
	<cfset var hasAttachments = ( StructKeyExists(Arguments,"Attachments") AND Len(Trim(Arguments.Attachments)) )>
	<!--- Kind of a pain to send attachments with SES (also they have a file) limit, so (for now) any messages with attachments will be sent through the local mail server. --->

	<!---
	Here is one of the key pieces of functionality for Mailer SES.
	It checks the quota and won't send if the threshold has been it.
	If it can, it will revert to sending out via the traditional Mailer.
	--->
	<cfif isWithinLimit AND isFromVerified AND NOT hasAttachments>
		<cfset sent = sendEmail_Internal(ArgumentCollection=Arguments)>
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
		<cfif hasAttachments>
			<cfthrow message="Mailer is currently unable to send messages with attachments through SES." type="Mailer" errorcode="SESLimit">
		</cfif>
	</cfif>

	<cfreturn sent>
</cffunction>

<cffunction name="sendEmail_Internal" access="private" returntype="boolean" output="no">

	<cfset var result = false>

	<cfif NOT ( StructKeyExists(Arguments,"mailerID") AND NOT Arguments.mailerID CONTAINS "ColdFusion" )>
		<cfset Arguments.mailerID = "Amazon SES (API)">
	</cfif>

	<!--- For now, we're doing a simple shield against an external process setting the mail server wrong. Need a better permanent fix here. --->
	<cfset Arguments.MailServer = Variables.MailServer>

	<!--- This needs to be done here so that the mail server won't get passed through from the SES version to the non-SES version. --->
	<cfif StructKeyExists(Arguments,"MailServer") AND NOT StructKeyExists(Arguments,"Server")>
		<cfset Arguments.Server = Arguments.MailServer>
	</cfif>
	<cfif NOT StructKeyExists(Arguments,"Server")>
		<cfset Arguments.Server = Variables.MailServer>
	</cfif>

	<!---
	Get username and password from AWS Credentials if they aren't passed in.
	Using Credentials is safer as you can keep that file out of source control.
	--->
	<cfif NOT ( StructKeyExists(Arguments,"username") AND Len(Arguments.username) )>
		<cfset Arguments.username = Variables.AWS.Credentials.get("SMTP_username")>
	</cfif>
	<cfif NOT ( StructKeyExists(Arguments,"password") AND Len(Arguments.password) )>
		<cfset Arguments.password = Variables.AWS.Credentials.get("SMTP_password")>
	</cfif>

	<cfif
			StructKeyExists(Arguments,"Contents") AND Len(Arguments.Contents)
		AND	NOT ( StructKeyExists(Arguments,"text") AND Len(Trim(Arguments.text)) )
		AND	NOT ( StructKeyExists(Arguments,"html") AND Len(Trim(Arguments.html)) )
	>
		<cfif StructKeyExists(Arguments,"type") AND Arguments.type EQ "html">
			<cfset Arguments.html = Arguments.Contents>
		<cfelse>
			<cfset Arguments.text = Arguments.Contents>
		</cfif>
	</cfif>

	<cfset Arguments.To = getEmailAddress(Arguments.To)>
	<cftry>
		<cfset result = Variables.SES.sendEmail(
			ArgumentCollection=Arguments
		)>
	<cfcatch>
		<cfif CFCATCH.Message CONTAINS "Missing">
			<cfset Arguments.To = getEmailAddress(Arguments.To)>
			<cfif StructKeyExists(Arguments,"CC")>
				<cfset Arguments.CC = getEmailAddress(Arguments.CC)>
			</cfif>
			<cfif StructKeyExists(Arguments,"BCC")>
				<cfset Arguments.BCC = getEmailAddress(Arguments.BCC)>
			</cfif>
			<cftry>
				<cfset result = Variables.SES.sendEmail(
					ArgumentCollection=Arguments
				)>
			<cfcatch>
				<cfset Arguments.ErrorMsg = CFCATCH.message>
				<cfset logSend(argumentCollection=arguments)>
				<cfset rethrowMessage(CFCATCH,"#CFCATCH.message# (to=#Arguments.To#)")>
			</cfcatch>
			</cftry>
		</cfif>
		<cfset Arguments.ErrorMsg = CFCATCH.message>
		<cfset logSend(argumentCollection=arguments)>
		<cfset rethrowMessage(CFCATCH,"#CFCATCH.message# (to=#Arguments.To#)")>
	</cfcatch>
	</cftry>

	<cfif IsSimpleValue(result)>
		<cfset Arguments.MessageID = result>
	<cfelse>
		<cfset Arguments.MessageID = result.XmlText>
	</cfif>

	<cfset logSend(argumentCollection=arguments)>

	<cfreturn true>
</cffunction>

<!--- https://blog.pengoworks.com/index.cfm/2011/5/26/Modifying-the-message-in-a-CFCATCH-before-rethrowing-error --->
<cffunction name="rethrowMessage" access="private" returntype="void" output="false" hint="Rethrow a CFCATCH error, but allows customizing the message key">
	<cfargument name="cfcatch" type="any" required="true">
	<cfargument name="message" type="string" required="false">

	<cfset var exception = "">

	<cfif NOT StructKeyExists(Arguments, "message")>
		<cfset Arguments.message = Arguments.cfcatch.message>
	</cfif>

	<cfset exception = createObject("java", "java.lang.Exception").init(Arguments.message)>
	<cfset exception.initCause(Arguments.cfcatch.getCause())>
	<cfset exception.setStackTrace(Arguments.cfcatch.getStackTrace())>

	<cfthrow object="#exception#">

</cffunction>

</cfcomponent>
