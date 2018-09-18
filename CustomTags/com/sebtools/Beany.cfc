<cfcomponent displayname="Beany" output="no">

<cffunction name="init" access="public" returntype="any" output="no" hint="I instantiate and return this object.">
	<cfargument name="mutable" type="boolean" default="true" hint="Are the properties mutable (can they be changed)?">

	<cfif NOT StructKeyExists(Variables,"Props")>
		<cfset Variables.Props = {}>
	</cfif>
	<cfif NOT StructKeyExists(Variables,"mutable")>
		<cfset Variables.mutable = Arguments.mutable>
	</cfif>
	<cfset StructDelete(Arguments,"mutable")>

	<cfset initProperties(ArgumentCollection=Arguments)>

	<cfreturn This>
</cffunction>

<cffunction name="dump" access="public" returntype="any" output="no">

	<cfreturn Variables.Props>
</cffunction>

<cffunction name="get" access="public" returntype="any" output="no" hint="I return the value for the property.">
	<cfargument name="property" type="string" required="yes">

	<cfreturn Variables.Props[Arguments.property]>
</cffunction>

<cffunction name="has" access="public" returntype="any" output="no" hint="I indicate if the property exists.">
	<cfargument name="property" type="string" required="yes">

	<cfreturn StructKeyExists(Variables.Props,Arguments.property)>
</cffunction>

<cffunction name="lock" access="public" returntype="void" output="no" hint="I lock this Beany, making it immutable.">
	<cfset Variables.mutable = false>
</cffunction>

<cffunction name="remove" access="public" returntype="void" output="no" hint="I remove the property from the bean.">
	<cfargument name="property" type="string" required="yes">

	<cfif Variables.mutable>
		<cfset StructDelete(Variables.Props,Arguments.property)>
	<cfelse>
		<cfthrow type="Beany" message="Unable to remove property. Object is not mutable." detail="Unable to remove #Arguments.property# property. Object is not mutable.">
	</cfif>

</cffunction>

<cffunction name="set" access="public" returntype="any" output="no" hint="I set the value for the property.">
	<cfargument name="property" type="string" required="yes">
	<cfargument name="value" type="any" required="yes">

	<cfif Variables.mutable>
		<cfset Variables.Props[Arguments.property] = Arguments.value>
	<cfelse>
		<cfthrow type="Beany" message="Unable to set property. Object is not mutable." detail="Unable to set #Arguments.property# property. Object is not mutable.">
	</cfif>

	<cfreturn get(Arguments.property)>
</cffunction>

<cffunction name="initProperties" access="public" returntype="any" output="no" hint="I initialize property values.">

	<cfset var ii = 0>

	<cfloop item="ii" collection="#Arguments#">
		<cfif NOT StructKeyExists(Variables,ii)>
			<cfset Variables.Props[ii] = Arguments[ii]>
		</cfif>
	</cfloop>

</cffunction>

<cffunction name="property_list" access="public" returntype="string" output="no" hint="I return a list of properties for the bean.">
	<cfreturn StructKeyList(Variables.Props)>
</cffunction>

<cfscript>
function getMissingMethodHandler() {
	var method = Trim(Arguments.missingMethodName);
	var property = ReReplaceNoCase(method,"^(([gs]et)|(has)|(remove))","");
	var action = "";

	if ( Len(property) ) {
		action = Reverse(Replace(Reverse(method), Reverse(property), ""));
	}

	return {action=action,property=property};
}
function onMissingMethod() {
	var sMethod = getMissingMethodHandler(ArgumentCollection=Arguments);
	var fMethod = 0;
	var args = Arguments.missingMethodArguments;

	if ( NOT StructKeyExists(This,sMethod.action) ) {
		throw("No such method.");
	}

	fMethod = This[sMethod.action];

	if ( sMethod.action IS "set" ) {
		sMethod["result"] = fMethod(sMethod.property,args[1]);
	} else {
		sMethod["result"] = fMethod(sMethod.property);
	}

	if ( StructKeyExists(sMethod,"result") ) {
		return sMethod["result"];
	}
}
</cfscript>

</cfcomponent>
