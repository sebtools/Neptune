<cfcomponent displayname="Timer Object">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="DataMgr" type="any" required="true">
	<cfargument name="label" type="any" required="true">
	<cfargument name="name" type="string" default="">
	<cfargument name="Template" type="string" default="#CGI.SCRIPT_NAME#">
	<cfargument name="data" type="struct" required="false">

	<!--- Make sure we have a structure for the timer objects. This allows us to cache it and avoid calling the loadXml() on every request. Caching is done by datasource in case more than one datasource is in use. --->
	<cfif NOT StructKeyExists(Application,"cf_timers")>
		<cfset Application.cf_timers = StructNew()>
	</cfif>
	
	<!--- Make sure we have a datasource attribute. --->
	<cfset Arguments.datasource = Arguments.DataMgr.getDatasource()>

	<!--- Make sure we have a timers component.. --->
	<cfif NOT StructKeyExists(Application.cf_timers,Arguments.datasource)>
		<cfset Application.cf_timers[Arguments.datasource] = CreateObject("component","timer").init(Arguments.DataMgr)>
	</cfif>
	
	<!--- Just a handy reference for the timers component needed in this tag. --->
	<cfset Variables.oTimer = Application.cf_timers[Arguments.datasource]>
	
	<!--- To identify when the page was loaded --->
	<cfif NOT StructKeyExists(request,"cf_timer_page_loaded")>
		<cfset request["cf_timer_page_loaded"] = now()>
	</cfif>

	<cfset Variables.sArgs = Arguments>

	<cfset start()>
	
	<cfreturn This>
</cffunction>

<cffunction name="start" access="public" returntype="any" output="no">

	<cfset Variables.StartTime = getTickCount()>

	<cfreturn This>
</cffunction>

<cffunction name="end" access="public" returntype="any" output="no">

	<cfset Variables.EndTime = getTickCount()>

	<cfset Variables.sArgs["Time_ms"] = Variables.EndTime - Variables.StartTime>
	<cfset Variables.sArgs["DatePageLoaded"] = request["cf_timer_page_loaded"]>

	<cfset Variables.oTimer.logTime(ArgumentCollection=Variables.sArgs)>

	<cfreturn This>
</cffunction>

</cfcomponent>