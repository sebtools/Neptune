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

<cffunction name="AddToArray" access="public" returntype="any" output="no" hint="I add a value to a property array.">
	<cfargument name="property" type="string" required="yes">
	<cfargument name="value" type="any" required="yes">

	<cfset checkMutable(Arguments.property)>

	<cfset __AddToArray(ArgumentCollection=Arguments)>

	<cfreturn get(Arguments.property)>
</cffunction>

<cffunction name="AddToList" access="public" returntype="any" output="no" hint="I add a value to a property string.">
	<cfargument name="property" type="string" required="yes">
	<cfargument name="value" type="string" required="yes">
	<cfargument name="delimiter" type="string" default=",">

	<cfset checkMutable(Arguments.property)>

	<cfset __AddToList(ArgumentCollection=Arguments)>

	<cfreturn get(Arguments.property)>
</cffunction>

<cffunction name="AddToString" access="public" returntype="any" output="no" hint="I add a value to a property string.">
	<cfargument name="property" type="string" required="yes">
	<cfargument name="value" type="string" required="yes">

	<cfset checkMutable(Arguments.property)>

	<cfset __AddToString(ArgumentCollection=Arguments)>

	<cfreturn get(Arguments.property)>
</cffunction>

<cffunction name="AddToStruct" access="public" returntype="any" output="no" hint="I add a value to a property structure.">
	<cfargument name="property" type="string" required="yes">
	<cfargument name="key" type="string" required="yes">
	<cfargument name="value" type="any" required="yes">
	<cfargument name="overwrite" type="boolean" default="true">

	<cfset checkMutable(Arguments.property)>

	<cfset __AddToStruct(ArgumentCollection=Arguments)>

	<cfreturn get(Arguments.property)>
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

	<cfset checkMutable(Arguments.property)>

	<cfset __remove(ArgumentCollection=Arguments)>

</cffunction>

<cffunction name="set" access="public" returntype="any" output="no" hint="I set the value for the property.">
	<cfargument name="property" type="string" required="yes">
	<cfargument name="value" type="any" required="yes">

	<cfset checkMutable(Arguments.property)>

	<cfset __set(ArgumentCollection=Arguments)>

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

<cffunction name="checkMutable" access="private" returntype="void" output="no" hint="I throw an exception when calls are made to change values if the bean is not mutable.">
	<cfargument name="property" type="string" required="yes">

	<cfif NOT Variables.mutable>
		<cfthrow type="Beany" message="Unable to alter property. Object is not mutable." detail="Unable to alter #Arguments.property# property. Object is not mutable.">
	</cfif>

</cffunction>

<cffunction name="__AddToArray" access="private" returntype="void" output="no" hint="I add a value to a property array.">
	<cfargument name="property" type="string" required="yes">
	<cfargument name="value" type="any" required="yes">

	<!--- If the property doesn't already exist, add it as an empty array. --->
	<cfif NOT has(Arguments.property)>
		<cfset set(Arguments.property,[])>
	</cfif>

	<!--- Can only add to structs. --->
	<cfif NOT isArray(get(Arguments.property))>
		<cfthrow type="Beany" message="Property is not an array." detail="#Arguments.property# property is not an array.">
	</cfif>

	<!--- Append the Array. --->
	<cfset ArrayAppend(Variables.Props[Arguments.property],Arguments.value)>

</cffunction>

<cffunction name="__AddToList" access="private" returntype="void" output="no" hint="I add a value to a property string.">
	<cfargument name="property" type="string" required="yes">
	<cfargument name="value" type="string" required="yes">
	<cfargument name="delimiter" type="string" default=",">

	<!--- If the property doesn't already exist, add it as an empty string. --->
	<cfif NOT has(Arguments.property)>
		<cfset set(Arguments.property,"")>
	</cfif>

	<!--- Can only add to structs. --->
	<cfif NOT isSimpleValue(get(Arguments.property))>
		<cfthrow type="Beany" message="Property is not a string." detail="#Arguments.property# property is not a string.">
	</cfif>

	<!--- Append the List. --->
	<cfset Variables.Props[Arguments.property] = ListAppend(get(Arguments.property),Arguments.value,Arguments.delimiter)>

</cffunction>

<cffunction name="__AddToString" access="private" returntype="void" output="no" hint="I add a value to a property string.">
	<cfargument name="property" type="string" required="yes">
	<cfargument name="value" type="string" required="yes">

	<!--- If the property doesn't already exist, add it as an empty string. --->
	<cfif NOT has(Arguments.property)>
		<cfset __set(Arguments.property,"")>
	</cfif>

	<!--- Can only add to structs. --->
	<cfif NOT isSimpleValue(get(Arguments.property))>
		<cfthrow type="Beany" message="Property is not a string." detail="#Arguments.property# property is not a string.">
	</cfif>

	<!--- Append the String. --->
	<cfset Variables.Props[Arguments.property] &= Arguments.value>

</cffunction>

<cffunction name="__AddToStruct" access="private" returntype="void" output="no" hint="I add a value to a property structure.">
	<cfargument name="property" type="string" required="yes">
	<cfargument name="key" type="string" required="yes">
	<cfargument name="value" type="any" required="yes">
	<cfargument name="overwrite" type="boolean" default="true">

	<!--- If the property doesn't already exist, add it as an empty struct. --->
	<cfif NOT has(Arguments.property)>
		<cfset Variables.Props[Arguments.property] = {}>
	</cfif>

	<!--- Can only add to structs. --->
	<cfif NOT isStruct(get(Arguments.property))>
		<cfthrow type="Beany" message="Property is not a struct." detail="#Arguments.property# property is not a struct.">
	</cfif>

	<!--- Make sure we don't overwrite properties if we are told not to do so. --->
	<cfif Arguments.overwrite OR NOT StructKeyExists(Variables.Props[Arguments.property],key)>
		<cfset Variables.Props[Arguments.property][Arguments.key] = Arguments.value>
	</cfif>

</cffunction>

<cffunction name="__remove" access="private" returntype="void" output="no" hint="I remove the property from the bean.">
	<cfargument name="property" type="string" required="yes">

	<cfset StructDelete(Variables.Props,Arguments.property)>

</cffunction>

<cffunction name="__set" access="public" returntype="void" output="no" hint="I set the value for the property.">
	<cfargument name="property" type="string" required="yes">
	<cfargument name="value" type="any" required="yes">

	<cfset checkMutable(Arguments.property)>

	<cfset Variables.Props[Arguments.property] = Arguments.value>

</cffunction>

</cfcomponent>
