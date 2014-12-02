<cfcomponent displayname="Example" output="no">

<cffunction name="init" access="public" returntype="any" output="no">
	
	<cfset This.Args = Arguments>
	<cfset This.DateLoaded = now()>
	
	<cfreturn This>
</cffunction>

</cfcomponent>