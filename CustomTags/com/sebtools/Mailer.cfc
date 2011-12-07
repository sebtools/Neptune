<!--- 2.0 Beta 1 --->
<!--- Last Updated: 2011-30-30 --->
<!--- Created by Steve Bryant 2004-12-08 --->
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
	
	<cfset variables.MailServer = arguments.MailServer>
	<cfset variables.DefaultFrom = arguments.From>
	<cfset variables.DefaultTo = arguments.To>
	<cfset variables.username = arguments.username>
	<cfset variables.password = arguments.password>
	<cfset variables.RootData = arguments.RootData>
	<cfset variables.ReplyTo = arguments.ReplyTo>
	<cfset variables.Sender = arguments.Sender>
	<cfset variables.logtable = arguments.logtable>
	
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
	
	<cfif StructKeyExists(arguments,"DataMgr")>
		<cfset variables.DataMgr = arguments.DataMgr>
		<cfif Arguments.log OR variables.mode EQ "Sim">
			<cfset startLogging(variables.DataMgr)>
		</cfif>
	</cfif>
	
	<cfreturn this>
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
	
	<cfset var sent = false>
	<cfset var attachment = "">
	
	<cfif NOT StructKeyExists(arguments,"Contents") AND NOT (Len(arguments.html) OR Len(arguments.text))>
		<cfthrow message="Send method requires Contents argument or html or text arguments.">
	</cfif>
	
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
	
	<cfreturn sent>
</cffunction>

<cffunction name="sendEmail" access="private" returntype="boolean" output="no">
	
	<cfset var sent = false>
	
	<cfif Len(arguments.text) OR Len(arguments.html)>
		<cfif Len(arguments.username) AND Len(arguments.password)>
			<cfmail to="#arguments.To#" from="#arguments.From#" subject="#arguments.Subject#" cc="#arguments.CC#" bcc="#arguments.BCC#" server="#arguments.MailServer#" failto="#arguments.failto#" mailerID="#arguments.mailerID#" wraptext="#arguments.wraptext#" username="#arguments.username#" password="#arguments.password#"><cfif Len(Trim(arguments.ReplyTo))><cfmailparam name="Reply-To" value="#Trim(arguments.ReplyTo)#"></cfif><cfif Len(Trim(arguments.Sender))><cfmailparam name="Sender" value="#Trim(arguments.Sender)#"></cfif>
				<cfif Len(arguments.text)>
					<cfmailpart type="text" charset="utf-8" wraptext="#arguments.wraptext#">#arguments.text#</cfmailpart>
				</cfif>
				<cfif Len(arguments.html)>
					<cfmailpart type="html" charset="utf-8" wraptext="#arguments.wraptext#">#arguments.html#</cfmailpart>
				</cfif>
				<cfif Len(arguments.Attachments)><cfloop index="Attachment" list="#arguments.Attachments#"><cfmailparam file="#Attachment#"></cfloop></cfif>
			</cfmail>
		<cfelse>
			<cfmail to="#arguments.To#" from="#arguments.From#" subject="#arguments.Subject#" cc="#arguments.CC#" bcc="#arguments.BCC#" server="#arguments.MailServer#" failto="#arguments.failto#" mailerID="#arguments.mailerID#" wraptext="#arguments.wraptext#"><cfif Len(Trim(arguments.ReplyTo))><cfmailparam name="Reply-To" value="#Trim(arguments.ReplyTo)#"></cfif><cfif Len(Trim(arguments.Sender))><cfmailparam name="Sender" value="#Trim(arguments.Sender)#"></cfif>
				<cfif Len(arguments.text)>
					<cfmailpart type="text" charset="utf-8" wraptext="#arguments.wraptext#">#arguments.text#</cfmailpart>
				</cfif>
				<cfif Len(arguments.html)>
					<cfmailpart type="html" charset="utf-8" wraptext="#arguments.wraptext#">#arguments.html#</cfmailpart>
				</cfif>
				<cfif Len(arguments.Attachments)><cfloop index="Attachment" list="#arguments.Attachments#"><cfmailparam file="#Attachment#"></cfloop></cfif>
			</cfmail>
		</cfif>
		<cfset sent = true>
	<cfelse>
		<cfif Len(arguments.username) AND Len(arguments.password)>
			<cfmail to="#arguments.To#" from="#arguments.From#" type="#arguments.type#" subject="#arguments.Subject#" cc="#arguments.CC#" bcc="#arguments.BCC#" server="#arguments.MailServer#" failto="#arguments.failto#" mailerID="#arguments.mailerID#" wraptext="#arguments.wraptext#" username="#arguments.username#" password="#arguments.password#"><cfif Len(Trim(arguments.ReplyTo))><cfmailparam name="Reply-To" value="#Trim(arguments.ReplyTo)#"></cfif><cfif Len(Trim(arguments.Sender))><cfmailparam name="Sender" value="#Trim(arguments.Sender)#"></cfif>#arguments.Contents#<cfif Len(Trim(arguments.Attachments))><cfloop index="Attachment" list="#arguments.Attachments#"><cfmailparam file="#Attachment#"></cfloop></cfif></cfmail>
		<cfelse>
			<cfmail to="#arguments.To#" from="#arguments.From#" type="#arguments.type#" subject="#arguments.Subject#" cc="#arguments.CC#" bcc="#arguments.BCC#" server="#arguments.MailServer#" failto="#arguments.failto#" mailerID="#arguments.mailerID#" wraptext="#arguments.wraptext#"><cfif Len(Trim(arguments.ReplyTo))><cfmailparam name="Reply-To" value="#Trim(arguments.ReplyTo)#"></cfif><cfif Len(Trim(arguments.Sender))><cfmailparam name="Sender" value="#Trim(arguments.Sender)#"></cfif>#arguments.Contents#<cfif Len(Trim(arguments.Attachments))><cfloop index="Attachment" list="#arguments.Attachments#"><cfmailparam file="#Attachment#"></cfloop></cfif></cfmail>
		</cfif>
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
	
	<cfif ListFindNoCase(SimModes,arguments.mode)>
		<cfset variables.mode = "Sim">
	<cfelse>
		<cfset variables.mode = "Live">
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
		<cfset arguments.DateSent = now()>
		<cfset variables.DataMgr.insertRecord(variables.logtable,variables.DataMgr.truncate(variables.logtable,arguments))>
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
		</table>
	</tables>
	</cfoutput></cfsavecontent>
	
	<cfreturn tableXML>
</cffunction>

</cfcomponent>