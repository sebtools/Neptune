<cfcomponent display="Mr. Ecache" hint="I am a handy wrapper for the built-in Ehcache functionality.">

<cffunction name="init" access="public" returntype="any" output="false">
	<cfargument name="id" type="string" default="">
	<cfargument name="timeSpan" type="string" required="false">
	<cfargument name="idleTime" type="string" required="false">
	<cfargument name="Observer" type="any" required="false">

	<cfset Variables.instance = Arguments>

	<cfset Variables.meta = StructNew()>

	<cfreturn This>
</cffunction>

<cffunction name="clearCaches" access="public" returntype="any" output="false" hint="I clear all caches that start with the given prefix.">
	<cfargument name="prefix" type="string" default="">

	<cfset var id = qualify(Arguments.prefix)><!--- Make sure to just get values for this instance of MrECache. --->
	<cfset var aCacheNames = CacheGetAllIds()>
	<cfset var ii = 0>

	<!--- Loop through all existing cache ids to ditch the ones that match the prefix. --->
	<cfloop index="ii" from="1" to="#ArrayLen(aCacheNames)#">
		<cfif Left(aCacheNames[ii],Len(id)) EQ id>
			<cfset remove(dequalify(aCacheNames[ii]))>
		</cfif>
	</cfloop>

</cffunction>

<cffunction name="exists" access="public" returntype="boolean" output="false" hint="I check to see if the id is in the cache.">
	<cfargument name="id" type="string" required="true">

	<cfset var aCacheNames = CacheGetAllIds()>
	<cfset var key = qualify(Arguments.id)>
	<cfset var ii = 0>

	<!--- Could use, cacheIdExists(), but ditching just that allows this to run on versions before ColdFusion 10. --->

	<cfscript>
	//Loop through all cache names to see if the given one exists.
	for ( ii=1; ii LTE ArrayLen(aCacheNames); ii=ii+1 ) {
		if ( aCacheNames[ii] EQ key ) {
			return true;
		}
	}
	</cfscript>

	<cfreturn false>
</cffunction>

<cffunction name="func" access="public" returntype="any" output="false" hint="I get data from the cache (getting the data from the function if isn't there yet).">
	<cfargument name="id" type="string" required="true">
	<cfargument name="Fun" type="any" required="true">
	<cfargument name="Args" type="struct" required="false">
	<cfargument name="timeSpan" type="string" required="false">
	<cfargument name="idleTime" type="string" required="false">

	<cfset var local = StructNew()>
	<cfset var begin = 0>

	<!--- Try to get this from cache. If it isn't there, this will return void and obliterate the key from the struct. --->
	<cfset local.result = get(Arguments.id)>

	<cfif NOT StructKeyExists(local,"result")>
		<cfif NOT StructKeyExists(Arguments,"Args")>
			<cfset Arguments["Args"] = {}>
		</cfif>
		<cfset begin = getTickCount()>
		<cfset local.result = Arguments.Fun(ArgumentCollection=Arguments.Args)>
		<cfset logCall(type="func",id=Arguments.id,began=begin,args=Arguments)>
		<!--- Need something to return and store in the cache so we don't call the method every time. --->
		<cfif StructKeyExists(local,"result")>
			<cfset local.result = "">
		</cfif>
		<cfset StructDelete(Arguments,"Fun")>
		<cfset StructDelete(Arguments,"Args")>
		<cfset Arguments["value"] = local.result>
		<cfset put(ArgumentCollection=Arguments)>
	</cfif>

	<cfreturn local.result>
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

<cffunction name="meth" access="public" returntype="any" output="false" hint="I get data from the cache (getting the data from the method if isn't there yet).">
	<cfargument name="Component" type="any" required="true">
	<cfargument name="MethodName" type="string" required="true">
	<cfargument name="Args" type="struct" required="false">
	<cfargument name="timeSpan" type="string" required="false">
	<cfargument name="idleTime" type="string" required="false">

	<cfif NOT StructKeyExists(Arguments,"id")>
		<cfset Arguments.id = ListFirst(Arguments.MethodName,"_")>
	</cfif>

	<cfif StructKeyExists(Arguments,"Args")>
		<cfset Arguments.id = This.id(Arguments.id,Arguments.Args)>
	</cfif>

	<cfreturn method(ArgumentCollection=Arguments)>
</cffunction>

<cffunction name="method" access="public" returntype="any" output="false" hint="I get data from the cache (getting the data from the method if isn't there yet).">
	<cfargument name="id" type="string" required="true">
	<cfargument name="Component" type="any" required="true">
	<cfargument name="MethodName" type="string" required="true">
	<cfargument name="Args" type="struct" required="false">
	<cfargument name="timeSpan" type="string" required="false">
	<cfargument name="idleTime" type="string" required="false">

	<cfset var local = StructNew()>
	<cfset var begin = 0>

	<!--- Try to get this from cache. If it isn't there, this will return void and obliterate the key from the struct. --->
	<cfset local.result = get(Arguments.id)>

	<cfif NOT StructKeyExists(local,"result")>
		<cfif NOT StructKeyExists(Arguments,"Args")>
			<cfset Arguments["Args"] = {}>
		</cfif>
		<cfset begin = getTickCount()>
		<cfinvoke
			returnvariable="local.result"
			component="#Arguments.Component#"
			method="#Arguments.MethodName#"
			argumentcollection="#Arguments.Args#"
		>
		<cfset logCall(type="method",id=Arguments.id,began=begin,args=Arguments)>
			<cfset StructDelete(Arguments,"Component")>
			<cfset StructDelete(Arguments,"MethodName")>
			<cfset StructDelete(Arguments,"Args")>
			<!--- Need something to return and store in the cache so we don't call the method every time. --->
			<cfif NOT StructKeyExists(local,"result")>
				<cfset local.result = "">
			</cfif>
			<cfset Arguments["value"] = local.result>
			<cfset put(ArgumentCollection=Arguments)>
	</cfif>

	<cfreturn local.result>
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

<cffunction name="getPrefix" access="public" returntype="string" output="false" hint="I return the prefix value for the given id.">
	<cfargument name="id" type="string" required="true">

	<cfset var prefix = "">

	<cfif Len(Trim(Variables.instance.id))>
		<cfset prefix = Trim(Variables.instance.id)>
		<cfif Len(Trim(Arguments.id))>
			<cfset prefix &= ":">
		</cfif>
	</cfif>

	<cfreturn prefix>
</cffunction>

<cffunction name="dequalify" access="public" returntype="string" output="false" hint="I return the localized reference to a fully qualified caching id.">
	<cfargument name="id" type="string" required="true">

	<cfset var prefix = getPrefix(Arguments.id)>

	<cfif Len(Trim(prefix))>
		<cfset Arguments.id = ReplaceNoCase(Arguments.id,prefix,"","ONE")>
	</cfif>

	<cfreturn Arguments.id>
</cffunction>

<cffunction name="qualify" access="public" returntype="string" output="false" hint="I return the fully qualified id for caching.">
	<cfargument name="id" type="string" required="true">

	<cfset var prefix = getPrefix(Arguments.id)>
	<cfset var result = prefix & Trim(Arguments.id)>

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

<cffunction name="spawn" access="public" returntype="any" output="false" hint="I spawn and return a new instance of MrECache.">
	<cfargument name="id" type="string" required="true">
	<cfargument name="timeSpan" type="string" required="false">
	<cfargument name="idleTime" type="string" required="false">

	<cfif StructKeyExists(Variables.Instance,"Observer")>
		<cfset Arguments.Observer = Variables.Instance.Observer>
	</cfif>

	<cfreturn CreateObject("component","MRECache").init(ArgumentCollection=Arguments)>
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

<cffunction name="logCall" access="private" returntype="void" output="false">
	<cfargument name="id" type="string" required="true">
	<cfargument name="began" type="numeric" required="true">
	<cfargument name="type" type="string" required="false">

	<!--- Notify Observer (if available) --->
	<cfif StructKeyExists(Variables.instance,"Observer") AND StructKeyExists(Variables.instance["Observer"],"announceEvent")>
		<cfset Arguments.args.runTime = getTickCount() - Arguments.began>
		<cftry>
			<cfset Variables.instance.Observer.announceEvent(EventName="MrECache:run",Args=args)>
		<cfcatch>
		</cfcatch>
		</cftry>
		<cfif StructKeyExists(args,"type")>
			<cftry>
				<cfset Variables.instance.Observer.announceEvent(EventName="MrECache:#args.type#",Args=args)>
			<cfcatch>
			</cfcatch>
			</cftry>
		</cfif>
	</cfif>

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
