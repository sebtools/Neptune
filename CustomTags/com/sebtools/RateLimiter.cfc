<cfcomponent>

<cffunction name="init" access="public" returntype="any" output="false">
	<cfargument name="id" type="string" default="rate">
	<cfargument name="timeSpan" type="string" default="#CreateTimeSpan(0,0,0,3)#">

	<cfset Variables.instance = Arguments>

	<cfset Variables.MrECache = CreateObject("component","MrECache").init("limit_#Arguments.id#",Arguments.timeSpan)>

	<cfreturn This>
</cffunction>

<cffunction name="called" access="public" returntype="void" output="false">
	<cfargument name="id" type="string" required="true">
	<cfargument name="result" type="string" required="false">

	<cfif NOT StructKeyExists(Arguments,"result")>
		<cfset Arguments.result = now()>
	</cfif>

	<cfset Variables.MrECache.put(Arguments.id,Arguments.result)>

</cffunction>

<cffunction name="isCallable" access="public" returntype="boolean" output="false">
	<cfargument name="id" type="string" required="true">

	<cfreturn NOT Variables.MrECache.exists(Arguments.id)>
</cffunction>

<cffunction name="method" access="public" returntype="any" output="false" hint="I call the given method if it hasn't been called within the rate limit time.">
	<cfargument name="id" type="string" required="true">
	<cfargument name="default" type="any" required="true">
	<cfargument name="Component" type="any" required="true">
	<cfargument name="MethodName" type="string" required="true">
	<cfargument name="Args" type="struct" required="false">

	<cfset var local = StructNew()>

	<cfif NOT isCallable(Arguments.id)>
		<!--- If MrECache has rate limiter value then we are within the rate limit and must return the default value. --->
		<cfreturn Arguments.default>
	<cfelse>
		<!--- If not within the rate limit then call the method and return the value. --->
		<cfset called(Arguments.id)>
		<cfif NOT StructKeyExists(Arguments,"Args")>
			<cfset Arguments["Args"] = {}>
		</cfif>
		<cfinvoke
			returnvariable="local.result"
			component="#Arguments.Component#"
			method="#Arguments.MethodName#"
			argumentcollection="#Arguments.Args#"
		>
		<cfif StructKeyExists(local,"result")>
			<cfset called(Arguments.id,local.result)>
			<cfreturn local.result>
		</cfif>
	</cfif>

</cffunction>

</cfcomponent>