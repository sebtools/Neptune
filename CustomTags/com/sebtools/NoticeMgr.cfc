<!--- 1.1.5 Build 10 --->
<!--- Last Updated: 2011-03-30 --->
<!--- Created by Steve Bryant 2006-12-07 --->
<!---
2006-12-07 SEB: Added getDatamgr(), getMailer() to return DataMgr and Mailer components
2007-02-02 SEB: Added removeNotice() method
2007-02-16 SEB: Added getMailerData()
2007-09-24 SEB: Added changeDataKeys()
2007-10-07 SEB: Version 1.0
2010-12-18 SEB: 1.0.1: This.DataMgr, This.Mailer
2011-03-01 SEB: 1.0.1: Works on DataMgr_Sim
--->
<cfcomponent displayname="Notices Manager" output="no" hint="I manage sending and editing notice email messages.">

<cffunction name="init" access="public" returntype="NoticeMgr" output="no" hint="I instantiate and return this component.">
	<cfargument name="DataMgr" type="DataMgr" required="yes">
	<cfargument name="Mailer" type="Mailer" required="yes">
	
	<cfscript>
	variables.DataMgr = arguments.DataMgr;
	variables.Mailer = arguments.Mailer;
	This.DataMgr = arguments.DataMgr;
	This.Mailer = arguments.Mailer;
	
	variables.datasource = variables.DataMgr.getDatasource();
	
	variables.DataMgr.loadXML(getDbXml(),true,true);
	loadNotices();
	
	//upgrade();
	</cfscript>
	
	<cfreturn this>
</cffunction>

<cffunction name="addNotice" access="public" returntype="any" output="no" hint="I add the given notice if it doesn't yet exist.">
	<cfargument name="Component" type="string" required="yes" hint="The path to your component (example com.sebtools.NoticeMgr).">
	<cfargument name="Name" type="string" required="yes" hint="The name of this notice (must be unique)">
	<cfargument name="Subject" type="string" required="yes" hint="The subject of the email.">
	<cfargument name="Text" type="string" required="no" hint="The text of the email (for plan-text email).">
	<cfargument name="HTML" type="string" required="no" hint="The HTML for the email (for HTML email)">
	<cfargument name="DataKeys" type="string" required="no" hint="A list of data keys for the component (the values to evaluate from within brackets in the email).">
	<cfargument name="Notes" type="string" required="no" hint="Notes about the Notice.">
	
	<cfset var qCheckNotice = 0>
	<cfset var sCheckNotice = StructNew()>
	
	<!---
	If a notice of this name already exists for another component, throw an error (type="NoticeMgr")
	--->
	<cfif Len(variables.datasource)>
		<cfquery name="qCheckNotice" datasource="#variables.datasource#">
		SELECT	NoticeID,Component
		FROM	emlNotices
		WHERE	Name = <cfqueryparam value="#arguments.Name#" cfsqltype="CF_SQL_VARCHAR">
			AND	Component <> <cfqueryparam value="#arguments.Component#" cfsqltype="CF_SQL_VARCHAR">
		</cfquery>
		<cfif qCheckNotice.RecordCount>
			<cfthrow message="A notice of this name is already being used by another component (""#qCheckNotice.Component#"")." type="NoticeMgr" errorcode="NameConflict">
		</cfif>
	</cfif>
	
	<!---
	Only take action if this notice of this name doesn't already exists for this component.
	(we don't want to update because the admin may have change the notice from the default settings)
	--->
	<cfset sCheckNotice["Name"] = arguments.Name>
	<cfset sCheckNotice["Component"] = arguments.Component>
	<cfset qCheckNotice = variables.DataMgr.getRecords(tablename="emlNotices",data=sCheckNotice,fieldlist="NoticeID,Component,Name,Subject,DataKeys,HTML,Text")>
	<cfif NOT qCheckNotice.RecordCount>
		<!--- Save notice if it exists (which includes updating Mailer with the information --->
		<cfset saveNotice(argumentCollection=arguments)>
	<cfelseif NOT StructKeyExists(variables.Mailer.getNotices(),qCheckNotice.Name)>
		<!--- If it does exist, make sure Mailer has it (don't send it to Mailer again if it doesn't though. --->
		<cfinvoke component="#variables.Mailer#" method="addNotice">
			<cfinvokeargument name="name" value="#qCheckNotice.Name#">
			<cfinvokeargument name="Subject" value="#qCheckNotice.Subject#">
			<cfinvokeargument name="datakeys" value="#qCheckNotice.DataKeys#">
			<cfinvokeargument name="html" value="#qCheckNotice.HTML#">
			<cfinvokeargument name="text" value="#qCheckNotice.Text#">
		</cfinvoke>
	</cfif>
	
</cffunction>

<cffunction name="changeDataKeys" access="public" returntype="void" output="no" hint="I change the Data Keys for the given notice.">
	<cfargument name="Name" type="string" required="yes" hint="The name of this notice (must be unique)">
	<cfargument name="DataKeys" type="string" required="no" hint="A list of data keys for the component (the values to evaluate from within brackets in the email).">
	
	<cfset var qCheckNotice = 0>
	<cfset var data = StructNew()>
	
	<cfset data["Name"] = arguments.Name>
	<cfset qCheckNotice = variables.DataMgr.getRecords(tablename="emlNotices",data=data,fieldlist="NoticeID,Subject,HTML,Text")>
	
	<cfif qCheckNotice.RecordCount>
		<cfset data = StructNew()>
		<cfset data["NoticeID"] = qCheckNotice.NoticeID>
		<cfset data["DataKeys"] = arguments.DataKeys>
		<cfset variables.DataMgr.updateRecord("emlNotices",data)>
		<cfinvoke component="#variables.Mailer#" method="addNotice">
			<cfinvokeargument name="name" value="#arguments.Name#">
			<cfinvokeargument name="Subject" value="#qCheckNotice.Subject#">
			<cfinvokeargument name="datakeys" value="#arguments.DataKeys#">
			<cfinvokeargument name="html" value="#qCheckNotice.HTML#">
			<cfinvokeargument name="text" value="#qCheckNotice.Text#">
		</cfinvoke>
	<cfelse>
		<cfthrow message="No notice of this name (#arguments.Name#) exists." type="NoticeMgr" errorcode="NoSuchNotice">
	</cfif>
	
</cffunction>

<cffunction name="getDataMgr" access="public" returntype="any" output="no" hint="I get the DataMgr for this component.">
	<cfreturn variables.DataMgr>
</cffunction>

<cffunction name="getMailer" access="public" returntype="any" output="no" hint="I get the Mailer for this component.">
	<cfreturn variables.Mailer>
</cffunction>

<cffunction name="getMailerData" access="public" returntype="struct" output="no" hint="I get the root data for the Mailer for this component.">
	<cfreturn variables.Mailer.getData()>
</cffunction>

<cffunction name="getNotice" access="public" returntype="query" output="no" hint="I get the requested notice.">
	<cfargument name="NoticeID" type="string" required="no" hint="The database id for this notice.">
	<cfargument name="Name" type="string" required="no" hint="The unique name for this notice.">
	
	<cfset var reqargs = "NoticeID,Name">
	<cfset var arg = "">
	<cfset var hasArg = false>
	
	<cfloop index="arg" list="#reqargs#">
		<cfif StructKeyExists(arguments,arg)>
			<cfset hasArg = true>
		</cfif>
	</cfloop>
	
	<cfif NOT hasArg>
		<cfthrow message="getNotice requires one of the following arguments: #reqargs#" type="NoticeMgr" errorcode="GetNoticeRequiredArgs">
	</cfif>
	

	<cfreturn variables.DataMgr.getRecord("emlNotices",arguments)>
</cffunction>

<cffunction name="getNotices" access="public" returntype="query" output="no" hint="I get all of the notices.">
	<cfargument name="fieldlist" type="string" default="">
	
	<cfset Arguments.tablename = "emlNotices">
	
	<cfreturn variables.DataMgr.getRecords(ArgumentCollection=Arguments)>
</cffunction>

<cffunction name="loadNotices" access="public" returntype="any" output="no">
	
	<cfset var qNotices = getNotices(fieldlist="Name,Subject,DataKeys,HTML,Text")>
	
	<cfloop query="qNotices">
		<cfinvoke component="#variables.Mailer#" method="addNotice">
			<cfinvokeargument name="name" value="#Name#">
			<cfinvokeargument name="Subject" value="#Subject#">
			<cfinvokeargument name="datakeys" value="#DataKeys#">
			<cfinvokeargument name="html" value="#HTML#">
			<cfinvokeargument name="text" value="#Text#">
		</cfinvoke>
	</cfloop>
	
</cffunction>

<cffunction name="removeNotice" access="public" returntype="void" output="no" hint="I remove a notice.">
	<cfargument name="name" type="string" required="yes">
	
	<cfset var qNotice = getNotice(Name=arguments.Name)>
	<cfset var data = StructNew()>
	
	<cfif qNotice.RecordCount>
		<cfset data["NoticeID"] = qNotice.NoticeID>
		<cfset variables.DataMgr.deleteRecord("emlNotices",data)>
	</cfif>
	
	<cfset variables.Mailer.removeNotice(arguments.Name)>
	
</cffunction>

<cffunction name="saveNotice" access="public" returntype="string" output="no" hint="I save a notice.">
	<cfargument name="Name" type="string" required="yes" hint="The unique name for this notice.">
	<cfargument name="Component" type="string" required="no" hint="The path to your component (example com.sebtools.NoticeMgr).">
	<cfargument name="Subject" type="string" required="yes" hint="The subject of the email.">
	<cfargument name="Text" type="string" required="no" hint="The text of the email (for plan-text email).">
	<cfargument name="HTML" type="string" required="no" hint="The HTML for the email (for HTML email)">
	<cfargument name="DataKeys" type="string" required="no" hint="A list of data keys for the component (the values to evaluate from within brackets in the email).">
	<cfargument name="Notes" type="string" required="no" hint="Notes about the Notice.">
	
	<cfset var result = 0>
	<cfset var qNotice = getNotice(Name=arguments.Name)>
	
	<!--- Actions to perform if this is an existing notice --->
	<cfif qNotice.RecordCount>
		<!--- Name drives the id here, not vice-versa --->
		<cfset arguments["NoticeID"] = qNotice.NoticeID>
		
		<!---
		TODO: Make sure Component and Name haven't changed if this is an existing notice
		--->
		<cfif StructKeyExists(arguments,"Component") AND arguments.Component neq qNotice.Component>
			<cfthrow message="You cannot change the component with which a notice is associated." type="NoticeMgr" errorcode="ChangeComponent">
		</cfif>
	</cfif>
	
	<!--- Make sure notice has something in it --->
	<cfif NOT
		(
				( StructKeyExists(arguments,"html") AND Len(arguments.html) )
			OR	( StructKeyExists(arguments,"text") AND Len(arguments.text) )
		)
	>
		<cfthrow message="If Contents argument is not provided than either html or text arguments must be." type="Mailer" errorcode="ContentsRequired">
	</cfif>
	
	
	<!--- Save notice record --->
	<cfset result = variables.DataMgr.saveRecord("emlNotices",arguments)>
	<!--- get notice record --->
	<cfset qNotice = getNotice(Name=arguments.Name)>
	
	<!--- Add/save notice to mailer --->
	<cfif Len(qNotice.HTML) OR Len(qNotice.Text)>
		<cfinvoke component="#variables.Mailer#" method="addNotice">
			<cfinvokeargument name="name" value="#qNotice.Name#">
			<cfinvokeargument name="Subject" value="#qNotice.Subject#">
			<cfinvokeargument name="datakeys" value="#qNotice.DataKeys#">
			<cfinvokeargument name="html" value="#qNotice.HTML#">
			<cfinvokeargument name="text" value="#qNotice.Text#">
		</cfinvoke>
	</cfif>
	
</cffunction>

<cffunction name="sendNotice" access="public" returntype="struct" output="no" hint="I send set/override any data based on the data given and send the given notice.">
	<cfargument name="name" type="string" required="yes" hint="The name of the notice you want to send.">
	<cfargument name="data" type="struct" hint="The data you want to use for this email message.">

	<cfreturn variables.Mailer.sendNotice(argumentCollection=arguments)>
</cffunction>

<cffunction name="upgrade" access="private" returntype="any" output="no">
	
	<cfset var dbtables = variables.DataMgr.getDatabaseTables()>
	<cfset var qOldRecords = 0>
	<cfset var qNewRecords = getNotices()>
	
	<!---
	Look for mainResponses table and copy all responses to emlNotices.
	Then ditch mainResponses.
	--->
	<cfif Len(variables.datasource) AND ListFindNoCase(dbtables,"mainResponses")>
		<cfquery datasource="#variables.datasource#">
		INSERT INTO emlNotices (
				Component,
				Name,
				Subject,
				Text,
				HTML,
				DataKeys
		)
		SELECT	Component,
				Response_Title,
				Response_Subject,
				Response_Text,
				NULL,
				Data_Keys
		FROM	mainResponses
		WHERE	NOT EXISTS (
					SELECT	NoticeID
					FROM	emlNotices
					WHERE	Component = mainResponses.Component
						AND	Name = mainResponses.Response_Title
				)
		</cfquery>
	</cfif>
	
</cffunction>

<cffunction name="getDbXml" access="private" returntype="string" output="no" hint="I return the XML for the tables needed for Searcher to work.">
	<cfset var tableXML = "">
	
	<cfsavecontent variable="tableXML">
	<tables>
		<table name="emlNotices">
			<field ColumnName="NoticeID" CF_DataType="CF_SQL_INTEGER" PrimaryKey="true" Increment="true" />
			<field ColumnName="Component" CF_DataType="CF_SQL_VARCHAR" Length="50" />
			<field ColumnName="Name" CF_DataType="CF_SQL_VARCHAR" Length="50" />
			<field ColumnName="Subject" CF_DataType="CF_SQL_VARCHAR" Length="100" />
			<field ColumnName="Text" CF_DataType="CF_SQL_LONGVARCHAR" />
			<field ColumnName="HTML" CF_DataType="CF_SQL_LONGVARCHAR" />
			<field ColumnName="DataKeys" CF_DataType="CF_SQL_VARCHAR" Length="250" />
			<field ColumnName="Notes" CF_DataType="CF_SQL_VARCHAR" Length="250" />
		</table>
	</tables>
	</cfsavecontent>
	
	<cfreturn tableXML>
</cffunction>

</cfcomponent>