<cfcomponent extends="com.sebtools.component" displayname="Data Trashcan" hint="I handle putting deleted records into Trashcan tables." output="no">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="DataLogger" type="any" required="yes">
	<cfargument name="DatabaseName" type="string" required="no">
	<cfargument name="Owner" type="string" default="dbo">

	<cfset Arguments.DataMgr = Arguments.DataLogger.getDataMgr()>
	<cfset Arguments.Observer = Arguments.DataLogger.getObserver()>

	<cfset initInternal(ArgumentCollection=Arguments)>

	<cfset loadDataMgr()>

	<cfset registerListener()>

	<cfset Variables.sLoadedTables = {}>

	<cfset Variables.DataLogger.setDataTrashcan(This)>

	<cfreturn This>
</cffunction>

<cffunction name="getDeletedRecord" access="public" returntype="any" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="data" type="struct" required="no">
	<cfargument name="fieldlist" type="string" required="no">

	<cfset var qRecords = 0>
	<cfset var sData = StructCopy(Arguments)>

	<cfset createTrashcanTable(Arguments.tablename)>

	<cfset sData["Tablename"] = getTrackingTableName(Arguments.tablename)>
	<cfset sData["maxrows"] = 1>
	<cfset sData["orderBy"] = "DataTrashcan_ID DESC">

	<!--- Make sure DataTrashcan fields are returned. --->
	<cfif StructKeyHasLen(Arguments,"fieldlist")>
		<cfset Arguments.fieldlist = ListAppend(Arguments.fieldlist,"DataTrashcan_ID,DataTrashcan_DateDeleted")>
	</cfif>

	<cfset qRecords = Variables.DataMgrTrashcan.getRecords(ArgumentCollection=sData)>

	<cfreturn qRecords>
</cffunction>

<cffunction name="loadDataMgr" access="private" returntype="any" output="no">

	<cfset var sArgs = {}><!--- Don't pass all arguments in. We specifically don't want Observer in there. --->

	<cfset sArgs["datasource"] = Variables.DataMgr.getDatasource()>
	<cfif StructKeyHasLen(Variables,"DatabaseName")>
		<cfset sArgs["databasename"] = Variables.DatabaseName>
	</cfif>

	<cfset Variables.DataMgrTrashcan = CreateObject("component","com.sebtools.DataMgr").init(ArgumentCollection=sArgs)>

</cffunction>

<cffunction name="logAction" access="public" returntype="any" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="action" type="string" required="yes">
	<cfargument name="data" type="struct" required="no">
	<cfargument name="ChangeUUID" type="string" required="no">
	<cfargument name="sql" type="any" required="no">

	<cfset var qRecords = 0>
	<cfset var sData = 0>

	<cfif NOT ListFindNoCase(Variables.DataLogger.getLoggedTables(),Arguments.tablename)>
		<cfreturn false>
	</cfif>

	<cfset qRecords = Variables.DataMgr.getRecords(tablename=Arguments.tablename,data=Arguments.data)>

	<cfset createTrashcanTable(Arguments.tablename)>

	<cfoutput query="qRecords">
		<cfset sData = Variables.DataMgr.QueryRowToStruct(qRecords,CurrentRow)>
		<cfset Variables.DataMgrTrashcan.runSQLArray(Variables.DataMgrTrashcan.insertRecordSQL(tablename=getTrackingTableName(Arguments.tablename),data=sData))>
	</cfoutput>

	<cfreturn true>
</cffunction>

<cffunction name="createTrashcanTable" access="private" returntype="any" output="no">
	<cfargument name="tablename" type="string" required="yes">

	<!--- Only load the table once per instantiation (should make sure it is current to recent changes without continuing to update it). --->
	<cfif NOT StructKeyExists(Variables.sLoadedTables,Arguments.tablename)>
		<cfset makeTable(Arguments.tablename)>
		<cfset growColumns(Arguments.tablename)>
		<cfset Variables.sLoadedTables[Arguments.tablename] = now()>
	</cfif>

</cffunction>

<cffunction name="ensureTrashcanTableExists" access="private" returntype="any" output="no">
	<cfargument name="tablename" type="string" required="yes">
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

<cffunction name="getTrackingTableName" access="private" returntype="any" output="no">
	<cfargument name="tablename" type="string" required="yes">

	<cfreturn "aud_" & Arguments.tablename & "_Trashcan">
</cffunction>

<cffunction name="growColumns" access="private" returntype="any" output="no" hint="I make sure that the columns in the trashcan are as big as their counterparts in the original table.">
	<cfargument name="tablename" type="string" required="yes">

	<cfset var qColumns = 0>
	<cfset var trashtable = getTrackingTableName(Arguments.tablename)>

	<cf_DMQuery name="qColumns">
		SELECT		main.COLUMN_NAME,
					main.DATA_TYPE,
					main.IS_NULLABLE,
					trashcan.CHARACTER_MAXIMUM_LENGTH CurrentMax,
					main.CHARACTER_MAXIMUM_LENGTH TargetMax
		FROM		INFORMATION_SCHEMA.COLUMNS main
		INNER JOIN	<cf_DMObject name="#DatabaseName#">.INFORMATION_SCHEMA.COLUMNS trashcan
			ON		main.COLUMN_NAME = trashcan.COLUMN_NAME
		WHERE		1 = 1
			AND		main.TABLE_NAME = <cf_DMParam value="#Arguments.tablename#" cfsqltype="CF_SQL_VARCHAR">
			AND		trashcan.TABLE_NAME = <cf_DMParam value="#trashtable#" cfsqltype="CF_SQL_VARCHAR">
			AND		main.CHARACTER_MAXIMUM_LENGTH > trashcan.CHARACTER_MAXIMUM_LENGTH
			AND		trashcan.CHARACTER_MAXIMUM_LENGTH > 0
	</cf_DMQuery>

	<cfoutput query="qColumns">
		<cf_DMQuery>
		ALTER TABLE		<cf_DMObject name="#Variables.DatabaseName#.dbo.#trashtable#">
		ALTER COLUMN	<cf_DMObject name="#COLUMN_NAME#"> #DATA_TYPE#(#TargetMax#)<cfif IS_NULLABLE IS NOT true> NOT</cfif> NULL
		</cf_DMQuery>
	</cfoutput>

</cffunction>

<cffunction name="makeTable" access="private" returntype="any" output="no">
	<cfargument name="tablename" type="string" required="yes">

	<cfset var sTypes = Variables.DataMgrTrashcan.getRelationTypes()>
	<cfset var TableXml = Variables.DataMgr.getXml(Arguments.tablename)>
	<cfset var xTable = XmlParse(TableXml)>
	<cfset var aPKs = 0>
	<cfset var aRelations = 0>
	<cfset var DataType = "">
	<cfset var reltype = "">
	<cfset var sRelType = 0>

	<!--- Rename table to tracking --->
	<cfset xTable.tables.table.XmlAttributes["name"] = getTrackingTableName(Arguments.tablename)>

	<!--- Need to preserve the value of the incoming field, not increment it. --->
	<cfset aPKs = XmlSearch(xTable,"//field[@Increment]")>
	<cfloop array="#aPKs#" index="xfield">
		<cfset StructDelete(xfield.XmlAttributes,"Increment")>
	</cfloop>

	<!--- External pk should not be a primary key. We may need to store more than one deletion for a given record (rare, probably). --->
	<cfset aPKs = XmlSearch(xTable,"//field[@PrimaryKey]")>
	<cfloop array="#aPKs#" index="xfield">
		<cfset StructDelete(xfield.XmlAttributes,"PrimaryKey")>
	</cfloop>

	<!--- Will store relation values directly in the trashcan table with appropriate data types, --->
	<cfset aRelations = XmlSearch(xTable,"//field[relation]")>
	<cfloop array="#aRelations#" index="xfield">
		<cfset DataType = "CF_SQL_LONGVARCHAR">
		<cfif StructKeyExists(xfield.XmlChildren[1].XmlAttributes,"type")>
			<cfset reltype = xfield.XmlChildren[1].XmlAttributes["type"]>
			<cfif StructKeyExists(xfield.XmlChildren[1].XmlAttributes,"cf_datatype")>
				<cfset DataType = xfield.XmlChildren[1].XmlAttributes["cf_datatype"]>
			<cfelseif StructKeyExists(sTypes,reltype)>
				<cfset sRelType = sTypes[reltype]>
				<cfif StructKeyExists(sRelType,"cfsqltype") AND Len(sRelType["cfsqltype"])>
					<cfset DataType = sRelType["cfsqltype"]>
				</cfif>
			</cfif>
		</cfif>
		<cfset xfield.XmlAttributes["CF_DataType"] = DataType>
		<cfset StructDelete(xfield,"XmlChildren")>
	</cfloop>

	<cfset TableXml = ToString(xTable)>
	<!--- Prepend Data Trashcan fields --->
	<cfset TableXml = ReplaceNoCase(TableXml, '<field', '<field ColumnName="DataTrashcan_DateDeleted" CF_DataType="CF_SQL_DATE" Special="CreationDate" /><field', 'ONE')>
	<cfset TableXml = ReplaceNoCase(TableXml, '<field', '<field ColumnName="DataTrashcan_ID" CF_DataType="CF_SQL_INTEGER" PrimaryKey="true" Increment="true" /><field', 'ONE')>

	<cfset Variables.DataMgrTrashcan.loadXml(TableXml,true,true)>

</cffunction>

<cffunction name="registerListener" access="private" returntype="void" output="no" hint="I register a listener with Observer to listen for services being loaded.">

	<!--- Need to listen to delete events before they happen so we can capture the data just prior to the deletion. --->
	<cfset Variables.Observer.registerListener(
		Listener = This,
		ListenerName = "DataTrashcan",
		ListenerMethod = "logAction",
		EventName = "DataMgr:beforeDelete"
	)>

</cffunction>

</cfcomponent>
