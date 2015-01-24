<cfcomponent displayname="Observer" output="no">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="Subject" type="any" required="false">
	
	<cfset Variables.sEvents = StructNew()>
	<!--- Default the number of times a particular event can be announced in the same request --->
	<cfset Variables.RecursionLimit = 15>
	
	<cfif StructKeyExists(Arguments,"Subject")>
		<cfset setSubject(Arguments.Subject)>
	</cfif>
	
	<cfset This["notifyEvent"] = announceEvent>
	<cfset This["register"] = registerListener>
	<cfset This["unregister"] = unregisterListener>
	
	<cfset This["announce"] = announceEvent>
	
	<cfreturn This>
</cffunction>

<cffunction name="announceEvent" access="public" returntype="void" output="no">
	<cfargument name="EventName" type="string" default="update">
	<cfargument name="Args" type="struct" required="false">
	<cfargument name="RecursionLimit" type="numeric" required="false" default="#Variables.RecursionLimit#">
	
	<cfset var key = "">
	<cfset var ii = 0>
	
	<cfset checkEventRecursion(Arguments.EventName,Arguments.RecursionLimit)>
	
	<cfif StructKeyExists(Variables.sEvents,Arguments.EventName) AND ArrayLen(Variables.sEvents[Arguments.EventName])>
		<cfloop index="ii" from="1" to="#ArrayLen(Variables.sEvents[Arguments.EventName])#">
			<cfinvoke
				component="#Variables.sEvents[EventName][ii].Listener#"
				method="#Variables.sEvents[EventName][ii].ListenerMethod#"
				argumentcollection="#Arguments.Args#"
			>
			</cfinvoke>
		</cfloop>
	</cfif>
	
	<!--- Decrement the event from the request stack --->
	<cfset request.ObserverEventStack[Arguments.EventName] = request.ObserverEventStack[Arguments.EventName] - 1>
	
</cffunction>

<cffunction name="checkEventRecursion" access="private" returntype="void" output="no">
	<cfargument name="EventName" type="string" default="update">
	<cfargument name="RecursionLimit" type="numeric" required="true">
	
	<cfif NOT StructKeyExists(request,"ObserverEventStack")>
		<cfset request["ObserverEventStack"] = {}>
	</cfif>
	
	<cfif NOT StructKeyExists(request.ObserverEventStack,Arguments.EventName)>
		<cfset request.ObserverEventStack[Arguments.EventName] = 0>
	</cfif>
	
	<cfset request.ObserverEventStack[Arguments.EventName] = request.ObserverEventStack[Arguments.EventName] + 1>
	
	<cfif request.ObserverEventStack[Arguments.EventName] GT Arguments.RecursionLimit>
		<cfthrow type="Observer" message="Event announced recursively" detail="The #Arguments.EventName# event was announced more than the maximum number of times allowed (#Arguments.RecursionLimit#) during a single request.">
	</cfif>
	
</cffunction>

<cffunction name="registerListener" access="public" returntype="void" output="no">
	<cfargument name="Listener" type="any" required="true">
	<cfargument name="ListenerName" type="string" required="true">
	<cfargument name="ListenerMethod" type="string" default="listen">
	<cfargument name="EventName" type="string" default="update">
	
	<cfset unregisterListener(ArgumentCollection=Arguments)>
	
	<cfif NOT StructKeyExists(Variables.sEvents,Arguments.EventName)>
		<cfset Variables.sEvents[Arguments.EventName] = ArrayNew(1)>
	</cfif>
	
	<cfset ArrayAppend(Variables.sEvents[Arguments.EventName],Arguments)>
	
</cffunction>

<cffunction name="unregisterListener" access="public" returntype="void" output="no">
	<cfargument name="ListenerName" type="string" required="true">
	<cfargument name="ListenerMethod" type="string" default="listen">
	<cfargument name="EventName" type="string" required="false">
	
	<cfset var ii = 0>
	
	<cfif StructKeyExists(Variables.sEvents,Arguments.EventName)>
		<cfloop index="ii" from="#ArrayLen(Variables.sEvents[Arguments.EventName])#" to="1" step="-1">
			<cfif
					Arguments.ListenerName EQ Variables.sEvents[Arguments.EventName][ii].ListenerName
				AND	Arguments.ListenerMethod EQ Variables.sEvents[Arguments.EventName][ii].ListenerMethod
				AND	Arguments.EventName EQ Variables.sEvents[Arguments.EventName][ii].EventName
			>
				<cfset ArrayDeleteAt(Variables.sEvents[Arguments.EventName],ii)>
				<cfbreak>
			</cfif>
		</cfloop>
	</cfif>
	
</cffunction>

<cffunction name="setSubject" access="public" returntype="any" output="no">
	<cfargument name="Subject" type="any" required="true">
	
	<cfset Variables.Subject = Arguments.Subject>
	
	<cfif StructKeyExists(Variables.Subject,"setObserver")>
		<cfset Variables.Subject.setObserver(This)>
	</cfif>
	
	<cfreturn This>
</cffunction>

</cfcomponent>