<cfcomponent displayname="Mailer" extends="RecordsTester" output="no">

<cffunction name="setUp" access="public" returntype="void" output="no">
	
	<cfset loadExternalVars("Mailer,DataMgr")>
	
</cffunction>

<cffunction name="shouldFailedEmailSendAlert" access="public" returntype="void" output="no"
	hint="If Mailer is set to verify with an ErrorTo, it should send a failed email alert when an email send fails."
	mxunit:transaction="rollback"
>

	<cfset var sEmail = {To="testto@example.com",From="testfrom@example.com",Subject="Testing#GetTickCount()#",Contents="Testing",CC="",BCC="",ReplyTo=""}>
	<cfset var ErrorTo = "test#GetTickCount()#@example.com">
	<cfset var sErrorEmail = {}>
	<cfset var qLogs = 0>
	
	<!--- Need to reset these after test --->
	<cfset var CurrentVerify = Variables.Mailer.getVerify()>
	<cfset var CurrentErrorTo = Variables.Mailer.getErrorTo()>
	
	<cftry>
		<cfset assertEmailTestable()>
		<cfif NOT CurrentVerify>
			<cfset Variables.Mailer.setVerify(true)>
		</cfif>
		<cfif NOT Len(CurrentErrorTo)>
			<cfset Variables.Mailer.setErrorTo(ErrorTo)>
		<cfelse>
			<cfset ErrorTo = CurrentErrorTo>
		</cfif>
		<cfset Variables.Mailer.send(argumentCollection=sEmail)>
		<cfset qLogs = Variables.DataMgr.getRecords(tablename="mailerLogs",data=sEmail,fieldlist="LogID")>
		
		<cfset assertTrue(qLogs.RecordCount,"Mailer is not logging and verify is set to true.")>
		
		<!--- Now we'll delete the log entry and manually verify --->
		<cfoutput query="qLogs">
			<cfset Variables.DataMgr.removeRecord(LogID)>
		</cfoutput>
		
		<!--- Because there is no longer a log entry, a "failed email" alert should be sent to ErrorTo --->
		<cfset Variables.Mailer.verifySent(argumentCollection=sEmail)>
		
		<cfset sErrorEmail["when"] = now()>
		<cfset sErrorEmail["To"] = ErrorTo>
		<cfset sErrorEmail["Subject"] = "Failed email">
		
		<cfset assertEmailSent(argumentCollection=sErrorEmail)>
		
		<cfset Variables.Mailer.setVerify(CurrentVerify)>
		<cfset Variables.Mailer.setErrorTo(CurrentErrorTo)>
		
		<cfcatch>
			<cfset Variables.Mailer.setVerify(CurrentVerify)>
			<cfset Variables.Mailer.setErrorTo(CurrentErrorTo)>
		</cfcatch>
	</cftry>
	
</cffunction>

<cffunction name="shouldVerifyLogSent" access="public" returntype="void" output="no"
	hint="If Mailer is set to verify, it should log all emails."
	mxunit:transaction="rollback"
>

	<cfset var sEmail = {To="test@example.com",Subject="Testing#GetTickCount()#",Contents="Testing"}>
	<cfset var qLogs = 0>
	
	<cfset assertEmailTestable()>
	<cfset Variables.Mailer.setVerify(true)>
	<cfset Variables.Mailer.send(argumentCollection=sEmail)>
	<cfset qLogs = Variables.DataMgr.getRecords(tablename="mailerLogs",data=sEmail)>
	
	<cfset assertTrue(qLogs.RecordCount,"Mailer is not logging and verify is set to true.")>
	
</cffunction>

</cfcomponent>