<!--- 1.0 Beta 2 (Build 26) --->
<!--- Last Updated: 2012-08-05 --->
<!--- Information: sebtools.com --->
<cfcomponent>

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="CGI" type="struct" required="yes">
	<cfargument name="Factory" type="any" required="no">
	
	<cfset initInternal(argumentCollection=arguments)>
	
	<cfreturn this>
</cffunction>

<cffunction name="initInternal" access="public" returntype="any" output="no">
	<cfargument name="CGI" type="struct" required="yes">
	<cfargument name="Factory" type="any" required="no">
	
	<cfset variables.CGI = arguments.CGI>
	<cfif StructKeyExists(arguments,"Factory")>
		<cfset variables.Factory = arguments.Factory>
	</cfif>
	
	<cfset variables.SCRIPT_NAME = variables.CGI.SCRIPT_NAME>
	<cfif Len(Trim(variables.CGI.QUERY_STRING))>
		<cfset variables.PageString = "#variables.CGI.SCRIPT_NAME#?#variables.CGI.QUERY_STRING#">
	<cfelse>
		<cfset variables.PageString = "#variables.CGI.SCRIPT_NAME#">
	</cfif>
	<cfset variables.FileName = ListLast(variables.SCRIPT_NAME,"/")>
	<cfset variables.DomainName = variables.CGI.SERVER_NAME>
	
	<cfset variables.me = StructNew()>
	<cfset variables.me.FileName = variables.FileName>
	<cfset variables.me.DomainName = variables.DomainName>
	<cfset variables.me.IncludeLayout = "layout">
	
	<cfset Variables.sThis = getMetaData(This)>
	
	<cfif Variables.sThis.name CONTAINS "Admin" AND ListLast(variables.CGI.SCRIPT_NAME,".") NEQ "cfc">
		<cfset importAdminMenu()>
	</cfif>
	
	<cfreturn this>
</cffunction>

<cffunction name="include" access="public" output="yes"><cfargument name="Page" type="string" required="yes"><cfargument name="VariablesScope" type="struct" required="no"><!--- Direct output feels wrong, but that is out layout components work, and how an include generally performs ---><cfoutput>#getIncludeOutput(argumentCollection=arguments)#</cfoutput></cffunction>

<cffunction name="switchLayout" access="public" returntype="layout" output="no">
	<cfargument name="layout" type="string" required="yes">
	
	<cfset var result = CreateObject("component",layout)>
	
	<cfset result.init(variables.CGI,variables.Factory)>
	
	<cfset result.setMe(variables.me)>
	<cfset this = result>
	
	<cfreturn result>
</cffunction>

<cffunction name="setMe" access="package" returntype="void" output="no">
	<cfargument name="me" type="struct" required="yes">
	
	<cfset StructAppend(variables.me,arguments.me,"no")>

</cffunction>

<cffunction name="getIncludeOutput" access="public" returntype="string" output="no">
	<cfargument name="Page" type="string" required="yes">
	<cfargument name="VariablesScope" type="struct" required="no">
	
	<!---
	I can set the layout variable here without setting it back to what it was because this is a local-scoped variable
	The layout component has built-in empty head/body/end methods.
	Any other output methods should be added to the site's layout.cfc with no output as well.
	--->
	<cfset var layout = switchLayout(variables.me.IncludeLayout)>
	<cfset var result = "">
	<cfset var TemplateHead = "">
	<cfset var sHeadMatch = 0>
	<cfset var PreActions = "">
	
	<!--- Make sure layout tag doesn't show head and body tag as having been called to that it calls them (so that we can get any embedded header code) --->
	<cfif StructKeyExists(request,"sLayoutTag") AND StructKeyExists(request.sLayoutTag,"actions")>
		<cfset PreActions = request.sLayoutTag.actions>
		<cfset request.sLayoutTag.actions = "">
	</cfif>
	
	<cfif Left(arguments.Page,1) NEQ "/">
		<cfset arguments.Page = getPageBrowserPath(arguments.Page,arguments.VariablesScope)>
	</cfif>
	
	<!---
	It is a bit sinful to mess with the entire variables scope of the component here.
	The risk is mitigated because:
		1) The layout component is variables-scoped so the component-wide addition of data will be only for this page.
		2) The third argument is "no", so essential variables will not be over-written
	This is here so that the included page can still reference variables scoped variables without scoping them.
	--->
	<cfif StructKeyExists(arguments,"VariablesScope")>
		<cfset StructAppend(variables,arguments.VariablesScope,"no")>
	</cfif>
	
	<!--- This is the main work. Putting it in cfsavecontent breaks cfflush, but allows us to put the header information in the correct place --->
	<cfsavecontent variable="result"><cfoutput><cfinclude template="#arguments.Page#"></cfoutput></cfsavecontent>
	
	<!--- Fix the header information --->
	<cfset sHeadMatch = ReFindNoCase("<head>.*?</head>",result,1,1)>
	<cfif StructCount(sHeadMatch) AND sHeadMatch.pos[1] AND sHeadMatch.len[1]>
		<cfset TemplateHead = Mid(result,sHeadMatch.pos[1],sHeadMatch.len[1])>
		<cfset result = ReplaceNoCase(result,TemplateHead,"")>
		
		<cfset TemplateHead = Trim(REReplaceNoCase(TemplateHead, "</?head>", "", "ALL"))>
		<cfif Len(Trim(TemplateHead))>
			<cfhtmlhead text="#TemplateHead#">
		</cfif>
	</cfif>
	
	<cfif Len(PreActions)>
		<cfset request.sLayoutTag.actions = PreActions>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="importAdminMenu" access="private" returntype="void" output="no">
	
	<cfif
			StructKeyExists(variables,"Factory")
		AND	StructKeyExists(variables.Factory,"Framework")
		AND	StructKeyExists(variables.Factory.Framework,"getProgramLinksArray")
	>
		<cfset variables.AdminMenu = variables.Factory.Framework.getProgramLinksArray()>
	<cfelse>
		<cfset importAdminMenuOld()>
	</cfif>
	
</cffunction>

<cffunction name="importAdminMenuOld" access="private" returntype="void" output="no">
	
	<cfset var xProgram = variables.Factory.Config.getSetting('ProgramMenu')>
	<cfset var aAdminMenu = ArrayNew(1)>
	<cfset var ii = 0>
	<cfset var jj = 0>
	
	<cfif StructKeyExists(xProgram.site,"program")>
		<cfloop index="ii" from="1" to="#ArrayLen(xProgram.site.program)#" step="1">
			<cfset ArrayAppend(aAdminMenu,StructNew())>
			<cfset aAdminMenu[ArrayLen(aAdminMenu)]["Link"] = xProgram.site.program[ii].XmlAttributes["path"]>
			<cfset aAdminMenu[ArrayLen(aAdminMenu)]["Label"] = xProgram.site.program[ii].XmlAttributes["name"]>
			<cfset aAdminMenu[ArrayLen(aAdminMenu)]["pages"] = "">
			<cfset aAdminMenu[ArrayLen(aAdminMenu)]["Folder"] = xProgram.site.program[ii].XmlAttributes["path"]>
			<cfset aAdminMenu[ArrayLen(aAdminMenu)]["items"] = ArrayNew(1)>
			<cfset aAdminMenu[ArrayLen(aAdminMenu)]["inTabs"] = true>
			<cfif StructKeyExists(xProgram.site.program[ii],"link")>
				<cfloop index="jj" from="1" to="#ArrayLen(xProgram.site.program[ii].link)#" step="1">
					<cfset ArrayAppend(aAdminMenu[ArrayLen(aAdminMenu)]["items"],StructNew())>
					<cfset aAdminMenu[ArrayLen(aAdminMenu)]["items"][jj]["Link"] = xProgram.site.program[ii].link[jj].XmlAttributes["url"]>
					<cfset aAdminMenu[ArrayLen(aAdminMenu)]["items"][jj]["Label"] = xProgram.site.program[ii].link[jj].XmlAttributes["label"]>
					<cfset aAdminMenu[ArrayLen(aAdminMenu)]["items"][jj]["pages"] = "">
					<cfset aAdminMenu[ArrayLen(aAdminMenu)]["items"][jj]["folder"] = xProgram.site.program[ii].XmlAttributes["path"]>
				</cfloop>
			</cfif>
		</cfloop>
	</cfif>
	<cfset variables.AdminMenu = aAdminMenu>
	
</cffunction>

<cffunction name="getPageBrowserPath" access="private" returntype="string" output="no">
	<cfargument name="Page" type="string" required="true">
	<cfargument name="VariablesScope" type="struct" required="true">
	
	<cfset var PathFile = "">
	<cfset var PathRoot = "">
	<cfset var result = "">
	
	<cftry>
		<cfset PathFile = getDirectoryFromPath(getScopeTemplatePath(arguments.VariablesScope))>
	<cfcatch>
		<cfset PathFile = getDirectoryFromPath(ExpandPath(Arguments.Page))>
	</cfcatch>
	</cftry>
	<cfset result = PathFile>
	
	<cfif StructKeyExists(variables,"Factory") AND StructKeyExists(variables.Factory,"Config") AND variables.Factory.Config.exists('RootPath')>
		<cfset PathRoot = variables.Factory.Config.getSetting('RootPath')>
	<cfelse>
		<cfset PathRoot = ExpandPath("/")>
	</cfif>
	<cfset result = ReplaceNoCase(PathFile,PathRoot,"")>
	<cfset result = ListChangeDelims(result,"/","\")>
	<cfset result = ListAppend(result,arguments.Page,"/")>
	<cfset result = "/#result#">
	
	<cfreturn result>
</cffunction>
<cffunction name="getScopeTemplatePath" access="private" returntype="string" output="no">
	<cfargument name="VariablesScope" type="struct" required="true">
	<cfscript>
	var field = getMetaData(arguments.VariablesScope).getDeclaredField("pageContext");
	field.setAccessible(true);
	return field.get(arguments.VariablesScope).getPage().getCurrentTemplatePath();
	</cfscript>
</cffunction>

<cfscript>
/** http://www.elliottsprehn.com/blog/2007/07/17/getting-the-expected-results-for-getcurrenttemplatepath-in-a-custom-tag/ */
/** Gets the path to the page that called this custom tag. */
function getCallerTemplatePath() {
	var field = getMetaData(Caller).getDeclaredField("pageContext");
	field.setAccessible(true);
	return field.get(caller).getPage().getCurrentTemplatePath();
}
</cfscript>

<cffunction name="head" access="public" output="yes"><head></cffunction>
<cffunction name="body" access="public" output="yes"></head></cffunction>
<cffunction name="end" access="public" output="yes"></cffunction>

</cfcomponent>