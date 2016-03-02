<cfcomponent displayname="Scheduler" extends="com.sebtools.RecordsTester" output="no">

<cffunction name="beforeTests" access="public" returntype="void" output="no">
	
	<cfset Variables.DataMgr = CreateObject("component","DataMgr").init("TestSQL")>
	<cfset loadScheduler()>
	
	<cfset Variables.ThisDotPath = StructFind(GetMetaData(This),"FullName")>
	<cfset Variables.ComponentsXML = '<site><components><component name="Example" path="#Variables.ThisDotPath#"></component></components></site>'>
	
</cffunction>

<cffunction name="runMe" access="public" returntype="void" output="no">
	
	<!--- I don't need to do anything. --->
	
</cffunction>

<cffunction name="testCondenseTaskName" access="public" returntype="void" output="no"
	hint="condenseTaskName() should return just the task name."
	testtype="unit"
>
	<cfset makePublic(Variables.Scheduler,"condenseTaskName")>
	
	<cfset assertEquals("23DCCC49-D5B7-A880-A820BD2FEF359D36",Variables.Scheduler.condenseTaskName("23DCCC49-D5B7-A880-A820BD2FEF359D36:202"),"condenseTaskName() failed to return only the task name.")>
	<cfset assertEquals("TestName:Rubarb",Variables.Scheduler.condenseTaskName("TestName:Rubarb:202"),"condenseTaskName() failed to return only the task name for a task with a colon in it.")>
	<cfset assertEquals("TestName:Rubarb",Variables.Scheduler.condenseTaskName("TestName:Rubarb"),"condenseTaskName() failed to return the whole task name for a task with a colon in it.")>
	
</cffunction>

<cffunction name="testIsExpandedForm" access="public" returntype="void" output="no"
	hint="isExpandedForm() should correctly identify expanded form task names."
	testtype="unit"
>
	<cfset makePublic(Variables.Scheduler,"isExpandedForm")>
	
	<cfset assertEquals(True,Variables.Scheduler.isExpandedForm("23DCCC49-D5B7-A880-A820BD2FEF359D36:202"),"isExpandedForm() failed to recognize a traditional expanded task name.")>
	<cfset assertEquals(False,Variables.Scheduler.isExpandedForm("23DCCC49-D5B7-A880-A820BD2FEF359D36"),"isExpandedForm() failed to recognize a traditional condensed task name.")>
	<cfset assertEquals(True,Variables.Scheduler.isExpandedForm("TestName:Rubarb:202"),"isExpandedForm() failed to recognize an expanded task name with an extra colon in it.")>
	<cfset assertEquals(False,Variables.Scheduler.isExpandedForm("TestName:Rubarb"),"isExpandedForm() mistakenly attributed as expanded a task name with a colon in it.")>
	
</cffunction>

<cffunction name="testSplitTaskName" access="public" returntype="void" output="no"
	hint="splitTaskName() should a structure with the TaskID and TaskName."
	testtype="unit"
>
	<cfset makePublic(Variables.Scheduler,"splitTaskName")>
	
	<cfset assertEquals(StructFromArgs(TaskName="23DCCC49-D5B7-A880-A820BD2FEF359D36",TaskID=202),Variables.Scheduler.splitTaskName("23DCCC49-D5B7-A880-A820BD2FEF359D36:202"),"splitTaskName() failed to return the task name and id.")>
	<cfset assertEquals(StructFromArgs(TaskName="TestName:Rubarb",TaskID=202),Variables.Scheduler.splitTaskName("TestName:Rubarb:202"),"splitTaskName() failed to return only the task name for a task with a colon in it.")>
	<cfset assertEquals(StructFromArgs(TaskName="TestName:Rubarb"),Variables.Scheduler.splitTaskName("TestName:Rubarb"),"splitTaskName() failed to return the whole task name for a task with a colon in it.")>
	
</cffunction>

<cffunction name="shouldRunBackToBackOneTimeTasks" access="public" returntype="void" output="no"
	hint="Identically named one-time tasks should succeed if created/run back to back."
	mxunit:transaction="rollback"
>
	<cfset var TaskName = CreateUUID()>
	<cfset var TaskArgs = {}>
	<cfset var TaskID1 = loadTask(Name=TaskName,args=TaskArgs)>
	<cfset var TaskID2 = 0>
	
	<cfset runTasksWithCheck(TaskID1,"The first one-time task failed to run.")>
	
	<cfset TaskArgs["Test"] = 1>
	<cfset TaskID2 = loadTask(Name=TaskName,args=TaskArgs)>
	
	<cfset runTasksWithCheck(TaskID2,"The second one-time task failed to run.")>
	
</cffunction>

<cffunction name="shouldRunSameNameOneTimeTasks" access="public" returntype="void" output="no"
	hint="Identically named one-time tasks should succeed if created back to back and then run."
	mxunit:transaction="rollback"
>
	<cfset var TaskName = CreateUUID()>
	<cfset var TaskArgs = {}>
	<cfset var TaskID1 = loadTask(Name=TaskName,args=TaskArgs)>
	<cfset var TaskID2 = 0>
	
	<cfset TaskArgs["Test"] = 1>
	<cfset TaskID2 = loadTask(Name=TaskName,args=TaskArgs)>
	
	<cfset runTasksWithCheck(TaskID1,"The first one-time task failed to run.")>
	<cfset runTasksWithCheck(TaskID2,"The second one-time task failed to run.")>
	
</cffunction>

<cffunction name="shouldRunMatchingOneTimeTasksWithSameJSON" access="public" returntype="void" output="no"
	hint="One-time tasks with matching name, comp method and jsonArgs should succeed if created and run back to back."
	mxunit:transaction="rollback"
>
	<cfset var TaskName = CreateUUID()>
	<cfset var sTaskArgs = {PKID=100,"resend"=false}>
	<cfset var TaskID1 = loadTask(Name=TaskName,args=sTaskArgs)>
	<cfset var TaskID2 = 0>
	<cfset var TaskID3 = 0>

	<cfset runTasks(true)>

	<cfset assertTrue(hasTaskRun(TaskID1),"The first one-time task failed to run.")>

	<cfset TaskID2 = loadTask(Name=TaskName,args=sTaskArgs)>

	<cfset runTasks(true)>

	<cfset assertTrue(hasTaskRun(TaskID2),"The second one-time task failed to run.")>

	<cfset TaskID3 = loadTask(Name=TaskName,args=sTaskArgs)>

	<cfset runTasks(true)>

	<cfset assertTrue(hasTaskRun(TaskID3),"The third one-time task failed to run.")>
	
</cffunction>

<cffunction name="shouldRunSameNameOneTimeTasksAfterReinitWithSFDef" access="public" returntype="void" output="no"
	hint="Identically named one-time tasks should succeed if created back to back and then run after Scheduler reinit with a defined Service Factory component."
	mxunit:transaction="rollback"
>
	<cfset var TaskName = CreateUUID()>
	<cfset var TaskArgs = {}>
	<cfset var TaskID1 = loadTask(Name=TaskName,args=TaskArgs)>
	<cfset var TaskID2 = 0>
	
	<cfset TaskArgs["Test"] = 1>
	<cfset TaskID2 = loadTask(Name=TaskName,args=TaskArgs)>
	
	<cfset dropScheduler()>
	<cfset loadScheduler(True,Variables.ComponentsXML)>
	
	<cfset runTasksWithCheck(TaskID1,"The first one-time task failed to run.")>
	<cfset runTasksWithCheck(TaskID2,"The second one-time task failed to run.")>
	
</cffunction>

<cffunction name="shouldRunSameNameOneTimeTasksAfterReinitWithSFNoDef" access="public" returntype="void" output="no"
	hint="Identically named one-time tasks should succeed if created back to back and then run after Scheduler reinit with Service Factory and undefined but loadable component."
	mxunit:transaction="rollback"
>
	<cfset var TaskName = CreateUUID()>
	<cfset var TaskArgs = {}>
	<cfset var TaskID1 = loadTask(Name=TaskName,args=TaskArgs)>
	<cfset var TaskID2 = 0>
	
	<cfset TaskArgs["Test"] = 1>
	<cfset TaskID2 = loadTask(Name=TaskName,args=TaskArgs)>
	
	<cfset dropScheduler()>
	<cfset loadScheduler(True)>
	
	<cfset runTasksWithCheck(TaskID1,"The first one-time task failed to run.")>
	<cfset runTasksWithCheck(TaskID2,"The second one-time task failed to run.")>
	
</cffunction>

<cffunction name="shouldRunSameNameOneTimeTasksAfterReinitWithoutSF" access="public" returntype="void" output="no"
	hint="Identically named one-time tasks should succeed if created back to back and then run after Scheduler reinit without setComponent or Service Factory."
	mxunit:transaction="rollback"
	mxunit:expectedException="Scheduler"
>
	<cfset var TaskName = CreateUUID()>
	<cfset var TaskArgs = {}>
	<cfset var TaskID1 = loadTask(Name=TaskName,args=TaskArgs)>
	<cfset var TaskID2 = 0>
	
	<cfset TaskArgs["Test"] = 1>
	<cfset TaskID2 = loadTask(Name=TaskName,args=TaskArgs)>
	
	<cfset dropScheduler()>
	<cfset loadScheduler()>
	
	<cfset runTasksWithCheck(TaskID1,"The first one-time task failed to run.")>
	<cfset runTasksWithCheck(TaskID2,"The second one-time task failed to run.")>
	
</cffunction>

<cffunction name="shouldRunSameNameOneTimeTasksAfterReinitAndSetComp" access="public" returntype="void" output="no"
	hint="Identically named one-time tasks should succeed if created back to back and then run after Scheduler reinit and setComponent."
	mxunit:transaction="rollback"
>
	<cfset var TaskName = CreateUUID()>
	<cfset var sTaskArgs = {}>
	<cfset var TaskID1 = loadTask(Name=TaskName,args=sTaskArgs)>
	<cfset var TaskID2 = 0>
	
	<cfset sTaskArgs["Test"] = 1>
	<cfset TaskID2 = loadTask(Name=TaskName,args=sTaskArgs)>

	<cfset dropScheduler()>
	<cfset loadScheduler()>
	
	<cfset Variables.Scheduler.setComponent(Component=This,ComponentPath=Variables.ThisDotPath)>
	
	<cfset runTasksWithCheck(TaskID1,"The first one-time task failed to run.")>
	<cfset runTasksWithCheck(TaskID2,"The second one-time task failed to run.")>
	
</cffunction>

<cffunction name="shouldRunSameNameRecurringTasks" access="public" returntype="void" output="no"
	hint="Identically named recurring tasks should succeed if created back to back and then run."
	mxunit:transaction="rollback"
>
	<cfset var TaskName = CreateUUID()>
	<cfset var TaskArgs = {}>
	<cfset var TaskID1 = loadTask(Name=TaskName,interval="hourly",args=TaskArgs)>
	<cfset var TaskID2 = 0>
	
	<cfset TaskArgs["Test"] = 1>
	<cfset TaskID2 = loadTask(Name=TaskName,interval="hourly",args=TaskArgs)>
	
	<cfset runTasksWithCheck(TaskID1,"The first recurring task failed to run.")>
	<cfset runTasksWithCheck(TaskID2,"The second recurring task failed to run.")>
	
</cffunction>

<cffunction name="shouldRunSameNameRecurringTasksAfterReinitWithSFDef" access="public" returntype="void" output="no"
	hint="Identically named recurring tasks should succeed if created back to back and then run after Scheduler reinit with a defined Service Factory component."
	mxunit:transaction="rollback"
>
	<cfset var TaskName = CreateUUID()>
	<cfset var TaskArgs = {}>
	<cfset var TaskID1 = loadTask(Name=TaskName,interval="hourly",args=TaskArgs)>
	<cfset var TaskID2 = 0>
	
	<cfset TaskArgs["Test"] = 1>
	<cfset TaskID2 = loadTask(Name=TaskName,interval="hourly",args=TaskArgs)>
	
	<cfset dropScheduler()>
	<cfset loadScheduler(True,Variables.ComponentsXML)>
	
	<cfset runTasksWithCheck(TaskID1,"The first recurring task failed to run.")>
	<cfset runTasksWithCheck(TaskID2,"The second recurring task failed to run.")>
	
</cffunction>

<cffunction name="shouldRunSameNameRecurringTasksAfterReinitWithSFNoDef" access="public" returntype="void" output="no"
	hint="Identically named recurring tasks should succeed if created back to back and then run after Scheduler reinit with Service Factory and undefined but loadable component."
	mxunit:transaction="rollback"
>
	<cfset var TaskName = CreateUUID()>
	<cfset var TaskArgs = {}>
	<cfset var TaskID1 = loadTask(Name=TaskName,interval="hourly",args=TaskArgs)>
	<cfset var TaskID2 = 0>
	
	<cfset TaskArgs["Test"] = 1>
	<cfset TaskID2 = loadTask(Name=TaskName,interval="hourly",args=TaskArgs)>
	
	<cfset dropScheduler()>
	<cfset loadScheduler(True)>
	
	<cfset runTasksWithCheck(TaskID1,"The first recurring task failed to run.")>
	<cfset runTasksWithCheck(TaskID2,"The second recurring task failed to run.")>
	
</cffunction>

<cffunction name="shouldRunSameNameRecurringTasksAfterReinitWithoutSF" access="public" returntype="void" output="no"
	hint="Identically named recurring tasks should succeed if created back to back and then run after Scheduler reinit without setComponent or Service Factory."
	mxunit:transaction="rollback"
	mxunit:expectedException="Scheduler"
>
	<cfset var TaskName = CreateUUID()>
	<cfset var TaskArgs = {}>
	<cfset var TaskID1 = loadTask(Name=TaskName,interval="hourly",args=TaskArgs)>
	<cfset var TaskID2 = 0>
	
	<cfset TaskArgs["Test"] = 1>
	<cfset TaskID2 = loadTask(Name=TaskName,interval="hourly",args=TaskArgs)>
	
	<cfset dropScheduler()>
	<cfset loadScheduler()>
	
	<cfset runTasksWithCheck(TaskID1,"The first recurring task failed to run.")>
	<cfset runTasksWithCheck(TaskID2,"The second recurring task failed to run.")>
	
</cffunction>

<cffunction name="shouldRunSameNameRecurringTasksAfterReinitAndSetComp" access="public" returntype="void" output="no"
	hint="Identically named recurring tasks should run if created back to back and run after Scheduler reinit and setComponent."
	mxunit:transaction="rollback"
>
	<cfset var TaskName = CreateUUID()>
	<cfset var TaskArgs = {}>
	<cfset var TaskID1 = loadTask(Name=TaskName,interval="hourly",args=TaskArgs)>
	<cfset var TaskID2 = 0>
	
	<cfset TaskArgs["Test"] = 1>
	<cfset TaskID2 = loadTask(Name=TaskName,interval="hourly",args=TaskArgs)>
	
	<cfset dropScheduler()>
	<cfset loadScheduler()>
	
	<cfset Variables.Scheduler.setComponent(Component=This,ComponentPath=Variables.ThisDotPath)>
	
	<cfset runTasksWithCheck(TaskID1,"The first recurring task failed to run.")>
	<cfset runTasksWithCheck(TaskID2,"The second recurring task failed to run.")>
	
</cffunction>

<cffunction name="shouldRunOneTimeTask" access="public" returntype="void" output="no"
	hint="A one-time task should always run the next time that the scheduler runs tasks."
	mxunit:transaction="rollback"
>
	
	<!--- I don't need to do anything. --->
	<cfset var TaskID = loadTask()>
	
	<cfset runTasksWithCheck(TaskID,"The one-time task failed to run.")>
	
</cffunction>

<cffunction name="shouldRunOneTimeTaskAfterReinit" access="public" returntype="void" output="no"
	hint="A one-time task should always run the next time that the scheduler runs tasks after it is reinitialized."
	mxunit:transaction="rollback"
>
	
	<!--- I don't need to do anything. --->
	<cfset var TaskID = loadTask()>
	
	<cfset dropScheduler()>
	<cfset loadScheduler()>
	
	<cfset Variables.Scheduler.setComponent(Component=This,ComponentPath=Variables.ThisDotPath)>
	
	<cfset runTasksWithCheck(TaskID,"The one-time task failed to run.")>
	
</cffunction>

<cffunction name="shouldPreverseArgs" access="public" returntype="void" output="no"
	hint="Simple arguments should be preserved across Scheduler restarts."
	mxunit:transaction="rollback"
>
	
	<!--- I don't need to do anything. --->
	<cfset var sArgs = StructFromArgs(a="Apple",b="Banana")>
	<cfset var TaskID = loadTask(args=sArgs)>
	
	<cfset dropScheduler()>
	<cfset loadScheduler()>
	
	<cfset stub()>
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
	<cfargument name="WithServiceFactory" type="boolean" default="false">
	<cfargument name="Components" type="string" required="false">
	
	<cfset var oServiceFactory = 0>
	
	<cfif Arguments.WithServiceFactory>
		<cfset oServiceFactory = CreateObject("component","_framework.ServiceFactory").init()>
		<cfif StructKeyExists(Arguments,"Components")>
			<cfset oServiceFactory.loadXml(Arguments.Components)>
		</cfif>
		<cfset Variables.Scheduler = CreateObject("component","com.sebtools.Scheduler").init(DataMgr=Variables.DataMgr,ServiceFactory=oServiceFactory)>
	<cfelse>
		<cfset Variables.Scheduler = CreateObject("component","com.sebtools.Scheduler").init(DataMgr=Variables.DataMgr)>
	</cfif>
	
</cffunction>

<cffunction name="loadTask" access="private" returntype="string" output="no">
	<cfargument name="interval" type="string" default="once">
	<cfargument name="Name" type="string" required="false">
	<cfargument name="MethodName" type="string" default="runMe">
	
	<cfif NOT ( StructKeyExists(Arguments,"Name") AND Len(Arguments.Name) )>
		<cfset Arguments.Name = CreateUUID()>
	</cfif>
	
	<cfset Arguments.ComponentPath = Variables.ThisDotPath>
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
	<cfargument name="force" type="boolean" default="false">
	
	<cfset Variables.Scheduler.runTasks(Arguments.force)>
	
</cffunction>

<cffunction name="runTasksWithCheck" access="private" returntype="void" output="no">
	<cfargument name="TaskID" type="numeric" required="true">
	<cfargument name="message" type="string" required="false">
	
	<cfset runTasks()>
	<cfset assertTaskRan(ArgumentCollection=Arguments)>
	
</cffunction>

</cfcomponent>