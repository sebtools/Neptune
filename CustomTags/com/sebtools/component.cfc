<cfcomponent>

<cfset Variables.component_instance_id = CreateUUID()>

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

<cffunction name="getComponentInstanceID" access="public" returntype="string" output="no">
	<cfreturn Variables.component_instance_id>
</cffunction>

<cffunction name="checkValidationErrors" access="public" returntype="void" output="false" hint="">
	<cfset throwValidationError("",true)>
</cffunction>

<cffunction name="throwValidationError" access="public" returntype="void" output="false" hint="">
	<cfargument name="message" type="string" required="yes">
	<cfargument name="stop" type="boolean" default="false" hint="Won't actually throw error until called with stop=true.">

	<cfscript>
	var result = "";
	if ( NOT StructKeyExists(Variables,"aValidationMessages") ) {
		Variables.aValidationMessages = [];
	}
	if ( Len(Trim(Arguments.message)) ) {
		ArrayAppend(
			Variables.aValidationMessages,
			Arguments.message
		);
	}

	if ( Arguments.stop AND ArrayLen(Variables.aValidationMessages) ) {
		if ( ArrayLen(Variables.aValidationMessages) EQ 1 ) {
			result = Variables.aValidationMessages[1];
		} else {
			result = SerializeJSON(Variables.aValidationMessages);
		}
		throw(
			type="validation",
			message="#result#"
		);
	}
	</cfscript>

</cffunction>

</cfcomponent>
