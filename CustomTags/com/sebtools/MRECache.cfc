<cfcomponent display="Mr. Ecache" hint="I am a handy wrapper for the built-in Ehcache functionality.">

<cffunction name="init" access="public" returntype="any" output="false">
	<cfargument name="id" type="string" default="">
	<cfargument name="timeSpan" type="string" required="false">
	<cfargument name="idleTime" type="string" required="false">

	<cfset Variables.instance = Arguments>

	<cfset Variables.meta = StructNew()>

	<cfreturn This>
</cffunction>

<cffunction name="exists" access="public" returntype="boolean" output="false" hint="I check to see if the id is in the cache.">
	<cfargument name="id" type="string" required="true">

	<cfset var result = CacheGet(qualify(Arguments.id))>

	<cfreturn NOT isNull(result)>
</cffunction>

<cffunction name="func" access="public" returntype="any" output="false" hint="I get data from the cache (getting the data from the function if isn't there yet).">
	<cfargument name="id" type="string" required="true">
	<cfargument name="Fun" type="any" required="true">
	<cfargument name="Args" type="struct" required="false">
	<cfargument name="timeSpan" type="string" required="false">
	<cfargument name="idleTime" type="string" required="false">

	<cfset var local = StructNew()>
	
	<cfif NOT exists(Arguments.id)>
		<cfif NOT StructKeyExists(Arguments,"Args")>
			<cfset Arguments["Args"] = {}>
		</cfif>
		<cfset local.result = Arguments.Fun(ArgumentCollection=Arguments.Args)>
		<cfif StructKeyExists(local,"result")>
			<cfset StructDelete(Arguments,"Fun")>
			<cfset StructDelete(Arguments,"Args")>
			<cfset Arguments["value"] = local.result>
			<cfset put(ArgumentCollection=Arguments)>
		</cfif>
	</cfif>

	<cfreturn get(Arguments.id)>
</cffunction>

<cffunction name="get" access="public" returntype="any" output="false" hint="I get data from the cache (first using the default if it is given but the id isn't in the cache).">
	<cfargument name="id" type="string" required="true">
	<cfargument name="default" type="any" required="false">

	<cfif StructKeyExists(Arguments,"default")>
		<cfif NOT exists(Arguments.id)>
			<cfset put(Arguments.id,Arguments.default)>
		</cfif>
	</cfif>

	<cfset got(Arguments.id)>

	<cfreturn CacheGet(qualify(Arguments.id))>
</cffunction>

<cffunction name="id" access="public" returntype="any" output="false" hint="I make an id from a key and data.">
	<cfargument name="key" type="string" required="true">
	<cfargument name="data" type="any" required="false">

	<cfset var result = Arguments.key>

	<cfif StructKeyExists(Arguments,"data")>
		<cfif isSimpleValue(Arguments.data)>
			<cfset result = "#result#_" & Arguments.data>
		<cfelse>
			<cfset result = "#result#_" & Hash(SerializeJSON(Arguments.data))>	
		</cfif>
	</cfif>

	<cfreturn result>
</cffunction>

<cffunction name="method" access="public" returntype="any" output="false" hint="I get data from the cache (getting the data from the method if isn't there yet).">
	<cfargument name="id" type="string" required="true">
	<cfargument name="Component" type="any" required="true">
	<cfargument name="MethodName" type="string" required="true">
	<cfargument name="Args" type="struct" required="false">
	<cfargument name="timeSpan" type="string" required="false">
	<cfargument name="idleTime" type="string" required="false">

	<cfset var local = StructNew()>
	
	<cfif NOT exists(Arguments.id)>
		<cfif NOT StructKeyExists(Arguments,"Args")>
			<cfset Arguments["Args"] = {}>
		</cfif>
		<cfinvoke
			returnvariable="local.result"
			component="#Arguments.Component#"
			method="#Arguments.MethodName#"
			argumentcollection="#Arguments.Args#"
		>
			<cfset StructDelete(Arguments,"Component")>
			<cfset StructDelete(Arguments,"MethodName")>
			<cfset StructDelete(Arguments,"Args")>
			<cfif StructKeyExists(local,"result")>
				<cfset Arguments["value"] = local.result>
			<cfelse>
				<cfset Arguments["value"] = "">
			</cfif>
			<cfset put(ArgumentCollection=Arguments)>
	</cfif>

	<cfreturn get(Arguments.id)>
</cffunction>

<cffunction name="put" access="public" returntype="void" output="false" hint="I put data into the cache.">
	<cfargument name="id" type="string" required="true">
	<cfargument name="value" type="any" required="true">
	<cfargument name="timeSpan" type="string" required="false">
	<cfargument name="idleTime" type="string" required="false">

	<cfset start(Arguments.id)>

	<cfset Arguments = putargs(ArgumentCollection=Arguments)>

	<cfif StructKeyExists(Arguments,"idleTime") AND StructKeyExists(Arguments,"timeSpan")>
		<cfset CachePut(qualify(Arguments.id),Arguments.value,convertTimeSpan(Arguments.timeSpan),convertTimeSpan(Arguments.idleTime))>
	<cfelseif StructKeyExists(Arguments,"timeSpan")>
		<cfset CachePut(qualify(Arguments.id),Arguments.value,convertTimeSpan(Arguments.timeSpan))>
	<cfelse>
		<cfset CachePut(qualify(Arguments.id),Arguments.value)>
	</cfif>

</cffunction>

<cffunction name="qualify" access="public" returntype="string" output="false" hint="I return the fully qualified id for caching.">
	<cfargument name="id" type="string" required="true">

	<cfset var result = "">

	<cfif Len(Trim(Variables.instance.id))>
		<cfset result = Trim(Variables.instance.id)>
	</cfif>

	<cfif Len(Trim(Variables.instance.id)) AND Len(Trim(Arguments.id))>
		<cfset result &= ":">
	</cfif>

	<cfif Len(Trim(Arguments.id))>
		<cfset result &= Trim(Arguments.id)>
	</cfif>

	<cfif NOT Len(Trim(result))>
		<cfthrow message="An id is required for caching.">
	</cfif>

	<cfreturn result>
</cffunction>

<cffunction name="remove" access="public" returntype="void" output="false" hint="I remove an id from the cache.">
	<cfargument name="id" type="string" required="true">

	<cfset CacheRemove(qualify(Arguments.id))>
	<cfset StructDelete(Variables.meta,Arguments.id)>

</cffunction>

<cffunction name="set" access="public" returntype="void" output="false" hint="I am here just in case you forget that the method is called 'put'.">
	<cfargument name="id" type="string" required="true">
	<cfargument name="value" type="any" required="true">

	<cfset put(ArgumentCollection=Arguments)>

</cffunction>

<cffunction name="convertTimeSpan" access="public" returntype="numeric" output="false" hint="I return a timespan from an interval string.">
	<cfargument name="interval" type="string" required="true">

	<cfif isNumeric(Arguments.interval)>
		<cfreturn Arguments.interval>
	</cfif>

	<cfreturn getTimeSpanFromInterval(Arguments.interval)>
</cffunction>

<cffunction name="getTimeSpanFromInterval" access="public" returntype="numeric" output="false" hint="I return a timespan from an interval string.">
	<cfargument name="interval" type="string" required="true">
	
	<cfset var result = 0>
	<cfset var timespans = "second,minute,hour,day,week,month,quarter,year">
	<cfset var dateparts = "s,n,h,d,ww,m,q,yyyy">
	<cfset var vals = "#CreateTimeSpan(0,0,0,1)#,#CreateTimeSpan(0,0,1,0)#,#CreateTimeSpan(0,1,0,0)#,1,7,30,90,365">
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
	
	<cfif ListLen(arguments.interval) GT 1>
		<cfloop list="#arguments.interval#" index="thisint">
			<cfset result += getTimeSpanFromInterval(thisint)>
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
		<cfloop list="#ordinals#" index="ordinal">
			<cfif ListFindNoCase(arguments.interval,ordinal," ")>
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
		
		<cfif ListFindNoCase(timespans,timespan)>
			<cfset value = ListGetAt(vals,ListFindNoCase(timespans,timespan))>
		<cfelse>
			<cfthrow message="#timespan# is not a valid inteval measurement.">
		</cfif>
		
		<cfset result = value * num>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="got" access="private" returntype="void" output="false">
	<cfargument name="id" type="string" required="true">

	<cfset start(Arguments.id)>

	<cfset Variables.meta[Arguments.id]["NumCalls"] += 1>

</cffunction>

<cffunction name="putargs" access="private" returntype="struct" output="false">
	<cfargument name="id" type="string" required="true">
	<cfargument name="value" type="any" required="true">
	<cfargument name="timeSpan" type="string" required="false">
	<cfargument name="idleTime" type="string" required="false">

	<cfif NOT StructKeyExists(Arguments,"timeSpan")>
		<cfif StructKeyExists(Variables.instance,"timeSpan")>
			<cfset Arguments.timeSpan = Variables.instance.timeSpan>
		</cfif>
	</cfif>

	<cfif NOT StructKeyExists(Arguments,"idleTime")>
		<cfif StructKeyExists(Variables.instance,"idleTime")>
			<cfset Arguments.idleTime = Variables.instance.idleTime>
		</cfif>
	</cfif>

	<cfreturn Arguments>
</cffunction>

<cffunction name="start" access="private" returntype="void" output="false">
	<cfargument name="id" type="string" required="true">

	<!--- Make sure we have a key in meta for this id. --->
	<cfif NOT StructKeyExists(Variables.meta,Arguments.id)>
		<cfset Variables.meta[Arguments.id] = StructNew()>
	</cfif>

	<cfif NOT StructKeyExists(Variables.meta[Arguments.id],"NumCalls")>
		<cfset Variables.meta[Arguments.id]["NumCalls"] = 0>
	</cfif>
	
</cffunction>

</cfcomponent>