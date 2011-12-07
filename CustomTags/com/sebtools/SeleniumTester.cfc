<cfcomponent displayname="Selenium" extends="com.sebtools.RecordsTester">

<cffunction name="setUp" access="public" returntype="void" output="no">
	<cfargument name="Browser" type="string" default="*chrome"><!--- *firefox --->
	<cfargument name="BaseURL" type="string" default="http://#CGI.HTTP_HOST#">
	
	<cfset Super.setup()>
	
	<!---<cftry>--->
		<cfset variables.selenium = CreateObject("component", "cfselenium.selenium_tags").init()>
		
		<cfset variables.selenium.start(Arguments.BaseURL,Arguments.Browser)>
	<!---<cfcatch>
		<cfset variables["Selenium"] = CreateObject("java","com.thoughtworks.selenium.DefaultSelenium").init("localhost", 4444, Arguments.Browser, Arguments.BaseURL)>
		<cfset variables.Selenium.start()>
	</cfcatch>
	</cftry>--->

</cffunction>

<cffunction name="tearDown" access="public" returntype="void" output="no">
	
	<cftry>
		<cfset variables.Selenium.close()>
	<cfcatch>
	</cfcatch>
	</cftry>
	
	<cfset variables.Selenium.stop()>
	
	<cftry>
		<cfset variables.selenium.stopServer()>
	<cfcatch>
	</cfcatch>
	</cftry>
	
</cffunction>

<cffunction name="getCookiesStruct" access="public" returntype="struct" output="no">
	
	<cfset var BrowserCookies = Variables.Selenium.getCookie()>
	<cfset var sCookies = StructNew()>
	<cfset var key = "">
	
	<cfloop list="#BrowserCookies#" index="key" delimiters=";">
		<cfset sCookies[Trim(ListFirst(key,"="))] = Trim(ListLast(key,"="))>
	</cfloop>
	
	<cfreturn sCookies>
</cffunction>

<cffunction name="getSessionScope" access="public" returntype="struct" output="no">
	
	<cfset var sResult = StructNew()>
	<cfset var sCookies = getCookiesStruct()>
	<cfset var oSessionTracker = CreateObject("java","coldfusion.runtime.SessionTracker")>  
	<cfset var key = "">
	<cfset var sSessions = oSessionTracker.getSessionCollection(Application.ApplicationName)>
	
	<cfif StructKeyExists(sCookies,"CFID") AND StructKeyExists(sCookies,"CFTOKEN")>
		<cfloop collection="#sSessions#" item="key">
			<cfif key CONTAINS "#sCookies.CFID#_#sCookies.CFTOKEN#">
				<cfreturn sSessions[key]>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfreturn sResult>
</cffunction>

</cfcomponent>