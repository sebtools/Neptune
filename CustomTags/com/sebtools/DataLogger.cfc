<cfcomponent extends="com.sebtools.component" displayname="Data Logger" hint="I log data changes for auditing." output="no">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="DataMgr" type="any" required="yes">
	<cfargument name="Observer" type="any" required="yes">

	<cfset initInternal(ArgumentCollection=Arguments)>

	<cfreturn This>
</cffunction>

<cffunction name="initInternal" access="public" returntype="any" output="no">
	<cfargument name="DataMgr" type="any" required="yes">
	<cfargument name="Observer" type="any" required="yes">

	<cfset Super.initInternal(ArgumentCollection=Arguments)>

	<cfset Variables.logged_tables = "">

	<cfset Variables.DataMgr.loadXML(getDbXml(),true,true)>

	<cfset registerListener()>

	<cfreturn This>
</cffunction>

<cffunction name="catchError" access="public" returntype="void" output="no" hint="I catch logging errors. This can be extended on a per-site basis.">
	<cfargument name="MethodName" type="string" required="yes">
	<cfargument name="Error" type="any" required="yes">
	<cfargument name="Args" type="struct" required="yes">

	<cfset Variables.Observer.announceEvent(
		EventName = "DataLogger:onError",
		Args = Arguments
	)>

</cffunction>

<cffunction name="getDataMgr" access="public" returntype="any" output="no">
	<cfreturn Variables.DataMgr>
</cffunction>

<cffunction name="getObserver" access="public" returntype="any" output="no">
	<cfreturn Variables.Observer>
</cffunction>

<cffunction name="getRestoreChanges" access="public" returntype="struct" output="no" hint="I get the changes needed to restore a record to its state at a given time.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="pkvalue" type="string" required="yes">
	<cfargument name="when" type="date" required="yes">
	<cfargument name="fieldlist" type="string" required="no">

	<cfset var qChanges = 0>
	<cfset var sResult = {}>

	<cf_DMQuery name="qChanges">
	SELECT		FieldName,
				OldValue
	FROM		audChangeSets s
	LEFT JOIN	audChanges c
		ON		s.ChangeSetID = c.ChangeSetID
	WHERE		1 = 1
		AND		tablename = <cf_DMParam name="tablename" value="#Arguments.tablename#" cfsqltype="CF_SQL_VARCHAR">
		AND		pkvalue = <cf_DMParam name="pkvalue" value="#Arguments.pkvalue#" cfsqltype="CF_SQL_INTEGER">
		AND		FieldName IS NOT NULL
		<!--- Only the oldest change since the date  --->
		AND		ChangeID IN (
					SELECT		Min(ChangeID) ChangeID
					FROM		audChangeSets s
					LEFT JOIN	audChanges c
						ON		s.ChangeSetID = c.ChangeSetID
					WHERE		1 = 1
						AND		tablename = <cf_DMParam name="tablename" value="#Arguments.tablename#" cfsqltype="CF_SQL_VARCHAR">
						AND		pkvalue = <cf_DMParam name="pkvalue" value="#Arguments.pkvalue#" cfsqltype="CF_SQL_INTEGER">
						AND		FieldName IS NOT NULL
						AND		DateCompleted >= <cfoutput>'#DateFormat(Arguments.when,"yyyy-mm-dd")# #TimeFormat(Arguments.when,"hh:mm:ss")#'</cfoutput>
					GROUP BY	FieldName
				)
	</cf_DMQuery>

	<cfoutput query="qChanges">
		<cfset sResult[FieldName] = OldValue>
	</cfoutput>

	<cfreturn sResult>
</cffunction>

<cffunction name="getRecord" access="public" returntype="query" output="no" hint="I get the record as it would have existed at the given point in time.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="pkvalue" type="string" required="yes">
	<cfargument name="when" type="date" required="yes">
	<cfargument name="fieldlist" type="string" required="no">

	<cfset var qRecord = 0>
	<cfset var sGet = {tablename=Arguments.tablename}>
	<cfset var pkfield = Variables.DataMgr.getPrimaryKeyFieldName(Arguments.tablename)>
	<cfset var sChanges = 0>
	<cfset var field = "">
	<cfset var cols = "">

	<cfset sGet["data"] = {"#pkfield#"=Arguments.pkvalue}>

	<cfif StructKeyExists(Arguments,"fieldlist")>
		<cfset sGet["fieldlist"] = Arguments.fieldlist>
	</cfif>

	<cfset qRecord = Variables.DataMgr.getRecord(ArgumentCollection=sGet)>

	<cfif NOT qRecord.RecordCount>
		<cfif StructKeyExists(Variables,"DataTrashcan")>
			<cfset qRecord = Variables.DataTrashcan.getDeletedRecord(ArgumentCollection=sGet)>
		</cfif>

		<cfif NOT qRecord.RecordCount>
			<!--- If record isn't found at all, then throw error. If it is found, but deleted still then return empty query. --->
			<cfthrow type="DataLogger" message="Unable to retrieve record for table #Arguments.tablename# with primary key value of #Arguments.pkvalue#.">
		</cfif>

		<!--- If a deleted record is found, make sure it was deleted after the When date --->
		<cfif qRecord.RecordCount AND ListFindNoCase(qRecord.ColumnList,"DataTrashcan_DateDeleted")>
			<!--- If the record was deleted before the given date, treat it as still deleted and return nothing. --->
			<cfif qRecord.DataTrashcan_DateDeleted LT Arguments.when>
				<cfset QueryDeleteRow(qRecord, 1)>
			</cfif>
		</cfif>
	</cfif>

	<cfset sChanges = getRestoreChanges(ArgumentCollection=Arguments)>

	<cfset cols = qRecord.ColumnList>
	<cfloop collection="#sChanges#" item="field">
		<cfif ListFindNoCase(cols,field)>
			<cfset QuerySetCell(qRecord,field,sChanges[field])>
		</cfif>
	</cfloop>

	<cfreturn qRecord>
</cffunction>

<cffunction name="getWho" access="public" returntype="string" output="no" hint="I get the 'Who' value for the data logging. This should be overridden on a per-site basis.">
	<cfreturn CGI.REMOTE_ADDR>
</cffunction>

<cffunction name="addChangeSet" access="public" returntype="string" output="no">
	<cfargument name="action" type="string" required="yes">
	<cfargument name="pkvalue" type="string" required="no">
	<cfargument name="ChangeUUID" type="string" required="no">
	<cfargument name="sql" type="any" required="no">

	<cfset var sArgs = StructCopy(Arguments)>

	<cfif NOT StructKeyExists(sArgs,"ChangeUUID")>
		<cfset sArgs.ChangeUUID = CreateUUID()>
	</cfif>
	<cfset sArgs["Who"] = getWho()>
	<cfif StructKeyExists(sArgs,"sql")>
		<cfset sArgs["sql"] = Variables.DataMgr.readableSQL(sArgs.sql)>
	</cfif>

	<cfreturn Variables.DataMgr.insertRecord(tablename="audChangeSets",data=sArgs)>
</cffunction>

<cffunction name="hasReset" access="public" returntype="string" output="no">
	<cfargument name="ChangeSetID" type="string" required="no">

	<cfset var sArgs = {ChangeSetID=Arguments.ChangeSetID,action="restore"}>

	<cfreturn Variables.DataMgr.hasRecords(tablename="audChangeSets",data=sArgs)>
</cffunction>

<cffunction name="convertArgs" access="public" returntype="any" output="no">

	<cfset var sArgs = {}>

	<cfset sArgs["tablename"] = Arguments.tablename>
	<cfset sArgs["action"] = Arguments.action>
	<cfif StructKeyExists(Arguments,"ChangeUUID")>
		<cfset sArgs["ChangeUUID"] = Arguments.ChangeUUID>
	</cfif>
	<cfif StructKeyExists(Arguments,"sql")>
		<cfset sArgs["sql"] = Arguments.sql>
	</cfif>
	<cfif StructKeyExists(Arguments,"pkvalue")>
		<cfset sArgs["pkvalue"] = Arguments.pkvalue>
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

	<cfif
			Arguments.action CONTAINS "after"
		OR
			StructKeyExists(Arguments, "after")
		OR
			( StructKeyExists(Arguments,"complete") AND Arguments.complete IS true )
	>
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

	<cfreturn sArgs>
</cffunction>

<cffunction name="logAction" access="public" returntype="any" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="action" type="string" required="yes">
	<cfargument name="data" type="struct" required="no">
	<cfargument name="ChangeUUID" type="string" required="no">
	<cfargument name="sql" type="any" required="no">
	<cfargument name="before" type="any" required="no">
	<cfargument name="after" type="any" required="no">

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

	<cfset sArgs = convertArgs(ArgumentCollection=Arguments)>

	<!---<cftry>--->
		<!--- ** Log the Change ** --->
		<cfif
			StructKeyExists(Arguments,"data")
			AND
			StructKeyHasVal(Arguments.data,"DataLogger_ChangeSetID")
			AND
			hasRestore(Arguments.data["DataLogger_ChangeSetID"])
		>
			<!--- In rare event where data specified a ChangeSetID, use it. Only current case: a restore --->
			<cfset ChangeSetID = Arguments.data["DataLogger_ChangeSetID"]>
		<cfelse>
			<!--- The rest of the time, we'll create one. --->
			<cfset ChangeSetID = addChangeSet(ArgumentCollection=sArgs)>
		</cfif>

		<cfscript>
		if ( sArgs["action"] EQ "update" ) {
			aChanges = getDataChanges(ArgumentCollection=Arguments);
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
		</cfscript>
	<!---<cfcatch>
		<cfset catchError("logAction",CFCATCH,Arguments)>
	</cfcatch>
	</cftry>--->

</cffunction>

<cffunction name="logActionComplete" access="public" returntype="any" output="no">
	<cfargument name="ChangeUUID" type="string" required="no">

	<cfset var sWhere = {DateCompleted=""}>
	<cfset var sSet = {DateCompleted=now()}>

	<cfif StructKeyExists(Arguments,"ChangeUUID") AND Len(Arguments.ChangeUUID)>
		<cfset sWhere["ChangeUUID"] = Arguments.ChangeUUID>
		<cftry>
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
		<cfcatch>
			<cfset catchError("logActionComplete",CFCATCH,Arguments)>
		</cfcatch>
		</cftry>
	</cfif>

</cffunction>

<cffunction name="getLoggedTables" access="public" returntype="any" output="no">
	<cfreturn Variables.logged_tables>
</cffunction>

<cffunction name="logTable" access="public" returntype="any" output="no">
	<cfargument name="tablename" type="string" required="yes">

	<cfset Arguments.tablename = Trim(Arguments.tablename)>

	<cfif Len(Arguments.tablename) AND NOT ListFindNoCase(Variables.logged_tables,Arguments.tablename)>
		<cfset Variables.logged_tables = ListAppend(Variables.logged_tables,Arguments.tablename)>
	</cfif>

</cffunction>

<cffunction name="logTables" access="public" returntype="any" output="no">
	<cfargument name="tables" type="string" required="yes">

	<cfset var table = "">

	<cfif ArrayLen(Arguments) GT 1>
		<cfset Arguments.tables = ArrayToList(Arguments)>
	</cfif>

	<cfloop list="#Arguments.tables#" index="table">
		<cfset logTable(table)>
	</cfloop>

</cffunction>

<cffunction name="restoreRecord" access="public" returntype="any" output="no" hint="I restore the record to the given point in time.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="pkvalue" type="string" required="yes">
	<cfargument name="when" type="date" required="yes">
	<cfargument name="fieldlist" type="string" required="no">

	<cfset var qRecord = getRecord(ArgumentCollection=Arguments)>
	<cfset var sRecord = {}>
	<cfset var pkfield = Variables.DataMgr.getPrimaryKeyFieldName(Arguments.tablename)>
	<cfset var sql_insert = 0>
	<cfset var ChangeSetID = 0>

	<cfif qRecord.RecordCount>
		<cfset sRecord = Variables.DataMgr.QueryRowToStruct(qRecord,qRecord.RecordCount)>

		<cfif Variables.DataMgr.hasRecords(Arguments.tablename,{"#pkfield#"=Arguments.pkvalue})>
			<cfset Variables.DataMgr.saveRecord(tablename=Arguments.tablename,data=sRecord)>
		<cfelse>
			<!--- Need ability to do identity insert on recovering deleted record. --->
			<cftransaction isolation="serializable">
				<cf_DMQuery sqlresult="sql_insert">
					SET IDENTITY_INSERT <cf_DMObject name="#Arguments.tablename#"> ON
					INSERT INTO <cf_DMObject name="#Arguments.tablename#"> (
						<cf_DMObject name="#pkfield#">
					) VALUES (
						<cf_DMParam value="#Arguments.pkvalue#" cfsqltype="CF_SQL_INTEGER">
					)
					SET IDENTITY_INSERT <cf_DMObject name="#Arguments.tablename#"> OFF
				</cf_DMQuery>
				<cfset ChangeSetID = addChangeSet(
					tablename=Arguments.tablename,
					action="restore",
					pkvalue=Arguments.pkvalue,
					sql=sql_insert
				)>
				<cfset sRecord["DataLogger_ChangeSetID"] = ChangeSetID>
				<cfset Variables.DataMgr.saveRecord(tablename=Arguments.tablename,data=sRecord)>
			</cftransaction>
		</cfif>
		<cfset addRestore(ArgumentCollection=Arguments)>
	<cfelse>
		<cfthrow type="DataLogger" message="Nothing to restore.">
	</cfif>

</cffunction>

<cffunction name="setDataTrashcan" access="public" returntype="any" output="no">
	<cfargument name="DataTrashcan" type="any" required="yes">

	<cfset Variables.DataTrashcan = Arguments.DataTrashcan>

</cffunction>

<cffunction name="addRestore" access="public" returntype="string" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="pkvalue" type="string" required="yes">
	<cfargument name="when" type="date" required="yes">
	<cfargument name="fieldlist" type="string" required="no">

	<cfset var sArgs = {
		"tablename"=Arguments.tablename,
		"pkvalue"=Arguments.pkvalue,
		"DateRestoredFrom"=Arguments.when
	}>
	<cfif StructKeyHasLen(Arguments,"fieldlist")>
		<cfset sArgs["fieldlist"] = Arguments.fieldlist>
	</cfif>

	<cfreturn Variables.DataMgr.insertRecord(tablename="audRestores",data=sArgs)>
</cffunction>

<cffunction name="getCurrentData" access="private" returntype="query" output="no" hint="I get the current data for the given record.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="data" type="struct" required="yes">

	<cfset var sPKData = getPKData(Arguments.tablename,Arguments.data)>
	<cfset var qRecord = Variables.DataMgr.getRecord(tablename=Arguments.tablename,data=sPKData,fieldlist=StructKeyList(Arguments.data))>

	<cfreturn qRecord>
</cffunction>

<cffunction name="getDataChangeArgs" access="private" returntype="any" output="no" hint="I get the data that has changed.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="data" type="struct" required="no">
	<cfargument name="before" type="any" required="no">
	<cfargument name="after" type="any" required="no">

	<cfset var sChangeArgs = {}>

	<cfscript>
	if ( StructKeyExists(Arguments,"data") AND StructCount(Arguments.data) ) {
		sChangeArgs["data"] = Arguments.data;
	}

	//If data is supplied, but no before then assume this is done before the change and query the data.
	if ( StructKeyExists(sChangeArgs,"data") AND NOT StructKeyExists(Arguments,"before") ) {
		Arguments["before"] = getCurrentData(Arguments.tablename,Arguments.data);
	}

	if ( StructKeyExists(Arguments, "before") ) {

		sChangeArgs["before"] = Arguments.before;

		if ( isQuery(sChangeArgs["before"]) AND sChangeArgs["before"].RecordCount ) {
			sChangeArgs["before"] = QueryRowToStruct(sChangeArgs["before"]);
		}

		if ( NOT ( isStruct(sChangeArgs["before"]) AND StructCount(sChangeArgs["before"]) ) ) {
			StructDelete(sChangeArgs,"before");
		}

	}

	//If data is supplied, but no after then assume this is done and that the data change will take as supplied.
	if ( StructKeyExists(sChangeArgs,"data") AND NOT StructKeyExists(sChangeArgs,"after") ) {
		Arguments["after"] = sChangeArgs["data"];
	}

	if ( StructKeyExists(Arguments, "before") AND StructKeyExists(Arguments, "after") ) {

		sChangeArgs["after"] = Arguments.after;

		if ( isQuery(sChangeArgs["after"]) AND sChangeArgs["after"].RecordCount ) {
			sChangeArgs["after"] = QueryRowToStruct(sChangeArgs["after"]);
		}

		if ( NOT ( isStruct(sChangeArgs["after"]) AND StructCount(sChangeArgs["after"]) ) ) {
			StructDelete(sChangeArgs,"after");
		}

	}

	//If after is supplied, but no data then use the after as the data.
	if ( StructKeyExists(sChangeArgs,"after") AND NOT StructKeyExists(sChangeArgs,"data") ) {
		sChangeArgs["data"] = sChangeArgs["after"];
	}

	if ( StructCount(sChangeArgs) ) {
		sChangeArgs["tablename"] = Arguments.tablename;
	}
	</cfscript>

	<cfreturn sChangeArgs>
</cffunction>

<cffunction name="getDataChanges" access="private" returntype="any" output="no" hint="I get the data that has changed.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="data" type="struct" required="no">
	<cfargument name="before" type="any" required="no">
	<cfargument name="after" type="any" required="no">

	<cfset var sArgs = getDataChangeArgs(ArgumentCollection=Arguments)>
	<cfset var qRecord = 0>
	<cfset var aResults = []>
	<cfset var sChange = []>
	<cfset var key = "">

	<cfscript>
	if ( StructCount(sArgs) ) {
		//Loop through the data fields provided (data changed in any other manner will have to be captured in the SQL passed in)
		for ( key in sArgs["data"] ) {
			//Make sure the field exists in the record (or nothing to compare to)
			if (
						StructKeyExists(sArgs,"before")
					AND StructKeyExists(sArgs["before"],key)
					AND isSimpleValue(sArgs["before"][key])
					AND StructKeyExists(sArgs,"after")
					AND StructKeyExists(sArgs["after"],key)
					AND isSimpleValue(sArgs["after"][key])
				) {
				//Only track if the data isn't the same
				if ( ListSort(sArgs["before"][key],"text") NEQ ListSort(sArgs["after"][key],"text") ) {
					sChange = {
						FieldName=key,
						OldValue=sArgs["before"][key],
						NewValue=sArgs["after"][key]
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
		EventNames = "DataMgr:afterInsert,DataMgr:afterDelete,DataMgr:afterUpdate"
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
		<table name="audRestores">
			<field ColumnName="RestoreID" CF_DataType="CF_SQL_INTEGER" PrimaryKey="true" Increment="true" />
			<field ColumnName="tablename" CF_DataType="CF_SQL_VARCHAR" Length="250" />
			<field ColumnName="pkvalue" CF_DataType="CF_SQL_VARCHAR" Length="250" />
			<field ColumnName="DateRestorePerformed" CF_DataType="CF_SQL_DATE" Special="CreationDate" />
			<field ColumnName="DateRestoredFrom" CF_DataType="CF_SQL_DATE" />
		</table>
	</tables>
	</cfoutput></cfsavecontent>

	<cfreturn tableXML>
</cffunction>

</cfcomponent>
