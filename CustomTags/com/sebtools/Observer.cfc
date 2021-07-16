<cfcomponent displayname="Observer" output="no">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="Subject" type="any" required="false" hint="A component with a 'setObserver' method into which Observer will be passed.">

	<!--- Here is where event listeners will be stored.  --->
	<cfset Variables.sEvents = StructNew()>

	<!--- Default the number of times a particular event can be announced in the same request. --->
	<cfset Variables.RecursionLimit = 15>

	<!--- This just provides some friendly method names that CF won't allow natively. --->
	<cfset This["notifyEvent"] = announceEvent>
	<cfset This["register"] = registerListener>
	<cfset This["unregister"] = unregisterListener>

	<cfset This["announce"] = announceEvent>

	<!--- Pass Observer to the Subject. --->
	<cfif StructKeyExists(Arguments,"Subject")>
		<cfset setSubject(Arguments.Subject)>
	</cfif>

	<cfset Variables.Me = This>

	<cfreturn This>
</cffunction>

<cffunction name="announceEvent" access="public" returntype="void" output="no" hint="I am called any time an event is run for which a listener may be attached.">
	<cfargument name="EventName" type="string" default="update">
	<cfargument name="Args" type="struct" required="false">
	<cfargument name="result" type="any" required="false">
	<cfargument name="This" type="any" required="false">
	<cfargument name="RecursionLimit" type="numeric" required="false">

	<cfset var key = "">
	<cfset var ii = 0>
	<cfset var begin = 0>
	<cfset var end = 0>
	<cfset var sRecursiveEvent = 0>
	<cfset var ArrLen = 0>

	<!--- In case this is called before init(). --->
	<cfif NOT StructKeyExists(Variables,"sEvents")>
		<cfexit>
	</cfif>

	<!--- Set default for RecursionLimit. Must be after above line in case this is called before init(). --->
	<cfif NOT StructKeyExists(Arguments,"RecursionLimit")>
		<cfset Arguments.RecursionLimit = Variables.RecursionLimit>
	</cfif>
	<!--- Ensure arguments exist. --->
	<cfif NOT StructKeyExists(Arguments,"Args")>
		<cfset Arguments["Args"] = {}>
	</cfif>
	<!--- Pass on result and This. --->
	<cfif StructKeyExists(Arguments,"result") AND NOT StructKeyExists(Arguments.Args,"result")>
		<cfset Arguments.Args.result = Arguments.result>
	</cfif>
	<cfif StructKeyExists(Arguments,"This") AND NOT StructKeyExists(Arguments.Args,"This")>
		<cfset Arguments.Args.This = Arguments.This>
	</cfif>

	<!--- Make sure that the event hasn't been called more times that Observer allows per request. --->
	<cfset checkEventRecursion(Arguments.EventName,Arguments.RecursionLimit)>

	<!--- If the event has listeners, call the listener method for each. --->
	<cfif StructKeyExists(Variables.sEvents,Arguments.EventName)>
		<cfset ArrLen = ArrayLen(Variables.sEvents[Arguments.EventName])>
		<cfif ArrLen>
			<cfloop index="ii" from="1" to="#ArrLen#">
				<cfset begin = getTickCount()>
				<cfset callListener(Variables.sEvents[EventName][ii],Arguments.Args)>
				<cfset end = getTickCount()>
				<!--- Observer should know about its own announcements. --->
				<cfif NOT StructKeyExists(request,"Observer_announcingevent")>
					<cfset request["Observer_announcingevent"] = now()>
					<cfset sRecursiveEvent = {
						EventName="Observer:announceEvent",
						Args={
							RunTime=end-begin,
							EventName=Arguments.EventName,
							ListenerName="#Variables.sEvents[EventName][ii].ListenerName#",
							Component=Variables.sEvents[EventName][ii].Listener,
							MethodName="#Variables.sEvents[EventName][ii].ListenerMethod#",
							args=Arguments.Args
						}
					}>
					<cfinvoke
						component="#Variables.Me#"
						method="announceEvent"
						argumentcollection="#sRecursiveEvent#"
					>
					</cfinvoke>
					<cfset StructDelete(request,"Observer_announcingevent")>
				</cfif>
			</cfloop>
		</cfif>
	</cfif>

	<cfset request.ObserverEventStack[Arguments.EventName] = request.ObserverEventStack[Arguments.EventName] - 1>

</cffunction>

<cffunction name="callListener" access="public" returntype="any" output="no" hint="I call the method for a listener.">
	<cfargument name="sListener" type="struct" required="true">
	<cfargument name="Args" type="struct" required="false">

	<cfif sListener.delay>
		<cfset callListenerLater(ArgumentCollection=Arguments)>
	<cfelse>
		<cfset callListenerNow(ArgumentCollection=Arguments)>
	</cfif>

</cffunction>

<cffunction name="callListenerLater" access="public" returntype="any" output="no" hint="I call the method for a listener.">
	<cfargument name="sListener" type="struct" required="true">
	<cfargument name="Args" type="struct" required="false">

	<cfscript>
	var ii = 0;

	Arguments["Hash"] = makeListenerCallHash(ArgumentCollection=Arguments);

	loadRequestVars();

	//If this listener call already exists, remove it (so we can add it back at the end of the queue)
	for ( ii = ArrayLen(request["Observer"]["aDelayeds"]); ii GTE 1; ii=ii-1 ) {
		if ( request["Observer"]["aDelayeds"][ii]["Hash"] EQ Arguments["Hash"] ) {
			ArrayDeleteAt(request["Observer"]["aDelayeds"], ii);
		}
	}

	ArrayAppend(
		request["Observer"]["aDelayeds"],
		Arguments
	);
	</cfscript>

</cffunction>

<cffunction name="callListenerNow" access="public" returntype="any" output="no" hint="I call the method for a listener.">
	<cfargument name="sListener" type="struct" required="true">
	<cfargument name="Args" type="struct" required="false">

	<cfinvoke
		component="#sListener.Listener#"
		method="#sListener.ListenerMethod#"
		argumentcollection="#Arguments.Args#"
	>
	</cfinvoke>

</cffunction>

<cffunction name="getEventListeners" access="public" returntype="struct" output="no" hint="I return all of the event listeners that Observer is tracking.">
	<cfreturn Variables.sEvents>
</cffunction>

<cffunction name="getListeners" access="public" returntype="struct" output="no" hint="I return all of the listeners for the given event.">
	<cfargument name="EventName" type="string" default="update">

	<cfset var sResult = StructNew()>
	<cfset var ii = "">

	<!--- Look through all of the event listeners and get only the ones for the given event. --->
	<cfif StructKeyExists(Variables.sEvents,Arguments.EventName) AND ArrayLen(Variables.sEvents[Arguments.EventName])>
		<cfloop index="ii" from="1" to="#ArrayLen(Variables.sEvents[Arguments.EventName])#">
			<cfset sResult[Variables.sEvents[Arguments.EventName][ii]["ListenerName"]] = Variables.sEvents[Arguments.EventName][ii]>
		</cfloop>
	</cfif>

	<cfreturn sResult>
</cffunction>

<cffunction name="checkEventRecursion" access="private" returntype="void" output="no" hint="I make sure that an event isn't called more times than Observer is set to allow.">
	<cfargument name="EventName" type="string" default="update">
	<cfargument name="RecursionLimit" type="numeric" required="true">

	<!--- Make sure the request variable exists. --->
	<cfif NOT StructKeyExists(request,"ObserverEventStack")>
		<cfset request["ObserverEventStack"] = {}>
	</cfif>

	<!--- Default the count to zero for this event. --->
	<cfif NOT StructKeyExists(request.ObserverEventStack,Arguments.EventName)>
		<cfset request.ObserverEventStack[Arguments.EventName] = 0>
	</cfif>

	<!--- Increment the count for this event --->
	<cfset request.ObserverEventStack[Arguments.EventName] = request.ObserverEventStack[Arguments.EventName] + 1>

	<!--- Throw an exception if the event is called more times in a request than allowed. --->
	<cfif request.ObserverEventStack[Arguments.EventName] GT Arguments.RecursionLimit>
		<cfthrow type="Observer" message="Event announced recursively" detail="The #Arguments.EventName# event was announced more than the maximum number of times allowed (#Arguments.RecursionLimit#) during a single request.">
	</cfif>

</cffunction>

<cffunction name="registerListener" access="public" returntype="void" output="no" hint="I register a listener for an event. Not Idempotent.">
	<cfargument name="Listener" type="any" required="true" hint="The component listening for the event, on which a method will be called.">
	<cfargument name="ListenerName" type="string" required="true" hint="A name for the listening component.">
	<cfargument name="ListenerMethod" type="string" default="listen" hint="The method to call on the component when the event occurs.">
	<cfargument name="EventName" type="string" default="update" hint="The name of the event to which this listener should respond.">
	<cfargument name="delay" type="boolean" default="false" hint="Indicate if the listener method call should be delayed until the runDelays method is called at the end of the request.">

	<cfset unregisterListener(ArgumentCollection=Arguments)>

	<cfif NOT StructKeyExists(Variables.sEvents,Arguments.EventName)>
		<cfset Variables.sEvents[Arguments.EventName] = ArrayNew(1)>
	</cfif>

	<cfset ArrayAppend(Variables.sEvents[Arguments.EventName],Arguments)>

</cffunction>

<cffunction name="registerListeners" access="public" returntype="void" output="no" hint="I register one listener to listen for multiple events at once.">
	<cfargument name="Listener" type="any" required="true" hint="The component listening for the event, on which a method will be called.">
	<cfargument name="ListenerName" type="string" required="true" hint="A name for the listening component.">
	<cfargument name="ListenerMethod" type="string" default="listen" hint="The method to call on the component when the event occurs.">
	<cfargument name="EventNames" type="string" required="true" hint="A list of events to which this listener should respond.">
	<cfargument name="delay" type="boolean" default="false" hint="Indicate if the listener method call should be delayed until the runDelays method is called at the end of the request.">

	<cfset var event = "">

	<cfloop list="#Arguments.EventNames#" index="event">
		<cfset registerListener(Listener=Listener,ListenerName=ListenerName,ListenerMethod=ListenerMethod,EventName=event)>
	</cfloop>

</cffunction>

<cffunction name="runDelays" access="public" returntype="void" output="no" hint="I run any delayed listener method calls.">

	<cfscript>
	var sListener = 0;

	//Make sure request variables exist.
	loadRequestVars();

	//Get the first item and delete it instead of looping through the array so that items can be appeneded as we are moving through the list.
	while ( ArrayLen(request.Observer.aDelayeds) ) {
		sListener = StructCopy(request.Observer.aDelayeds[1]);
		ArrayDeleteAt(request.Observer.aDelayeds,1);
		callListenerNow(ArgumentCollection=sListener);
	}
	</cfscript>

</cffunction>

<cffunction name="unregisterListener" access="public" returntype="void" output="no" hint="I make a listener no longer listen for the given event.">
	<cfargument name="ListenerName" type="string" required="true" hint="The component that was listening for the event.">
	<cfargument name="ListenerMethod" type="string" default="listen" hint="The method that was to be called on the component when the event occurs.">
	<cfargument name="EventName" type="string" required="false" hint="The name of the event to which this listener would have responded. No action is taken unless this is included.">

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

<cffunction name="injectObserver" access="public" returntype="string" output="no">
	<cfargument name="Component" type="any" required="true">

	<cfset Arguments.Component.setObserver = setObserver>

	<cfset Arguments.Component.setObserver(This)>

</cffunction>

<cffunction name="setObserver" access="public" returntype="string" output="no">
	<cfargument name="Observer" type="any" required="true">

	<cfif NOT StructKeyExists(Variables,"Observer")>
		<cfset Variables.Observer = Arguments.Observer>
		<cfset This.Observer = Arguments.Observer>
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

<cffunction name="loadRequestVars" access="private" returntype="any" output="no" hint="I make sure the needed request variables exist.">
	<cfscript>
	if ( NOT StructKeyExists(request,"Observer") ) {
		request["Observer"] = {};
	}
	if ( NOT StructKeyExists(request["Observer"],"aDelayeds") ) {
		request["Observer"]["aDelayeds"] = [];
	}
	</cfscript>
</cffunction>

<cffunction name="makeListenerCallHash" access="private" returntype="string" output="no">
	<cfargument name="sListener" type="struct" required="true">
	<cfargument name="Args" type="struct" required="false">

	<cfset var result = Arguments.sListener.ListenerName & "." & Arguments.sListener.ListenerMethod & "." & Arguments.sListener.EventName>
	<cfset var sCanonicalArgs = {}>
	<cfset var key = "">

	<cfscript>
	if ( StructKeyExists(Arguments,"Args") AND StructCount(Arguments.Args) ) {
		for ( key in Arguments.Args ) {
			//We don't want to deal with null args
			if ( StructKeyExists(Arguments.Args,key) ) {
				sCanonicalArgs[key] = Arguments.Args[key];
			}
		}
		if ( StructCount(sCanonicalArgs) ) {
			result = result & "." & SerializeJSON(sCanonicalArgs);
		}
	}

	result = Hash(LCase(result));
	</cfscript>

	<cfreturn result>
</cffunction>

</cfcomponent>
