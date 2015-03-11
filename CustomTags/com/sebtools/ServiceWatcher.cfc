<cfcomponent displayname="Service Watcher" output="no">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="ServiceFactory" type="any" required="yes">
	<cfargument name="Observer" type="any" required="yes">
	<cfargument name="DataMgr" type="any" required="yes">
	
	<cfset Variables.DataMgr = Arguments.DataMgr>
	<cfset Variables.Observer = Arguments.Observer>
	<cfset Variables.ServiceFactory = Arguments.ServiceFactory>

	<cfset Variables.DataMgr.loadXml(getDbXml(),true,true)>

	<cfset Variables.datasource = Variables.DataMgr.getDatasource()>

	<cfset registerListener()>
	
	<cfreturn This>
</cffunction>

<cffunction name="getLastLoadData" access="public" returntype="query" output="no" hint="I return information about the last time that the given service was loaded.">
	<cfargument name="ServiceName" type="string" required="true">
	
	<cfset var qServiceData = 0>

	<cfquery name="qServiceData" datasource="#Variables.datasource#">
	SELECT		TOP 1 LoadID,ServiceID,ServiceName,DateLoaded,LoadTime,DateTracked
	FROM		svcLoads
	WHERE		ServiceID = <cfqueryparam value="#Val(getServiceID(Arguments.ServiceName))#" cfsqltype="CG_SQL_INTEGER">
	ORDER BY	LoadID DESC
	</cfquery>
	
	<cfreturn qServiceData>
</cffunction>

<cffunction name="getLastLoadTime" access="public" returntype="numeric" output="no" hint="I return the time to load the given service last time it was loaded.">
	<cfargument name="ServiceName" type="string" required="true">
	
	<cfset var qServiceData = getLastLoadData(Arguments.ServiceName)>

	<cfreturn qServiceData.LoadTime>
</cffunction>

<cffunction name="getServicesReport" access="public" returntype="struct" output="no" hint="I return a report about services that have been loaded.">
	
	<cfset var qServiceData = 0>
	<cfset var sResult = StructNew()>

	<cfquery name="qServiceData" datasource="#Variables.datasource#">
	SELECT	ServiceID,
			ServiceName,
			(
				SELECT	AVG(LoadTime) AS AvgLoadTime
				FROM	svcLoads
				WHERE	ServiceID = svcServices.ServiceID
			) AS AvgLoadTime,
			(
				SELECT	Max(DateLoaded) AS LastLoadTime
				FROM	svcLoads
				WHERE	ServiceID = svcServices.ServiceID
			) AS LastLoadTime,
			(
				SELECT	Max(DateUpdated) AS LastUpdateDate
				FROM	svcServicesStates
				WHERE	ServiceID = svcServices.ServiceID
			) AS LastUpdateDate,
			(
				SELECT		TOP 1 FileHash
				FROM		svcServicesStates
				WHERE		ServiceID = svcServices.ServiceID
				ORDER BY	DateUpdated DESC
			) AS FileHash,
			(
				SELECT		TOP 1 [Path]
				FROM		svcServicesStates
				WHERE		ServiceID = svcServices.ServiceID
				ORDER BY	DateUpdated DESC
			) AS FilePath
	FROM		svcServices
	</cfquery>

	<cfoutput query="qServiceData" group="ServiceName">
		<cfset sResult[ServiceName] = {
			ServiceName=ServiceName,
			AvgLoadTime=AvgLoadTime,
			FileHash=FileHash,
			LastLoadTime=LastLoadTime,
			LastUpdateDate=LastUpdateDate,
			FilePath=FilePath
		}>
	</cfoutput>

	<cfreturn sResult>
</cffunction>

<cffunction name="logServiceLoad" access="public" returntype="numeric" output="no" hint="I log information about the loading of a service.">
	<cfargument name="ServiceName" type="string" required="true">
	<cfargument name="Service" type="any" required="true">
	<cfargument name="Meta" type="any" required="true">

	<cfset var sService = StructNew()>
	<cfset var sServiceState = StructNew()>
	<cfset var sServiceLoad = StructNew()>
	<cfset var sFileInfo = 0>

	<cfset sService["ServiceName"] = Arguments.ServiceName>
	<cfif StructKeyExists(Arguments.Meta,"DisplayName")>
		<cfset sService["DisplayName"] = Arguments.Meta.DisplayName>
	</cfif>
	<cfif StructKeyExists(Arguments.Meta,"FullName")>
		<cfset sService["FullName"] = Arguments.Meta.FullName>
	</cfif>
	<cfset sService["Path"] = Arguments.Meta.Path>

	<cfset Arguments.ServiceID = Variables.DataMgr.saveRecord(tablename="svcServices",data=sService,checkFields="ServiceName")>

	<cfset sFileInfo = GetFileInfo(sService["Path"])>

	<cfset sServiceState["ServiceID"] = Arguments.ServiceID>
	<cfset sServiceState["DateUpdated"] = sFileInfo.lastmodified>
	<cfset sServiceState["FullName"] = sService["FullName"]>
	<cfset sServiceState["Path"] = sService["Path"]>
	<cfif StructKeyExists(sService,"DisplayName")>
		<cfset sServiceState["DisplayName"] = sService["DisplayName"]>
	</cfif>

	<cfif NOT Variables.DataMgr.hasRecords(tablename='svcServicesStates',data=sServiceState)>
		<cfset sServiceState["FileHash"] = Hash(FileRead(sService["Path"]))>
		<cfset Variables.DataMgr.saveRecord(tablename="svcServicesStates",data=sServiceState)>
	</cfif>

	<cfscript>
	sServiceLoad["ServiceID"] = Arguments["ServiceID"];
	sServiceLoad["ServiceName"] = Arguments["ServiceName"];
	sServiceLoad["DateLoaded"] = Arguments.Meta.DateLoaded;
	sServiceLoad["LoadTime"] = Arguments.Meta.LoadTime;

	return Variables.DataMgr.insertRecord(tablename="svcLoads",data=sServiceLoad,onExists="insert");
	</cfscript>

</cffunction>

<cffunction name="getServiceLoadTime" access="public" returntype="string" output="no" hint="I return the average load time for the give service from the given state (or the average since the last change if no date is given).">
	<cfargument name="ServiceName" type="string" required="true">
	<cfargument name="SinceDate" type="date" required="false">

	<cfset var qServiceData = 0>

	<cfquery name="qServiceData" datasource="#Variables.datasource#">
	SELECT	AVG(LoadTime) AS AvgLoadTime
	FROM	svcLoads
	WHERE	1 = 1
	<cfif StructKeyExists(Arguments,"ServiceDate")>
		AND	DateTracked >= #createODBCDate(Arguments.ServiceDate)#
	</cfif>
	</cfquery>
	
	<cfreturn qServiceData.AvgLoadTime>
</cffunction>

<cffunction name="getServiceID" access="public" returntype="numeric" output="no" hint="I return the ServiceID for the given ServiceName.">
	<cfargument name="ServiceName" type="string" required="true">

	<cfreturn Variables.DataMgr.getPKFromData(tablename="svcServices",fielddata=Arguments)>
</cffunction>

<cffunction name="registerListener" access="private" returntype="void" output="no" hint="I register a listener with Observer to listen for services being loaded.">
	
	<cfset Variables.Observer.registerListener(
		Listener = This,
		ListenerName = "ServiceWatcher",
		ListenerMethod = "logServiceLoad",
		EventName = "ServiceFactory:loadService"
	)>
	
</cffunction>

<!--- Ability to track changes to component as well (from date and by Hash?) --->

<cffunction name="getDbXml" access="private" returntype="string" output="no" hint="I return the XML for the tables needed for ServiceWatcher to work.">
	
	<cfset var result = "">
	
	<cfsavecontent variable="result"><cfoutput>
	<tables>
		<table name="svcLoads">
			<field ColumnName="LoadID" CF_DataType="CF_SQL_BIGINT" PrimaryKey="true" Increment="true" />
			<field ColumnName="ServiceID" CF_DataType="CF_SQL_INTEGER" />
			<field ColumnName="ServiceName" CF_DataType="CF_SQL_VARCHAR" Length="50" />
			<field ColumnName="DateLoaded" CF_DataType="CF_SQL_DATE" />
			<field ColumnName="LoadTime" CF_DataType="CF_SQL_INTEGER" />
			<field ColumnName="DateTracked" CF_DataType="CF_SQL_DATE" Special="CreationDate" />
		</table>
		<table name="svcServices">
			<field ColumnName="ServiceID" CF_DataType="CF_SQL_INTEGER" PrimaryKey="true" Increment="true" />
			<field ColumnName="ServiceName" CF_DataType="CF_SQL_VARCHAR" Length="50" />
			<field ColumnName="FullName" CF_DataType="CF_SQL_VARCHAR" Length="500" />
			<field ColumnName="Path" CF_DataType="CF_SQL_VARCHAR" Length="500" />
			<field ColumnName="DisplayName" CF_DataType="CF_SQL_VARCHAR" Length="500" />
		</table>
		<table name="svcServicesStates">
			<field ColumnName="ServiceStateID" CF_DataType="CF_SQL_BIGINT" PrimaryKey="true" Increment="true" />
			<field ColumnName="ServiceID" CF_DataType="CF_SQL_INTEGER" />
			<field ColumnName="DateUpdated" CF_DataType="CF_SQL_DATE" />
			<field ColumnName="FullName" CF_DataType="CF_SQL_VARCHAR" Length="500" />
			<field ColumnName="Path" CF_DataType="CF_SQL_VARCHAR" Length="500" />
			<field ColumnName="DisplayName" CF_DataType="CF_SQL_VARCHAR" Length="500" />
			<field ColumnName="FileHash" CF_DataType="CF_SQL_LONGVARCHAR" />
		</table>
	</tables>
	</cfoutput></cfsavecontent>
	
	<cfreturn result>
</cffunction>

</cfcomponent>