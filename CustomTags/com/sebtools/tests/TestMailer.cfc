<cfcomponent displayname="Mailer" extends="RecordsTester" output="no">

<cffunction name="setUp" access="public" returntype="void" output="no">
	
	<cfset var sConfig = StructFromArgs(datasource="#Application.DataMgr.getDatasource()#")>

	<cfset Variables.ServiceFactory = CreateObject("component","admin.meta.model.ServiceFactory").init(config=sConfig)>
	<cfset Variables.ServiceFactory.setScope(Variables)>
	<cfset loadServices()>

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

<cffunction name="shouldFixEmail" access="public" returntype="void" output="no"
	hint="Mailer should be able to fix basic mistakes in email addresses."
>

	<cfset assertEquals('josh@resonantmedia.com',Variables.Mailer.fixEmail('josh @resonantmedia,com'),"Failed to correct space and comma in non-aliased email address.")>
	<cfset assertEquals('good@resonantmedia.com',Variables.Mailer.fixEmail('good@resonantmedia,com'),"Failed to correct comma in non-aliased email address.")>
	<cfset assertEquals('better@resonantmedia.com',Variables.Mailer.fixEmail('better@resonantmedia.com'),"Failed to preserve valid email address.")>
	<cfset assertEquals('Better Option <better@resonantmedia.com>',Variables.Mailer.fixEmail('Better Option <better@resonantmedia,com>'),"Failed to correct comma in aliased email address.")>
	<cfset assertEquals('"Better Option" <better@resonantmedia.com>',Variables.Mailer.fixEmail('"Better Option" <better@resonantmedia,com>'),"Failed to correct comma in email address with quoted alias.")>
	<cfset assertEquals('"Better Option" <better@resonantmedia.com>',Variables.Mailer.fixEmail('"Better Option" <better @resonantmedia,com>'),"Failed to correct comma and space in email address with a quoated alias.")>
	<cfset assertEquals('"Option, Better" <better@resonantmedia.com>',Variables.Mailer.fixEmail('"Option, Better" <better @resonantmedia,com>'),"Failed to preserve comma in quoated alias.")>
	
</cffunction>

<cffunction name="getXML" access="private" returntype="string" output="no">
	<cfset var TestXML = "">
	
	<cfsavecontent variable="TestXML"><cfoutput><site>
		<components>
			<component name="DataMgr" path="com.sebtools.DataMgr">
				<argument name="datasource" arg="datasource" />
			</component>
			<component name="Mailer" path="admin.meta.model.Mailer">
				<argument name="DataMgr" ifmissing="skiparg" />
				<argument name="MailServer" value="mail.test.com" />
				<argument name="From" value="from@example.com" />
				<argument name="Mode" value="Sim" />
			</component>
		</components>
	</site></cfoutput></cfsavecontent>
	
	<cfreturn TestXML>
</cffunction>

<cffunction name="loadServices" access="private" returntype="void" output="no">
	
	<cfset Variables.ServiceFactory.loadXml(getXML())>
	<cfset Variables.ServiceFactory.getAllServices()>
	
</cffunction>

</cfcomponent>