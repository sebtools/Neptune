<cfcomponent displayname="Example" output="no">

<cffunction name="init" access="public" returntype="any" output="no">
	
	<cfset var key = 1>
	
	<cfset sleep(2)>
	
	<cfif StructKeyExists(request,"Loaded#key#")>
		<cfset key = key + 1>
	</cfif>
	
	<cfset request["Loaded#key#"]["BeginTime"] = getTickCount()>
	
	<cfset This.Args = Arguments>
	<cfset This.DateLoaded = now()>
	
	<cfset sleep(60)>
	
	<cfset request["Loaded#key#"]["EndTime"] = getTickCount()>
	
	<cfreturn This>
</cffunction>

</cfcomponent>