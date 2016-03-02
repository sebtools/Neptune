<cfcomponent displayname="Beany" output="no">

<cffunction name="init" access="public" returntype="any" output="no" hint="I instantiate and return this object.">
	<cfargument name="mutable" type="boolean" default="true" hint="Are the properties mutable (can they be changed)?">
	
	<cfset initProperties(ArgumentCollection=Arguments)>
	
	<cfreturn This>
</cffunction>

<cffunction name="get" access="public" returntype="any" output="no" hint="I return the value for the property.">
	<cfargument name="property" type="string" required="yes">
	
	<cfreturn Variables[Arguments.property]>
</cffunction>

<cffunction name="has" access="public" returntype="any" output="no" hint="I indicate if the property exists.">
	<cfargument name="property" type="string" required="yes">
	
	<cfreturn StructKeyExists(Variables,Arguments.property)>
</cffunction>

<cffunction name="set" access="public" returntype="any" output="no" hint="I set the value for the property.">
	<cfargument name="property" type="string" required="yes">
	<cfargument name="value" type="any" required="yes">
	
	<cfif Variables.mutable>
		<cfset Variables[Arguments.property] = Arguments.value>
	<cfelse>
		<cfthrow type="Beany" message="Unable to set property. Object is not mutable." detail="Unable to set #Arguments.property# property. Object is not mutable.">
	</cfif>
	
	<cfreturn get(Variables.property)>
</cffunction>

<cffunction name="initProperties" access="public" returntype="any" output="no" hint="I initialize property values.">
	
	<cfset var ii = 0>

	<cfloop item="ii" collection="#Arguments#">
		<cfif NOT StructKeyExists(Variables,"ii")>
			<cfset Variables[ii] = Arguments[ii]>
		</cfif>
	</cfloop>

</cffunction>

<cfscript>
function getMissingMethodHandler() {
	var result = 0;
	var method = Trim(Arguments.missingMethodName);
	var property = ReReplaceNoCase(method,"^(([gs]et)|(has))","");
	var args = Arguments.missingMethodArguments;
	var action = "";
	var fMethod = 0;

	if ( NOT Len(property) ) {
		return false;
	}

	if ( property NEQ method ) {
		action = Left(method,3);
	} else {
		action = iif(ArrayLen(args),DE("set"),DE("get"));
	}

	return {action=action,property=property};
}
function onMissingMethod() {
	var result = 0;
	var sMethod = getMissingMethodHandler(ArgumentCollection=Arguments);
	var fMethod = 0;

	if ( NOT StructKeyExists(This,sMethod.action) ) {
		return false;
	}

	fMethod = This[sMethod.action];

	if ( sMethod.action IS "set" ) {
		result = fMethod(sMethod.property,args[1]);
	} else {
		result = fMethod(sMethod.property);
	}

	return result;
}
</cfscript>

</cfcomponent>