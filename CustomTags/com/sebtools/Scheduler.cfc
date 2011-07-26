<!--- 1.1.1 Build 9 --->
<!--- Last Updated: 2010-05-30 --->
<!--- Created by Steve Bryant 2007-01-31 --->
<cfcomponent displayname="Scheduler">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="DataMgr" type="any" required="yes">
	
	<cfset variables.DataMgr = arguments.DataMgr>
	
	<cfset variables.datasource = variables.DataMgr.getDatasource()>
	<cfset variables.DataMgr.loadXml(getDbXml(),true,true)>
	
	<cfset variables.tasks = StructNew()>
	
	<cfreturn this>
</cffunction>

<cffunction name="createCFTask" access="public" returntype="void" output="no">
	<cfargument name="URL" type="string" required="yes">
	<cfargument name="Name" type="string" required="yes">
	<cfargument name="interval" type="string" default="1800">
	
	<cfschedule action="UPDATE" task="#arguments.Name#"  operation="HTTPRequest" url="#arguments.URL#" startdate="#now()#" starttime="12:00 AM" interval="#arguments.interval#">
	
</cffunction>

<cffunction name="getActionRecords" access="public" returntype="query" output="no">
	
	<cfreturn variables.DataMgr.getRecords("schActions")>
</cffunction>

<cffunction name="getTaskRecords" access="public" returntype="query" output="no">
	
	<cfreturn variables.DataMgr.getRecords("schTasks",arguments)>
</cffunction>

<cffunction name="getTasks" access="public" returntype="struct" output="no">
	
	<cfreturn variables.tasks>
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
	
	<cfset var qTask = getTaskNameRecord(arguments.Name)>
	
	<!--- Make sure task of this name doesn't exist for another component. --->
	<cfif StructKeyExists(variables.tasks,arguments.Name)>
		<cfif
				( variables.tasks[arguments.Name].ComponentPath NEQ arguments.ComponentPath )
			OR	( variables.tasks[arguments.Name].MethodName NEQ arguments.MethodName )
		>
			<cfthrow message="A task using this name already exists for another component method." type="Scheduler" errorcode="NameExists">
		</cfif>
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

<cffunction name="runTask" access="public" returntype="void" output="no">
	<cfargument name="Name" type="string" required="yes">
	<cfargument name="remove" type="boolean" default="false">
	
	<cfset var sTask = StructNew()>
	<cfset var qTask = getTaskNameRecord(arguments.Name)>
	<cfset var sAction = StructNew()>
	<cfset var key = "">
	
	<cfset var TimeMarkBegin = 0>
	<cfset var TimeMarkEnd = 0>
	
	<cfloop collection="#variables.tasks[arguments.Name]#" item="key">
		<cfset sTask[key] = variables.tasks[arguments.Name][key]>
	</cfloop>
	
	<cfset sAction["TaskID"] = qTask.TaskID>
	
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
		<cfset sAction.Success = false>
		<cfset TimeMarkEnd = getTickCount()>
		<cfset sAction.Seconds = GetSecondsDiff(TimeMarkBegin,TimeMarkEnd)>
		<cfset sAction.ErrorMessage = CFCATCH.Message>
		<cfset sAction.ErrorDetail = CFCATCH.Detail>
		<cfset sAction = variables.DataMgr.truncate("schActions",sAction)>
		<cfset variables.DataMgr.insertRecord("schActions",sAction,"insert")>
		<cfrethrow>
	</cfcatch>
	</cftry>
	
	<cfset sAction.Seconds = GetSecondsDiff(TimeMarkBegin,TimeMarkEnd)>
	
	<cfset sAction = variables.DataMgr.truncate("schActions",sAction)>
	<cfset variables.DataMgr.insertRecord("schActions",sAction,"insert")>
	
</cffunction>

<cffunction name="runTasks" access="public" returntype="void" output="no">
	
	<cfset var aTasks = getCurrentTasks(now())>
	<cfset var ii = 0>
	
	<cfloop index="ii" from="1" to="#ArrayLen(aTasks)#" step="1">
		<cfif aTasks[ii].interval EQ "once">
			<cfset runTask(aTasks[ii].name,true)>
		<cfelse>
			<cfset runTask(aTasks[ii].name)>
		</cfif>
	</cfloop>
	
</cffunction>

<cffunction name="getCurrentTasks" access="public" returntype="array" output="false">
	<cfargument name="runtime" type="date" default="#now()#">
	
	<cfset var aResults = ArrayNew(1)>
	<cfset var task = "">
	<cfset var qTask = 0>
	<cfset var qCheckRun = 0>
	<cfset var sIntervals = getIntervals()>
	<cfset var adjustedtime = DateAdd("n",10,arguments.runtime)><!--- Tasks run every 15 minutes at most and we need a margin of error for date checks. --->
	
	<!--- Look at each task --->
	<cfloop collection="#variables.tasks#" item="task">
		<cfset qTask = getTaskNameRecord(task)>
		<!--- If hours are specified, make sure current time is in that list of hours --->
		<cfif
				1 EQ 1
			AND	(
						NOT ( StructKeyExists(variables.tasks[task],"hours") AND Len(variables.tasks[task].hours) )
					OR	ListFindNoCase(variables.tasks[task].hours,Hour(arguments.runtime))
				)
			AND	(
						NOT ( StructKeyExists(variables.tasks[task],"weekdays") AND Len(variables.tasks[task].weekdays) )
					OR	ListFindNoCase(variables.tasks[task].weekdays,DayofWeekAsString(DayOfWeek(arguments.runtime))) )
		>
			<!--- See if the task has already been run within its interval --->
			<cfquery name="qCheckRun" datasource="#variables.datasource#">
			SELECT	#variables.DataMgr.getMaxRowsPrefix(1)# ActionID
			FROM	schActions
			WHERE	TaskID = <cfqueryparam value="#Val(qTask.TaskID)#" cfsqltype="CF_SQL_INTEGER">
			<!--- If the interval is numeric, check by the number of seconds --->
			<cfif isNumeric(variables.tasks[task].interval) AND variables.tasks[task].interval GT 0>
				<cfset adjustedtime = DateAdd("s",Int(variables.tasks[task].interval/10),arguments.runtime)>
				AND	DateRun > #CreateODBCDateTime(DateAdd("s", -Int(variables.tasks[task].interval), adjustedtime))#--numeric
			<!--- If a key exists for the interval, use that --->
			<cfelseif StructKeyExists(sIntervals,variables.tasks[task].interval)>
				<!--- If the key value is numeric, check by the number of seconds --->
				<cfif sIntervals[variables.tasks[task].interval] GT 0>
				<cfset adjustedtime = DateAdd("s",Int(sIntervals[variables.tasks[task].interval]/10),arguments.runtime)>
				AND	DateRun > #CreateODBCDateTime(DateAdd("s", -Int(sIntervals[variables.tasks[task].interval]), adjustedtime))#--converted numeric
				<!--- If the key value is "daily", check by one day --->
				<cfelseif variables.tasks[task].interval EQ "daily">
				<cfset adjustedtime = DateAdd("n",55,arguments.runtime)>
				AND	DateRun > #CreateODBCDateTime(DateAdd("d", -1, adjustedtime))#--daily
				<!--- If the key value is "weekly", check by one week --->
				<cfelseif variables.tasks[task].interval EQ "weekly">
				<cfset adjustedtime = DateAdd("h",12,arguments.runtime)>
				AND	DateRun > #CreateODBCDateTime(DateAdd("ww", -1, adjustedtime))#--weekly
				<!--- If the key value is "monthly", check by one month --->
				<cfelseif variables.tasks[task].interval EQ "monthly">
				<cfset adjustedtime = DateAdd("h",12,arguments.runtime)>
				AND	DateRun > #CreateODBCDateTime(DateAdd("m", -1, adjustedtime))#--monthly
				</cfif>
			<cfelse>
				AND	DateRun > #CreateODBCDateTime(DateAdd("s", -3600, adjustedtime))#--default
			</cfif>
			ORDER BY ActionID DESC
			#variables.DataMgr.getMaxRowsSuffix(1)#
			</cfquery>
			<!--- If the task hasn't been run within the interval, run it --->
			<cfif NOT qCheckRun.RecordCount>
				<cfset ArrayAppend(aResults,variables.tasks[task])>
			</cfif>
		</cfif>
	</cfloop>
	
	<cfreturn aResults>
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
			<field ColumnName="hours" CF_DataType="CF_SQL_VARCHAR" Length="60" />
			<field ColumnName="dateCreated" CF_DataType="CF_SQL_DATE" Special="CreationDate" />
			<field ColumnName="dateDeleted" CF_DataType="CF_SQL_DATE" Special="DeletionMark" />
		</table>
		<table name="schActions">
			<field ColumnName="ActionID" CF_DataType="CF_SQL_BIGINT" PrimaryKey="true" Increment="true" />
			<field ColumnName="TaskID" CF_DataType="CF_SQL_INTEGER" />
			<field ColumnName="DateRun" CF_DataType="CF_SQL_DATE" Special="CreationDate" />
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