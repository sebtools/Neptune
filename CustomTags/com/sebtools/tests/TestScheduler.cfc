<cfcomponent displayname="Scheduler" extends="mxunit.framework.TestCase" output="no">

<cffunction name="beforeTests" access="public" returntype="void" output="no">
	
	<cfset Variables.DataMgr = CreateObject("component","DataMgr").init("TestSQL")>
	<cfset loadScheduler()>
	
</cffunction>

<cffunction name="runMe" access="public" returntype="void" output="no">
	
	<!--- I don't need to do anything. --->
	
</cffunction>

<cffunction name="shouldRunOneTimeTask" access="public" returntype="void" output="no"
	hint="I one-time task should always run the next time that the scheduler runs tasks."
	mxunit:transaction="rollback"
>
	
	<!--- I don't need to do anything. --->
	<cfset var TaskID = loadTask()>
	
	<cfset runTasksWithCheck(TaskID,"The one-time task failed to run.")>
	
</cffunction>

<cffunction name="assertTaskRan" access="public" returntype="void" output="no" hint="I assert that given date is recent, as defined by the arguments provided.">
	<cfargument name="TaskID" type="numeric" required="true">
	<cfargument name="message" type="string" default="The task did not run.">
	
	<cfset assertTrue(hasTaskRun(Arguments.TaskID),arguments.message)>
	
</cffunction>

<cffunction name="dropScheduler" access="private" returntype="void" output="no">
	
	<cfset StructDelete(Variables,"Scheduler")>
	
</cffunction>

<cffunction name="hasTaskRun" access="private" returntype="numeric" output="no">
	<cfargument name="TaskID" type="numeric" required="true">
	
	<cfset var qCheckRun = 0>
	
	<cfquery name="qCheckRun" datasource="#Variables.DataMgr.getDatasource()#">
	SELECT		count(*) NumRuns
	FROM		schActions
	WHERE		TaskID = <cfqueryparam value="#Val(Arguments.TaskID)#" cfsqltype="CF_SQL_INTEGER">
		AND		DateRun >= #CreateODBCDateTime(DateAdd("s",-20,now()))#
	</cfquery>
	
	<cfreturn qCheckRun.NumRuns>
</cffunction>

<cffunction name="loadScheduler" access="private" returntype="void" output="no">
	
	<cfset Variables.Scheduler = CreateObject("component","com.sebtools.Scheduler").init(DataMgr=Variables.DataMgr)>
	
</cffunction>

<cffunction name="loadTask" access="private" returntype="string" output="no">
	<cfargument name="interval" type="string" default="once">
	<cfargument name="Name" type="string" required="false">
	<cfargument name="MethodName" type="string" default="runMe">
	
	<cfif NOT ( StructKeyExists(Arguments,"Name") AND Len(Arguments.Name) )>
		<cfset Arguments.Name = CreateUUID()>
	</cfif>
	
	<cfset Arguments.ComponentPath = "admin.meta.tests.TestScheduler">
	<cfset Arguments.Component = This>
	
	<cfif NOT StructKeyExists(Variables,"Scheduler")>
		<cfset loadScheduler()>
	</cfif>
	
	<cfreturn Variables.Scheduler.setTask(ArgumentCollection=Arguments)>
</cffunction>

<cffunction name="reloadScheduler" access="private" returntype="void" output="no">
	
	<cfset dropScheduler()>
	<cfset loadScheduler()>
	
</cffunction>

<cffunction name="runTasks" access="private" returntype="void" output="no">
	
	<cfset Variables.Scheduler.runTasks()>
	
</cffunction>

<cffunction name="runTasksWithCheck" access="private" returntype="void" output="no">
	<cfargument name="TaskID" type="numeric" required="true">
	<cfargument name="message" type="string" required="false">
	
	<cfset runTasks()>
	<cfset assertTaskRan(ArgumentCollection=Arguments)>
	
</cffunction>

</cfcomponent>