<cfsilent>
<!---
I run a query using DataMgr
Version 1.0 Beta 1 (build 4)
Updated: 2010-10-01
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

<!--- Get UDFs --->
<cfif NOT isDefined("getDMSQLArray")><cfinclude template="DMUdfs.cfm"></cfif>

<cfif ThisTag.HasEndTag AND ThisTag.ExecutionMode EQ "End" AND Len(Trim(ThisTag.GeneratedContent))>
	<!--- Execute the given SQL if given any --->
	<cfset aSQL = getDMSQLArray()>
	<cftry>
		<cfset qRecords = attributes.DataMgr.runSQLArray(aSQL)>
	<cfcatch>
		<cfdump var="#aSQL#">
		<cfabort>
	</cfcatch>
	</cftry>
	<cfif StructKeyExists(attributes,"name") AND isDefined("qRecords")>
		<cfset Caller[attributes.name] = qRecords>
	</cfif>
<cfelseif NOT ThisTag.HasEndTag OR ( ThisTag.ExecutionMode EQ "End" AND NOT Len(Trim(ThisTag.GeneratedContent)) )>
	<!--- Otherwise we'll have to turn to methods --->
	<cfparam name="attributes.method">
	<cfinvoke
		returnvariable="qRecords"
		component="#attributes.DataMgr#"
		method="#attributes.method#"
		argumentcollection="#attributes#"
	>
	<cfif StructKeyExists(attributes,"name") AND isDefined("qRecords")>
		<cfset Caller[attributes.name] = qRecords>
	</cfif>
</cfif>

</cfsilent>