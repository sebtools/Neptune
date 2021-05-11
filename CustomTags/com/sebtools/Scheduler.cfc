<!--- 1.5 Build 11 --->
<!--- Last Updated: 2014-12-04 --->
<!--- Created by Steve Bryant 2007-01-31 --->
<cfcomponent displayname="Scheduler">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="DataMgr" type="any" required="yes">
	<cfargument name="ServiceFactory" type="any" required="no">

	<cfset variables.DataMgr = arguments.DataMgr>
	<cfif StructKeyExists(arguments,"ServiceFactory")>
		<cfset variables.ServiceFactory = arguments.ServiceFactory>
	</cfif>

	<cfset variables.datasource = variables.DataMgr.getDatasource()>
	<cfset variables.DataMgr.loadXml(getDbXml(),true,true)>

	<cfset variables.tasks = StructNew()>
	<cfset variables.sComponents = StructNew()>
	<cfset variables.sRunningTasks = StructNew()>

	<!--- Initialize Date of run from last action if there is one. --->
	<cfset Variables.DateLastRunTasks = getDateOfLastAction()>
	<cfif NOT isDate(Variables.DateLastRunTasks)>
		<cfset StructDelete(Variables,"DateLastRunTasks")>
	</cfif>

	<cfreturn This>
</cffunction>

<cffunction name="createCFTask" access="public" returntype="void" output="no">
	<cfargument name="URL" type="string" required="yes">
	<cfargument name="Name" type="string" required="yes">
	<cfargument name="interval" type="string" default="1800">

	<cfschedule action="UPDATE" task="#condenseTaskName(arguments.Name)#"  operation="HTTPRequest" url="#arguments.URL#" startdate="#now()#" starttime="12:00 AM" interval="#arguments.interval#">

</cffunction>

<cffunction name="DateAddInterval" access="public" returntype="string" output="no">
	<cfargument name="interval" type="string" required="true">
	<cfargument name="date" type="string" default="#now()#">

	<cfset var result = arguments.date>
	<cfset var timespans = "millisecond,second,minute,hour,day,week,month,quarter,year">
	<cfset var dateparts = "l,s,n,h,d,ww,m,q,yyyy">
	<cfset var num = 1>
	<cfset var timespan = "">
	<cfset var datepart = "">
	<cfset var DayOf = "">
	<cfset var OrdinationString = "">
	<cfset var ordinals = "first,second,third,fourth,fifth,sixth,seventh,eighth,ninth,tenth,eleventh,twelfth">
	<cfset var ordinal = "">
	<cfset var numbers = "one,two,three,four,five,six,seven,eight,nine,ten,eleven,twelve">
	<cfset var number = "">
	<cfset var weekdays = "Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday">
	<cfset var weekday = "">
	<cfset var thisint = "">
	<cfset var sNums = 0>
	<cfset var isSubtraction = Left(Trim(arguments.interval),1) EQ "-">
	<cfset var sub = "">

	<cfif NOT isDate(Arguments.date)>
		<cfreturn "">
	</cfif>

	<cfif isSubtraction>
		<cfset arguments.interval = Trim(ReplaceNoCase(arguments.interval,"-","","ALL"))>
		<cfset sub = "-">
	</cfif>

	<cfset arguments.interval = REReplaceNoCase(arguments.interval,"\s+(and|plus)\b",",","ALL")>

	<cfif ListLen(arguments.interval) GT 1>
		<cfloop list="#arguments.interval#" index="thisint">
			<cfset result = DateAddInterval("#sub##thisint#",result)>
		</cfloop>
	<cfelse>
		<cfset arguments.interval = ReplaceNoCase(arguments.interval,"annually","yearly","ALL")>
		<cfset arguments.interval = ReReplaceNoCase(arguments.interval,"\b(\d+)(nd|rd|th)\b","\1","ALL")>
		<cfset sNums = ReFindNoCase("\b\d+\b",arguments.interval,1,true)>
		<!--- Figure out number --->
		<cfif ArrayLen(sNums.pos) AND sNums.pos[1] GT 0>
			<cfset num = Mid(arguments.interval,sNums.pos[1],sNums.len[1])>
		</cfif>
		<cfif ListFindNoCase(arguments.interval,"every"," ")>
			<cfset arguments.interval = ListDeleteAt(arguments.interval,ListFindNoCase(arguments.interval,"every"," ")," ")>
		</cfif>

		<!--- Day of the month/year --->
		<cfset OrdinationString = REReplaceNoCase(arguments.interval,"\bsecond$","")><!--- Making sure "every [other,ordinal] second" isn't considered as an ordinal interval --->
		<cfloop list="#ordinals#" index="ordinal">
			<cfif ReFindNoCase("#ordinal#\s+of\s+",OrdinationString)>
				<cfset DayOf = ListFindNoCase(ordinals,ordinal)>
				<cfset OrdinationString = ReReplaceNoCase(OrdinationString,"#ordinal#\s+of\s+","")>
			</cfif>
		</cfloop>

		<!--- Regular ordination --->
		<cfloop list="#ordinals#" index="ordinal">
			<cfif ListFindNoCase(OrdinationString,ordinal," ")>
				<cfset num = num * ListFindNoCase(ordinals,ordinal)>
			</cfif>
		</cfloop>
		<cfloop list="#numbers#" index="number">
			<cfif ListFindNoCase(arguments.interval,number," ")>
				<cfset num = num * ListFindNoCase(numbers,number)>
			</cfif>
		</cfloop>
		<cfif ListFindNoCase(arguments.interval,"other"," ")>
			<cfset arguments.interval = ListDeleteAt(arguments.interval,ListFindNoCase(arguments.interval,"other"," ")," ")>
			<cfset num = num * 2>
		</cfif>
		<!--- Check if day of week is specified --->
		<cfloop list="#weekdays#" index="weekday">
			<!--- Make sure user could pluralize the weekday and this would still work. --->
			<cfset arguments.interval = ReplaceNoCase(arguments.interval,"#weekday#s",weekday,"ALL")>
			<cfif ListFindNoCase(arguments.interval,weekday," ")>
				<!--- Make sure the date given is on the day of week specified (subtract days as needed) --->
				<cfset arguments.date = DateAdd("d",- Abs( 7 - ListFindNoCase(weekdays,weekday) + DayOfWeek(arguments.date) ) MOD 7,arguments.date)>
				<cfset arguments.interval = ListDeleteAt(arguments.interval,ListFindNoCase(arguments.interval,weekday," ")," ")>
				<!--- Make sure we are adding weeks --->
				<cfset arguments.interval = ListAppend(arguments.interval,"week"," ")>
			</cfif>
		</cfloop>

		<!--- Figure out timespan --->
		<cfset timespan = ListLast(arguments.interval," ")>

		<!--- Ditch ending "s" or "ly" --->
		<cfif Right(timespan,1) EQ "s">
			<cfset timespan = Left(timespan,Len(timespan)-1)>
		</cfif>
		<cfif Right(timespan,2) EQ "ly">
			<cfset timespan = Left(timespan,Len(timespan)-2)>
		</cfif>
		<cfif timespan EQ "dai">
			<cfset timespan = "day">
		</cfif>

		<cfif ListFindNoCase(timespans,timespan)>
			<cfset datepart = ListGetAt(dateparts,ListFindNoCase(timespans,timespan))>
		<cfelse>
			<cfthrow message="#timespan# is not a valid interval measurement.">
		</cfif>

		<cfset result = DateAdd(datepart,"#sub##num#",arguments.date)>

		<cfif Val(DayOf)>
			<cfset result = CreateDateTime(Year(result),Month(result),DayOf,Hour(result),Minute(result),Second(result))>
		</cfif>
	</cfif>

	<cfreturn result>
</cffunction>

<cffunction name="failsafe" access="public" returntype="void" output="no">

	<!--- So long as runTasks is called every three hours, then all is well. --->
	<cfif NOT ( StructKeyExists(Variables,"DateLastRunTasks") AND DateDiff("h",Variables.DateLastRunTasks,now()) LTE 3 )>
		<!--- Otherwise, raise the alerm and call the method to keep things running. --->
		<cf_scaledAlert><cfoutput>
		Scheduler (#CGI.SERVER_NAME#) runTasks hasn't run since <cfif isDate(Variables.DateLastRunTasks)>#DateFormat(Variables.DateLastRunTasks,'mmm d yyy')# at #TimeFormat(Variables.DateLastRunTasks,'hh:mm:ss tt')#<cfelse>it was loaded</cfif>.
		Running now...
		</cfoutput></cf_scaledAlert>
		<cfset runTasks()>
	</cfif>

</cffunction>

<cffunction name="getActionRecords" access="public" returntype="query" output="no">

	<cfif StructKeyExists(Arguments,"TaskName")>
		<cfset Arguments.TaskName = condenseTaskName(arguments.TaskName)>
	</cfif>

	<cfreturn variables.DataMgr.getRecords("schActions",arguments)>
</cffunction>

<cffunction name="getDateOfLastAction" access="public" returntype="string" output="no">

	<cfset var qLastAction = 0>

	<cfquery name="qLastAction" datasource="#variables.datasource#">
	SELECT	Max(DateRun) AS DateLastRun
	FROM	schActions
	</cfquery>

	<cfreturn qLastAction.DateLastRun>

</cffunction>

<cffunction name="getTaskRecords" access="public" returntype="query" output="no">

	<cfif StructKeyExists(Arguments,"TaskName")>
		<cfset Arguments.TaskName = condenseTaskName(arguments.TaskName)>
	</cfif>

	<cfreturn variables.DataMgr.getRecords("schTasks",arguments)>
</cffunction>

<cffunction name="getTasks" access="public" returntype="struct" output="no">

	<cfset loadAbandonedTasks()>

	<cfreturn variables.tasks>
</cffunction>

<cffunction name="getTasksTruncated" access="public" returntype="struct" output="no">

	<cfset var sResult = StructNew()>
	<cfset var key = "">
	<cfset var key2 = "">

	<cfset loadAbandonedTasks()>

	<cfloop collection="#variables.tasks#" item="key">
		<cfset sResult[key] = StructNew()>
		<cfloop collection="#variables.tasks[key]#" item="key2">
			<cfif isSimpleValue(variables.tasks[key][key2])>
				<cfset sResult[key][key2] = variables.tasks[key][key2]>
			</cfif>
		</cfloop>
	</cfloop>

	<cfreturn sResult>
</cffunction>

<cffunction name="loadAbandonedTasks" access="public" returntype="void" output="false">

	<!--- <cfset var qTasks = getTaskRecords(interval="once")> --->
	<cfset var qTasks = getTaskRecords()>
	<cfset var sSavedArgs = 0>
	<cfset var aErrorMessages = ArrayNew(1)>
	<cfset var ExpandedTaskName = "">

	<cfloop query="qTasks">
		<cfset ExpandedTaskName = expandTaskName(Name=Name,jsonArgs=jsonArgs,TaskID=TaskID)>
		<cfif
				NOT StructKeyExists(variables.tasks,ExpandedTaskName)
			AND	dateCreated GTE DateAdd("d",-1,now())
		>
			<cfif StructKeyExists(Variables,"ServiceFactory") AND NOT StructKeyExists(variables.sComponents,ComponentPath)>
				<cftry>
					<cfset setComponent(ComponentPath,Variables.ServiceFactory.getServiceByPath(ComponentPath))>
				<cfcatch>
				</cfcatch>
				</cftry>
			</cfif>
			<cfif NOT StructKeyExists(variables.sComponents,ComponentPath)>
				<cfset removeTask(Name)>
				<cfset ArrayAppend(aErrorMessages,"The task #Name# has been deleted because the component specified by this task's component path (#ComponentPath#) is not available to Scheduler.")>
			<cfelse>
				<cfset variables.tasks[ExpandedTaskName] = StructNew()>
				<cfset variables.tasks[ExpandedTaskName]["ComponentPath"] = ComponentPath>
				<cfset variables.tasks[ExpandedTaskName]["Component"] = variables.sComponents[ComponentPath]>
				<cfset variables.tasks[ExpandedTaskName]["MethodName"] = MethodName>
				<cfset variables.tasks[ExpandedTaskName]["interval"] = "once">
				<cfset variables.tasks[ExpandedTaskName]["Hours"] = Hours>
				<cfset variables.tasks[ExpandedTaskName]["jsonArgs"] = jsonArgs>
				<cfset variables.tasks[ExpandedTaskName]["name"] = ExpandedTaskName>

				<cfif jsonArgs CONTAINS "[[Complex Value Removed by Scheduler]]">
					<cfset removeTask(Name)>
					<cfset ArrayAppend(aErrorMessages,"Unable to retrieve complex arguments for #MethodName# method in the #Name# task. The task has been deleted.")>
				<cfelse>
					<!--- Load arguments from the json string in db and if not empty --->
					<cfset sSavedArgs = DeserializeJSON( jsonArgs )>
					<cfif StructCount( sSavedArgs ) GT 0>
						<cfset variables.tasks[ExpandedTaskName]["Args"] = sSavedArgs>
					</cfif>
				</cfif>
			</cfif>
		</cfif>
	</cfloop>

	<!--- Now we can throw any errors since successful tasks have now been reloaded into variables scope --->
	<cfif ArrayLen(aErrorMessages)>
		<cfif ArrayLen(aErrorMessages) EQ 1>
			<cfthrow message="#aErrorMessages[1]#" type="Scheduler">
		<cfelse>
			<cfthrow message="The following errors occurred when trying to load abandoned tasks." detail="#ArrayToList(aErrorMessages,';')#" type="Scheduler">
		</cfif>
	</cfif>

</cffunction>

<cffunction name="removeTask" access="public" returntype="void" output="no">
	<cfargument name="Name" type="string" required="yes">

	<cfset var qTask = getTaskNameRecord(Name=Arguments.Name,fieldlist="TaskID")>
	<cfset var data = StructNew()>

	<cfset data["TaskID"] = qTask.TaskID>

	<cfset StructDelete(variables.tasks, expandTaskName(arguments.Name,qTask.jsonargs,qTask.TaskID))>
	<cfset variables.DataMgr.deleteRecord("schTasks",data)>

</cffunction>

<cffunction name="serializeArgsJSON" access="private" returntype="string" output="no">
	<cfargument name="args" type="any" required="yes">

	<cfset var serializedJSON = "">
	<cfset var argCount = 1>
	<cfset var quotedKey = "">
	<cfset var quotedValue = "">
	<cfset var keyValuePair = "">
	<cfset var key = "">

	<cfloop collection="#arguments.args#" item="key">
		<cfset quotedKey = ListQualify( key ,'"',",","CHAR")>
		<cfif IsSimpleValue( args[ key ] )>
			<cfset quotedValue = ListQualify( args[ key ] ,'"',",","CHAR")>
		<cfelse>
			<cfset quotedValue = '"[[Complex Value Removed by Scheduler]]"'>
		</cfif>
		<cfset keyValuePair = quotedKey & ":" & quotedValue>
		<cfif ( argCount NEQ 1 )>
			<cfset serializedJSON &= "," & keyValuePair>
		<cfelse>
			<cfset serializedJSON &= keyValuePair>
		</cfif>
		<cfset argCount = argCount + 1>
	</cfloop>

	<cfreturn "{" & serializedJSON & "}">
</cffunction>

<cffunction name="setComponent" access="public" returntype="void" output="no">
	<cfargument name="ComponentPath" type="string" required="yes" hint="The path to your component (example com.sebtools.NoticeMgr).">
	<cfargument name="Component" type="any" required="yes">

	<cfset variables.sComponents[arguments.ComponentPath] = arguments.Component>

</cffunction>

<cffunction name="setTask" access="public" returntype="numeric" output="no">
	<cfargument name="Name" type="string" required="yes">
	<cfargument name="ComponentPath" type="string" required="yes" hint="The path to your component (example com.sebtools.NoticeMgr).">
	<cfargument name="Component" type="any" required="yes">
	<cfargument name="MethodName" type="string" required="yes">
	<cfargument name="interval" type="string" required="yes">
	<cfargument name="args" type="struct" required="no">
	<cfargument name="hours" type="string" required="no" hint="The hours in which the task can be run.">
	<cfargument name="weekdays" type="string" required="no" hint="The week days on which the task can be run.">

	<cfset var qTask = 0>
	<cfset var ExpandedTaskName = "">

	<cfif Len(Arguments.ComponentPath) GT 50>
		<cfset Arguments.ComponentPath = Right(Arguments.ComponentPath,50)>
	</cfif>

	<cfif StructKeyExists(arguments,"hours")>
		<cfset arguments.hours = expandHoursList(arguments.hours)>
	</cfif>

	<cfif StructKeyExists( arguments, "args" )>
		<cfset arguments.jsonArgs = serializeArgsJSON( arguments.args ) />
	<cfelse>
		<cfset arguments.jsonArgs = "{}"/> <!--- compliant empty json string --->
	</cfif>

	<cfset qTask = getTaskNameRecord(ArgumentCollection=arguments)>
	<cfif qTask.RecordCount>
		<cfset arguments.TaskID = qTask.TaskID>
	<cfelse>
		<cfset arguments.TaskID = variables.DataMgr.saveRecord("schTasks",arguments)>
	</cfif>

	<cfset ExpandedTaskName = expandTaskName(arguments.Name,arguments.jsonArgs,arguments.TaskID)>

	<!--- Make sure task of this name doesn't exist for another component. --->
	<cfif StructKeyExists(variables.tasks,ExpandedTaskName)>
		<cfif
				( variables.tasks[ExpandedTaskName].ComponentPath NEQ arguments.ComponentPath )
			OR	( variables.tasks[ExpandedTaskName].MethodName NEQ arguments.MethodName )
		>
			<cfthrow message="A task using this name already exists for another component method." type="Scheduler" errorcode="NameExists">
		</cfif>
	</cfif>

	<!---
	Set the component even if we have it to ensure that we are always using the newest version of a component.
	The component could have gotten loaded while loading missing tasks, using an old copy.
	--->
	<cfif isObject(arguments.Component)>
		<cfset setComponent(arguments.ComponentPath,arguments.Component)>
	</cfif>

	<cfset variables.tasks[ExpandedTaskName] = arguments>

	<cfreturn arguments.TaskID>
</cffunction>

<cffunction name="rerun" access="public" returntype="any" output="no">
	<cfargument name="Name" type="string" required="yes">

	<cfset var qTask = getTaskNameRecord(arguments.Name)>
	<cfset var sTaskUpdate = StructNew()>

	<cfset sTaskUpdate["TaskID"] = qTask.TaskID>
	<cfset sTaskUpdate["rerun"] = 1>
	<cfset variables.DataMgr.updateRecord("schTasks",sTaskUpdate)>

</cffunction>

<cffunction name="runTask" access="public" returntype="any" output="no">
	<cfargument name="Name" type="string" required="yes">
	<cfargument name="remove" type="boolean" default="false">

	<cfset var sTask = StructNew()>
	<cfset var qTask = getTaskNameRecord(arguments.Name)>
	<cfset var ExpandedTaskName = expandTaskName(arguments.Name)>
	<cfset var sTaskUpdate = StructNew()>
	<cfset var sAction = StructNew()>
	<cfset var key = "">

	<cfset var TimeMarkBegin = 0>
	<cfset var TimeMarkEnd = 0>

	<cfif qTask.RecordCount>
		<cfif StructKeyExists(variables.sRunningTasks,ExpandedTaskName)>
			<cfreturn false>
		</cfif>

		<cfset variables.sRunningTasks[ExpandedTaskName] = now()>

		<cfset sTaskUpdate["TaskID"] = qTask.TaskID>
		<cfset sTaskUpdate["rerun"] = 0>
		<cfset variables.DataMgr.updateRecord("schTasks",sTaskUpdate)>

		<cfset sAction["TaskID"] = qTask.TaskID>
		<cfset sAction["ActionID"] = variables.DataMgr.insertRecord("schActions",sAction,"insert")>

		<cfloop collection="#variables.tasks[ExpandedTaskName]#" item="key">
			<cfset sTask[key] = variables.tasks[ExpandedTaskName][key]>
		</cfloop>

		<cfif arguments.remove>
			<cfset removeTask(arguments.Name)>
		</cfif>

		<cfset TimeMarkBegin = getTickCount()>
		<cftry>
			<cfinvoke returnvariable="sAction.ReturnVar" component="#sTask.Component#" method="#sTask.MethodName#">
				<cfif StructKeyExists(sTask,"args")>
					<cfinvokeargument name="argumentcollection" value="#sTask.args#">
				</cfif>
			</cfinvoke>
			<cfset TimeMarkEnd = getTickCount()>
			<cfset sAction.Success = true>
		<cfcatch>
			<cfset StructDelete(variables.sRunningTasks,ExpandedTaskName)>
			<cfset sAction.Success = false>
			<cfset TimeMarkEnd = getTickCount()>
			<cfset sAction.Seconds = GetSecondsDiff(TimeMarkBegin,TimeMarkEnd)>
			<cfset sAction.ErrorMessage = CFCATCH.Message>
			<cfset sAction.ErrorDetail = CFCATCH.Detail>
			<cfset sAction.DateRunEnd = now()>
			<cfset sAction = variables.DataMgr.truncate("schActions",sAction)>
			<cfset variables.DataMgr.updateRecord("schActions",sAction)>
			<cfrethrow>
		</cfcatch>
		</cftry>

		<cfset sAction.Seconds = GetSecondsDiff(TimeMarkBegin,TimeMarkEnd)>

		<cfset sAction.DateRunEnd = now()>
		<cfset sAction = variables.DataMgr.truncate("schActions",sAction)>
		<cfset variables.DataMgr.updateRecord("schActions",sAction)>

		<cfset StructDelete(variables.sRunningTasks,ExpandedTaskName)>
	</cfif>

</cffunction>

<cffunction name="runTasks" access="public" returntype="void" output="no">
	<cfargument name="force" type="boolean" default="false">

	<cfset var aTasks = 0>
	<cfset var ii = 0>

	<!--- Don't do this more than once every 3 minutes --->
	<cfif Arguments.force OR NOT ( StructKeyExists(Variables,"DateLastRunTasks") AND DateDiff("n",Variables.DateLastRunTasks,now()) LTE 3 )>

		<cfset Variables.DateLastRunTasks = now()>

		<cfset aTasks = getCurrentTasks(now())>

		<cfloop index="ii" from="1" to="#ArrayLen(aTasks)#" step="1">
			<cfif StructKeyExists(aTasks[ii],"name") AND NOT StructKeyExists(variables.sRunningTasks,aTasks[ii].name)>
				<cfif aTasks[ii].interval EQ "once">
					<cfset runTask(ExpandTaskName(aTasks[ii].name,aTasks[ii].jsonArgs),true)>
				<cfelse>
					<cfset runTask(ExpandTaskName(aTasks[ii].name,aTasks[ii].jsonArgs))>
				</cfif>
			</cfif>
		</cfloop>

	</cfif>

</cffunction>

<cffunction name="getComponentDefs" access="public" returntype="struct" output="false">

	<cfreturn variables.sComponents>
</cffunction>

<cffunction name="getCurrentTasks" access="public" returntype="array" output="false">
	<cfargument name="runtime" type="date" default="#now()#">

	<cfset var aResults = ArrayNew(1)>
	<cfset var task = "">

	<cfset loadAbandonedTasks()>

	<!--- Look at each task --->
	<cfloop collection="#variables.tasks#" item="task">
		<cfif isRunnableTask(ExpandTaskName(task,variables.tasks[task].jsonargs),arguments.runtime)>
			<cfset ArrayAppend(aResults,variables.tasks[task])>
		</cfif>
	</cfloop>

	<cfreturn aResults>
</cffunction>

<cffunction name="getIncompleteTasks" access="public" returntype="struct" output="false">

	<cfset var sResult = {}>

	<cfset StructAppend(sResult,Variables.Tasks)>

	<cfset StructAppend(sResult,Variables.sRunningTasks)>

	<cfreturn sResult>
</cffunction>

<cffunction name="getIntervalFromDate" access="public" returntype="date" output="false" hint="I return the date since which a task would have been run to be within the current interval defined for it.">
	<cfargument name="Name" type="string" required="yes">
	<cfargument name="runtime" type="date" default="#now()#">

	<cfset var sIntervals = getIntervals()>
	<cfset var adjustedtime = DateAdd("n",10,arguments.runtime)><!--- Tasks run every 15 minutes at most and we need a margin of error for date checks. --->
	<cfset var result = now()>
	<cfset var task = expandTaskName(Arguments.Name)>

	<cfscript>
	// If the interval is numeric, check by the number of seconds
	if ( isNumeric(variables.tasks[task].interval) AND variables.tasks[task].interval GT 0 ) {
		adjustedtime = DateAdd("s",Int(variables.tasks[task].interval/10),arguments.runtime);
		result = DateAdd("s", -Int(variables.tasks[task].interval), adjustedtime);
	// If a key exists for the interval, use that
	} else if ( StructKeyExists(sIntervals,variables.tasks[task].interval) ) {
		// If the key value is numeric, check by the number of seconds
		if ( sIntervals[variables.tasks[task].interval] GT 0 ) {
			adjustedtime = DateAdd("s",Int(sIntervals[variables.tasks[task].interval]/10),arguments.runtime);
			result = DateAdd("s", -Int(sIntervals[variables.tasks[task].interval]), adjustedtime);
		// If the key value is "daily", check by one day
		} else if ( variables.tasks[task].interval EQ "daily" ) {
			adjustedtime = DateAdd("n",55,arguments.runtime);
			result = DateAdd("d", -1, adjustedtime);
		// If the key value is "weekly", check by one week
		} else if ( variables.tasks[task].interval EQ "weekly" ) {
			adjustedtime = DateAdd("h",12,arguments.runtime);
			result = DateAdd("ww", -1, adjustedtime);
		// If the key value is "monthly", check by one month
		} else if ( variables.tasks[task].interval EQ "monthly" ) {
			adjustedtime = DateAdd("h",12,arguments.runtime);
			result = DateAdd("m", -1, adjustedtime);
		}
	} else {
		result = DateAdd("s", -3600, adjustedtime);
	}
	</cfscript>

	<cfreturn result>
</cffunction>

<cffunction name="hasTaskRunWithinInterval" access="public" returntype="boolean" output="false" hint="I check to see if the given task has already run within the period of the interval defined for it.">
	<cfargument name="Name" type="string" required="yes">
	<cfargument name="runtime" type="date" default="#now()#">

	<cfset var result = false>
	<cfset var qCheckRun = 0>
	<cfset var sIntervals = getIntervals()>
	<cfset var adjustedtime = DateAdd("n",10,arguments.runtime)><!--- Tasks run every 15 minutes at most and we need a margin of error for date checks. --->
	<cfset var task = expandTaskName(Arguments.Name)>
	<cfset var qTask = getTaskNameRecord(Arguments.Name)>

	<cfif Len(variables.datasource)>
		<!--- See if the task has already been run within its interval --->
		<cfquery name="qCheckRun" datasource="#variables.datasource#">
		SELECT	#variables.DataMgr.getMaxRowsPrefix(1)# ActionID
		FROM	schActions
		WHERE	TaskID = <cfqueryparam value="#Val(qTask.TaskID)#" cfsqltype="CF_SQL_INTEGER">
			AND	DateRun > #CreateODBCDateTime(getIntervalFromDate(task,Arguments.runtime))#--#variables.tasks[task].interval#
		ORDER BY ActionID DESC
		#variables.DataMgr.getMaxRowsSuffix(1)#
		</cfquery>

		<cfif qCheckRun.RecordCount>
			<cfset result = true>
		</cfif>
	</cfif>

	<cfreturn result>
</cffunction>

<cffunction name="isRunnableTask" access="public" returntype="boolean" output="false">
	<cfargument name="Name" type="string" required="yes">
	<cfargument name="runtime" type="date" default="#now()#">

	<cfset var result = false>
	<cfset var qTask = getTaskNameRecord(Name=Arguments.Name,fieldlist="rerun")>
	<cfset var task = expandTaskName(Arguments.Name)>

	<!--- If hours are specified, make sure current time is in that list of hours --->
	<cfif qTask.rerun IS true>
		<cfset result = true>
	<cfelseif
			1 EQ 1
		AND	(
					NOT ( StructKeyExists(variables.tasks[task],"hours") AND Len(variables.tasks[task].hours) )
				OR	ListFindNoCase(variables.tasks[task].hours,Hour(arguments.runtime))
			)
		AND	(
					NOT ( StructKeyExists(variables.tasks[task],"weekdays") AND Len(variables.tasks[task].weekdays) )
				OR	ListFindNoCase(variables.tasks[task].weekdays,DayofWeekAsString(DayOfWeek(arguments.runtime)))
			)
	>
		<!--- task is valid at given time - has it already been run? --->
		<cfif NOT hasTaskRunWithinInterval(Arguments.Name,Arguments.runtime)>
			<cfset result = true>
		</cfif>
	</cfif>

	<cfreturn result>
</cffunction>

<cffunction name="notifyComponent" access="public" returntype="void" output="false">
	<cfargument name="ComponentPath" type="string" required="yes" hint="The path to your component (example com.sebtools.NoticeMgr).">
	<cfargument name="Component" type="any" required="yes">

	<cfset variables.sComponents[arguments.ComponentPath] = arguments.Component>

</cffunction>

<cffunction name="condenseTaskName" access="private" returntype="string" output="no" hint="I return the TaskName in its condensed form, that is just the task name itself.">
	<cfargument name="Name" type="string" required="true">

	<!--- SEB: This is the same as ListFirst(Arguments.Name,":") except that it allows for TaskNames that contain ":". --->
	<cfreturn ReReplaceNoCase(Arguments.Name,":\d+$","")>
</cffunction>

<cffunction name="expandTaskName" access="private" returntype="string" output="no" hint="I return the TaskName in its expanded form - including the TaskID.">
	<cfargument name="Name" type="string" required="true">
	<cfargument name="jsonArgs" type="string" required="false">
	<cfargument name="TaskID" type="string" required="false">

	<cfset var result = Arguments.Name>
	<cfset var qTask = 0>
	<cfset var sRecord = 0>

	<!--- Only take action if the name doesn't already match the expanded form --->
	<cfif NOT isExpandedForm(Arguments.Name)>
		<cfif NOT StructKeyExists(Arguments,"TaskID")>
			<cfset sRecord = StructNew()>
			<cfset sRecord["Name"] = Arguments.Name>
			<cfset sRecord["fieldlist"] = "TaskID">
			<cfif StructKeyExists(Arguments,"jsonArgs")>
				<cfset sRecord["jsonArgs"] = Arguments.jsonArgs>
			</cfif>
			<cfset qTask = getTaskNameRecord(ArgumentCollection=sRecord)>
			<cfif qTask.RecordCount EQ 1>
				<cfset Arguments.TaskID = qTask.TaskID>
				<!--- <cfif NOT StructKeyExists(variables.tasks,"#Arguments.Name#:#qTask.TaskID#")>
					<cfset result = "#Arguments.Name#:#qTask.TaskID#">
				<cfelse>
					<cfthrow message="Unable to uniquely identify the task #Arguments.Name#." type="Scheduler" errorcode="NoUniqueTaskFound">
				</cfif> --->
			<cfelse>
				<cfthrow message="The task record for #Arguments.Name# was not found." type="Scheduler" errorcode="NoTaskFound">
			</cfif>
		</cfif>
		<cfset result = "#Arguments.Name#:#Arguments.TaskID#">
	</cfif>

	<cfreturn result>
</cffunction>

<cffunction name="splitTaskName" access="private" returntype="struct" output="no" hint="I return a structure of values from a TaskName.">
	<cfargument name="Name" type="string" required="true">

	<cfset var sResult = StructNew()>

	<cfif isExpandedForm(Arguments.Name)>
		<cfset sResult["Name"] = condenseTaskName(Arguments.Name)>
		<cfset sResult["TaskID"] = ListLast(Arguments.Name,":")>
	<cfelse>
		<cfset sResult["Name"] = Arguments.Name>
	</cfif>

	<cfreturn sResult>
</cffunction>

<cffunction name="isExpandedForm" access="private" returntype="boolean" output="no" hint="I determine if the given TaskName is in expanded form.">
	<cfargument name="Name" type="string" required="true">

	<cfset var result = false>

	<cfif ReFindNoCase(":\d+$",Arguments.Name)>
		<cfset result = true>
	</cfif>

	<cfreturn result>
</cffunction>

<cffunction name="getIntervals" access="private" returntype="struct" output="no">

	<cfset var sResult = StructNew()>

	<cfscript>
	sResult["once"] = 0;
	sResult["hourly"] = 3600;
	sResult["daily"] = 86400;
	sResult["daily"] = 0;
	sResult["weekly"] = 604800;
	sResult["monthly"] = 0;
	</cfscript>

	<cfreturn sResult>
</cffunction>

<cffunction name="GetSecondsDiff" access="private" returntype="numeric" output="no">
	<cfargument name="begin" type="numeric" required="yes">
	<cfargument name="end" type="numeric" required="yes">

	<cfset var result = 0>

	<cfif arguments.end GTE arguments.begin>
		<cfset result = Int( ( arguments.end - arguments.begin ) / 1000 )>
	</cfif>

	<cfreturn result>
</cffunction>

<cffunction name="getTaskNameRecord" access="private" returntype="query" output="no">
	<cfargument name="Name" type="string" required="yes">

	<cfreturn variables.DataMgr.getRecords("schTasks",splitTaskName(Arguments.Name))>
</cffunction>

<cffunction name="expandHoursList" access="public" returntype="string" output="false" hint="">
	<cfargument name="hours" type="string" required="yes">

	<cfset var hourset = 0>
	<cfset var hour = 0>
	<cfset var result = "">
	<cfset var hour_from = 0>
	<cfset var hour_to = 0>

	<cfif ListLen(arguments.hours,"-") GT 1>
		<cfloop list="#arguments.hours#" index="hourset">
			<cfif ListLen(hourset,"-") GT 1>
				<cfset hour_from  = Val(ListFirst(hourset,"-")) MOD 24>
				<cfset hour_to  = Val(ListLast(hourset,"-")) MOD 24>
				<cfif hour_from GT hour_to>
					<cfloop index="hour" from="#hour_from#" to="23" step="1">
						<cfset result = ListAppend(result,hour)>
					</cfloop>
					<cfloop index="hour" from="0" to="#hour_to#" step="1">
						<cfset result = ListAppend(result,hour)>
					</cfloop>
				<cfelse>
					<cfloop index="hour" from="#hour_from#" to="#hour_to#" step="1">
						<cfset result = ListAppend(result,hour)>
					</cfloop>
				</cfif>
			<cfelse>
				<cfset result = ListAppend(result,Val(hourset))>
			</cfif>
		</cfloop>
	<cfelse>
		<cfset result = arguments.hours>
	</cfif>

	<cfreturn result>
</cffunction>

<cffunction name="getDbXml" access="private" returntype="string" output="no" hint="I return the XML for the tables needed for Searcher to work.">

	<cfset var result = "">

	<cfsavecontent variable="result">
	<tables>
		<table name="schTasks">
			<field ColumnName="TaskID" CF_DataType="CF_SQL_INTEGER" PrimaryKey="true" Increment="true" />
			<field ColumnName="Name" CF_DataType="CF_SQL_VARCHAR" Length="50" />
			<field ColumnName="ComponentPath" CF_DataType="CF_SQL_VARCHAR" Length="50" />
			<field ColumnName="MethodName" CF_DataType="CF_SQL_VARCHAR" Length="50" />
			<field ColumnName="interval" CF_DataType="CF_SQL_VARCHAR" Length="100" />
			<field ColumnName="weekdays" CF_DataType="CF_SQL_VARCHAR" Length="60" />
			<field ColumnName="hours" CF_DataType="CF_SQL_VARCHAR" Length="60" />
			<field ColumnName="dateCreated" CF_DataType="CF_SQL_DATE" Special="CreationDate" />
			<field ColumnName="dateDeleted" CF_DataType="CF_SQL_DATE" Special="DeletionMark" />
			<field ColumnName="rerun" CF_DataType="CF_SQL_BIT" Default="0" />
			<field ColumnName="AvgSeconds">
				<relation
					type="avg"
					table="schActions"
					field="Seconds"
					join-field="TaskID"
				/>
			</field>
			<field ColumnName="jsonArgs" CF_DataType="CF_SQL_VARCHAR" Length="320" />
		</table>
		<table name="schActions">
			<field ColumnName="ActionID" CF_DataType="CF_SQL_BIGINT" PrimaryKey="true" Increment="true" />
			<field ColumnName="TaskID" CF_DataType="CF_SQL_INTEGER" />
			<field ColumnName="DateRun" CF_DataType="CF_SQL_DATE" Special="CreationDate" />
			<field ColumnName="DateRunStart" CF_DataType="CF_SQL_DATE" Special="CreationDate" />
			<field ColumnName="DateRunEnd" CF_DataType="CF_SQL_DATE" Special="Date" />
			<field ColumnName="ErrorMessage" CF_DataType="CF_SQL_VARCHAR" Length="250" />
			<field ColumnName="ErrorDetail" CF_DataType="CF_SQL_VARCHAR" Length="250" />
			<field ColumnName="Success" CF_DataType="CF_SQL_BIT" />
			<field ColumnName="Seconds" CF_DataType="CF_SQL_BIGINT" />
			<field ColumnName="ReturnVar" CF_DataType="CF_SQL_VARCHAR" Length="250" />
			<field ColumnName="TaskName">
				<relation
					type="label"
					table="schTasks"
					field="Name"
					join-field="TaskID"
				/>
			</field>
		</table>
	</tables>
	</cfsavecontent>

	<cfreturn result>
</cffunction>

</cfcomponent>
