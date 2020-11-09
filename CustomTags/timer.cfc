<cfcomponent displayname="Timer" output="no">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="DataMgr" type="any" required="yes">

	<cfset Variables.DataMgr = Arguments.DataMgr>

	<cfset Variables.datasource = Variables.DataMgr.getDatasource()>
	<cfset Variables.DataMgr.loadXml(getDbXml(),true,true)>

	<cfset Variables.DateTimeLoaded = now()>

	<cfreturn This>
</cffunction>

<cffunction name="getDateLoaded" access="public" returntype="any" output="no">
	<cfreturn Variables.DateTimeLoaded>
</cffunction>

<cffunction name="getDataMgr" access="public" returntype="any" output="no">
	<cfreturn Variables.DataMgr>
</cffunction>

<cffunction name="logTime" access="public" returntype="any" output="no">
	<cfargument name="Time_ms" type="numeric" required="true">
	<cfargument name="Name" type="string" required="false">
	<cfargument name="Label" type="string" required="false">
	<cfargument name="Template" type="string" default="#CGI.SCRIPT_NAME#">
	<cfargument name="data" type="struct" required="false">

	<!--- We need a load time for the page so we can group data by request --->
	<cfif NOT StructKeyExists(request,"TimerPageDate")>
		<cfset request.TimerPageDate = now()>
	</cfif>

	<cfif NOT StructKeyExists(Arguments,"DatePageLoaded")>
		<cfset Arguments.DatePageLoaded = request.TimerPageDate>
	</cfif>

	<!--- Actually, we need a UUID so we can group data by request. --->
	<cfif NOT StructKeyExists(request,"TimerUUID")>
		<cfset request.TimerUUID = CreateUUID()>
	</cfif>
	<cfset Arguments.RequestUUID = request.TimerUUID>

	<cfif StructKeyExists(Arguments,"data") AND NOT StructIsEmpty(Arguments.data)>
		<cfset Arguments.data = SerializeJSON(Arguments.data)>
	<cfelse>
		<cfset StructDelete(Arguments,"data")>
	</cfif>

	<!---
	<cfquery datasource="#Variables.DataMgr.getDatasource()#">
	INSERT INTO cf_timer (

		Template
	)
	VALUES (
		<cfqueryparam value="#Arguments.Template#" cfsqltype="CF_SQL_INTEGER">
	)
	</cfquery>
	--->
	<cfset Arguments = Variables.DataMgr.truncate("cf_timer",Arguments)>
	<cfset Variables.DataMgr.runSQLArray(
		Variables.DataMgr.insertRecordSQL(
			tablename="cf_timer",
			OnExists="insert",
			data=Arguments
		)
	)>

</cffunction>

<cffunction name="getDbXml" access="private" returntype="string" output="no">

	<cfset var result = "">

	<cfsavecontent variable="result"><cfoutput>
	<tables>
		<table name="cf_timer">
			<field ColumnName="TimerID" CF_DataType="CF_SQL_BIGINT" PrimaryKey="true" Increment="true" />
			<field ColumnName="Name" CF_DataType="CF_SQL_VARCHAR" Length="255" />
			<field ColumnName="Template" CF_DataType="CF_SQL_VARCHAR" Length="255" />
			<field ColumnName="Label" CF_DataType="CF_SQL_VARCHAR" Length="250" />
			<field ColumnName="Time_ms" CF_DataType="CF_SQL_INTEGER" />
			<field ColumnName="data" CF_DataType="CF_SQL_LONGVARCHAR" Length="60" />
			<field ColumnName="DatePageLoaded" CF_DataType="CF_SQL_DATE" />
			<field ColumnName="DateAdded" CF_DataType="CF_SQL_DATE" Special="CreationDate" />
			<field ColumnName="RequestUUID" CF_DataType="CF_SQL_VARCHAR" Length="50" />
		</table>
	</tables>
	</cfoutput></cfsavecontent>

	<cfreturn result>
</cffunction>

</cfcomponent>
