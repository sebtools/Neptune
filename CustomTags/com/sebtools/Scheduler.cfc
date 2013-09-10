<!--- 1.4 Build 10 --->
<!--- Last Updated: 2011-04-11 --->
<!--- Created by Steve Bryant 2007-01-31 --->
<cfcomponent displayname="Scheduler">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="DataMgr" type="any" required="yes">
	
	<cfset variables.DataMgr = arguments.DataMgr>
	
	<cfset variables.datasource = variables.DataMgr.getDatasource()>
	<cfset variables.DataMgr.loadXml(getDbXml(),true,true)>
	
	<cfset variables.tasks = StructNew()>
	<cfset variables.sComponents = StructNew()>
	<cfset variables.sRunningTasks = StructNew()>
	
	<cfreturn This>
</cffunction>

<cffunction name="createCFTask" access="public" returntype="void" output="no">
	<cfargument name="URL" type="string" required="yes">
	<cfargument name="Name" type="string" required="yes">
	<cfargument name="interval" type="string" default="1800">
	
	<cfschedule action="UPDATE" task="#arguments.Name#"  operation="HTTPRequest" url="#arguments.URL#" startdate="#now()#" starttime="12:00 AM" interval="#arguments.interval#">
	
</cffunction>

<cffunction name="getActionRecords" access="public" returntype="query" output="no">
	
	<cfreturn variables.DataMgr.getRecords("schActions",arguments)>
</cffunction>

<cffunction name="getTaskRecords" access="public" returntype="query" output="no">
	
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
	
	<cfset var qTasks = getTaskRecords(interval="once")>
	
	<cfloop query="qTasks">
		<cfif
				NOT StructKeyExists(variables.tasks,Name)
			AND	StructKeyExists(variables.sComponents,ComponentPath)
			AND	dateCreated GTE DateAdd("d",-1,now())
		>
			<cfset variables.tasks[Name] = StructNew()>
			<cfset variables.tasks[Name]["ComponentPath"] = ComponentPath>
			<cfset variables.tasks[Name]["Component"] = variables.sComponents[ComponentPath]>
			<cfset variables.tasks[Name]["MethodName"] = MethodName>
			<cfset variables.tasks[Name]["interval"] = "once">
			<cfset variables.tasks[Name]["Hours"] = Hours>
		</cfif>
	</cfloop>
	
</cffunction>

<cffunction name="removeTask" access="public" returntype="void" output="no">
	<cfargument name="Name" type="string" required="yes">
	
	<cfset var qTask = getTaskNameRecord(arguments.Name)>
	<cfset var data = StructNew()>
	
	<cfset data["TaskID"] = qTask.TaskID>
	
	<cfset variables.DataMgr.deleteRecord("schTasks",data)>
	<cfset StructDelete(variables.tasks, arguments.Name)>
	
</cffunction>

<cffunction name="setTask" access="public" returntype="void" output="no">
	<cfargument name="Name" type="string" required="yes">
	<cfargument name="ComponentPath" type="string" required="yes" hint="The path to your component (example com.sebtools.NoticeMgr).">
	<cfargument name="Component" type="any" required="yes">
	<cfargument name="MethodName" type="string" required="yes">
	<cfargument name="interval" type="string" required="yes">
	<cfargument name="args" type="struct" required="no">
	<cfargument name="hours" type="string" required="no" hint="The hours in which the task can be run.">
	<cfargument name="weekdays" type="string" required="no" hint="The week days on which the task can be run.">
	
	<cfset var qTask = getTaskNameRecord(arguments.Name)>
	
	<cfif Len(Arguments.ComponentPath) GT 50>
		<cfset Arguments.ComponentPath = Right(Arguments.ComponentPath,50)>
	</cfif>
	
	<!--- Make sure task of this name doesn't exist for another component. --->
	<cfif StructKeyExists(variables.tasks,arguments.Name)>
		<cfif
				( variables.tasks[arguments.Name].ComponentPath NEQ arguments.ComponentPath )
			OR	( variables.tasks[arguments.Name].MethodName NEQ arguments.MethodName )
		>
			<cfthrow message="A task using this name already exists for another component method." type="Scheduler" errorcode="NameExists">
		</cfif>
	</cfif>
	
	<cfif isObject(arguments.Component) AND NOT StructKeyExists(variables.sComponents,arguments.ComponentPath)>
		<cfset variables.sComponents[arguments.ComponentPath] = arguments.Component>
	</cfif>
	
	<cfif StructKeyExists(arguments,"hours")>
		<cfset arguments.hours = expandHoursList(arguments.hours)>
	</cfif>
	
	<cfset variables.tasks[arguments.Name] = arguments>
	
	<cfif qTask.RecordCount>
		<cfset arguments.TaskID = qTask.TaskID>
	</cfif>
	
	<cfset arguments.TaskID = variables.DataMgr.saveRecord("schTasks",arguments)>
	
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
	<cfset var sTaskUpdate = StructNew()>
	<cfset var sAction = StructNew()>
	<cfset var key = "">
	
	<cfset var TimeMarkBegin = 0>
	<cfset var TimeMarkEnd = 0>
	
	<cfif StructKeyExists(variables.sRunningTasks,arguments.name)>
		<cfreturn false>
	</cfif>
	
	<cfset variables.sRunningTasks[arguments.Name] = now()>
	
	<cfset sTaskUpdate["TaskID"] = qTask.TaskID>
	<cfset sTaskUpdate["rerun"] = 0>
	<cfset variables.DataMgr.updateRecord("schTasks",sTaskUpdate)>

	<cfset sAction["TaskID"] = qTask.TaskID>
	<cfset sAction["ActionID"] = variables.DataMgr.insertRecord("schActions",sAction,"insert")>
	
	<cfloop collection="#variables.tasks[arguments.Name]#" item="key">
		<cfset sTask[key] = variables.tasks[arguments.Name][key]>
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
		<cfset StructDelete(variables.sRunningTasks,arguments.Name)>
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
	
	<cfset StructDelete(variables.sRunningTasks,arguments.Name)>
	
</cffunction>

<cffunction name="runTasks" access="public" returntype="void" output="no">
	
	<cfset var aTasks = getCurrentTasks(now())>
	<cfset var ii = 0>
	
	<cfloop index="ii" from="1" to="#ArrayLen(aTasks)#" step="1">
		<cfif StructKeyExists(aTasks[ii],"name") AND NOT StructKeyExists(variables.sRunningTasks,aTasks[ii].name)>
			<cfif aTasks[ii].interval EQ "once">
				<cfset runTask(aTasks[ii].name,true)>
			<cfelse>
				<cfset runTask(aTasks[ii].name)>
			</cfif>
		</cfif>
	</cfloop>
	
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
		<cfif isRunnableTask(task,arguments.runtime)>
			<cfset ArrayAppend(aResults,variables.tasks[task])>
		</cfif>
	</cfloop>
	
	<cfreturn aResults>
</cffunction>

<cffunction name="getIntervalFromDate" access="public" returntype="date" output="false" hint="I return the date since which a task would have been run to be within the current interval defined for it.">
	<cfargument name="Name" type="string" required="yes">
	<cfargument name="runtime" type="date" default="#now()#">
	
	<cfset var sIntervals = getIntervals()>
	<cfset var adjustedtime = DateAdd("n",10,arguments.runtime)><!--- Tasks run every 15 minutes at most and we need a margin of error for date checks. --->
	<cfset var result = now()>
	<cfset var task = Arguments.Name>
	
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
	<cfset var task = Arguments.Name>
	<cfset var qTask = getTaskNameRecord(task)>

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
	<cfset var task = Arguments.Name>
	<cfset var qTask = getTaskNameRecord(task)>
	
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
	
	<cfset sComponents[arguments.ComponentPath] = arguments.Component>
	
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
	
	<cfreturn variables.DataMgr.getRecords("schTasks",arguments)>
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