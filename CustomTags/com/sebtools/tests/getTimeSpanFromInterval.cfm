

<cffunction name="getTimeSpanFromInterval" access="public" returntype="date" output="false" hint="I return a timespan from an interval string.">
	<cfargument name="interval" type="string" required="true">
	
	<cfset var result = 0>
	<cfset var timespans = "second,minute,hour,day,week,month,quarter,year">
	<cfset var val_year = 364.25>
	<cfset var val_month = val_year / 12>
	<cfset var vals = "#CreateTimeSpan(0,0,0,1)#,#CreateTimeSpan(0,0,1,0)#,#CreateTimeSpan(0,1,0,0)#,1,7,#val_month#,#(val_month*3)#,#val_year#">
	<cfset var num = 1>
	<cfset var timespan = "">
	<cfset var value = 0>
	<cfset var ordinals = "first,second,third,fourth,fifth,sixth,seventh,eighth,ninth,tenth,eleventh,twelfth">
	<cfset var ordinal = "">
	<cfset var numbers = "one,two,three,four,five,six,seven,eight,nine,ten,eleven,twelve">
	<cfset var number = "">
	<cfset var instances = "once,twice">
	<cfset var instance = "">
	<cfset var thisint = "">
	<cfset var sNums = 0>
	<cfset var findtemp = 0>
	<cfset var sVals = {
		second=CreateTimeSpan(0,0,0,1),
		minute=CreateTimeSpan(0,0,1,0),
		hour=CreateTimeSpan(0,1,0,0),
		day=1,
		week=7,
		month=val_month,
		quarter=(val_month*3),
		year=val_year
	}>

	<cfset arguments.interval = Trim(arguments.interval)>

	<!--- Allow "and" as a list delimiter since that is naturally how people type --->
	<cfset arguments.interval = ReplaceNoCase(arguments.interval,"and",",","ALL")>
	
	<cfif ListLen(arguments.interval) GT 1>
		<cfloop list="#arguments.interval#" index="thisint">
			<cfset result += getTimeSpanFromInterval(thisint)>
		</cfloop>
	<cfelse>
		<!--- Makes years easier to deal with if we change "annually" to "yearly" at the start --->
		<cfset arguments.interval = ReplaceNoCase(arguments.interval,"annually","yearly","ALL")>
		<!--- ordinal endings to numeric just get in the way --->
		<cfset arguments.interval = ReReplaceNoCase(arguments.interval,"\b(\d+)(nd|rd|th)\b","\1","ALL")>
		<cfset sNums = ReFindNoCase("\b\d+\b",arguments.interval,1,true)>
		<!--- Figure out number --->
		<cfif ArrayLen(sNums.pos) AND sNums.pos[1] GT 0>
			<cfset num = Mid(arguments.interval,sNums.pos[1],sNums.len[1])>
		</cfif>
		<!--- The word "every" serves no purpose --->
		<cfif ListFindNoCase(arguments.interval,"every"," ")>
			<cfset arguments.interval = ListDeleteAt(arguments.interval,ListFindNoCase(arguments.interval,"every"," ")," ")>
		</cfif>
		<cfloop list="#ordinals#" index="ordinal">
			<cfset findtemp = ListFindNoCase(arguments.interval,ordinal," ")>
			<cfif findtemp AND findtemp LT ListLen(arguments.interval," ")>
				<cfset num = num * ListFindNoCase(ordinals,ordinal)>
			</cfif>
		</cfloop>
		<cfloop list="#numbers#" index="number">
			<cfif REFindNoCase("\b#number# times\b",arguments.interval)>
				<cfset num = num / ListFindNoCase(numbers,number)>
			<cfelseif ListFindNoCase(arguments.interval,number," ")>
				<cfset num = num * ListFindNoCase(numbers,number)>
			</cfif>
		</cfloop>
		<cfloop list="#instances#" index="instance">
			<cfif ListFindNoCase(arguments.interval,instance," ")>
				<cfset num = num / ListFindNoCase(instances,instance)>
			</cfif>
		</cfloop>
		<cfif ListFindNoCase(arguments.interval,"other"," ")>
			<cfset arguments.interval = ListDeleteAt(arguments.interval,ListFindNoCase(arguments.interval,"other"," ")," ")>
			<cfset num = num * 2>
		</cfif>
		
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
		
		<cfif StructKeyExists(sVals,timespan)>
			<cfset value = sVals[timespan]>
		<cfelse>
			<cfthrow message="#timespan# is not a valid inteval measurement.">
		</cfif>
		
		<cfset result = value * num>
	</cfif>
	
	<cfreturn Trim(result)><!--- Don't use Val()! It will break very small numbers (because they include an "E" notation) --->
</cffunction>

<cfset aTests = [
	{text="annually",number=364.25},
	{text="yearly",number=364.25},
	{text="every four years",number=364.25*4},
	{text="quarterly",number=364.25/4},
	{text="monthly",number=364.25/12},
	{text="daily",number=CreateTimeSpan(1,0,0,0)},
	{text="every day",number=CreateTimeSpan(1,0,0,0)},
	{text="every other day",number=CreateTimeSpan(2,0,0,0)},
	{text="every 12 hours",number=CreateTimeSpan(0,12,0,0)},
	{text="three times daily",number=CreateTimeSpan((1/3),0,0,0)},
	{text="every eight hours",number=CreateTimeSpan(0,8,0,0)},
	{text="hourly",number=CreateTimeSpan(0,1,0,0)},
	{text="every hour",number=CreateTimeSpan(0,1,0,0)},
	{text="every other hour",number=CreateTimeSpan(0,2,0,0)},
	{text="four times hourly",number=CreateTimeSpan(0,0,15,0)},
	{text="every 15 minutes",number=CreateTimeSpan(0,0,15,0)},
	{text="every 15 seconds",number=CreateTimeSpan(0,0,0,15)},
	{text="every 2 days, 14 hours",number=CreateTimeSpan(2,14,0,0)},
	{text="every 3 days and 6 hours",number=CreateTimeSpan(3,6,0,0)},
	{text="2 hours, 15 minutes and 30 seconds",number=CreateTimeSpan(0,2,15,30)},
	{text="every second",number=CreateTimeSpan(0,0,0,1)},
	{text="every second second",number=CreateTimeSpan(0,0,0,2)}
]>

<cfoutput>
<ul>
<cfloop index="ii" from="1" to="#ArrayLen(aTests)#">
	<cfset sTest = aTests[ii]>
	<cfset result = getTimeSpanFromInterval(sTest.text)>
	<cfset diff = (Max(result,sTest.number) - Min(result,sTest.number))>
	<!--- If the result is accurate within about 10 zeros to the right of the decimal point, that should be close enough --->
	<cfif (diff * ( 10 ^ 10 )) LT 1>
		<cfset success = true>
		<cfset color="green">
	<cfelse>
		<cfset success = false>
		<cfset color="red">
	</cfif>
	<li style="color:#color#;">#sTest.text#: #result#<cfif NOT success>  (#sTest.number#: #diff#)</cfif></li>
</cfloop>
</ul>
</cfoutput>
