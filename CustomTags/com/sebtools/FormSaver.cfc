<!--- 1.0 (Build 3) --->
<!--- Last Updated: 2007-06-12 --->
<!--- Created by Steve Bryant 2005-10-20 --->
<!--- Information: sebtools.com --->
<cfcomponent displayname="Form Saver" hint="I save and retreive form information (using either DataMgr or SessionMgr).">

<cffunction name="init" access="public" returntype="any" output="no" hint="I instantiate and return this component. Either the DataMgr or the SessionMgr must be passed in to initialize this component.">
	<cfargument name="DataMgr" type="any" required="no">
	<cfargument name="SessionMgr" type="any" required="no">
	<cfargument name="tablename" type="string" default="frmSaveds">
	
	<cfset variables.table = arguments.tablename>
	
	<cfif StructKeyExists(arguments,"DataMgr")><!--- If DataMgr is passed in, use that --->
		<cfset variables.DataMgr = arguments.DataMgr>
		<cfset variables.DataMgr.loadXml(getDbXml(),true)><!--- Create table if it doesn't exist --->
	</cfif>
	
	<cfif StructKeyExists(arguments,"SessionMgr")><!--- Else use SessionMgr --->
		<cfset variables.SessionMgr = arguments.SessionMgr>
	</cfif>
	
	<!--- If neither is passed in, throw an error. --->
	<cfif NOT ( StructKeyExists(arguments,"DataMgr") OR StructKeyExists(arguments,"SessionMgr") )>
		<cfthrow message="Form Saver must have either a DataMgr or SessionMgr to save form information." type="FormSaver">
	</cfif>
	
	<cfreturn this>
</cffunction>

<cffunction name="store" access="public" returntype="void" output="no" hint="I store the form.">
	<cfargument name="formdata" type="struct" required="yes" hint="The structure of form data - can simply be the form scope itself.">
	<cfargument name="formname" type="string" required="yes" hint="A name to uniquely identify this form.">
	<cfargument name="usertoken" type="string" required="no" hint="Any unique string (maybe cfid_cftoken) to identify the user. Required only if using DataMgr.">
	
	<cfset var key = "">
	<cfset var data = "">
	
	<!--- usertoken is required when using DataMgr --->
	<cfif isDefined("variables.DataMgr") AND NOT StructKeyExists(arguments,"usertoken")>
		<cfthrow message="usertoken argument must be provided to identify user when using DataMgr to store forms.">
	</cfif>
	
	<cfwddx action="CFML2WDDX" input="#arguments.formdata#" output="arguments.FormWDDX">
	
	<cfif isDefined("variables.DataMgr")>
		<cfset variables.DataMgr.saveRecord('frmSaveds',arguments)>
	</cfif>
	<cfif isDefined("variables.SessionMgr")>
		<cfset variables.SessionMgr.setValue("formsaver_#arguments.formname#",formdata)>
	</cfif>
	
</cffunction>

<cffunction name="retrieve" access="public" returntype="struct" output="no" hint="I retrieve the form.">
	<cfargument name="formname" type="string" required="yes" hint="A name to uniquely identify this form.">
	<cfargument name="usertoken" type="string" required="no" hint="Any unique string (maybe cfid_cftoken) to identify the user. Required only if using DataMgr.">
	
	<cfset wddxData = "">
	<cfset qRecord = 0>
	<cfset result = StructNew()>
	
	<!--- usertoken is required when using DataMgr --->
	<cfif isDefined("variables.DataMgr") AND NOT StructKeyExists(arguments,"usertoken")>
		<cfthrow message="usertoken argument must be provided to identify user when using DataMgr to store forms.">
	</cfif>
	
	<!--- Get the wddx of the form --->
	<cfif isDefined("variables.DataMgr")>
		<cfset qRecord = variables.DataMgr.getRecord('frmSaveds',arguments)>
		<cfif qRecord.RecordCount>
			<cfset wddxData = qRecord.FormWDDX>
			<!--- Convert the wddx back to a ColdFusion structure --->
			<cfwddx action="WDDX2CFML" input="#wddxData#" output="result">
		</cfif>
	</cfif>
	<cfif isDefined("variables.SessionMgr")>
		<cfif variables.SessionMgr.Exists("formsaver_#arguments.formname#")>
			<cfset result = variables.SessionMgr.getValue("formsaver_#arguments.formname#")>
			<!--- Convert the wddx back to a ColdFusion structure --->
			<!--- <cfwddx action="WDDX2CFML" input="#wddxData#" output="result"> --->
		</cfif>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="delete" access="public" returntype="void" output="no" hint="I delete a form.">
	<cfargument name="formname" type="string" required="yes" hint="A name to uniquely identify this form.">
	<cfargument name="usertoken" type="string" required="no" hint="Any unique string (maybe cfid_cftoken) to identify the user. Required only if using DataMgr.">
	
	<!--- usertoken is required when using DataMgr --->
	<cfif isDefined("variables.DataMgr") AND NOT StructKeyExists(arguments,"usertoken")>
		<cfthrow message="usertoken argument must be provided to identify user when using DataMgr to store forms.">
	</cfif>
	
	<cfif isDefined("variables.DataMgr")>
		<cfset variables.DataMgr.deleteRecord('frmSaveds',arguments)>
	</cfif>
	<cfif isDefined("variables.SessionMgr")>
		<cfset variables.SessionMgr.deleteVar("formsaver_#arguments.formname#")>
	</cfif>
	
</cffunction>

<cffunction name="getDbXml" access="public" returntype="string" output="no" hint="I return the XML for the tables needed for FormSaver to work.">
	
	<cfset var tableXML = "">
	
	<cfsavecontent variable="tableXML"><cfoutput>
	<tables>
		<table name="#variables.table#">
			<field ColumnName="formname" CF_DataType="CF_SQL_VARCHAR" Length="180" PrimaryKey="true" />
			<field ColumnName="usertoken" CF_DataType="CF_SQL_VARCHAR" Length="180" PrimaryKey="true" />
			<field ColumnName="FormWDDX" CF_DataType="CF_SQL_LONGVARCHAR" />
		</table>
	</tables>
	</cfoutput></cfsavecontent>
	
	<cfreturn tableXML>
</cffunction>

</cfcomponent>