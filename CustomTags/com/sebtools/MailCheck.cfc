<!--- 1.0 Dev 1 --->
<!--- Last Updated: 2011-01-21 --->
<!--- Created by Steve Bryant 2011-01-21 --->
<cfcomponent displayname="Mailer" hint="I handle sending of email notices. The advantage of using Mailer instead of cfmail is that I can be instantiated with information and then passed as an object to a component that sends email, circumventing the need to pass a bunch of email-related information to each component that sends email.">

<cffunction name="init" access="public" returntype="any" output="no" hint="I instantiate and return this object.">
	<cfargument name="MailServer" type="string" default="">
	<cfargument name="username" type="string" default="">
	<cfargument name="password" type="string" default="">
	<!---<cfargument name="mode" type="string" required="false">--->
	
	<cfset variables.MailServer = arguments.MailServer>
	<cfset variables.username = arguments.username>
	<cfset variables.password = arguments.password>
	
	<!---<cfif NOT Len(arguments.MailServer)>
		<cfset arguments.mode = "Sim">
	</cfif>
	
	<cfif NOT StructKeyExists(arguments,"mode")>
		<cfif getMetaData(this).name CONTAINS "Sim">
			<cfset arguments.mode = "Sim">
		<cfelse>
			<cfset arguments.mode = "Live">
		</cfif>
	</cfif>
	
	<cfset setMode(arguments.mode)>--->
	
	<cfreturn This>
</cffunction>

<cffunction name="deleteMessage" access="public" returntype="void" output="no">
	<cfargument name="uid" type="string" required="yes">
	
	<cfpop
		server="#variables.MailServer#"
		username="#variables.username#"
		password="#variables.password#"
		action="delete"
		uid="#arguments.uid#"
	>
	
</cffunction>

<cffunction name="getAll" access="public" returntype="query" output="no">
	<cfargument name="uid" type="string" required="no">
	
	<cfset arguments.action = "getAll">
	
	<cfreturn getMessages(argumentCollection=arguments)>
</cffunction>

<cffunction name="getHeaderOnly" access="public" returntype="query" output="no">
	<cfargument name="uid" type="string" required="no">
	
	<cfset arguments.action = "getHeaderOnly">
	
	<cfreturn getMessages(argumentCollection=arguments)>
</cffunction>

<cffunction name="getMessages" access="public" returntype="query" output="no">
	<cfargument name="action" type="string" default="getAll">
	<cfargument name="uid" type="string" required="no">
	
	<cfset var qMessages = 0>
	
	<cfif StructKeyExists(arguments,"uid")>
		<cfpop name="qMessages" server="#variables.MailServer#" username="#variables.username#" password="#variables.password#" action="#arguments.action#" attachmentPath="mail/" uid="#arguments.uid#">
	<cfelse>
		<cfpop name="qMessages" server="#variables.MailServer#" username="#variables.username#" password="#variables.password#" action="#arguments.action#" attachmentPath="mail/">
	</cfif>
	
	<cfreturn qMessages>
</cffunction>

<!---<cffunction name="setMode" access="public" returntype="void" output="no">
	<cfargument name="mode" type="string" required="yes">
	
	<cfset var SimModes = "Sim,Dev">
	
	<cfif ListFindNoCase(SimModes,arguments.mode)>
		<cfset variables.mode = "Sim">
	<cfelse>
		<cfset variables.mode = "Live">
	</cfif>
	
</cffunction>--->

</cfcomponent>