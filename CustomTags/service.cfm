<cfif NOT IsDefined("ThisTag.executionMode")>This must be called as custom tag.<cfabort></cfif>
<cfsilent>

<cfparam name="Attributes.name" default="">
<cfparam name="Attributes.service" default="#Attributes.name#">

	<!--- 1: Check in the attributes of the calling tag --->
	<cfif StructKeyExists(Caller,"Attributes") AND StructKeyExists(Caller.Attributes,Attributes.service) AND isObject(Caller.Attributes[Attributes.service])>
		<cfset Variables.result = Caller.Attributes[Attributes.service]>
	</cfif>

	<!--- 2: Check in Caller scopes (walk up the tree, this could be called be a custom, which could have been called by a custom tag...) --->
	<cfif NOT StructKeyExists(Variables,"result")>
		<cfset MyCaller = Caller>
		<cfscript>
		while ( StructKeyExists(MyCaller,"Caller") AND NOT StructKeyExists(Variables,Attributes.service)  ) {
			MyCaller = MyCaller["Caller"];
			if ( StructKeyExists(MyCaller,Attributes.service) AND isObject(MyCaller[Attributes.service]) ) {
				Variables.Slack = MyCaller[Attributes.service];
			}
		}
		</cfscript>
	</cfif>

	<!--- 3: Ask Service Factory --->
	<cfif NOT StructKeyExists(Variables,"result")>
		<cfif
				StructKeyExists(Caller,"Application")
			AND	StructKeyExists(Application,"ServiceFactory")
			AND	isObject(Application.ServiceFactory)
			AND	StructKeyExists(Application.ServiceFactory,"getService")
			AND	StructKeyExists(Application.ServiceFactory,"hasService")
			AND	Application.ServiceFactory.hasService(Attributes.service)
		>
			<cfset Variables.result = Application.ServiceFactory.getService(Attributes.service)>
		</cfif>
	</cfif>

	<!--- 4: Check in Application scope --->
	<cfif NOT StructKeyExists(Variables,"result")>
		<cfif StructKeyExists(Caller,"Application") AND StructKeyExists(Application,Attributes.service) AND isObject(Application[Attributes.service])>
			<cfset Variables.result = Application[Attributes.service]>
		</cfif>
	</cfif>

	<cfif StructKeyExists(Variables,"result")>
		<cfset Caller[Attributes.name] = Variables.result>
	</cfif>

</cfsilent>
