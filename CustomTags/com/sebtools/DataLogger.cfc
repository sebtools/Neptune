<cfcomponent displayname="Data Logger" hint="I log data changes for auditing." output="no">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="DataMgr" type="any" required="yes">
	<cfargument name="Observer" type="any" required="yes">

	<cfset initInternal(ArgumentCollection=Arguments)>

	<cfreturn This>
</cffunction>

<cffunction name="initInternal" access="public" returntype="any" output="no">
	<cfargument name="DataMgr" type="any" required="yes">
	<cfargument name="Observer" type="any" required="yes">

	<cfset StructAppend(Variables,Arguments)>

	<cfset Variables.logged_tables = "">

	<cfset Variables.DataMgr.loadXML(getDbXml(),true,true)>

	<cfset Variables.Datasource = Variables.DataMgr.getDatasource()>

	<cfset registerListener()>

	<cfreturn This>
</cffunction>

<cffunction name="getWho" access="public" returntype="string" output="no" hint="I get the 'Who' value for the data logging. This should be overridden on a per-site basis.">
	<cfreturn CGI.REMOTE_ADDR>
</cffunction>

<cffunction name="logAction" access="public" returntype="any" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="action" type="string" required="yes">
	<cfargument name="data" type="struct" required="no">
	<cfargument name="ChangeUUID" type="string" required="no">
	<cfargument name="sql" type="any" required="no">

	<cfset var sArgs = {}>
	<cfset var sDataChanges = {}>
	<cfset var ChangeSetID = 0>
	<cfset var aChanges = 0>
	<cfset var ii = 0>
	<cfset var key = "">

	<!--- Don't create an infinite loop by attempting to log the DataLogger tables. --->
	<cfif Arguments.tablename CONTAINS "audChange">
		<cfreturn false>
	</cfif>

	<!--- Only log tables that DataLogger has been requested to log. --->
	<cfif NOT ListFindNoCase(Variables.logged_tables,Arguments.tablename)>
		<cfreturn false>
	</cfif>

	<!--- Convert action arguments. --->
	<cfif Arguments.action CONTAINS "insert">
		<cfset sArgs["action"] = "insert">
	<cfelseif Arguments.action CONTAINS "update">
		<cfset sArgs["action"] = "update">
	<cfelseif Arguments.action CONTAINS "delete">
		<cfset sArgs["action"] = "delete">
	<cfelse>
		<!--- For now, only logging the above actions --->
		<cfreturn false>
	</cfif>

	<cfif Arguments.action CONTAINS "after">
		<cfif sArgs["action"] EQ "update">
			<cfreturn logActionComplete(ArgumentCollection=Arguments)>
		<cfelse>
			<cfset sArgs["DateCompleted"] = now()>
		</cfif>
	<cfelseif StructKeyExists(Arguments,"complete") AND Arguments.complete IS true>
		<cfset sArgs["DateCompleted"] = now()>
	</cfif>

	<!--- We won't know the primary key value yet for an insert --->
	<cfif NOT ( StructKeyExists(Arguments,"pkvalue") AND Len(Arguments["pkvalue"]) )>
		<cfif StructKeyExists(Arguments,"data") AND StructCount(Arguments.data)>
			<cfif sArgs["action"] NEQ "insert" AND NOT StructKeyExists(Arguments,"pkvalue")>
				<cfset Arguments["pkvalue"] = getPKValue(Arguments.tablename,Arguments.data)>
			</cfif>
		</cfif>
	</cfif>

	<cfset sArgs["tablename"] = Arguments.tablename>
	<cfset sArgs["Who"] = getWho()>
	<cfif StructKeyExists(Arguments,"ChangeUUID")>
		<cfset sArgs["ChangeUUID"] = Arguments.ChangeUUID>
	</cfif>
	<cfif StructKeyExists(Arguments,"sql")>
		<cfset sArgs["sql"] = Variables.DataMgr.readableSQL(Arguments.sql)>
	</cfif>
	<cfif StructKeyExists(Arguments,"pkvalue")>
		<cfset sArgs["pkvalue"] = Arguments.pkvalue>
	</cfif>

	<!--- ** Log the Change ** --->
	<cfset ChangeSetID = Variables.DataMgr.insertRecord(tablename="audChangeSets",data=sArgs)>

	<cfscript>
	if ( StructKeyExists(Arguments,"data") AND StructCount(Arguments.data) ) {
		// Track individual changes on updates
		if ( sArgs["action"] EQ "update" ) {
			aChanges = getDataChanges(Arguments.tablename,Arguments.data);
			for  ( ii=1; ii LTE ArrayLen(aChanges); ii++ ) {
				//Make sure to track the change set
				aChanges[ii]["ChangeSetID"] = ChangeSetID;
				if ( StructCount(aChanges[ii]) GT 1 ) {
					//Save the change
					Variables.DataMgr.runSQLArray(
						Variables.DataMgr.insertRecordSQL(
							tablename="audChanges",
							OnExists="insert",
							data=aChanges[ii]
						)
					);
				}
			}
		}
	}
	</cfscript>

</cffunction>

<cffunction name="logActionComplete" access="public" returntype="any" output="no">
	<cfargument name="ChangeUUID" type="string" required="no">

	<cfset var sWhere = {ChangeUUID=Arguments.ChangeUUID,DateCompleted=""}>
	<cfset var sSet = {DateCompleted=now()}>

	<cfif StructKeyExists(Arguments,"ChangeUUID") AND Len(Arguments.ChangeUUID)>
		<!--- Set change set to completed --->
		<cfset Variables.DataMgr.updateRecords(
			tablename="audChangeSets",
			data_set=sSet,
			data_where=sWhere
		)>
		<!--- Record the primary key value for the change set if we got it and didn't have it before. --->
		<cfif StructKeyExists(Arguments,"pkvalue") AND Len(Arguments.pkvalue)>
			<cfset sWhere = {ChangeUUID=Arguments.ChangeUUID,pkvalue=""}>
			<cfset sSet = {pkvalue=Arguments.pkvalue}>
			<cfset Variables.DataMgr.updateRecords(
				tablename="audChangeSets",
				data_set=sSet,
				data_where=sWhere
			)>
		</cfif>
	</cfif>

</cffunction>

<cffunction name="getLoggedTables" access="public" returntype="any" output="no">
	<cfreturn Variables.logged_tables>
</cffunction>

<cffunction name="logTable" access="public" returntype="any" output="no">
	<cfargument name="tablename" type="string" required="yes">

	<cfif NOT ListFindNoCase(Variables.logged_tables,Arguments.tablename)>
		<cfset Variables.logged_tables = ListAppend(Variables.logged_tables,Arguments.tablename)>
	</cfif>

</cffunction>

<cffunction name="getCurrentData" access="private" returntype="query" output="no" hint="I get the current data for the given record.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="data" type="struct" required="yes">

	<cfset var sPKData = getPKData(Arguments.tablename,Arguments.data)>
	<cfset var qRecord = Variables.DataMgr.getRecord(tablename=Arguments.tablename,data=sPKData,fieldlist=StructKeyList(Arguments.data))>

	<cfreturn qRecord>
</cffunction>

<cffunction name="getDataChanges" access="private" returntype="any" output="no" hint="I get the data that has changed.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="data" type="struct" required="yes">

	<cfset var qRecord = getCurrentData(Arguments.tablename,Arguments.data)>
	<cfset var aResults = []>
	<cfset var sChange = []>
	<cfset var key = "">

	<cfscript>
	//Only track data changes if a record exists in the database
	if ( qRecord.RecordCount ) {
		//Loop through the data fields provided (data changed in any other manner will have to be captured in the SQL passed in)
		for ( key in Arguments.data ) {
			//Make sure the field exists in the record (or nothing to compare to)
			if ( ListFindNoCase(qRecord.ColumnList,key) AND isSimpleValue(Arguments.data[key]) ) {
				//Only track if the data isn't the same
				if ( qRecord[key][1] NEQ Arguments.data[key] ) {
					sChange = {
						FieldName=key,
						OldValue=qRecord[key][1],
						NewValue=Arguments.data[key]
					};
					ArrayAppend(
						aResults,
						sChange
					);
				}
			}
		}
	}
	</cfscript>

	<cfreturn aResults>
</cffunction>

<cffunction name="registerListener" access="private" returntype="void" output="no" hint="I register a listener with Observer to listen for services being loaded.">

	<cfset Variables.Observer.registerListeners(
		Listener = This,
		ListenerName = "DataLogger",
		ListenerMethod = "logAction",
		EventNames = "DataMgr:afterInsert,DataMgr:afterDelete,DataMgr:beforeUpdate,DataMgr:afterUpdate"
	)>

</cffunction>

<cffunction name="getPKData" access="private" returntype="struct" output="no" hint="I get the primary key value for the given data.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="data" type="struct" required="yes">

	<cfset var sResult = {}>
	<cfset var pkfields = Variables.DataMgr.getPrimaryKeyFieldNames(arguments.tablename)>
	<cfset var pkfield = "">

	<cfloop list="#pkfields#" index="pkfield">
		<cfset sResult[pkfield] = Arguments.data[pkfield]>
	</cfloop>

	<cfreturn sResult>
</cffunction>

<cffunction name="getPKValue" access="private" returntype="string" output="no" hint="I get the primary key value for the given data.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="data" type="struct" required="yes">

	<cfset var result = "">
	<cfset var pkfields = Variables.DataMgr.getPrimaryKeyFieldNames(arguments.tablename)>
	<cfset var pkfield = "">

	<cfloop list="#pkfields#" index="pkfield">
		<cfset result = ListAppend(result,Arguments.data[pkfield])>
	</cfloop>

	<cfreturn result>
</cffunction>

<cffunction name="getDbXml" access="public" returntype="string" output="no" hint="I return the XML for the tables needed for SpamFilter.cfc to work.">

	<cfset var tableXML = "">

	<cfsavecontent variable="tableXML"><cfoutput>
	<tables>
		<table name="audChangeSets">
			<field ColumnName="ChangeSetID" CF_DataType="CF_SQL_INTEGER" PrimaryKey="true" Increment="true" />
			<field ColumnName="tablename" CF_DataType="CF_SQL_VARCHAR" Length="250" />
			<field ColumnName="Action" CF_DataType="CF_SQL_VARCHAR" Length="50" />
			<field ColumnName="ChangeUUID" CF_DataType="CF_SQL_VARCHAR" Length="50" />
	        <field ColumnName="DateLogged" CF_DataType="CF_SQL_DATE" Special="CreationDate" />
	        <field ColumnName="Who" CF_DataType="CF_SQL_VARCHAR" Length="250" />
	        <field ColumnName="pkvalue" CF_DataType="CF_SQL_VARCHAR" Length="250" />
			<field ColumnName="SQL" CF_DataType="CF_SQL_LONGVARCHAR" />
			<field ColumnName="DateCompleted" CF_DataType="CF_SQL_DATE" />
		</table>
		<table name="audChanges">
			<field ColumnName="ChangeID" CF_DataType="CF_SQL_INTEGER" PrimaryKey="true" Increment="true" />
			<field ColumnName="ChangeSetID" CF_DataType="CF_SQL_INTEGER" />
			<field ColumnName="FieldName" CF_DataType="CF_SQL_VARCHAR" Length="250" />
			<field ColumnName="OldValue" CF_DataType="CF_SQL_LONGVARCHAR" />
			<field ColumnName="NewValue" CF_DataType="CF_SQL_LONGVARCHAR" />
		</table>
	</tables>
	</cfoutput></cfsavecontent>

	<cfreturn tableXML>
</cffunction>

</cfcomponent>
