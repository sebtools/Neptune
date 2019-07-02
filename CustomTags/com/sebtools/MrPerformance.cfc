<cfcomponent display="Mr. Performance" hint="I track the performance of cacheable operations.">

<cffunction name="init" access="public" returntype="any" output="false">
	<cfargument name="DataMgr" type="any" required="true">
	<cfargument name="Observer" type="any" required="true">
	<cfargument name="autostart" type="boolean" default="true">

	<cfset Variables.instance = Arguments>
	<cfset Variables.instance.Timer = CreateObject("component","utils.Timer").init(Arguments.DataMgr,Arguments.Observer)>

	<cfset Variables.isTracking = false>

	<cfif Arguments.autostart>
		<cfset startTracking()>
	</cfif>

	<cfreturn This>
</cffunction>

<cffunction name="isTracking" access="public" returntype="boolean" output="no" hint="I indicate if Mr Performance is currently tracking.">
	<cfreturn Variables.isTracking>
</cffunction>

<cffunction name="logRunCacheable" access="public" returntype="any" output="no" hint="I log information about running of cacheable code.">
	<cfargument name="id" type="string" required="true">
	<cfargument name="RunTime" type="numeric" required="true">

	<cfset var sArgs = {time_ms=Arguments.RunTime,name=Arguments.id}>
	<cfset var sComp = 0>

	<cfif StructKeyExists(Arguments,"Fun")>
		<cfset sArgs["Label"] = Arguments.Fun.Metadata.Name>
	</cfif>

	<cfif StructKeyExists(Arguments,"Component") AND StructKeyExists(Arguments,"MethodName")>
		<cfset sComp = getMetaData(Arguments.Component)>
		<cfif StructKeyExists(sComp,"DisplayName")>
			<cfset sArgs["Label"] = sComp.DisplayName & ": " & Arguments.MethodName>
		<cfelse>
			<cfset sArgs["Label"] = sComp.Name & "." & Arguments.MethodName>
		</cfif>
	</cfif>

	<!---<cfset Variables.instance.Timer.hearMrECache(Arguments.id,Arguments.RunTime)>--->
	<cfset Variables.instance.Timer.logTime(Arguments.RunTime,Arguments.id,sArgs["Label"])>

</cffunction>

<cffunction name="logRunObservable" access="public" returntype="any" output="no" hint="I log information about running of cacheable code.">
	<cfargument name="RunTime" type="numeric" required="true">
	<cfargument name="ListenerName" type="string" required="true">

	<cfset var sArgs = {time_ms=Arguments.RunTime,name=Arguments.ListenerName}>
	<cfset var sComp = 0>

	<cfif StructKeyExists(Arguments,"Fun")>
		<cfset sArgs["Label"] = Arguments.Fun.Metadata.Name>
	</cfif>

	<cfif StructKeyExists(Arguments,"Component") AND StructKeyExists(Arguments,"MethodName")>
		<cfset sComp = getMetaData(Arguments.Component)>
		<cfif StructKeyExists(sComp,"DisplayName")>
			<cfset sArgs["Label"] = sComp.DisplayName & ": " & Arguments.MethodName>
		<cfelse>
			<cfset sArgs["Label"] = sComp.Name & "." & Arguments.MethodName>
		</cfif>
	</cfif>

	<cfif StructKeyExists(Arguments,"Args") AND StructCount(Arguments.Args)>
		<cfset sArgs.Data = Arguments.Args>
	</cfif>

	<!---<cfset Variables.instance.Timer.hearMrECache(Arguments.id,Arguments.RunTime)>--->
	<cfset Variables.instance.Timer.logTime(ArgumentCollection=sArgs)>

</cffunction>

<cffunction name="startTracking" access="public" returntype="void" output="no" hint="I register a listener with Observer to listen for services being loaded.">

	<cfset Variables.isTracking = true>
	<cfset Variables.instance.Observer.registerListener(
		Listener = This,
		ListenerName = "MrPerformance",
		ListenerMethod = "logRunCacheable",
		EventName = "MrECache:run"
	)>
	<cfset Variables.instance.Observer.registerListener(
		Listener = This,
		ListenerName = "MrPerformanceObserv",
		ListenerMethod = "logRunObservable",
		EventName = "Observer:announceEvent"
	)>


</cffunction>

<cffunction name="stopTracking" access="public" returntype="void" output="no" hint="I register a listener with Observer to listen for services being loaded.">

	<cfset Variables.isTracking = false>
	<cfset Variables.instance.Observer.unregisterListener(
		ListenerName = "MrPerformance",
		ListenerMethod = "logRunCacheable",
		EventName = "MrECache:run"
	)>
	<cfset Variables.instance.Observer.unregisterListener(
		ListenerName = "MrPerformanceObserv",
		ListenerMethod = "logRunObservable",
		EventName = "Observer:announceEvent"
	)>

</cffunction>

</cfcomponent>
