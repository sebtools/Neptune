<!--- 1.0 Beta 2 (Build 26) --->
<!--- Last Updated: 2012-08-05 --->
<!--- Information: sebtools.com --->
<cfcomponent output="false">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="CGI" type="struct" required="yes">
	<cfargument name="Framework" type="any" required="yes">
	<cfargument name="Proxy" type="any" required="no">
	
	<cfif StructKeyExists(arguments,"CGI")>
		<cfset variables.CGI = arguments.CGI>
	</cfif>
	<cfset variables.Framework = arguments.Framework>
	<cfset variables.Factory = variables.Framework.Loader>
	<cfif StructKeyExists(arguments,"Proxy")>
		<cfset variables.Proxy = arguments.Proxy>
	</cfif>
	
	<cfset variables.isPageControllerLoaded = false>
	<cfset variables.RootPath = variables.Framework.Config.getSetting("RootPath")>
	
	<cfset variables.instance = variables>
	
	<cfreturn this>
</cffunction>

<cffunction name="call" access="public" returntype="any" output="false" hint="">
	<cfargument name="component" type="string" required="yes">
	<cfargument name="method" type="string" required="yes">
	
	<cfreturn variables.Framework.call(argumentCollection=arguments)>
	
</cffunction>

<cffunction name="loadPage" access="public" returntype="void" output="no">
	
	<cfset variables.Framework.loadPage(URL.refresh)>
	
</cffunction>

<cffunction name="loadPageController" access="public" returntype="any" output="no">
	<cfargument name="vars" type="struct" required="true">
	<cfargument name="SCRIPT_NAME" type="string" required="true">
	<cfargument name="reload" type="boolean" default="false">
	
	<cfif arguments.reload OR NOT ( StructKeyExists(variables,"isPageControllerLoaded") AND variables.isPageControllerLoaded )>
		<cfset arguments.vars.Controller = getPageController(arguments.SCRIPT_NAME)>
		<cfset arguments.vars.PageController = arguments.vars.Controller>
		<cfset StructAppend(arguments.vars,arguments.vars.Controller.loadData(arguments.vars))>
	</cfif>
	
	<cfset variables.isPageControllerLoaded = true>
	
	<cfreturn arguments.vars.PageController>
</cffunction>

<cffunction name="getPageController" access="private" returntype="any" output="no">
	<cfargument name="SCRIPT_NAME" type="string" required="true">
	
	<cfreturn variables.Framework.getPageController(arguments.SCRIPT_NAME)>
</cffunction>

<cffunction name="getPageController_BAK" access="private" returntype="any" output="no">
	<cfargument name="SCRIPT_NAME" type="string" required="true">
	
	<cfset var ScriptName = arguments.SCRIPT_NAME>
	<cfset var CompPath = "">
	<cfset var result = "">
	
	<!---<cfif NOT StructKeyExists(variables,"PageController")>--->
		<cfif Left(CompPath,Len(variables.instance.RootPath)) EQ variables.instance.RootPath>
			<cfset ScriptName = ReplaceNoCase(ScriptName,variables.Framework.Config.getSetting("RootPath"),"")>
		</cfif>
		
		<cfset ScriptName = ListChangeDelims(ScriptName,"/","\")>
		
		<cfif NOT Left(ScriptName,1) EQ "/">
			<cfset ScriptName = "/#ScriptName#">
		</cfif>
		
		<!--- Remove file extension --->
		<cfif ListLen(ScriptName,".") GT 1>
			<cfset CompPath = reverse(ListRest(reverse(ScriptName),"."))>
		<cfelse>
			<cfset CompPath = ScriptName>
		</cfif>
		<!--- Change from browser path to component path --->
		<cfset CompPath = ListChangeDelims(CompPath,".","/")>
		
		<cfif Left(CompPath,1) EQ "."><cfset CompPath = Right(CompPath,Len(CompPath)-1)></cfif>
		<cfif Right(CompPath,1) EQ "."><cfset CompPath = Left(CompPath,Len(CompPath)-1)></cfif>
		
		<cfif StructKeyExists(variables,"Proxy")>
			<cfset result = variables.Proxy.createComponent(CompPath)>
		<cfelse>
			<cfset result = CreateObject("component",CompPath)>
		</cfif>
	<!---</cfif>--->
	
	<cfreturn result>
</cffunction>

</cfcomponent>