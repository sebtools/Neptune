<cfcomponent displayname="Timer" output="no">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="DataMgr" type="any" required="yes">
	<cfargument name="Observer" type="any" required="yes">
	
	<cfset Variables.DataMgr = Arguments.DataMgr>
	<cfset Variables.Observer = Arguments.Observer>
	
	<cfset Variables.datasource = Variables.DataMgr.getDatasource()>
	<cfset Variables.DataMgr.loadXml(getDbXml(),true,true)>
	
	<cfset Variables.DateTimeLoaded = now()>

	<cfset Variables.MrECache = CreateObject("component","com.sebtools.MrECache").init("timer",CreateTimeSpan(0,0,5,0))>

	<cfset registerListeners()>
	
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

	<cfif NOT StructKeyExists(Arguments,"Template")>
		<cfset Arguments.Template = CGI.SCRIPT_NAME>
	</cfif>
	
	<cfset Variables.DataMgr.insertRecord(
		tablename="cf_timer",
		OnExists="insert",
		data=Arguments
	)>
	
</cffunction>

<cffunction name="hearMrECache" access="public" returntype="void" output="no">
	<cfargument name="id" type="string" required="true">
	<cfargument name="runTime" type="numeric" required="true">

	<cfif isFilteredEvent(Arguments.id)>
		<cfset logTime(Name=Arguments.id,Time_ms=Int(runTime))>
	</cfif>

</cffunction>

<cffunction name="isFilteredEvent" access="public" returntype="boolean" output="no">
	<cfargument name="Name" type="string" required="true">

	<cfreturn Variables.MrECache.method(
		id="isfiltered_#Arguments.Name#",
		Component=This,
		MethodName="_isFilteredEvent",
		Args=Arguments
	)>
</cffunction>

<cffunction name="_isFilteredEvent" access="public" returntype="boolean" output="no">
	<cfargument name="Name" type="string" required="true">

	<cfset var qFilters = 0>

	<cfif ListFirst(Arguments.Name,"_") EQ "timer" OR ListFirst(Arguments.Name,":") EQ "timer">
		<cfreturn false>
	</cfif>

	<cfset qFilters = getFilters()>

	<cfoutput query="qFilters">
		<cfif regex EQ "*">
			<cfreturn true>
		</cfif>
		<cfif ReFindNoCase(regex,Arguments.Name)>
			<cfreturn true>
		</cfif>
	</cfoutput>

	<cfreturn false>
</cffunction>

<cffunction name="getFilters" access="public" returntype="query" output="no">
	<cfreturn Variables.MrECache.method(
		id="filters",
		Component=This,
		MethodName="_getFilters"
	)>
</cffunction>

<cffunction name="_getFilters" access="public" returntype="query" output="no">
	<cfset Arguments.isActive = true>
	<cfreturn Variables.DataMgr.getRecords(tablename="cf_timer_filters",data=Arguments,fieldlist="FilterID,regex")>
</cffunction>

<cffunction name="resetFilters" access="public" returntype="void" output="no">
	
	<cfset Variables.MrECache.remove("filters")>
	<cfset Variables.MrECache.clearCaches("isfiltered")>

</cffunction>

<cffunction name="registerListeners" access="private" returntype="void" output="no" hint="I register a listener with Observer to listen for timed events.">
	
	<cfset Variables.Observer.registerListener(
		Listener = This,
		ListenerName = "TimeMrECache",
		ListenerMethod = "hearMrECache",
		EventName = "MrECache:run"
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
		</table>
		<table name="cf_timer_filters">
			<field ColumnName="FilterID" CF_DataType="CF_SQL_INTEGER" PrimaryKey="true" Increment="true" />
			<field ColumnName="regex" CF_DataType="CF_SQL_VARCHAR" Length="255" />
			<field ColumnName="isActive" CF_DataType="CF_SQL_BIT" Default="1" />
			<field ColumnName="DateAdded" CF_DataType="CF_SQL_DATE" Special="CreationDate" />
		</table>
	</tables>
	</cfoutput></cfsavecontent>
	
	<cfreturn result>
</cffunction>

</cfcomponent>