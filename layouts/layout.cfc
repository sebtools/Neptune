<cfcomponent extends="_framework.layout">

<cffunction name="switchLayout" access="public" returntype="layout" output="no">
	<cfargument name="layout" type="string" required="yes">
	
	<cfset var result = CreateObject("component",layout)>
	
	<cfset result.init(variables.CGI,variables.Factory)>
	
	<cfset result.setMe(variables.me)>
	<cfset this = result>
	
	<cfreturn result>
</cffunction>

<cffunction name="setMe" access="package" returntype="void" output="no">
	<cfargument name="me" type="struct" required="yes">
	
	<cfset variables.me = me>

</cffunction>

</cfcomponent>