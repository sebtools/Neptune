<cfsilent>
<!---
I get a SQL array for use with DataMgr
Version 1.0 Beta 1 (build 4)
Updated: 2010-10-01
Created: 2010-01-12
--->

<!--- Get UDFs --->
<cfif NOT isDefined("getDMSQLArray")><cfinclude template="DMUdfs.cfm"></cfif>

<!--- Associate with CF_DMQuery if called from within it --->
<cfif ThisTag.ExecutionMode EQ "Start">
	<cfset isNestedTag = false>
	<cfif ListFindNoCase(getBaseTagList(),"CF_DMQuery")>
		<cfassociate basetag="cf_DMQuery" dataCollection="aSQLs">
		<cfset ParentData = getBaseTagData("cf_DMQuery")>
		<cfset isNestedTag = true>
	</cfif>
</cfif>

<cfif isNestedTag>
	<cfset Variables.DataMgr = ParentData.attributes.DataMgr>
<cfelse>
	<cfif StructKeyExists(Attributes,"DataMgr")>
		<cfset Variables.DataMgr = Attributes.DataMgr>
	<cfelseif StructKeyExists(Caller,"DataMgr")>
		<cfset Variables.DataMgr = Caller.DataMgr>
	<cfelseif StructKeyExists(Application,"DataMgr")>
		<cfset Variables.DataMgr = Application.DataMgr>
	<cfelse>
		<!---<cfparam name="attributes.path" default="com.sebtools.DataMgr">
		<cfinvoke returnvariable="Variables.DataMgr" component="#attributes.path#" method="init" argumentCollection="#attributes#">
		</cfinvoke>--->
		<cfthrow message="Unable to determine DataMgr">
	</cfif>
</cfif>

<cfparam name="Attributes.method" default="getRecordsSQL">

<cfif ThisTag.ExecutionMode EQ "End" OR NOT ThisTag.HasEndTag>
	<!--- Return the SQL array --->
	<cfif NOT (
				StructKeyExists(attributes,"sql")
			AND	(
						isArray(attributes.sql)
					OR	(
								isSimpleValue(attributes.sql)
							AND	Len(Trim(attributes.sql))
						)
				)
	)>
		<cfif Len(Trim(ThisTag.GeneratedContent))>
			<!--- Get SQL from generated content --->
			<cfset attributes.sql = getDMSQLArray()>
		<cfelseif StructKeyExists(attributes,"method") AND isSimpleValue(Attributes.method) AND Len(Trim(Attributes.method))>
			<!--- Or use a method to get it --->
			<cfinvoke
				returnvariable="attributes.sql"
				component="#Variables.DataMgr#"
				method="#attributes.method#"
				argumentcollection="#attributes#"
			>
		<cfelse>
			<!--- If all else failed, just make an empty array --->
			<cfset attributes.sql = ArrayNew(1)>
		</cfif>
	</cfif>
	<!--- If a name attribute is passed in, set the given variable in the calling page --->
	<cfif StructKeyExists(attributes,"name")>
		<cfset Caller[attributes.name] = attributes.sql>
	</cfif>
</cfif>

</cfsilent><cfif isNestedTag AND ( ThisTag.ExecutionMode EQ "End" OR NOT ThisTag.HasEndTag )><cfoutput>[DataMgrSQL:#ArrayLen(ParentData.ThisTag.aSQLs)#]</cfoutput></cfif>