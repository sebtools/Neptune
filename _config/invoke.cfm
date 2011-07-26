<cfparam name="URL.refresh" default="false">
<!---
Framework documentation: http://www.bryantwebconsulting.com/docs/neptune/
--->
<cfif NOT isDefined("Application.Framework") OR ( isDefined("URL.refresh") AND ( URL.refresh EQ true OR ListFindNoCase(URL.refresh,"Framework") ) )>
	<cfinvoke returnvariable="Application.Framework" component="_framework.Framework" method="init">
		<cfinvokeargument name="RootPath" value="#Expandpath('/')#">
		<cfinvokeargument name="scopes" value="request">
	</cfinvoke>
</cfif>
<cfset Application.Framework.loadPage(URL.refresh)>
<cfset FrontController = CreateObject("component","_framework.FrontController").init(CGI,Application.Framework)>
<cfset layout = CreateObject("component","layouts.Default").init(CGI,Application.Framework.Loader)>
