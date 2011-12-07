<cfcomponent output="false">

<cffunction name="init" access="public" returntype="any" output="no">
	
	<cfset var comp = 0>
	<cfset var cfVersion = "">
	<cfset var cfVersionMajor = "">
	
	<cflock scope="Server" timeout="30">
		<cfset cfVersion = Server.ColdFusion.ProductVersion>
	</cflock>
	
	<cfset cfVersionMajor = ListFirst(cfVersion)>
	
	<!--- <cfif cfVersionMajor GTE 8>
		<cfset comp = CreateObject("component","com.sebtools.cfimage").init()>
	<cfelse>
		<cfset comp = CreateObject("component","com.sebtools.ImageCFC").init()>
	</cfif> --->
	<cfset comp = CreateObject("component","com.sebtools.ImageCFC").init()>
	
	<cfreturn comp>
</cffunction>

</cfcomponent>