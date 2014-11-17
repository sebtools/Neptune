<cfcomponent displayname="Observer" extends="mxunit.framework.TestCase" output="no">

<cffunction name="beforeTests" access="public" returntype="void" output="no">
	
	<cfset variables.Observer = CreateObject("component","Observer").init()>
	
	<cfset variables.Observer.register(Listener=This,ListenerName="TestObserver",ListenerMethod="respond",EventName="Observer Test")>
	<cfset variables.Observer.register(Listener=This,ListenerName="TestObserver",ListenerMethod="respondRecursive",EventName="Observer Test Recursive")>
	
</cffunction>

<cffunction name="setUp" access="public" returntype="void" output="no">
	
	<cfset request.TestObserverResponseRuns = 0>
	
</cffunction>

<cffunction name="shouldNotifyListener" access="public" returntype="void" output="no"
	hint="Observer should notify listeners of events."
>
	
	<cfset listenedAction()>
	
	<cfset assertEquals(1,request.TestObserverResponseRuns,"Observer failed to notify the listeners of requested event.")>
	
</cffunction>

<cffunction name="shouldWorkOnSequentialEvents" access="public" returntype="void" output="no"
	hint="Observer should work when non-recursive events are called that exceed the depth limit."
>
	
	<cfset var ii = 0>
	
	<cfloop index="ii" from="1" to="5">
		<cfset listenedAction()>
	</cfloop>
	
</cffunction>

<cffunction name="shouldFailOnTooMuchDepth" access="public" returntype="void" output="no"
	hint="Observer should throw an exception of the recursion depth exceeds the limit."
>
	<cfset var hasRecursionException = false>
	
	<cftry>
		<cfset listenedActionRecursive()>
	<cfcatch type="Observer">
		<cfset hasRecursionException = true>
	</cfcatch>
	</cftry>
	
	<cfset assertTrue(hasRecursionException,"Observer failed to throw an exception when the recursion depth was exceeded.")>
	
</cffunction>

<cffunction name="respond" access="public" returntype="void" output="no">
	
	<cfif NOT StructKeyExists(request,"TestObserverResponseRuns")>
		<cfset request.TestObserverResponseRuns = 0>
	</cfif>
	
	<cfset request.TestObserverResponseRuns = request.TestObserverResponseRuns + 1>
</cffunction>

<cffunction name="respondRecursive" access="public" returntype="void" output="no">
	
	<cfset respond()>
	
	<cfif request.TestObserverResponseRuns LTE 20>
		<cfset Variables.Observer.notifyEvent(EventName="Observer Test Recursive",RecursionLimit=3)>
	</cfif>
		
</cffunction>

<cffunction name="listenedAction" access="public" returntype="void" output="no">
	
	<cfset Variables.Observer.notifyEvent(EventName="Observer Test",RecursionLimit=3)>
</cffunction>

<cffunction name="listenedActionRecursive" access="public" returntype="void" output="no">
	
	<cfset Variables.Observer.notifyEvent(EventName="Observer Test Recursive",RecursionLimit=3)>
	
</cffunction>

</cfcomponent>