<!--- 2.1 --->
<!--- Last Updated: 2014-08-22 --->
<!--- Created by Steve Bryant 2004-12-08 --->
<!--- Requires Coldfusion 8 or higher --->
<cfcomponent displayname="Mailer" hint="I handle sending of email notices. The advantage of using Mailer instead of cfmail is that I can be instantiated with information and then passed as an object to a component that sends email, circumventing the need to pass a bunch of email-related information to each component that sends email.">

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
	<cfargument name="port" type="string" required="false">
	<cfargument name="useTLS" type="boolean" required="false">
	<cfargument name="ErrorTo" type="string" default="">
	<cfargument name="verify" type="boolean" default="false">
	<cfargument name="Scheduler" type="any" required="false">
	<cfargument name="Observer" type="any" required="false">
	
	<cfset setUpVariables(ArgumentCollection=Arguments)>

	<!--- If Scheduler is passed is, make sure it regularly checks the mail service. --->
	<cfif StructKeyExists(Variables,"Scheduler")>
		<cfinvoke component="#Variables.Scheduler#" method="setTask">
			<cfinvokeargument name="Name" value="Mailer: Check Mail Server">
			<cfinvokeargument name="ComponentPath" value="com.sebtools.Mailer">
			<cfinvokeargument name="Component" value="#This#">
			<cfinvokeargument name="MethodName" value="checkMailService">
			<cfinvokeargument name="interval" value="hourly">
		</cfinvoke>
	</cfif>

	<cfset checkMailService()>
	
	<cfreturn This>
</cffunction>

<cffunction name="setUpVariables" access="private" returntype="void" output="no">
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
	<cfargument name="port" type="string" required="false">
	<cfargument name="useTLS" type="boolean" required="false">
	<cfargument name="ErrorTo" type="string" default="">
	<cfargument name="verify" type="boolean" default="false">
	<cfargument name="Scheduler" type="any" required="false">
	<cfargument name="Observer" type="any" required="false">

	<cfset var key = "">

	<!--- Convert init arguments into variables. --->
	<cfloop collection="#Arguments#" item="key">
		<cfset variables[key] = Arguments[key]>
		<cfif isObject(Arguments[key])>
			<cfset This[key] = Arguments[key]>
		</cfif>
	</cfloop>

	<!--- From and To are only defaults. --->
	<cfset StructDelete(Variables,"From")>
	<cfset StructDelete(Variables,"To")>
	<cfset variables.DefaultFrom = arguments.From>
	<cfset variables.DefaultTo = arguments.To>
	
	<cfset variables.Notices = StructNew()>
	<cfset variables.isLogging = false>
	

	<cfif NOT (
			Len(arguments.MailServer)
		AND	Len(arguments.From)
	)>
		<cfset arguments.mode = "Sim">
	</cfif>
	<cfif NOT StructKeyExists(arguments,"mode")>
		<cfif getMetaData(this).name CONTAINS "Sim">
			<cfset arguments.mode = "Sim">
		<cfelse>
			<cfset arguments.mode = "Live">
		</cfif>
	</cfif>
	
	<cfset setMode(arguments.mode)>
	
	<cfif StructKeyExists(Variables,"DataMgr")>
		<cfif Arguments.log OR variables.mode EQ "Sim" OR variables.verify>
			<cfset startLogging(variables.DataMgr)>
		</cfif>
	</cfif>

</cffunction>

<cffunction name="addNotice" access="public" returntype="void" output="no" hint="I add a notice to the mailer.">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="Subject" type="string" required="yes">
	<cfargument name="Contents" type="string" required="no">
	<cfargument name="To" type="string" default="">
	<cfargument name="From" type="string" default="">
	<cfargument name="datakeys" type="string" default="">
	<cfargument name="type" type="string" default="text">
	<cfargument name="CC" type="string" default="">
	<cfargument name="BCC" type="string" default="">
	<cfargument name="ReplyTo" type="string" default="">
	<cfargument name="Attachments" type="string" default="">
	<cfargument name="html" type="string" default="">
	<cfargument name="text" type="string" default="">
	<cfargument name="username" type="string" default="">
	<cfargument name="password" type="string" default="">
	<cfargument name="FailTo" type="string" default="">
	<cfargument name="mailerID" type="string" default="ColdFusion MX Application Server">
	<cfargument name="wraptext" type="string" default="800">
	<cfargument name="Sender" type="string" default="">
	
	<cfif NOT
		(
				( StructKeyExists(arguments,"Contents") AND Len(arguments.Contents) )
			OR	( StructKeyExists(arguments,"html") AND Len(arguments.html) )
			OR	( StructKeyExists(arguments,"text") AND Len(arguments.text) )
		)
	>
		<cfthrow message="If Contents argument is not provided than either html or text arguments must be." type="Mailer" errorcode="ContentsRequired">
	</cfif>
	
	<cfset variables.Notices[arguments.name] = Duplicate(arguments)>
	
</cffunction>

<cffunction name="fixEmail" access="public" returntype="string" output="no" hint="I fix an email address (or attempt to).">
	<cfargument name="email" type="string" required="yes">
	
	<!--- <cfif Len(Arguments.email)>
			<cfif REFind("(\[|\(|<)",Arguments.email)>
				<cfset Arguments.email = Left(Arguments.email,REFind("(\[|\(|<)",Arguments.email) -1).concat(ReplaceNoCase(ReplaceNoCase(Mid(Arguments.email,REFind("(\[|\(|<)",Arguments.email),Len(Arguments.email)),',','.','ALL'),' ','','ALL'))>
			</cfif>
		</cfif> --->
	
	<cfreturn Arguments.email>
</cffunction>

<cffunction name="getData" access="public" returntype="struct" output="no" hint="I get the data stored in the Mailer component.">
	<cfreturn variables.RootData>
</cffunction>

<cffunction name="getDataKeys" access="public" returntype="string" output="no" hint="I get the datakeys for the given email notice. The datakeys are the items that can/should be overridden by incoming data.">
	<cfargument name="name" type="string" required="yes">
	
	<cfset var result = "">
	
	<cfif StructKeyExists(variables.Notices, arguments.name)>
		<cfset result = variables.Notices[arguments.name].DataKeys>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getEmailAddress" access="public" returntype="string" output="no">
	<cfargument name="string" type="string" required="true">
	<cfreturn ArrayToList(reMatchNoCase("[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,63}", Arguments.string))>
</cffunction>

<cffunction name="getFrom" access="public" returntype="string" output="no">
	<cfreturn variables.DefaultFrom>
</cffunction>

<cffunction name="getIsLogging" access="public" returntype="boolean" output="no">
	<cfreturn variables.isLogging>
</cffunction>

<cffunction name="getMailServer" access="public" returntype="string" output="no">
	<cfreturn variables.MailServer>
</cffunction>

<cffunction name="getMessages" access="public" returntype="query" output="no">
	
	<cfif StructKeyExists(variables,"DataMgr")>
		<cfset startLogging(variables.DataMgr)>
	</cfif>
	
	<cfreturn variables.DataMgr.getRecords(tablename=variables.logtable,fieldlist="LogID,DateSent,To,Subject,ReplyTo")>
</cffunction>

<cffunction name="getMessage" access="public" returntype="query" output="no">
	<cfargument name="LogID" type="numeric" required="yes">
	
	<cfif StructKeyExists(variables,"DataMgr")>
		<cfset startLogging(variables.DataMgr)>
	</cfif>
	
	<cfreturn variables.DataMgr.getRecord(variables.logtable,arguments)>
</cffunction>

<cffunction name="getLogTable" access="public" returntype="string" output="no">
	<cfreturn variables.logtable>
</cffunction>

<cffunction name="getNotices" access="public" returntype="struct" output="no">
	<cfreturn variables.Notices>
</cffunction>

<cffunction name="getTo" access="public" returntype="string" output="no">
	<cfreturn variables.Defaultto>
</cffunction>

<cffunction name="removeNotice" access="public" returntype="void" output="no" hint="I remove a notice from the mailer.">
	<cfargument name="name" type="string" required="yes">
	
	<cfset StructDelete(variables.Notices,arguments.name)>
	
</cffunction>

<cffunction name="resendEmails" access="public" returntype="void" output="no">
	<cfargument name="LogIDs" type="string" required="true">
	
	<cfset var qMailLogs = 0>
	<cfset var sMail = 0>
	<cfset var keys = "To,Subject,Contents,From,CC,BCC,type,ReplyTo,Attachments,html,text,username,password,FailTo,wraptext,notice">
	<cfset var key = "">

	<cfif StructKeyExists(Variables,"DataMgr")>
		<cfquery name="qMailLogs" datasource="#Variables.DataMgr.getDatasource()#">
		SELECT	*
		FROM	#logtable#
		WHERE	LogID IN (<cfqueryparam value="#Arguments.LogIDs#" cfsqltype="cf_sql_integer" list="true">)
		</cfquery>

		<cfoutput query="qMailLogs">
			<cfset sMail = StructNew()>
			<cfloop list="#keys#" index="key">
				<cfif Len(Trim(qMailLogs[key][CurrentRow]))>
					<cfset sMail[key] = qMailLogs[key][CurrentRow]>
				</cfif>
			</cfloop>
			<cfset sMail["ResendOfLogID"] = LogID>
			<cfset StructDelete(sMail,"MailMode")>
			<cfset send(ArgumentCollection=sMail)>
		</cfoutput>
	<cfelse>
		<cfthrow type="Mailer" message="DataMgr is required for resendEmails. The current Mailer object does not have access to DataMgr.">
	</cfif>
	
</cffunction>

<cffunction name="send" access="public" returntype="boolean" output="no" hint="I send an email message and indicate if the send was successful.">
	<cfargument name="To" type="string" default="#variables.DefaultTo#">
	<cfargument name="Subject" type="string" required="yes">
	<cfargument name="Contents" type="string" required="no">
	<cfargument name="From" type="string" default="#variables.DefaultFrom#">
	<cfargument name="CC" type="string" default="">
	<cfargument name="BCC" type="string" default="">
	<cfargument name="type" type="string" default="text">
	<cfargument name="ReplyTo" type="string" default="#variables.ReplyTo#">
	<cfargument name="Attachments" type="string" default="">
	<cfargument name="html" type="string" default="">
	<cfargument name="text" type="string" default="">
	<cfargument name="username" type="string" default="#variables.username#">
	<cfargument name="password" type="string" default="#variables.password#">
	<cfargument name="FailTo" type="string" default="">
	<cfargument name="mailerID" type="string" default="ColdFusion Application Server">
	<cfargument name="wraptext" type="string" default="800">
	<cfargument name="Sender" type="string" default="#variables.Sender#">
	<cfargument name="MailServer" type="string" default="#variables.MailServer#">
	<cfargument name="verify" type="boolean" default="false">
	
	<cfset var sent = false>
	<cfset var attachment = "">
	<cfset var e = "">
	
	<!--- Need to check for variables.verify here instead of cfargument to maintain backwards compatibility --->
	<cfif StructKeyExists(Variables,"verify")>
		<cfset Arguments.verify = Variables.verify>
	</cfif>
	
	<cfif NOT StructKeyExists(arguments,"Contents") AND NOT (Len(arguments.html) OR Len(arguments.text))>
		<cfthrow message="Send method requires Contents argument or html or text arguments.">
	</cfif>

	<!--- double check for invalid email addresses and fix them if possible --->
	<cfloop list="From,CC,BCC,To,ReplyTo,Sender" index="e">
		<cfif StructKeyExists(Arguments,e) AND Len(Arguments[e])>
			<cfset Arguments[e] = fixEmail(Arguments[e])>
		</cfif>
	</cfloop>
	
	<!--- Filter invalid recipients --->
	<cfif variables.mode EQ "Live">
		<cfset arguments = filterRecipients(arguments)>
	</cfif>
	
	<!--- If we have no "To" then don't sent --->
	<cfif NOT Len(arguments.To)>
		<cfreturn false>
	</cfif>
	
	<!--- If sender is set and reply to is not, then set reply to as sender (sort of a back-up in case sender is not honored) --->
	<cfif Len(Trim(arguments.Sender)) AND NOT Len(Trim(arguments.ReplyTo))>
		<cfset arguments.ReplyTo = arguments.Sender>
	</cfif>
	
	<!---
	If contents isn't passed in but only one of text/html is, set contents to the one passed in.
	(to avoid CF trying to send multi-part email)
	--->
	<cfif NOT StructKeyExists(arguments,"Contents")>
		<cfif Len(arguments.text) AND NOT Len(arguments.html)>
			<cfset arguments.Contents = arguments.text>
			<cfset arguments.type = "text">
			<cfset arguments.text = "">
		</cfif>
		<cfif Len(arguments.html) AND NOT Len(arguments.text)>
			<cfset arguments.Contents = arguments.html>
			<cfset arguments.type = "HTML">
			<cfset arguments.html = "">
		</cfif>
	</cfif>
	
	<cfif variables.mode EQ "Live">
		<cfset sent = sendEmail(argumentCollection=arguments)>
	</cfif>
	
	<cfset logSend(argumentCollection=arguments)>
	
	<cfif Arguments.verify>
		<cfset verifySent(ArgumentCollection=Arguments)>
	</cfif>
	
	<cfreturn sent>
</cffunction>

<cffunction name="sendEmail" access="package" returntype="boolean" output="no">
	
	<cfset var sent = false>
	<cfset var Attachment = "">
	
	<cfif StructKeyExists(variables,"port") AND Len(variables.port) AND isNumeric(variables.port)>
		<cfparam name="arguments.port" default="#variables.port#">
	</cfif>
	<cfif StructKeyExists(variables,"useTLS") AND isBoolean(variables.useTLS)>
		<cfparam name="arguments.useTLS" default="#variables.useTLS#">
	</cfif>

	<cfif StructKeyExists(Arguments,"MailServer") AND NOT StructKeyExists(Arguments,"Server")>
		<cfset Arguments.Server = Arguments.MailServer>
	</cfif>
	
	<cfif Len(arguments.text) OR Len(arguments.html)>
		<cfmail attributeCollection="#arguments#"><cfif Len(Trim(arguments.ReplyTo))><cfmailparam name="Reply-To" value="#Trim(arguments.ReplyTo)#"></cfif><cfif Len(Trim(arguments.Sender))><cfmailparam name="Sender" value="#Trim(arguments.Sender)#"></cfif>
			<cfif Len(arguments.text)>
				<cfmailpart type="text" charset="utf-8" wraptext="#arguments.wraptext#">#arguments.text#</cfmailpart>
			</cfif>
			<cfif Len(arguments.html)>
				<cfmailpart type="html" charset="utf-8" wraptext="#arguments.wraptext#">#arguments.html#</cfmailpart>
			</cfif>
			<cfif Len(arguments.Attachments)><cfloop index="Attachment" list="#arguments.Attachments#"><cfmailparam file="#Attachment#"></cfloop></cfif>
		</cfmail>
		<cfset sent = true>
	<cfelse>
		<cfmail attributeCollection="#arguments#"><cfif Len(Trim(arguments.ReplyTo))><cfmailparam name="Reply-To" value="#Trim(arguments.ReplyTo)#"></cfif><cfif Len(Trim(arguments.Sender))><cfmailparam name="Sender" value="#Trim(arguments.Sender)#"></cfif>#arguments.Contents#<cfif Len(Trim(arguments.Attachments))><cfloop index="Attachment" list="#arguments.Attachments#"><cfmailparam file="#Attachment#"></cfloop></cfif></cfmail>
		<cfset sent = true>
	</cfif>
	
	<cfreturn sent>
</cffunction>

<cffunction name="sendNotice" access="public" returntype="struct" output="no" hint="I send set/override any data based on the data given and send the given notice.">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="data" type="struct">
	
	<cfset var sMessage = getNoticeMessage(argumentCollection=arguments)>
	
	<cfinvoke
		method="send"
		argumentcollection="#sMessage#"
	>
	</cfinvoke>
	
	<cfreturn sMessage>
</cffunction>

<cffunction name="getNoticeMessage" access="public" returntype="struct" output="no">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="data" type="struct">
	
	<cfset var key = 0>
	<cfset var thisNotice = StructNew()>
	<cfset var missingkeys = "">
	<cfset var fields = "Subject,Contents,html,text">
	<cfset var field = "">
	<cfset var info = StructNew()>
	
	<cfif StructKeyExists(arguments,"data")>
		<cfset info = Duplicate(arguments.data)>
	</cfif>
	
	<!--- Put in RootData, if any --->
	<cfset StructAppend(info, variables.RootData , false)>
	
	<cflock timeout="40" throwontimeout="yes" name="Mailer_SendNotice" type="EXCLUSIVE">
		<cfset thisNotice = Duplicate(variables.Notices[arguments.name])>
	</cflock>
	
	<!--- If this notice should have incoming data, make sure all keys are present --->
	<cfif Len(thisNotice.datakeys)>
		<cfloop index="key" list="#thisNotice.datakeys#">
			<cfif NOT StructKeyExists(info,key)>
				<cfset missingkeys = ListAppend(missingkeys,key)>
			</cfif>
		</cfloop>
		<cfif Len(missingkeys)>
			<cfthrow message="This Mailer Notice (#arguments.name#) is missing the following required keys: #missingkeys#." type="MailerErr">
		</cfif>
	</cfif>
	
	<cfif StructKeyExists(arguments,"data")>
		<!--- If any data is passed, reset values and modify contents accordingly. --->
		<cfloop collection="#info#" item="key">
			<cfif StructKeyExists(info, key)>
				<!--- If this data key matches a key in the main struct for this notice, replace it --->
				<cfif key neq "username" AND key neq "password">
					<cfset thisNotice[key] = info[key]>
				</cfif>
				<!--- Modify any parameters for arguments that can have them modified --->
				<cfloop index="field" list="#fields#">
					<cfif StructKeyExists(thisNotice, field) AND FindNoCase("[#key#]", thisNotice[field])>
						<cfset thisNotice[field] = ReplaceNoCase(thisNotice[field], "[#key#]", info[key], "ALL")>
					</cfif>
				</cfloop>
			</cfif>
		</cfloop>
	</cfif>
	<cfloop collection="#arguments#" item="key">
		<cfif key neq "name" AND key neq "data" AND isSimpleValue(arguments[key]) AND key neq "username" AND key neq "password">
			<cfset thisNotice[key] = arguments[key]>
		</cfif>
	</cfloop>
	
	<!--- Setting defaults here instead of in addNotice() in case variables change between addNotice and sendNotice --->
	<cfif NOT Len(thisNotice.To)><cfset thisNotice.To = variables.DefaultTo></cfif>
	<cfif NOT Len(thisNotice.From)><cfset thisNotice.From = variables.DefaultFrom></cfif>
	<cfif NOT Len(thisNotice.username)><cfset thisNotice.username = variables.username></cfif>
	<cfif NOT Len(thisNotice.password)><cfset thisNotice.password = variables.password></cfif>
	<cfset thisNotice["notice"] = arguments.name>
	
	<cfreturn thisNotice>
</cffunction>

<cffunction name="getMode" access="public" returntype="string" output="no">
	<cfreturn variables.mode>
</cffunction>

<cffunction name="setMode" access="public" returntype="void" output="no">
	<cfargument name="mode" type="string" required="yes">
	
	<cfset var SimModes = "Sim,Dev">
	<cfset var sAnnounce = {}>
	
	<cfif ListFindNoCase(SimModes,arguments.mode)>
		<cfset variables.mode = "Sim">
	<cfelse>
		<cfset variables.mode = "Live">
	</cfif>

	<!--- Announce setMode --->
	<cfif StructKeyExists(variables,"Observer")>
		<cfset sAnnounce["mode"] = Arguments.mode>
		<cfset variables.Observer.announce("Mailer mode set",sAnnounce)>
	</cfif>
	
</cffunction>

<cffunction name="startLogging" access="public" returntype="void" output="no" hint="I make sure that all email sent from Mailer is logged in the mailerLogs table of the datasource managed by the given DataMgr.">
	<cfargument name="DataMgr" type="any" required="yes">
	<cfargument name="tablename" type="string" default="#variables.logtable#">
	
	<cfset var dbXml = "">
	
	<cfif NOT variables.isLogging>
		<cfset dbXml = getDbXml(arguments.tablename)>
		
		<cfset variables.logtable = arguments.tablename>
		<cfset variables.DataMgr = arguments.DataMgr>
		
		<cfset variables.DataMgr.loadXml(dbXml,true,true)>
		
		<cfset variables.isLogging = true>
	</cfif>
	
</cffunction>

<cffunction name="stopLogging" access="public" returntype="void" output="no" hint="I stop the logging of email sent from Mailer.">
	
	<cfset variables.isLogging = false>
	
</cffunction>

<cffunction name="isEmail" access="public" returntype="boolean" output="no">
	<cfargument name="string" type="string" required="yes">
	
	<cfreturn ( ReFindNoCase("^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$",string) GT 0 )>
</cffunction>

<cffunction name="filterRecipients" access="private" returntype="struct" output="no">
	<cfargument name="data" type="struct" required="yes">
	
	<cfset var recipfields = "To,CC,BCC">
	<cfset var key = "">
	<cfset var elem = "">
	<cfset var temp = "">
	
	<cfloop collection="#arguments.data#" item="key">
		<cfif ListFindNoCase(recipfields,key)>
			<cfset arguments[key] = ListChangeDelims(arguments[key],",",";")>
			<cfset temp = "">
			<cfloop list="#arguments.data[key]#" index="elem">
				<!--- Filter example records unless logging is enabled --->
				<cfif variables.isLogging OR NOT (elem CONTAINS "@example.com")>
					<cfset temp = ListAppend(temp,elem)>
				</cfif>
			</cfloop>
			<cfset arguments.data[key] = temp>
		</cfif>
	</cfloop>
	
	<cfreturn arguments.data>
</cffunction>

<cffunction name="logSend" access="private" returntype="void" output="no">
	
	<cfif variables.isLogging>
		<cfset arguments.MailMode = getMode()>
		<cfset arguments.DateSent = now()>
		<cfset variables.DataMgr.insertRecord(variables.logtable,variables.DataMgr.truncate(variables.logtable,arguments))>
	</cfif>
	
</cffunction>

<cffunction name="getVerify" access="public" returntype="boolean" output="no">
	<cfreturn variables.verify>
</cffunction>

<cffunction name="getErrorTo" access="public" returntype="string" output="no">
	
	<cfset var ErrorTo = "">
	
	<cfif StructKeyExists(Variables,"ErrorTo")>
		<cfset ErrorTo = Variables.ErrorTo>
	</cfif>
	
	<cfreturn ErrorTo>
</cffunction>

<cffunction name="setVerify" access="public" returntype="void" output="no">
	<cfargument name="verify" type="boolean" required="yes">
	
	<cfset variables.verify = arguments.verify>
	
</cffunction>

<cffunction name="setErrorTo" access="public" returntype="void" output="no">
	<cfargument name="ErrorTo" type="string" required="yes">
	
	<cfset variables.ErrorTo = arguments.ErrorTo>
	
</cffunction>

<cffunction name="sendErrorEmail" access="private" returntype="void" output="no">
		
	<cfset var sError = {}>
	<cfset var ErrorContent = "">
	<cfset var arg = "">
	
	<cfif StructKeyExists(variables,"ErrorTo") AND Len(variables.ErrorTo)>
		<cfset sError["To"] = variables.ErrorTo>
		<cfset sError["Subject"] = "Failed email">
		<cfset sError["type"] = "text">
		<cfoutput>
			<cfsavecontent variable="ErrorContent">
			Failed email details:
			<cfloop collection="#Arguments#" item="arg"> 
				#arg#: #StructFind(Arguments,arg)#
			</cfloop>
			</cfsavecontent>
		</cfoutput>
		<cfset sError["Contents"] = ErrorContent>
		<cfset sError["verify"] = false>
		
		<cfset send(ArgumentCollection=sError)>
	</cfif>
</cffunction>

<cffunction name="checkMailService" access="public" returntype="void" output="no">

	<cfset var restart = false>
	<cfset var spool = "">
	<cfset var sFactory = 0>
	<cfset var MailSpoolService = 0>

	<cflock name="Mailer_CheckMailService" timeout="60">
		<!--- Source: http://stackoverflow.com/questions/94932/coldfusion-mail-queue-stops-processing --->
		<cfdirectory action="list" directory="#Server.ColdFusion.rootdir#\Mail\Spool\" name="spool" sort="datelastmodified">

		<cfif isDate(spool.datelastmodified) AND datediff('n', spool.datelastmodified, now()) gt 60>
			<cfset restart = true>
		</cfif>

		<cfif restart>
			<cflock name="Mailer_RestartMailService" timeout="30">
				<cfset sFactory = CreateObject("java","coldfusion.server.ServiceFactory")>
				<cfset MailSpoolService = sFactory.mailSpoolService>
				<cfset MailSpoolService.stop()>
				<cfset MailSpoolService.start()>
		    </cflock>
		</cfif>
	</cflock>

</cffunction>

<cffunction name="verifySent" access="public" returntype="void" output="no">
	<cfargument name="To" type="string" required="yes">
	<cfargument name="Subject" type="string" required="yes">
	<cfargument name="From" type="string" required="yes">
	<cfargument name="CC" type="string" required="yes">
	<cfargument name="BCC" type="string" required="yes">
	<cfargument name="ReplyTo" type="string" required="yes">
	
	<cfset var qLogs = 0>
	<cfset var sLogArgs = {}>
	<cfset var aFilters = ArrayNew(1)>
	<cfset var sFilter = {}>
	<cfset var currentTime = now()>
	<cfset var fiveMinAgo = dateAdd("n", -5, currentTime)>
	<!---
	Set BeforeSend to 5 minutes ago so we can check if the email was sent in the last five minutes.
	This should avoid conflict with previous similar emails.
	--->
	<cfset var BeforeSend = CreateDateTime(Year(fiveMinAgo),Month(fiveMinAgo),Day(fiveMinAgo),Hour(fiveMinAgo),Minute(fiveMinAgo),Second(fiveMinAgo))>
	<cfset var RightNow = CreateDateTime(Year(currentTime),Month(currentTime),Day(currentTime),Hour(currentTime),Minute(currentTime),Second(currentTime))>
	
	<cfset sLogArgs["To"] = Arguments.To>
	<cfset sLogArgs["Subject"] = Arguments.Subject>
	<cfset sLogArgs["From"] = Arguments.From>
	<cfset sLogArgs["CC"] = Arguments.CC>
	<cfset sLogArgs["BCC"] = Arguments.BCC>
	<cfset sLogArgs["ReplyTo"] = Arguments.ReplyTo>

	<cfset sFilter = {field="DateSent",operator="GT",value="#BeforeSend#"}>
	<cfset ArrayAppend(aFilters,sFilter)>
	
	<cfset qLogs = variables.DataMgr.getRecords(tablename=variables.logtable,data=sLogArgs,filters=aFilters)>
	
	<cfif NOT qLogs.RecordCount>
		<cfset sendErrorEmail(ArgumentCollection=sLogArgs)>
	</cfif>
		
</cffunction>

<cffunction name="getDbXml" access="private" returntype="string" output="no" hint="I return the XML for the tables needed for Searcher to work.">
	<cfargument name="tablename" type="string" default="#variables.logtable#">
	
	<cfset var tableXML = "">
	
	<cfsavecontent variable="tableXML"><cfoutput>
	<tables>
		<table name="#arguments.tablename#">
			<field ColumnName="LogID" CF_DataType="CF_SQL_INTEGER" PrimaryKey="true" Increment="true" />
			<field ColumnName="DateSent" CF_DataType="CF_SQL_DATE" Special="CreationDate" />
			<field ColumnName="To" CF_DataType="CF_SQL_VARCHAR" Length="250" />
			<field ColumnName="Subject" CF_DataType="CF_SQL_VARCHAR" Length="180" />
			<field ColumnName="Contents" CF_DataType="CF_SQL_LONGVARCHAR" />
			<field ColumnName="From" CF_DataType="CF_SQL_VARCHAR" Length="180" />
			<field ColumnName="CC" CF_DataType="CF_SQL_VARCHAR" Length="250" />
			<field ColumnName="BCC" CF_DataType="CF_SQL_VARCHAR" Length="250" />
			<field ColumnName="type" CF_DataType="CF_SQL_VARCHAR" Length="30" />
			<field ColumnName="ReplyTo" CF_DataType="CF_SQL_VARCHAR" Length="180" />
			<field ColumnName="Attachments" CF_DataType="CF_SQL_LONGVARCHAR" />
			<field ColumnName="html" CF_DataType="CF_SQL_LONGVARCHAR" />
			<field ColumnName="text" CF_DataType="CF_SQL_LONGVARCHAR" />
			<field ColumnName="username" CF_DataType="CF_SQL_VARCHAR" Length="180" />
			<field ColumnName="password" CF_DataType="CF_SQL_VARCHAR" Length="180" />
			<field ColumnName="FailTo" CF_DataType="CF_SQL_VARCHAR" Length="180" />
			<field ColumnName="mailerID" CF_DataType="CF_SQL_VARCHAR" Length="250" />
			<field ColumnName="wraptext" CF_DataType="CF_SQL_VARCHAR" Length="40" />
			<field ColumnName="notice" CF_DataType="CF_SQL_VARCHAR" Length="180" />
			<field ColumnName="MailMode" CF_DataType="CF_SQL_VARCHAR" Length="10" />
			<field ColumnName="ResendOfLogID" CF_DataType="CF_SQL_INTEGER" />
		</table>
	</tables>
	</cfoutput></cfsavecontent>
	
	<cfreturn tableXML>
</cffunction>

</cfcomponent>