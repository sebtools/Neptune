<cfcomponent>

<cffunction name="init" access="public" returntype="any" output="false">
	<cfargument name="id" type="string" default="rate">
	<cfargument name="timeSpan" type="string" default="#CreateTimeSpan(0,0,0,3)#">

	<cfset Variables.instance = Arguments>
	<cfset Variables.running = StructNew()>

	<cfset Variables.timeSpan_ms = Int(Arguments.timeSpan * 100000 / 1.1574074074) * 1000>

	<cfset Variables.Cacher = CreateObject("component","MrECache").init("rlcache",CreateTimeSpan(0,0,10,0))>
	<cfset Variables.MrECache = CreateObject("component","MrECache").init("limit_#Arguments.id#",Arguments.timeSpan)>

	<cfreturn This>
</cffunction>

<cffunction name="called" access="public" returntype="void" output="false">
	<cfargument name="id" type="string" required="true">
	<cfargument name="result" type="any" required="false">

	<cfif NOT StructKeyExists(Arguments,"result")>
		<cfset Arguments.result = now()>
	</cfif>

	<cfset Variables.MrECache.put(Arguments.id,Arguments.result)>
	<cfset StructDelete(Variables.running,Arguments.id)>

</cffunction>

<cffunction name="calling" access="public" returntype="void" output="false">
	<cfargument name="id" type="string" required="true">

	<cfset Variables.running[Arguments.id] = now()>

</cffunction>

<cffunction name="isAvailable" access="public" returntype="boolean" output="false">
	<cfargument name="id" type="string" required="true">

	<cfreturn Variables.MrECache.exists(Arguments.id)>
</cffunction>

<cffunction name="isCallable" access="public" returntype="boolean" output="false">
	<cfargument name="id" type="string" required="true">

	<cfreturn NOT ( isAvailable(Arguments.id) OR isCalling(Arguments.id) )>
</cffunction>

<cffunction name="isCalling" access="public" returntype="boolean" output="false">
	<cfargument name="id" type="string" required="true">
	<cfargument name="check" type="boolean" default="false" hint="Check if it was run recently.">

	<!--- If it was last called over 10 minutes ago, something is hinky and/or no need to worry about the rate limiting for this part. --->
	<cfif
			Arguments.check
		AND	StructKeyExists(Variables.running,Arguments.id)
		AND	DateAdd("n",10,Variables.running[Arguments.id]) LT now()
	>
		<cfset StructDelete(Variables.running,Arguments.id)>
	</cfif>

	<cfreturn StructKeyExists(Variables.running,Arguments.id)>
</cffunction>

<cffunction name="cached" access="public" returntype="any" output="false" hint="I call the given method if it hasn't been called within the rate limit time. I return a cached value if one is available.">
	<cfargument name="id" type="string" required="true">
	<cfargument name="Component" type="any" required="true">
	<cfargument name="MethodName" type="string" required="true">
	<cfargument name="Args" type="struct" required="false">
	<cfargument name="default" type="any" required="false">
	<cfargument name="timeSpan" type="string" required="false">
	<cfargument name="idleTime" type="string" required="false">
	<cfargument name="waitlimit" type="numeric" default="100" hint="Maximum number of milliseconds to wait.">
	<cfargument name="waitstep" type="numeric" default="20" hint="Milliseconds to wait between checks.">

	<cfset var sCacherArgs = {
		Component=This,
		MethodName="method",
		Args=Arguments
	}>
	<cfif StructKeyExists(Arguments,"timeSpan")>
		<cfset sCacherArgs["timeSpan"] = Arguments.timeSpan>
	</cfif>
	<cfif StructKeyExists(Arguments,"idleTime")>
		<cfset sCacherArgs["idleTime"] = Arguments.idleTime>
	</cfif>

	<cfreturn Variables.Cacher.meth(ArgumentCollection=sCacherArgs)>
</cffunction>

<cffunction name="method" access="public" returntype="any" output="false" hint="I call the given method if it hasn't been called within the rate limit time.">
	<cfargument name="id" type="string" required="true">
	<cfargument name="Component" type="any" required="true">
	<cfargument name="MethodName" type="string" required="true">
	<cfargument name="Args" type="struct" required="false">
	<cfargument name="default" type="any" required="false">
	<cfargument name="waitlimit" type="numeric" default="100" hint="Maximum number of milliseconds to wait.">
	<cfargument name="waitstep" type="numeric" default="20" hint="Milliseconds to wait between checks.">

	<cfset var local = StructNew()>
	<cfset var waited = 0>

	<!--- No reason to wait longer than the limit of the rate limiter. --->
	<cfset Arguments.waitlimit = Min(Arguments.waitlimit,Variables.timeSpan_ms)>

	<!--- If method is currently running, wait up to the wait limit for it to finish. --->
	<cfif isCalling(Arguments.id,true)>
		<cfscript>
		while ( isCalling(Arguments.id) AND waited LT waitlimit ) {
			sleep(Arguments.waitstep);
			waited += Arguments.waitstep;
		}
		</cfscript>
	</cfif>
	
	<cfif NOT isCallable(Arguments.id)>
		<!--- If MrECache has rate limiter value then we are within the rate limit and must return the default value. --->
		<cfif NOT StructKeyExists(Arguments,"default")>
			<cfif isAvailable(Arguments.id)>
				<cfset Arguments.default = Variables.MrECache.get(Arguments.id)>
			<cfelse>
				<cfset called(Arguments.id)>
				<cfthrow message="Unable to retrieve data from #Arguments.MethodName# (waited #waited# milliseconds)." type="RateLimiter">
			</cfif>
		</cfif>
		<cfset called(Arguments.id,Arguments.default)>
		<cfreturn Arguments.default>
	<cfelse>
		<!--- If not within the rate limit then call the method and return the value. --->
		<cfset calling(Arguments.id)>
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
		<cfelse>
			<cfset called(Arguments.id)>
		</cfif>
	</cfif>

</cffunction>

</cfcomponent>