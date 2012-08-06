<cfcomponent displayname="Observer" output="no">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="Subject" type="any" required="false">
	
	<cfset Variables.sEvents = StructNew()>
	
	<cfif StructKeyExists(Arguments,"Subject")>
		<cfset setSubject(Arguments.Subject)>
	</cfif>
	
	<cfreturn This>
</cffunction>

<cffunction name="notifyEvent" access="public" returntype="void" output="no">
	<cfargument name="EventName" type="string" default="update">
	<cfargument name="Args" type="struct" required="false">
	<cfargument name="result" type="any" required="false">
	
	<cfset var key = "">
	<cfset var ii = 0>
	
	<cfif StructKeyExists(Variables.sEvents,Arguments.EventName) AND ArrayLen(Variables.sEvents[Arguments.EventName])>
		<cfloop index="ii" from="1" to="#ArrayLen(Variables.sEvents[Arguments.EventName])#">
			<cfinvoke
				component="#Variables.sEvents[EventName][ii].Listener#"
				method="#Variables.sEvents[EventName][ii].ListenerMethod#"
				argumentcollection="#Arguments#"
			>
			</cfinvoke>
		</cfloop>
	</cfif>
	
</cffunction>

<cffunction name="register" access="public" returntype="void" output="no">
	<cfargument name="Listener" type="any" required="true">
	<cfargument name="ListenerName" type="string" required="true">
	<cfargument name="ListenerMethod" type="string" default="listen">
	<cfargument name="EventName" type="string" default="update">
	
	<cfset unregister(ArgumentCollection=Arguments)>
	
	<cfif NOT StructKeyExists(Variables.sEvents,Arguments.EventName)>
		<cfset Variables.sEvents[Arguments.EventName] = ArrayNew(1)>
	</cfif>
	
	<cfset ArrayAppend(Variables.sEvents[Arguments.EventName],Arguments)>
	
</cffunction>

<cffunction name="unregister" access="public" returntype="void" output="no">
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