<cfcomponent output="false">

<cffunction name="init" access="public" returntype="any" output="no">
	
	<cfreturn This>
</cffunction>

<cffunction name="read" access="public" returntype="query" output="no">
	<cfargument name="src" type="string" required="yes">
	
	<cfset var qResults = 0>
	
	<cfspreadsheet action="read" src="#Arguments.src#" query="qResults" headerrow="1" rows="2-65536">
	
	<cfreturn qResults>
</cffunction>

<cffunction name="write" access="public" returntype="void" output="no">
	<cfargument name="FileName" type="string" required="yes">
	<cfargument name="query" type="query" required="yes">
	
	<cfspreadsheet action="write" FileName="#Arguments.FileName#" query="Arguments.query">
	
</cffunction>

</cfcomponent>