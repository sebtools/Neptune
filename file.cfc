<!--- Serves uploaded files: http://www.bryantwebconsulting.com/docs/neptune/file-uploads.cfm --->
<cfcomponent extends="_config.PageController" output="no">

<cfset loadExternalVars("Config",".Framework")>

<cffunction name="loadData" access="public" returntype="struct" output="no">
	
	<cfreturn loadData_File()>
</cffunction>

</cfcomponent>