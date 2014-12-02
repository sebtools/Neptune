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
	
	<cfif StructKeyExists(Arguments,"data") AND NOT StructIsEmpty(Arguments.data)>
		<cfset Arguments.data = SerializeJSON(Arguments.data)>
	<cfelse>
		<cfset StructDelete(Arguments,"data")>
	</cfif>
	
	<cfset result = Variables.DataMgr.insertRecord(
		tablename="cf_timer",
		OnExists="insert",
		data=Arguments
	)>
	
</cffunction>

<cffunction name="getDbXml" access="private" returntype="string" output="no" hint="I return the XML for the tables needed for Searcher to work.">
	
	<cfset var result = "">
	
	<cfsavecontent variable="result"><cfoutput>
	<tables>
		<table name="cf_timer">
			<field ColumnName="TimerID" CF_DataType="CF_SQL_BIGINT" PrimaryKey="true" Increment="true" />
			<field ColumnName="Name" CF_DataType="CF_SQL_VARCHAR" Length="255" />
			<field ColumnName="Template" CF_DataType="CF_SQL_VARCHAR" Length="255" />
			<field ColumnName="Label" CF_DataType="CF_SQL_VARCHAR" Length="50" />
			<field ColumnName="Time_ms" CF_DataType="CF_SQL_INTEGER" />
			<field ColumnName="data" CF_DataType="CF_SQL_LONGVARCHAR" Length="60" />
			<field ColumnName="DatePageLoaded" CF_DataType="CF_SQL_DATE" />
			<field ColumnName="DateAdded" CF_DataType="CF_SQL_DATE" Special="CreationDate" />
		</table>
	</tables>
	</cfoutput></cfsavecontent>
	
	<cfreturn result>
</cffunction>

</cfcomponent>