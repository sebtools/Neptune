<cfcomponent output="no">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="Records" type="any" required="yes">
	
	<cfset Variables.Records = Arguments.Records>
	<cfset Variables.sMeta = Arguments.Records.getMetaStruct()>
	
	<cfset addTestMethods()>
	
	<cfreturn This>
</cffunction>

<cffunction name="getPrimaryKeyValues" access="public" returntype="string" output="no">
	
	<cfset var sMetaStruct = getMetaStruct()>
	
	<cfif StructKeyExists(sMetaStruct,"arg_pk")>
		<cfset Arguments.field = sMetaStruct["arg_pk"]>
		<cfinvoke returnvariable="result" method="getTableFieldValue" argumentcollection="#Arguments#">
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="copyRecord" access="public" returntype="string" output="no">
	
	<cfreturn 0>
</cffunction>

<cffunction name="deleteRecord" access="public" returntype="void" output="no">
	<cfset removeRecord(argumentCollection=arguments)>
</cffunction>

<cffunction name="removeRecord" access="public" returntype="void" output="no">
	
</cffunction>

<cffunction name="RecordObject" access="public" returntype="any" output="no">
	<cfargument name="Record" type="any" required="yes">
	<cfargument name="fields" type="string" default="">
	
	<cfset Arguments.Service = This>
	
	<cfreturn CreateObject("component","RecordObject").init(ArgumentCollection=Arguments)>
</cffunction>

<cffunction name="saveRecord" access="public" returntype="string" output="no">
	
	<cfset var sArgs = 0>
	<cfset var result = "">
	<cfset var oRecord = RecordObject(Record=Arguments)>
	
	<cfif oRecord.isNewRecord()>
		<cfset StructAppend(Arguments,Variables.Records.getSpecifyingValues(),"no")>
	</cfif>
	
	<cfinvoke
		returnvariable="sArgs"
		component="#This#"
		method="#Variables.sMeta.method_validate#"
		argumentCollection="#Arguments#"
	>
	
	<cfif StructKeyExists(Variables.sMeta,"arg_pk") AND StructKeyExists(sArgs,Variables.sMeta.arg_pk)>
		<cfset result = sArgs[Variables.sMeta.arg_pk]>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="sortRecords" access="public" returntype="void" output="no">
	
</cffunction>

<cffunction name="addTestMethods" access="private" returntype="void" output="no">
	
	<cfset var singular = Variables.sMeta.method_Singular>
	<cfset var plural = Variables.sMeta.method_Plural>
	<cfset var methods = "remove#singular#,save#singular#,sort#plural#,copy#singular#">
	<cfset var rmethods = "removeRecord,saveRecord,sortRecords,copyRecord">
	<cfset var method = "">
	<cfset var rmethod = "">
	<cfset var ii = 0>
	
	<cfloop index="ii" from="1" to="#ListLen(methods)#" step="1">
		<cfset method = ListGetAt(methods,ii)>
		<cfset rmethod = ListGetAt(rmethods,ii)>
		<cfif NOT StructKeyExists(This,method)>
			<cfset This[method] = variables[rmethod]>
		</cfif>
		<cfif NOT StructKeyExists(variables,method)>
			<cfset variables[method] = variables[rmethod]>
		</cfif>
	</cfloop>
	
</cffunction>

<cffunction name="onMissingMethod" access="public" returntype="any" output="no">
	
	<cfset var result = 0>
	<cfset var TestMethods = "#Variables.sMeta.method_copy#,#Variables.sMeta.method_remove#,#Variables.sMeta.method_save#">
	<cfset var TestRMethods = "copyRecord,removeRecord,saveRecord">
	<cfset var method = arguments.missingMethodName>
	<cfset var args = arguments.missingMethodArguments>
	
	<cfif ListFindNoCase(TestMethods,method)>
		<cfinvoke
			returnvariable="result"
			method="#ListGetAt(TestRMethods,ListFindNoCase(TestMethods,method))#"
			ArgumentCollection="#args#"
		>
	<cfelse>
		<cfinvoke
			returnvariable="result"
			component="#Variables.Records#"
			method="#method#"
			ArgumentCollection="#args#"
		>
	</cfif>
	
	<cfif isDefined("result")>
		<cfreturn result>
	</cfif>
</cffunction>

</cfcomponent>