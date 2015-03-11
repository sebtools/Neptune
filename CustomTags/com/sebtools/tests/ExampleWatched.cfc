<cfcomponent displayname="Example" output="no">

<cffunction name="init" access="public" returntype="any" output="no">
	
	<cfset This.Args = Arguments>
	<cfset This.DateLoaded = now()>
	
	<cfset sleep(20)>
	
	<cfreturn This>
</cffunction>

<cffunction name="setRequestFoo" access="public" returntype="void" output="no">
	<cfargument name="FooVal" type="string" default="bar">
	
	<cfset request.foo = Arguments.FooVal>
	
</cffunction>

</cfcomponent>