<cf_Service name="Scheduler">

<cfset aTests = [
	{i="monthly",d="2021-07-01"},
	{i="monthly",d="2021-06-01"},
	{i="quarterly",d="2021-06-01"},
	{i="quarterly",d="2021-05-01"},
	{i="quarterly",d="2021-04-04"},
	{i="daily",d="2021-06-01"},
	{i="daily",d="2021-07-09"},
	{i="weekly",d="2021-07-03"},
	{i="weekly",d="2021-07-02"},
	{i="weekly",d="2021-07-01"},
	{i="hourly",d="2021-07-09 9:02 AM"},
	{i="hourly",d="2021-07-09 9:00 AM"},
	{i="hourly",d="2021-07-09 8:50 AM"},
	{i="every other hour",d="2021-07-09 8:02 AM"},
	{i="every other hour",d="2021-07-09 8:00 AM"},
	{i="every other hour",d="2021-07-09 7:50 AM"},
	{i="every five days",d="2021-06-04"},
	{i="every five days",d="2021-07-05"}
]>
<cfset currTime = "2021-07-09 10:00 AM">

<cffunction name="MyDateFormat" access="public" returntype="string" output="false">
	<cfargument name="date" type="date" required="yes">

	<cfset var result = DateFormat(Arguments.date,"mmmm d, yyyy")>
	<cfset var t = TimeFormat(aTests[ii].d)>

	<cfif t NEQ "12:00 AM">
		<cfset result = result & " " & t>
	</cfif>

	<cfreturn result>
</cffunction>

<cffunction name="runResponse" access="public" returntype="string" output="false">
	<cfargument name="interval" type="string" required="yes">
	<cfargument name="lastrun" type="date" required="yes">
	<cfargument name="runtime" type="date" default="#now()#">

	<cfif Variables.Scheduler.hasRunWithinInterval(aTests[ii].i,aTests[ii].d,currTime)>
		<cfreturn '<span style="color:##990000">Already Ran</span>'>
	<cfelse>
		<cfreturn '<span style="color:##008888">Runnable<span>'>
	</cfif>
</cffunction>

<cfoutput>
<p>Today is: #DateFormat(currTime,"mmmm d, yyyy")#</p>
<ul>
	<cfloop index="ii" from="1" to="#ArrayLen(aTests)#">
		<li>#aTests[ii].i# since #MyDateFormat(aTests[ii].d,"mmmm d, yyyy")#: #runResponse(aTests[ii].i,aTests[ii].d,currTime)#</li>
	</cfloop>
</ul>
</cfoutput>
