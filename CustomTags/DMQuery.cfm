<cfsilent>
<!---
I run a query using DataMgr
Version 1.0
Updated: 2017-08-08
Created: 2010-01-12
--->

<cfif StructKeyExists(Caller,"DataMgr")>
	<cfparam name="attributes.DataMgr" default="#Caller.DataMgr#">
<cfelseif StructKeyExists(Application,"DataMgr")>
	<cfparam name="attributes.DataMgr" default="#Application.DataMgr#">
</cfif>
<cfparam name="attributes.path" default="com.sebtools.DataMgr">
<cfif NOT StructKeyExists(attributes,"DataMgr")>
	<cfinvoke returnvariable="attributes.DataMgr" component="#attributes.path#" method="init" argumentCollection="#attributes#">
	</cfinvoke>
</cfif>
<cfparam name="attributes.DataMgr">

<cfif StructKeyExists(Caller,"DataLogger")>
	<cfparam name="attributes.DataLogger" default="#Caller.DataLogger#">
<cfelseif StructKeyExists(Application,"DataLogger")>
	<cfparam name="attributes.DataLogger" default="#Application.DataLogger#">
<cfelse>
	<cftry>
		<cf_service name="DataLogger">
		<cfset Attributes.DataLogger = Variables.DataLogger>
	<cfcatch>
	</cfcatch>
	</cftry>
</cfif>


<!--- Get UDFs --->
<cfif NOT isDefined("getDMSQLArray")><cfinclude template="DMUdfs.cfm"></cfif>

<cfif ThisTag.HasEndTag AND ThisTag.ExecutionMode EQ "End" AND Len(Trim(ThisTag.GeneratedContent))>
	<!--- Execute the given SQL if given any --->
	<cfset sqlarray = getDMSQLArray()>
	<cfset sActions = getActionArgs(sqlarray)>
	<cfset Variables.result = attributes.DataMgr.runSQLArray(sqlarray,attributes)>
	<!---- Try to log action ---->
	<cfset StructAppend(Attributes,sActions,"no")>
	<cfif doLog(Attributes)>
		<cfinvoke
			component="#Attributes.DataLogger#"
			method="logAction"
			tablename="#Trim(Attributes.tablename)#"
			action="#Attributes.action#"
			sql="#sqlarray#"
			complete="true"
		>
			<cfif StructKeyExists(Attributes,"pkvalue")>
				<cfinvokeargument name="pkvalue" value="#Attributes.pkvalue#">
			<cfelseif StructKeyExists(Variables,"result") AND isSimpleValue(Variables.result)>
				<cfinvokeargument name="pkvalue" value="#Variables.result#">
			</cfif>
		</cfinvoke>
	</cfif>
	<cfif StructKeyExists(attributes,"name") AND StructKeyExists(Variables,"result")>
		<cfset Caller[attributes.name] = Variables.result>
	</cfif>
	<cfif StructKeyExists(Attributes,"sqlresult") AND isSimpleValue(Attributes.sqlresult) AND Len(Attributes.sqlresult)>
		<cfset Caller[Attributes.sqlresult] = sqlarray>
	</cfif>
<cfelseif NOT ThisTag.HasEndTag OR ( ThisTag.ExecutionMode EQ "End" AND NOT Len(Trim(ThisTag.GeneratedContent)) )>
	<!--- Otherwise we'll have to turn to methods --->
	<cfparam name="attributes.method">
	<cfinvoke
		returnvariable="Variables.result"
		component="#attributes.DataMgr#"
		method="#attributes.method#"
		argumentcollection="#attributes#"
	>
	<cfif StructKeyExists(attributes,"name") AND StructKeyExists(Variables,"result")>
		<cfset Caller[attributes.name] = Variables.result>
	</cfif>
</cfif>

</cfsilent>
