<cfcomponent>

<cfinclude template="udfs.cfm">

<cffunction name="init" access="public" returntype="any" output="no">

	<cfset initInternal(ArgumentCollection=Arguments)>

	<cfreturn This>
</cffunction>

<cffunction name="initInternal" access="private" returntype="any" output="no">

	<cfset var key = "">

	<!--- Get all components from arguments --->
	<cfloop collection="#Arguments#" item="key">
		<cfset Variables[key] = Arguments[key]>
		<cfif isObject(Arguments[key])>
			<cfset This[key] = Arguments[key]>
		</cfif>
	</cfloop>

	<cfif
		NOT StructKeyExists(Variables,"DataMgr")
		AND
		StructKeyExists(Variables,"Manager")
		AND
		StructKeyExists(Variables.Manager,"DataMgr")
	>
		<cfset Variables.DataMgr = Variables.Manager.DataMgr>
	</cfif>

	<cfif StructKeyExists(Variables,"DataMgr")>
		<cfset Variables.datasource = Variables.DataMgr.getDatasource()>
	</cfif>

</cffunction>

</cfcomponent>
