<!--- 1.0 Beta 2 (Build 26) --->
<!--- Last Updated: 2012-08-05 --->
<!--- Information: sebtools.com --->
<!--- Created by Steve Bryant 2007-06-27 --->
<cfcomponent output="false">

<cffunction name="init" access="Public" returnType="Framework" output="false" hint="I return the Framework component.">
	<cfargument name="RootPath" type="string" required="yes" hint="the root file path of the site.">
	<cfargument name="scopes" type="string" required="yes" hint="Any scopes to shich configuration data should be copied.">
	<cfargument name="ConfigFolder" default="/_config/" hint="The folder holding site-wide configuration data.">
	<cfargument name="ComponentsFile" default="components.cfm" hint="The file (in the config folder) holding component data.">
	<cfargument name="vars" type="struct" required="false">
	<cfargument name="Proxy" type="any" required="false">
	<cfargument name="ExcludeDirs" type="string" required="false">
	
	<cfset variables.CFServer = Server.ColdFusion.ProductName>
	<cfset variables.CFVersion = ListFirst(Server.ColdFusion.ProductVersion)>
	
	<cfset variables.dirdelim = CreateObject("java", "java.io.File").separator>
	
	<cfset variables.instance = StructNew()>
	
	<cfset variables.instance["RootPath"] = arguments.RootPath>
	<cfset variables.instance["Hash"] = Hash(arguments.RootPath)>
	<cfset variables.instance["scopes"] = arguments.scopes>
	<cfset variables.instance["dirdelim"] = variables.dirdelim>
	<cfset variables.instance["programs"] = StructNew()>
	<cfset variables.instance["ProgramFilePaths"] = "">
	<cfset variables.instance["PathServices"] = StructNew()>
	<cfset variables.instance["NoPathServices"] = StructNew()>
	<cfif StructKeyExists(arguments,"Proxy")>
		<cfset variables.instance["Proxy"] = arguments.Proxy>
	</cfif>
	<cfif StructKeyExists(arguments,"ExcludeDirs")>
		<cfset variables.instance["ExcludeDirs"] = arguments.ExcludeDirs>
	</cfif>
	
	<!--- Config Process --->
	<cfset variables.instance["ConfigFolder"] = arguments.ConfigFolder>
	<cfset variables.instance["ConfigFolderPath"] = variables.instance["RootPath"] & variables.instance["dirdelim"] & ReplaceNoCase(variables.instance.ConfigFolder,"/",variables.instance.dirdelim,"ALL")>
	<cfscript>
	//Remove extra folder delimeters from config folder path
	while ( FindNoCase("#variables.instance.dirdelim##variables.instance.dirdelim#",variables.instance["ConfigFolderPath"]) ) {
		variables.instance["ConfigFolderPath"] = ReplaceNoCase(variables.instance["ConfigFolderPath"],"#variables.instance.dirdelim##variables.instance.dirdelim#",variables.instance.dirdelim,"ALL");
	}
	</cfscript>
	<cfinvoke
		returnvariable="this.Config"
		component="Config"
		method="init"
	>
		<cfinvokeargument name="scopes" value="#Arguments.scopes#">
		<cfinvokeargument name="RootPath" value="#variables.instance.RootPath#">
		<cfinvokeargument name="dirdelim" value="#variables.instance.dirdelim#">
		<cfif StructKeyExists(arguments,"Proxy")>
			<cfinvokeargument name="Proxy" value="#variables.instance.Proxy#">
		</cfif>
	</cfinvoke>
	
	<!--- Loader Process --->
	<cfset variables.instance["ComponentsFile"] = arguments.ComponentsFile>
	<cfset variables.instance["ComponentsFilePath"] = variables.instance["ConfigFolderPath"] & variables.instance["ComponentsFile"]>
	
	<!--- Make sure programlinks.cfm exists --->
	<cfset registerLinks()>
	
	<!--- Make programs.cfm --->
	<cfset makeProgramsFile()>
	
	<!--- Make udfs.cfm --->
	<cfif NOT FileExists("#variables.instance.ConfigFolderPath#udf.cfm")>
		<cffile action="write" file="#variables.instance.ConfigFolderPath#udf.cfm" output="">
	</cfif>
	
	<!--- Make /_config/PageController.cfc --->
	<cfset makeConfigPageControllerFile()>
	<cfset makeConfigProgramFile()>
	
	<cfset variables.Config = This.Config>
	<cfset variables.Framework = This>
	<cfif StructKeyExists(arguments,"Proxy")>
		<cfset variables.instance["Proxy"].setConfig(variables.Config)>
		<cfset variables.instance["Proxy"].setFramework(variables.Framework)>
	</cfif>
	
	<!---<cfset this.Config.runConfigFiles("#variables.instance.ConfigFolder#config.cfm")>--->
	
	<!--- Only way to preserve Loader Arguments state across reload of Loader so that it doesn't force reload of all components --->
	<cfif StructKeyExists(Application,"Framework") AND StructKeyExists(Application.Framework,"Loader")>
		<cfset request.Apploader_Args = Application.Framework.Loader.getArgs()>
	</cfif>
	
	<cfset This["getDirectoryList"] = getMyDirectoryList>
	
	<cfreturn This>
</cffunction>

<cffunction name="call" access="public" returntype="any" output="false" hint="">
	<cfargument name="component" type="string" required="yes">
	<cfargument name="method" type="string" required="yes">
	
	<cfset var sArgs = arguments>
	<cfset var result = 0>
	<cfset var comp = arguments.component>
	<cfset var meth = arguments.method>
	
	<cfset StructDelete(sArgs,"component")>
	<cfset StructDelete(sArgs,"method")>
	
	<cfif StructKeyExists(This.Loader,comp) AND isObject(This.Loader[comp]) AND StructKeyExists(This.Loader[comp],meth)>
		<cfinvoke
			returnvariable="result"
			component="#This.Loader[comp]#"
			method="#meth#"
			argumentCollection="#sArgs#"
		>
		</cfinvoke>
		
		<cfif isDefined("result")>
			<cfreturn result>
		</cfif>
	</cfif>
	
</cffunction>

<cffunction name="loadLoader" access="public" returntype="boolean" output="no">
	
	<cfset var doLoad = false>
	<cfset var qFiles = 0>
	<cfset var sLoaderArgs = StructNew()>
	
	<!--- Determine if Loader needs to be created --->
	<!--- Load should be created if it doesn't exist of if the file has been updated since it was last created --->
	<cfif NOT ( StructKeyExists(this,"Loader") AND StructKeyExists(variables.instance,"LoaderLoaded") AND isDate(variables.instance.LoaderLoaded) )>
		<cfset doLoad = true>
	<cfelse>
		<!--- <cfdirectory name="qFiles" action="list" directory="#variables.instance.ConfigFolderPath#" filter="#variables.instance.ComponentsFile#"> --->
		<cfset qFiles = getMyDirectoryList(directory="#variables.instance.ConfigFolderPath#",filter="#variables.instance.ComponentsFile#")>
		
		<cfif qFiles.DateLastModified GT variables.instance.LoaderLoaded>
			<cfset doLoad = true>
		</cfif>
	</cfif>
	
	<!--- If Loader should be created, create it and remember when it was created --->
	<cfif doLoad>
		<cfset sLoaderArgs["XmlFilePath"] = variables.instance.ComponentsFilePath>
		<cfif StructKeyExists(variables.instance,"Proxy")>
			<cfset sLoaderArgs["Proxy"] = variables.instance.Proxy>
		</cfif>
		<cfset this.Loader = CreateObject("component","AppLoader").init(argumentCollection=sLoaderArgs)>
		<cfset this.Loader.Config = this.Config>
		<cfset this.Loader["Framework"] = This>
		
		<cfset variables.instance.LoaderLoaded = now()>
	</cfif>
	
	<cfreturn doLoad>
</cffunction>

<cffunction name="getSpecialService" access="public" returntype="any" output="no">
	<cfargument name="type" type="string" required="no">
	
	<cfif hasSpecialService(arguments.type)>
		<cfreturn This.Loader.getSpecialService(arguments.type)>
	</cfif>
</cffunction>

<cffunction name="hasSpecialService" access="public" returntype="boolean" output="no">
	<cfargument name="type" type="string" required="no">
	
	<cfreturn This.Loader.hasSpecialService(arguments.type)>
</cffunction>

<cffunction name="loadConfigSettings" access="private" returntype="string" output="no">
	
	<cfset var configvars = this.Config.getSettings()>
	<cfset var configkey = "">
	<cfset var result = "">
	
	<cfinvoke returnvariable="result" component="#this.Loader#" method="setArgs">
		<cfloop collection="#configvars#" item="configkey">
			<cfinvokeargument name="#configkey#" value="#configvars[configkey]#">
		</cfloop>
	</cfinvoke>
	
	<cfreturn result>
</cffunction>

<cffunction name="loadPage" access="public" returntype="void" output="no" hint="I load the necessary information for a page to run (run on every request).">
	<cfargument name="refresh" type="string" required="yes">
	
	<cfset var isAnyProgramRegistered = false>
	<cfset var isLocalProgramRegistered = false>
	<cfset var isRegistrationPerformed = false>
	<cfset var doLoad = false>
	<cfset var oPageController = 0>
	<cfset var ChangedSettings = "">

	<!--- Initialization --->
	<cfset this.Config.runConfigFiles("#variables.instance.ConfigFolder#config.cfm")>
	
	<!--- Registration --->
	<!--- If any components are being refreshed, check for changes to XML --->
	<cfset doLoad = loadLoader()>
	<cfif
			doLoad
		OR	( Len(arguments.refresh) AND arguments.refresh NEQ false )
	>
		<cfset ChangedSettings = loadConfigSettings()>
		<cfset isAnyProgramRegistered = registerAllPrograms(false)>
	</cfif>
	<cfset isLocalProgramRegistered = registerProgram(GetDirectoryFromPath(GetBaseTemplatePath()))>
	
	<cfif isAnyProgramRegistered OR isLocalProgramRegistered>
		<cfset isRegistrationPerformed = true>
	</cfif>
	
	<!--- Configuration --->
	<cfset runConfigFiles()>
	<cfset runConfigProgramLinks()>
	<!---<cfif isRegistrationPerformed>--->
		<cfset ChangedSettings = ListAppend(
			ChangedSettings,
			loadConfigSettings()
		)>
	<!---</cfif>--->
	<cfset this.Config.loadSettings()>
	
	<!--- Component Creation --->
	<!---<cftry>--->
		<!---<cfcatch>
			<cfset registerAllPrograms(true)>
			<cfinvoke component="#this.Loader#" method="load">
				<cfinvokeargument name="refresh" value="#arguments.refresh#">
			</cfinvoke>
		</cfcatch>	
	</cftry>--->
	<cfif doLoad OR arguments.refresh NEQ false OR Len(ChangedSettings)>
		
		<cfinvoke component="#this.Loader#" method="load">
			<cfinvokeargument name="refresh" value="#arguments.refresh#">
			<!---<cfinvokeargument name="ChangedSettings" value="#ChangedSettings#">--->
		</cfinvoke>
		
		<cfset variables.instance["PathServices"] = StructNew()>
		<cfset variables.instance["NoPathServices"] = StructNew()> 
		
		<cfif This.Loader.hasSpecialService("Security")>
			<cfset variables.oSecurity = This.Loader.getSpecialService("Security")>
			<cfif StructKeyExists(Variables,"Security_Permissions")>
				<cfset Security_AddPermissions(Variables.Security_Permissions)>
				<cfset StructDelete(Variables,"Security_Permissions")>
			</cfif>
		</cfif>
	</cfif>
	
</cffunction>

<cffunction name="loadPageController" access="public" returntype="any" output="no">
	<cfargument name="vars" type="struct" required="true">
	<cfargument name="path" type="string" required="true">
	<cfargument name="reload" type="boolean" default="false">
	
	<cfset var key = "">
	<cfset var sData = 0>
	
	<cfif arguments.reload OR NOT ( StructKeyExists(request.cf_PageController,"isPageControllerLoaded") AND request.cf_PageController.isPageControllerLoaded )>
		<cfset arguments.vars.Controller = getPageController(path=arguments.path,Caller=Arguments.vars)>
		<cfset arguments.vars.PageController = arguments.vars.Controller>
		
		<cfif StructKeyExists(arguments.vars.Controller,"loadData")>
			<cfset sData = arguments.vars.Controller.loadData(arguments.vars)>
			<cfif
					isStruct(sData) AND StructCount(sData)
			>
				<cfloop collection="#sData#" item="key">
					<cfif isSimpleValue(key) AND Len(Trim(key)) AND ListLen(key,".") EQ 1>
						<cfset arguments.vars["#key#"] = sData[key]>
					</cfif>
				</cfloop>
			</cfif>
		</cfif>
	</cfif>
	
	<cfset request.cf_PageController.isPageControllerLoaded = true>
	
	<cfreturn arguments.vars.PageController>
</cffunction>

<cffunction name="da"><cfdump var="#arguments[1]#"><cfabort></cffunction>

<cfscript>
function hasPageController(path) {
	
	var ControllerFilePath = "";
	var RootPath = variables.instance.RootPath;
	
	//Copy path to ControllerFilePath
	ControllerFilePath = arguments.path;
	
	//Change file extension to .cfc
	if ( ListLen(ListLast(ListLast(ControllerFilePath,"/"),"\"),".") GT 1 ) {
		ControllerFilePath = reverse(ListRest(reverse(ControllerFilePath),"."));
	}
	ControllerFilePath = "#ControllerFilePath#.cfc";
	
	//Make sure ControllerFilePath is a valid file path
	if ( NOT isValidFilePath(ControllerFilePath) ) {
		if ( Left(ControllerFilePath,1) EQ "/" ) {
			ControllerFilePath = ReplaceNoCase(ControllerFilePath,"/",RootPath,"ONE");
		} else {
			ControllerFilePath = getDirectoryFromPath(getBaseTemplatePath()) & arguments.path;
			if ( ListLast(ControllerFilePath,".") NEQ "cfc" ) {
				ControllerFilePath = "#ControllerFilePath#.cfc";;
			}
		}
	}
	
	return FileExists(ControllerFilePath);
}
function getPageControllerCompPath(path) {
	var CompPath = path;
	var RootPath = variables.instance.RootPath;
	
	if ( hasPageController(path) ) {
		if ( Left(CompPath,Len(RootPath)) EQ RootPath ) {
			CompPath = ReplaceNoCase(CompPath,RootPath,"");
		}
		
		CompPath = ListChangeDelims(CompPath,"/","\");
		
		if ( ListLen(CompPath,".") GT 1 ) {
			CompPath = reverse(ListRest(reverse(CompPath),"."));// Remove file extension
		}
		
		CompPath = ListChangeDelims(CompPath,".","/");// Change from browser path to component path
	} else {
		CompPath = "_config.PageController";
	}
	
	return CompPath;
}
function getPageController(path) {
	
	var oPageController = 0;
	var CompPath = path;
	var check = true;
	var sArgs = StructNew();
	
	if ( ArrayLen(arguments) GTE 2 AND isSimpleValue(arguments[2]) AND arguments[2] IS false ) {
		check = false;
	}
	
	CompPath = getPageControllerCompPath(path);
	
	oPageController = CreateObject("component",CompPath);
	sArgs["path"] = getBrowserPath(path);
	sArgs["Framework"] = This;
	sArgs["check"] = check;
	if ( StructKeyExists(Arguments,"Caller") ) {
		sArgs["Caller"] = Arguments.Caller;
	}
	if ( StructKeyExists(oPageController,"init") ) {
		oPageController = oPageController.init(ArgumentCollection=sArgs);
	}
	
	return oPageController;
}
</cfscript>

<cffunction name="checkRefresh" access="public" returntype="boolean" output="no">
	<cfargument name="components" type="string" required="yes">
	<cfargument name="refresh" type="string" required="yes">
	
	<cfreturn this.Loader.checkRefresh(argumentCollection=arguments)>
</cffunction>

<cffunction name="getBrowserPath" access="public" returntype="string" output="no">
	<cfargument name="FilePath" type="string" required="yes">
	
	<cfset var result = ReplaceNoCase(arguments.FilePath,variables.instance.RootPath,"")>
	
	<!--- Browser paths are always "/", regardless of OS --->
	<cfset result = ListChangeDelims(result,"/","\")>
	
	<!--- Make sure browser path starts and ends with "/" --->
	<cfif Left(result,1) NEQ "/">
		<cfset result = "/#result#">
	</cfif>
	<cfif Right(arguments.FilePath,1) EQ variables.instance["dirdelim"] AND Right(result,1) NEQ "/">
		<cfset result = "#result#/">
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getComponentPath" access="public" returntype="string" output="no">
	<cfargument name="FilePath" type="string" required="yes">
	
	<cfset var result = ReplaceNoCase(arguments.FilePath,variables.instance.RootPath,"")>
	
	<!--- Change any path delimiters to dots --->
	<cfset result = ListChangeDelims(result,"/","\")>
	<cfset result = ListChangeDelims(result,".","/")>
	
	<!--- Make sure result doesn't start with a dot --->
	<cfif Left(result,1) EQ ".">
		<cfset result = Right(result,Len(result)-1)>
	</cfif>
	<!--- Make sure result ends with a dot (if it has anything in it) --->
	<cfif Len(result) AND Right(result,1) NEQ ".">
		<cfset result = "#result#.">
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getFilePathFromBrowserPath" access="public" returntype="string" output="no">
	<cfargument name="BrowserPath" type="string" required="yes">
	
	<cfset var result = arguments.BrowserPath>
	
	<!--- Change to file dirdelim --->
	<cfif variables.instance.dirdelim NEQ "/">
		<cfset result = ListChangeDelims(result,variables.instance.dirdelim,"/")>
	</cfif>
	
	<cfset result = variables.instance.RootPath & result>
	
	<cfif Right(result,1) NEQ variables.instance.dirdelim>
		<cfset result = "#result##variables.instance.dirdelim#">
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getProgramLinksArray" access="public" returntype="array" output="no">
	<cfargument name="Program" type="string" required="false">
	
	<cfset var aResults = Duplicate(This.Config.getSetting("Framework_aProgramLinks"))>
	<cfset var ff = 0>
	<cfset var ii = 0>
	<cfset var PageURL = "">
	<cfset var selected = 0>
	<cfset var isInPermissions = 0>
	<cfset var isInPageAccess = 0>
	
	<cfloop index="ff" from="#ArrayLen(aResults)#" to="1" step="-1">
		<cfset isInPermissions = hasPermissions(aResults[ff].permissions)>
		<cfset isInPageAccess = hasPageAccess(aResults[ff].Link)>
		<cfif isInPermissions AND isInPageAccess>
			<cfloop index="ii" from="#ArrayLen(aResults[ff].items)#" to="1" step="-1">
				<cfset PageURL = aResults[ff].items[ii].Link>
				<cfif NOT PageURL CONTAINS "/">
					<cfset PageURL = "#aResults[ff].items[ii].folder##PageURL#">
				</cfif>
				<cfif NOT hasPageAccess(PageURL)>
					<cfset ArrayDeleteAt(aResults[ff].items,ii)>
				</cfif>
			</cfloop>
		<cfelse>
			<cfset ArrayDeleteAt(aResults,ff)>
		</cfif>
	</cfloop>
	
	<cfif StructKeyExists(arguments,"program") AND Len(arguments.program)>
		<cfloop index="ff" from="#ArrayLen(aResults)#" to="1" step="-1">
			<cfif aResults[ff].name EQ arguments.program>
				<cfreturn aResults[ff].items>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfreturn aResults>
</cffunction>

<cffunction name="createLink" access="public" returntype="string" output="no">
	<cfargument name="path" type="string" required="yes">
	<cfargument name="text" type="string" required="yes">
	<cfargument name="ScriptName" type="string" required="no">
	
	<cfset var result = "">
	
	<cfif hasPageAccess(argumentCollection=arguments)>
		<cfset result = '<a href="#arguments.path#">#arguments.text#</a>'>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="createListLink" access="public" returntype="string" output="no">
	<cfargument name="path" type="string" required="yes">
	<cfargument name="text" type="string" required="yes">
	<cfargument name="ScriptName" type="string" required="no">
	
	<cfset var result = createLink(argumentCollection=arguments)>
	
	<cfif Len(result)>
		<cfset result = '<li>#result#</li>'>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="hasPageAccess" access="public" returntype="boolean" output="no">
	<cfargument name="path" type="string" required="yes">
	<cfargument name="ScriptName" type="string" required="no">
	
	<cfset var oPageController = 0>
	<cfset var sURL = Duplicate(URL)>
	<cfset var result = true>
	
	<cfscript>
	if ( StructKeyExists(arguments,"ScriptName") AND NOT arguments.path CONTAINS "/" ) {
		arguments.path = ListAppend(
			ListDeleteAt(
				arguments.ScriptName,
				ListLen(arguments.ScriptName,"/"),
				"/"
			),
			arguments.path,
			"/"
		);
	}
	</cfscript>
	
	<cfif Right(Arguments.path,1) EQ "/">
		<cfset Arguments.path = "#Arguments.path#index.cfm">
	</cfif>
	<!---<cfset URL = QueryString2Struct(ListRest(arguments.path,"?"))>--->
	<cfset Arguments.path = ListFirst(Arguments.path,"?")>
	
	<cfif hasPageController(Arguments.path)>
		<cfset oPageController = getPageController(Arguments.path,false)>
		
		<cfif StructKeyExists(oPageController,"hasAccess")>
			<cfset result = oPageController.hasAccess()>
		</cfif>
	<cfelse>
		<cfset oPageController = CreateObject("component","_config.PageController")>
		<cfset result = oPageController.hasAccess()>
	</cfif>
	
	<!---<cfset URL = sURL>--->
	
	<cfreturn result>
</cffunction>

<cffunction name="hasPermissions" access="public" returntype="boolean" output="no">
	<cfargument name="permissions" type="string" required="yes">
	
	<cfset var result = true>
	<cfset var oSecurity = 0>
	
	<cfif Len(arguments.permissions) AND hasSpecialService("Security")>
		<cfset oSecurity = getSpecialService("Security")>
		<cfif StructKeyExists(oSecurity,"checkUserAllowed")>
			<cfset result = oSecurity.checkUserAllowed(arguments.permissions)>
		</cfif>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getProgramLinksArrayInternal" access="private" returntype="array" output="no">
	
	<cfset var xProgram = 0>
	<cfset var aAdminMenu = ArrayNew(1)>
	<cfset var ii = 0>
	<cfset var jj = 0>
	<cfset var key = 0>
	
	<cflock name="#Application.ApplicationName#_ProgramMenu" timeout="30">
		<cfset xProgram = Duplicate(This.Config.getSetting('Framework_xProgramMenu'))>
	</cflock>
	
	<cfif StructKeyExists(xProgram,"site") AND StructKeyExists(xProgram.site,"program")>
		<cfloop index="ii" from="1" to="#ArrayLen(xProgram.site.program)#" step="1">
			<cfset ArrayAppend(aAdminMenu,StructNew())>
			<cfloop collection="#xProgram.site.program[ii].XmlAttributes#" item="key">
				<cfif StructKeyExists(xProgram.site.program[ii].XmlAttributes,key)>
					<cfset aAdminMenu[ArrayLen(aAdminMenu)][key] = xProgram.site.program[ii].XmlAttributes[key]>
				</cfif>
			</cfloop>
			<cfset aAdminMenu[ArrayLen(aAdminMenu)]["Link"] = xProgram.site.program[ii].XmlAttributes["path"]>
			<cfset aAdminMenu[ArrayLen(aAdminMenu)]["Label"] = xProgram.site.program[ii].XmlAttributes["name"]>
			<cfset aAdminMenu[ArrayLen(aAdminMenu)]["permissions"] = "">
			<cfif StructKeyExists(xProgram.site.program[ii].XmlAttributes,"permissions")>
				<cfset aAdminMenu[ArrayLen(aAdminMenu)]["permissions"] = xProgram.site.program[ii].XmlAttributes["permissions"]>
				<cfset Security_AddPermissions(aAdminMenu[ArrayLen(aAdminMenu)]["permissions"])>
			</cfif>
			<cfset aAdminMenu[ArrayLen(aAdminMenu)]["pages"] = "">
			<cfif StructKeyExists(xProgram.site.program[ii].XmlAttributes,"pages")>
				<cfset aAdminMenu[ArrayLen(aAdminMenu)]["pages"] = xProgram.site.program[ii].XmlAttributes["pages"]>
			</cfif>
			<cfset aAdminMenu[ArrayLen(aAdminMenu)]["Folder"] = xProgram.site.program[ii].XmlAttributes["path"]>
			<cfset aAdminMenu[ArrayLen(aAdminMenu)]["items"] = ArrayNew(1)>
			<cfset aAdminMenu[ArrayLen(aAdminMenu)]["inTabs"] = true>
			<!---<cftry>--->
				<cfif StructKeyExists(xProgram.site.program[ii],"link")>
					<cfloop index="jj" from="1" to="#ArrayLen(xProgram.site.program[ii].link)#" step="1">
						<cfif StructKeyExists(xProgram.site.program[ii].link[jj].XmlAttributes,"url")>
							<cfset ArrayAppend(aAdminMenu[ArrayLen(aAdminMenu)]["items"],StructNew())>
							<cfloop collection="#xProgram.site.program[ii].link[jj].XmlAttributes#" item="key">
								<cfif StructKeyExists(xProgram.site.program[ii].link[jj].XmlAttributes,key)>
									<cfset aAdminMenu[ArrayLen(aAdminMenu)]["items"][jj][key] = xProgram.site.program[ii].link[jj].XmlAttributes[key]>
								</cfif>
							</cfloop>
							<cfset aAdminMenu[ArrayLen(aAdminMenu)]["items"][jj]["Link"] = xProgram.site.program[ii].link[jj].XmlAttributes["url"]>
							<cfset aAdminMenu[ArrayLen(aAdminMenu)]["items"][jj]["Label"] = xProgram.site.program[ii].link[jj].XmlAttributes["label"]>
							<cfset aAdminMenu[ArrayLen(aAdminMenu)]["items"][jj]["pages"] = "">
							<cfif StructKeyExists(xProgram.site.program[ii].link[jj].XmlAttributes,"pages")>
								<cfset aAdminMenu[ArrayLen(aAdminMenu)]["items"][jj]["pages"] = xProgram.site.program[ii].link[jj].XmlAttributes["pages"]>
							</cfif>
							<cfset aAdminMenu[ArrayLen(aAdminMenu)]["items"][jj]["folder"] = xProgram.site.program[ii].XmlAttributes["path"]>
						</cfif>
					</cfloop>
				</cfif>
			<!---<cfcatch>
			</cfcatch>
			</cftry>--->
		</cfloop>
	</cfif>
	
	<cfreturn aAdminMenu>
</cffunction>

<cffunction name="getProgramComponents" access="public" returntype="array" output="no">
	<cfargument name="path" type="string" required="yes">
	
	<cfset var ii = 0>
	<cfset var path_file = getFilePathFromBrowserPath(arguments.path)>
	<cfset var path_comp = getComponentPath(path_file)>
	<cfset var aComponents = This.Loader.getComponents()>
	<cfset var aProgramComponents = ArrayNew(1)>
	
	<cfif Len(path_comp)>
		<!--- Get all of the programs for this component --->
		<cfloop index="ii" from="1" to="#ArrayLen(aComponents)#" step="1">
			<cfif Len(aComponents[ii].path) GT Len(path_comp) AND Left(aComponents[ii].path,Len(path_comp)) EQ path_comp>
				<cfset ArrayAppend(aProgramComponents,aComponents[ii])>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfreturn aProgramComponents>
</cffunction>

<cffunction name="getProgramFromPath" access="public" returntype="any" output="no">
	<cfargument name="path" type="string" required="yes">
	
	<cfset var sResult = StructNew()>
	<cfset var xMenu = getProgramLinksXml()>
	<cfset var axPrograms = XmlSearch(xMenu,"//program[string-length(@path)>0]")>
	<cfset var key = "">
	<cfset var ii = 0>
	
	<cfloop index="ii" from="1" to="#ArrayLen(axPrograms)#">
		<cfif arguments.path CONTAINS axPrograms[ii].XmlAttributes["path"]>
			<cfset sResult = axPrograms[ii].XmlAttributes>
			<cfset StructAppend(sResult,axPrograms[ii].XmlAttributes)>
		</cfif>
	</cfloop>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="getProgramMainServiceName" access="public" returntype="string" output="no">
	<cfargument name="path" type="string" required="yes">
	
	<cfset var aProgram = XmlSearch(variables.instance.xPrograms,"//program[@path='#arguments.path#']")>
	<cfset var result = "">
	<cfset var ii = 0>
	<cfset var aComponents = 0>
	<cfset var oComponent = 0>
	<cfset var sComponent = 0>
	<cfset var aProgramComponents = ArrayNew(1)>
	
	<cfif StructKeyExists(variables.instance,"xPrograms")>
		<cfset aProgram = XmlSearch(variables.instance.xPrograms,"//program[@path='#arguments.path#']")>
	</cfif>
	
	<cfif isArray(aProgram) AND StructKeyExists(aProgram[1].XmlAttributes,"service") AND Len(aProgram[1].XmlAttributes["service"])>
		<!--- If this program is defined with a main service --->
		<cfset result = aProgram[1].XmlAttributes["service"]>
	<cfelse>
		<!--- Get all of the programs for this component --->
		<cfset aProgramComponents = getProgramComponents(arguments.path)>
		<cfif ArrayLen(aProgramComponents) EQ 1>
			<!--- If the program only has one component, then that is the one --->
			<cfset result = aProgramComponents[1].name>
		<cfelse>
			<cfloop index="ii" from="1" to="#ArrayLen(aProgramComponents)#" step="1">
				<cfset oComponent = This.Loader[aProgramComponents[ii].name]>
				<cfset sComponent = getMetaData(oComponent)>
				<cfif StructKeyExists(sComponent,"mainservice") AND sComponent.mainservice IS true>
					<cfset result = aComponents[ii].name>
					<cfbreak>
				</cfif>
			</cfloop>
			<cfloop index="ii" from="1" to="#ArrayLen(aProgramComponents)#" step="1">
				<cfset oComponent = This.Loader[aProgramComponents[ii].name]>
				<cfset sComponent = getMetaData(oComponent)>
				<cfif StructKeyExists(sComponent,"extends") AND ListLast(sComponent.extends.name,".") EQ "ProgramManager">
					<cfset result = aComponents[ii].name>
					<cfbreak>
				</cfif>
			</cfloop>
			<cfif ArrayLen(aProgramComponents) AND NOT Len(result)>
				<cfset result = aProgramComponents[1].name>
			</cfif>
		</cfif>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getService" access="public" returntype="any" output="no">
	<cfargument name="name" type="string" required="yes">
	
	<cfset arguments.name = arguments.name>
	
	<cfif StructKeyExists(This.Loader,arguments.name)>
		<cfreturn This.Loader[arguments.name]>
	<cfelse>
		<cfreturn getServiceFromPath(arguments.name)>
	</cfif>
	
</cffunction>

<cffunction name="getServiceFromPath" access="public" returntype="any" output="no">
	<cfargument name="path" type="string" required="yes">
	
	<cfset var dir = getDirectoryFromPath(arguments.path)>
	<cfset var file = getFileFromPath(arguments.path)>
	<cfset var FileLabel = ListFirst(file,"-")>
	<cfset var key = "#dir#:#FileLabel#">
	
	<cflock name="Framework_PathServices" timeout="120" throwontimeout="yes">
		<cfif
				NOT	StructKeyExists(variables.instance.NoPathServices,key)
			AND	NOT (
							StructKeyExists(variables.instance.PathServices,key)
						AND	isObject(variables.instance.PathServices[key])
					)
		>
			<cflock name="#variables.instance.Hash#_#key#" timeout="20" throwontimeout="no">
				<cfset variables.instance.PathServices[key] = getServiceFromDirAndLabel(dir,FileLabel)>
				<cfif NOT StructkeyExists(variables.instance.PathServices,key)>
					<cfset variables.instance.NoPathServices[key] = false>
				</cfif>
			</cflock>
		</cfif>
		
		<cfif ( StructKeyExists(variables.instance.PathServices,key) AND isObject(variables.instance.PathServices[key]) )>
			<cfreturn variables.instance.PathServices[key]>
		</cfif>
	</cflock>
	
	<cfreturn false>
</cffunction>

<cffunction name="getServiceFromDirAndLabel" access="public" returntype="any" output="no">
	<cfargument name="Dir" type="string" required="yes">
	<cfargument name="Label" type="string" required="yes">
	
	<cfset var aComponents = getProgramComponents(arguments.Dir)>
	<cfset var ii = 0>
	<cfset var key = 0>
	<cfset var oComponent = 0>
	<cfset var checkLabel = 0>
	
	<cfif NOT ArrayLen(aComponents)>
		<cfset aComponents = This.Loader.getComponents()>
	</cfif>
	
	<cfloop index="checkLabel" from="0" to="1" step="1">
		<cfloop index="ii" from="1" to="#ArrayLen(aComponents)#" step="1">
			<cfset oComponent = This.Loader[aComponents[ii].name]>
			<cfif isComponentForLabel(oComponent,arguments.Label,checkLabel)>
				<cfreturn oComponent>
			<cfelse>
				<cfloop item="key" collection="#oComponent#">
					<cfif isComponentForLabel(oComponent[key],arguments.Label,checkLabel)>
						<cfreturn oComponent[key]>
					</cfif>
				</cfloop>
			</cfif>
		</cfloop>
	</cfloop>
	
	<cfreturn false>
</cffunction>

<cffunction name="isComponentForLabel" access="public" returntype="boolean" output="no">
	<cfargument name="Component" type="any" required="true">
	<cfargument name="labelSingular" type="string" default="true">
	<cfargument name="checkLabel" type="boolean" default="false">
	
	<cfset var result = false>
	<cfset var sMetaStruct = 0>
	
	<cfif isSimpleValue(arguments.Component) AND StructKeyExists(This.Loader,arguments.Component)>
		<cfset arguments.Component = This.Loader[arguments.Component]>
	</cfif>
	
	<cfif
			isObject(arguments.Component)
		AND	StructKeyExists(arguments.Component,"getMetaStruct")
	>
		<cftry>
			<cfset sMetaStruct = arguments.Component.getMetaStruct()>
		<cfcatch>
			<cfset sMetaStruct = StructNew()>
		</cfcatch>
		</cftry>
		<cfif StructKeyExists(sMetaStruct,"entity") AND sMetaStruct["entity"] EQ makeCompName(arguments.labelSingular)>
			<cfset result = true>
		<cfelseif StructKeyExists(sMetaStruct,"method_Singular") AND sMetaStruct["method_Singular"] EQ makeCompName(arguments.labelSingular)>
			<cfset result = true>
		<cfelseif arguments.checkLabel AND StructKeyExists(sMetaStruct,"label_Singular") AND makeCompName(sMetaStruct["label_Singular"]) EQ makeCompName(arguments.labelSingular)>
			<cfset result = true>
		</cfif>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="registerComponents" access="public" returntype="void" output="no">
	<cfargument name="ComponentXML" type="string" required="yes">
	<cfargument name="overwrite" type="boolean" default="false">
	
	<cftry>
		<cfset this.Loader.register(arguments.ComponentXML,arguments.overwrite)>
	<cfcatch type="AppLoader">
		<cfif CFCATCH.ErrorCode EQ "NoSuchArg">
			<cfset this.Config.throwError(errorcode="Required",name=CFCATCH.ExtendedInfo)>
		<cfelse>
			<cfrethrow>
		</cfif>
	</cfcatch>
	</cftry>
	
</cffunction>

<cffunction name="getProgramLinksXml" access="public" returntype="any" output="no">
	
	<cfset var MenuFilePath = "#variables.instance.ConfigFolderPath#programlinks.cfm">
	<cfset var MenuCode = "">
	<cfset var xMenu = 0>
	
	<cfsavecontent variable="MenuCode"><cfoutput><?xml version="1.0"?><site>
	</site></cfoutput></cfsavecontent>
	
	<!--- Make sure config file exists --->
	<cfif NOT FileExists(MenuFilePath)>
		<cffile action="write" file="#MenuFilePath#" output="#MenuCode#">
	</cfif>
	
	<cffile action="read" file="#MenuFilePath#" variable="MenuCode">
	<cfset xMenu = XmlParse(MenuCode)>
	
	<cfreturn xMenu>
</cffunction>

<cffunction name="registerLinks" access="public" returntype="void" output="no">
	<cfargument name="name" type="string" required="false">
	
	<cfset var MenuFilePath = "#variables.instance.ConfigFolderPath#programlinks.cfm">
	<cfset var MenuCode = "">
	<cfset var xMenu = 0>
	<cfset var ii = 0>
	<cfset var exists = false>
	<cfset var ProgramMenuCode = "">
	<cfset var ProgramLinks = "">
	<cfset var xProgramLinks = 0>
	<cfset var aProgramLinks = ArrayNew(1)>
	<cfset var sProgram = 0>
	<cfset var cr = "
">

	<cfsavecontent variable="MenuCode"><cfoutput><?xml version="1.0"?><site>
	</site></cfoutput></cfsavecontent>
	
	<!--- Make sure config file exists --->
	<cfif NOT FileExists(MenuFilePath)>
		<cffile action="write" file="#MenuFilePath#" output="#MenuCode#">
	</cfif>
	
	<cffile action="read" file="#MenuFilePath#" variable="MenuCode">
	<cfset xMenu = XmlParse(MenuCode)>
	
	<!--- Only load site-specific links if a program name is given and links should be created for program (has index.cfm or links method) --->
	<cfif StructKeyExists(arguments,"name") AND ( FileExists("#variables.instance['programs'][name].path_file#index.cfm") OR StructKeyExists(variables.instance["programs"][arguments.name]["program"],"links") )>
	
		<cfif StructKeyExists(xMenu.site,"program")>
			<cfloop index="ii" from="1" to="#ArrayLen(xMenu.site.program)#" step="1">
				<cfif StructKeyExists(xMenu.site.program[ii].XmlAttributes,"name") AND xMenu.site.program[ii].XmlAttributes["name"] EQ arguments.name>
					<cfset exists = true>
				</cfif>
			</cfloop>
		</cfif>
		
		<cfif NOT exists>
			<cfif StructKeyExists(variables.instance["programs"][arguments.name]["program"],"links")>
				<cfset ProgramLinks = getMethodOutputValue(variables.instance["programs"][arguments.name]["program"],"links")>
				<cfset xProgramLinks = XmlParse(ProgramLinks)>
				<cfset aProgramLinks = XmlSearch(xProgramLinks,"//link")>
			</cfif>
			
			<cfif ArrayLen(aProgramLinks)>
				<cfset ProgramMenuCode = '<program name="#XmlFormat(name)#" path="#variables.instance.programs[name].path_browser#"'>
				<cfif StructKeyExists(xProgramLinks,"program") AND StructKeyExists(xProgramLinks.program.XmlAttributes,"permissions")>
					<cfset ProgramMenuCode = '#ProgramMenuCode# permissions="#XmlFormat(xProgramLinks.program.XmlAttributes.permissions)#"'>
				<cfelseif StructKeyExists(xProgramLinks,"links") AND StructKeyExists(xProgramLinks.links.XmlAttributes,"permissions")>
					<cfset ProgramMenuCode = '#ProgramMenuCode# permissions="#XmlFormat(xProgramLinks.links.XmlAttributes.permissions)#"'>
				</cfif>
				<cfset ProgramMenuCode = '#ProgramMenuCode#>'>
				<cfloop index="ii" from="1" to="#ArrayLen(aProgramLinks)#" step="1">
					<cfset ProgramMenuCode = '#ProgramMenuCode#<link label="#aProgramLinks[ii].XmlAttributes.label#" url="#aProgramLinks[ii].XmlAttributes.url#" />'>
				</cfloop>
				<cfset ProgramMenuCode = '#ProgramMenuCode##cr#</program>'>
			<cfelse>
				<cfset sProgram = getMetaData(variables.instance["programs"][arguments.name]["program"])>
				<cfset ProgramMenuCode = '<program name="#XmlFormat(name)#" path="#variables.instance.programs[name].path_browser#"'>
				<cfif StructKeyExists(sProgram,"security_permissions")>
					<cfset ProgramMenuCode = '#ProgramMenuCode# permissions="#XmlFormat(sProgram.security_permissions)#"'>
				</cfif>
				<cfset ProgramMenuCode = '#ProgramMenuCode# />'>
			</cfif>
			<cfset MenuCode = ReplaceNoCase(MenuCode, "</site>", "#ProgramMenuCode##cr#</site>")>
			
			<cffile action="write" file="#MenuFilePath#" output="#XmlHumanReadable(XmlParse(MenuCode))#">
			<cfset variables.instance["ProgramFilePaths"] = ListAppend(variables.instance["ProgramFilePaths"],variables.instance["programs"][name]["path_file"])>
		</cfif>
	</cfif>
	
</cffunction>

<cffunction name="registerConfig" access="public" returntype="void" output="no">
	<cfargument name="ProgramFilePath" type="string" required="true">
	<cfargument name="name" type="string" required="true">
	<cfargument name="struct" type="struct" required="true">
	
	<cfset var ConfigFilePath = "#variables.instance.ConfigFolderPath#configfiles.cfm">
	<cfset var ConfigCode = "">
	<cfset var cfcCode = "">
	<cfset var find = 0>
	<cfset var ProgramConfigCode = "">
	<cfset var pcodeStartComment = "#chr(60)#!--- Start #arguments.name# program Code ---#chr(62)#">
	<cfset var pcodeStopComment  = "#chr(60)#!--- End #arguments.name# program Code ---#chr(62)#">
	<cfset var key = "">
	
	<!--- Make sure config file exists --->
	<cfif NOT FileExists(ConfigFilePath)>
		<cffile action="write" file="#ConfigFilePath#" output="#ConfigCode#">
	</cfif>
	
	<cffile action="read" file="#ConfigFilePath#" variable="ConfigCode">
	<cffile action="read" file="#arguments.ProgramFilePath#" variable="cfcCode">
	
	<!--- Remove config code for this program --->
	<cfset ConfigCode = ReReplaceNoCase(ConfigCode,"#pcodeStartComment#.*?#pcodeStopComment#","","ALL")>
	
	<!--- Get config function --->
	<cfset find = ReFindNoCase("<cffunction[^>]*? name=#chr(34)#config#chr(34)#[^>]*?>(.*?)</cffunction>",cfcCode,1,1)>
	
	<!--- If a config function is found --->
	<cfif ArrayLen(find.pos) EQ 2 AND find.pos[2] AND find.len[2]>
		<!--- Get contents of function (first subexpression is second item in array) --->
		<cfset ProgramConfigCode = Mid(cfcCode,find.pos[2],find.len[2])>
		<!--- Remove argument tag(s) --->
		<cfset ProgramConfigCode = ReReplaceNoCase(ProgramConfigCode,"<cfargument[^>]*?>","","ALL")>
		
		<!--- Replace key markers --->
		<cfset ProgramConfigCode = ReplaceNoCase(ProgramConfigCode,"GetDirectoryFromPath(GetCurrentTemplatePath())","Expandpath(#chr(34)#[path_browser]#chr(34)#)")>
		<cfloop collection="#arguments.struct#" item="key">
			<cfif isSimpleValue(arguments.struct[key])>
				<cfset ProgramConfigCode = ReplaceNoCase(ProgramConfigCode,"[#key#]",arguments.struct[key],"ALL")>
			</cfif>
		</cfloop>
		
		<!--- If program config code is found, add it to file --->
		<cfif Len(Trim(ProgramConfigCode))>
			<cfset ConfigCode = ConfigCode & pcodeStartComment & ProgramConfigCode & pcodeStopComment>
			<cffile action="write" file="#ConfigFilePath#" output="#Trim(ConfigCode)#">
		</cfif>
	</cfif>
	
	<!---<cfset runConfigFiles()>
	<cfset loadConfigSettings()>--->
	
</cffunction>

<cffunction name="registerProgram" access="public" returntype="boolean" output="no">
	<cfargument name="FilePath" type="string" required="yes">
	<cfargument name="overwrite" type="boolean" default="false">
	
	<cfset var path_file = arguments.FilePath>
	<cfset var path_browser = "">
	<cfset var path_component = "">
	<cfset var ComponentsXML = "">
	<cfset var xComponents = 0>
	<cfset var ProgramXML = "">
	<cfset var xProgram = 0>
	<cfset var oProgram = 0>
	<cfset var sProgram = 0>
	<cfset var name = "">
	<cfset var qProgramFile = 0>
	<cfset var aRegisteredPrograms = 0>
	<cfset var DateInstalled = "">
	<cfset var result = false>
	
	<!--- Make sure file path ends with path delimiter for this OS --->
	<cfif Right(path_file,1) NEQ variables.instance["dirdelim"]>
		<cfset path_file = path_file & variables.instance["dirdelim"]>
	</cfif>
	<cfset path_browser = getBrowserPath(path_file)>
	<cfset path_component = getComponentPath(path_file)>
	
	<!---<cfdirectory name="qProgramFile" action="list" directory="#arguments.FilePath#" filter="Program.cfc">--->
	<cfset qProgramFile = getMyDirectoryList(directory=arguments.FilePath,filter="Program.cfc",recurse=false,exclude=getExcludeDirs())>
	
	<cfset aRegisteredPrograms = XmlSearch(variables.instance.xPrograms,"//program[@path='#path_browser#']")>
	<cfif ArrayLen(aRegisteredPrograms)>
		<cfset DateInstalled = aRegisteredPrograms[1].XmlAttributes.installed>
	</cfif>
	
	<cfif
			qProgramFile.RecordCount
		AND	(
					NOT isDate(DateInstalled)
				OR	qProgramFile.DateLastModified GT DateInstalled
			)
	>
		<cfif Len(path_component)>
			<cftry>
				<cfset oProgram = CreateObject("component","#path_component#Program")>
			<cfcatch>
				<cfreturn false>
				<!---<cfthrow message="The #path_component# is not a valid component path.">--->
			</cfcatch>
			</cftry>
		<cfelse>
			<cfset oProgram = CreateObject("component","Program")>
		</cfif>
		<cfif StructKeyExists(oProgram,"components")>
			
			<cfset sProgram = getMetaData(oProgram)>
			
			<cfset ComponentsXML = getMethodOutputValue(oProgram,"components")>
			
			<cfif NOT ( Len(ComponentsXML) AND isXml(ComponentsXML) )>
				<cfif StructKeyExists(sProgram,"Display") AND Len(Trim(sProgram.Display))>
					<cfset name = sProgram.Display>
				<cfelseif ListLen(sProgram.name,".") GT 1>
					<cfset name = ListGetAt(sProgram.name,ListLen(sProgram.name,".")-1,".")>
				</cfif>
				<cfset ComponentsXML = getProgramComponentFiles(path_file,name)>
			</cfif>
			
			<cfif Len(ComponentsXML) AND isXml(ComponentsXML)>
				<cfset ComponentsXML = ReplaceNoCase(ComponentsXML,"[path_file]",path_file,"ALL")>
				<cfset ComponentsXML = ReplaceNoCase(ComponentsXML,"[path_browser]",path_browser,"ALL")>
				<cfset ComponentsXML = ReplaceNoCase(ComponentsXML,"[path_component]",path_component,"ALL")>
				
				<cfset xComponents = XmlParse(Trim(ComponentsXML))>
			</cfif>
			
			<cfif StructKeyExists(sProgram,"Display") AND Len(Trim(sProgram.Display))>
				<cfset name = sProgram.Display>
			<cfelseif isXmlDoc(xComponents) AND StructKeyExists(xComponents.program.XmlAttributes,"name")>
				<cfset name = xComponents.program.XmlAttributes.name>
			<cfelseif ListLen(sProgram.name,".") GT 1>
				<cfset name = ListGetAt(sProgram.name,ListLen(sProgram.name,".")-1,".")>
			<cfelse>
				<cfset name = "Root">
			</cfif>
			
			<cfset variables.instance["programs"][name] = StructNew()>
			<cfset variables.instance["programs"][name]["path_file"] = path_file>
			<cfset variables.instance["programs"][name]["path_browser"] = path_browser>
			<cfset variables.instance["programs"][name]["path_component"] = path_component>
			<cfset variables.instance["programs"][name]["program"] = oProgram>
			
			<!--- Run install method, if one exists --->
			<cfif StructKeyExists(oProgram,"install")>
				<cfset oProgram.install(this.Config)>
			</cfif>
			
			<!--- If program has a _public folder, copy files from it into site root --->
			<cfif DirectoryExists("#path_file#_public")>
				<cfset This.directoryCopy("#path_file#_public",variables.instance["RootPath"],"skip")>
			</cfif>
			
			<cfset registerConfig("#path_file#Program.cfc",name,variables.instance["programs"][name])>
			<cfif StructKeyExists(oProgram,"Config")>
				<cfset oProgram.config(Config=This.Config,Framework=This)>
				<cfset loadConfigSettings()>
			</cfif>
			<cfif Len(Trim(ComponentsXML))>
				<cfset registerComponents(ComponentsXML,arguments.overwrite)>
			</cfif>
			<cfset registerLinks(name)>
			
			<!--- If program has a _public folder, run the files --->
			<cfif DirectoryExists("#path_file#_public")>
				<cfset runFiles("#path_file#_public")>
			</cfif>
			
			<!--- If program has a _instructions folder, copy files into root _instructions folder --->
			<cfif DirectoryExists("#path_file#_instructions")>
				<cfset makeInstructionsFolder()>
				<cfset This.directoryCopy("#path_file#_instructions","#variables.instance.RootPath#_instructions","skip")>
			</cfif>
			
			<cfset registerProgramXml(name,path_file,path_browser)>
			
		</cfif>
		
		<cfset result = true>
		
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="XmlDateFormat" access="private" returntype="string" output="no">
	<cfargument name="date" type="date" default="#now()#">
	
	<cfreturn "#DateFormat(arguments.date,"yyyy-mm-dd")# #TimeFormat(arguments.date,"HH:mm:ss")#">
</cffunction>

<cffunction name="registerProgramXml" access="public" returntype="void" output="no">
	<cfargument name="ProgramName" type="string" required="true">
	<cfargument name="ProgramFilePath" type="string" required="true">
	<cfargument name="ProgramBrowserPath" type="string" required="true">
	
	<cfset var qFiles = getMyDirectoryList(directory=arguments.ProgramFilePath,recurse=true)>
	<cfset var ProgramXml = "">
	<cfset var FileName = "">
	<cfset var ProgramsFilePath = "#variables.instance.ConfigFolderPath#programs.cfm">
	<cfset var ProgramsCode = "">
	<cfset var aFindProgram = "">
	
	<!--- Make XML for this program --->
	<cfset ProgramXml = '<program name="#XmlFormat(arguments.ProgramName)#" path="#arguments.ProgramBrowserPath#" installed="#XmlDateFormat()#">'>
	<cfloop query="qFiles">
		<cfset FileName = ReplaceNoCase(ReplaceNoCase(Directory,arguments.ProgramFilePath,""),"\","/","ALL") & name>
		<cfset ProgramXml = '#ProgramXml#<file name="#FileName#" modified="#XmlDateFormat(DateLastModified)#" />'>
	</cfloop>
	<cfset ProgramXml = '#ProgramXml#</program>'>
	
	<!--- Change the file --->
	<cfset aFindProgram = XmlSearch(variables.instance.xPrograms,"//program[@name='#ProgramName#']")>
	<cfif ArrayLen(aFindProgram)>
		<cfset aFindProgram[1].XmlAttributes.installed = XmlDateFormat()>
		<cfset ProgramsCode = XmlHumanReadable(variables.instance.xPrograms,"name,path")>
	<cfelseif FileExists(ProgramsFilePath)>
		<cffile action="read" file="#ProgramsFilePath#" variable="ProgramsCode">
		<cfset ProgramsCode = ReplaceNoCase(ProgramsCode,"</site>","#ProgramXml#</site>")>
		<cfset ProgramsCode = XmlHumanReadable(ProgramsCode,"name,path")>
		<cfif Len(Trim(ProgramsCode))>
			<cfset variables.instance.xPrograms = XmlParse(ProgramsCode)>
		<cfelse>
			<cfset variables.instance.xPrograms = XmlNew(false)>
		</cfif>
	</cfif>
	<cfif NOT Len(Trim(ProgramsCode))>
		<cfset ProgramsCode = '<?xml version="1.0"?><site></site>'>
	</cfif>
	<cffile action="write" file="#ProgramsFilePath#" output="#ProgramsCode#" addnewline="false">
	
</cffunction>

<cffunction name="getProgramsXml" access="public" returntype="any" output="no">
	
	<cfset var ProgramsXml = "">
	
	<cfif NOT StructKeyExists(Variables,"xPrograms")>
		<cffile action="read" file="#variables.instance.ConfigFolderPath#programs.cfm" variable="ProgramsXml">
		<cfset Variables.xPrograms = XmlParse(ProgramsXml)>
	</cfif>
	
	<cfreturn Variables.xPrograms>
</cffunction>

<cffunction name="registerAllPrograms" access="public" returntype="boolean" output="no">
	<cfargument name="overwrite" type="boolean" default="false">
	
	<cfset var qProgramFiles = 0>
	<cfset var exclude = getExcludeDirs()>
	<cfset var isRegistered = false>
	<cfset var result = false>
	<cfset var xPrograms = getProgramsXml()>
	<cfset var Folder = "">
	<cfset var axPrograms = 0>
	
	<!--- Get program files --->
	<cfset qProgramFiles = getMyDirectoryList(directory=variables.instance.RootPath,filter="Program.cfc",recurse=true,exclude=exclude)>
	
	<cfif qProgramFiles.RecordCount>
		<!--- Attempt to register program files --->
		<cfloop query="qProgramFiles">
			<cfset Folder = ReplaceNoCase(Directory,variables.instance.RootPath,'')>
			<cfset Folder = "/" & ListChangeDelims(Folder,"/","\")>
			<cfif Right(Folder,1) NEQ "/">
				<cfset Folder = "#Folder#/">
			</cfif>
			<cfset axPrograms = XmlSearch(xPrograms,"/site/program[@path='#Folder#']")>
			<cfif NOT ArrayLen(axPrograms)>
				<cfset isRegistered = registerProgram(Directory)>
				<cfset result = (result OR isRegistered)>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="runConfigFiles" access="public" returnType="void" output="false" hint="I run the config files for the programs of this site.">
	
	<cfset var Config = this.Config>
	<cfset var Framework = this>
	
	<cfset includePage("#variables.instance.ConfigFolder#configfiles.cfm")>
	
</cffunction>

<cffunction name="runConfigProgramLinks" access="public" returnType="void" output="false">
	
	<cfset var MenuFilePath = "#variables.instance.ConfigFolderPath#programlinks.cfm">
	<cfset var MenuCode = "">
	<cfset var xMenu = 0>
	<cfset var qLinksFile = 0>
	
	<cfset qLinksFile = getMyDirectoryList(directory="#variables.instance.ConfigFolderPath#",filter="programlinks.cfm")>
	
	<cfif
			qLinksFile.RecordCount
		AND	(
					NOT This.Config.exists("Framework_ProgramLinks_Updated")
				OR	NOT This.Config.exists("Framework_ProgramLinks_Code")
				OR	This.Config.getSetting("Framework_ProgramLinks_Updated") NEQ qLinksFile.DateLastModified
			)
	>
		<cflock name="read_#MenuFilePath#" timeout="30">
			<cffile action="read" file="#MenuFilePath#" variable="MenuCode">
		</cflock>
		
		<cfif NOT This.Config.exists("Framework_ProgramLinks_Code") OR MenuCode NEQ This.Config.getSetting("Framework_ProgramLinks_Code")>
			<cfset xMenu = XmlParse(MenuCode)>
			<cfset This.Config.setSetting("Framework_ProgramLinks_Code",MenuCode)>
			<cfset This.Config.setSetting("ProgramMenu",xMenu)><!--- Just for backwards compatibility with old custom code --->
			<cfset This.Config.setSetting("Framework_xProgramMenu",xMenu)>
			<cfset This.Config.setSetting("Framework_aProgramLinks",getProgramLinksArrayInternal())>
			<cfset This.Config.setSetting("Framework_DateProgramLinksSet",now())>
		</cfif>
		
		<cfset This.Config.setSetting("Framework_ProgramLinks_Updated",qLinksFile.DateLastModified)>
		
	</cfif>
	
</cffunction>

<cffunction name="getExcludeDirs" access="private" returntype="string" output="no">
	
	<cfset var result = "/_framework/,#variables.instance.ConfigFolder#,/layouts/">
	
	<cfif This.Config.exists("UploadURL")>
		<cfset result = ListAppend(result,This.Config.getSetting("UploadURL"))>
	<cfelse>
		<cfset result = ListAppend(result,"/f/")>
	</cfif>
	<cfif This.Config.exists("LibraryPath")>
		<cfset result = ListAppend(result,This.Config.getSetting("LibraryPath"))>
	<cfelseif StructKeyExists(request,"cftags") AND StructKeyExists(request.cftags,"sebtags") AND StructKeyExists(request.cftags.sebtags,"LibraryPath")>
		<cfset result = ListAppend(result,request.cftags.sebtags.LibraryPath)>
	<cfelse>
		<cfset result = ListAppend(result,"/lib/")>
	</cfif>
	
	<cfif StructKeyExists(variables.instance,"ExcludeDirs")>
		<cfset result = ListAppend(result,variables.instance.ExcludeDirs)>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getProgramSchema" access="private" returntype="string" output="no">
	<cfset var SchemaXML = "">
	
	<cfsavecontent variable="SchemaXML"><cfoutput><xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema"><xsd:element name="program" /></xsd:schema></cfoutput></cfsavecontent>
	
	<!--- <cfset SchemaXML = ReplaceNoCase(SchemaXML, "xsd:", "", "ALL")> --->
	<cfreturn SchemaXML>
</cffunction>

<cffunction name="makeConfigPageControllerFile" access="public" returntype="void" output="no">
	
	<cfset var FilePath = "#variables.instance.ConfigFolderPath#PageController.cfc">
	<cfset var FileCode = '<cfcomponent extends="_framework.PageController"></cfcomponent>'>
	
	<!--- Make sure file exists --->
	<cfif NOT FileExists(FilePath)>
		<cffile action="write" file="#FilePath#" output="#FileCode#" addnewline="no">
	</cfif>
	
</cffunction>

<cffunction name="makeConfigProgramFile" access="public" returntype="void" output="no">
	
	<cfset var FilePath = "#variables.instance.ConfigFolderPath#Program.cfc">
	<cfset var FileCode = '<cfcomponent extends="_framework.BaseProgram"></cfcomponent>'>
	
	<!--- Make sure file exists --->
	<cfif NOT FileExists(FilePath)>
		<cffile action="write" file="#FilePath#" output="#FileCode#" addnewline="no">
	</cfif>
	
</cffunction>

<cffunction name="makeInstructionsFolder" access="public" returntype="any" output="false" hint="">
	
	<cfset var path = "#variables.instance.RootPath#_instructions/">
	<cfset var abort = "<cfabort>">
	
	<cfif NOT DirectoryExists(path)>
		<cfdirectory action="create" directory="#path#" mode="777">
		<cffile action="write" file="#path#Application.cfm" output="#abort#">
	</cfif>
	
</cffunction>

<cffunction name="makeProgramsFile" access="public" returntype="void" output="no">
	
	<cfset var MenuFilePath = "#variables.instance.ConfigFolderPath#programlinks.cfm">
	<cfset var xMenu = 0>
	<cfset var FilePath = "#variables.instance.ConfigFolderPath#programs.cfm">
	<cfset var FileCode = '<?xml version="1.0"?><site></site>'>
	<cfset var name = "">
	<cfset var MenuCode = "">
	<cfset var ii = 0>
	
	<cffile action="read" file="#MenuFilePath#" variable="MenuCode">
	<cfset xMenu = XmlParse(MenuCode)>
	
	<!--- Make sure file exists --->
	<cfif StructKeyExists(xMenu.site,"program") AND NOT FileExists(FilePath)>
		<cfset FileCode = '<?xml version="1.0"?><site>'>
		<cfloop index="ii" from="1" to="#ArrayLen(xMenu.site.program)#">
			<cfif StructKeyExists(xMenu.site.program[ii].XmlAttributes,"name")>
				<cfset name = xMenu.site.program[ii].XmlAttributes["name"]>
				<cfif NOT StructKeyExists(variables.instance.programs,name)>
					<cfset variables.instance.programs[name] = StructNew()>
					<cfset variables.instance["programs"][name] = StructNew()>
					<cfif StructKeyExists(xMenu.site.program[ii].XmlAttributes,"path")>
						<cfset variables.instance["programs"][name]["path_browser"] = xMenu.site.program[ii].XmlAttributes["path"]>
						<cfset variables.instance["programs"][name]["path_component"] = getComponentPath(variables.instance["programs"][name]["path_browser"])>
						<cfset variables.instance["programs"][name]["path_file"] = getFilePathFromBrowserPath(xMenu.site.program[ii].XmlAttributes["path"])>
					</cfif>
					<cfset variables.instance["programs"][name]["program"] = name>
					<cfset variables.instance["programs"][name]["installed"] = now()>
					<cfset variables.instance["ProgramFilePaths"] = ListAppend(variables.instance["ProgramFilePaths"],variables.instance["programs"][name]["path_file"])>
					<cfset FileCode = '#FileCode#<program name="#XmlFormat(name)#" path="#XmlFormat(xMenu.site.program[ii].XmlAttributes.path)#" installed="#XmlDateFormat()#">'>
					<cfset FileCode = '#FileCode#</program>'>
				</cfif> 
			</cfif>
		</cfloop>
		<cfset FileCode = '#FileCode#</site>'>
		<cfset FileCode = XmlHumanReadable(FileCode,'name,path')>
		<cffile action="write" file="#FilePath#" output="#FileCode#" addnewline="no">
	</cfif>
	
	<cfif FileExists(FilePath)>
		<cffile action="read" file="#FilePath#" variable="FileCode">
		<cfif Len(Trim(FileCode))>
			<cfset variables.instance.xPrograms = XmlParse(FileCode)>
		<cfelse>
			<cfset variables.instance.xPrograms = XmlNew(false)>
		</cfif>
	<cfelse>
		<cfset variables.instance.xPrograms = XmlNew(false)>
	</cfif>
	
</cffunction>

<cffunction name="getMethodOutputValue" access="private" returntype="string" output="no" hint="DEPRECATED">
	<cfargument name="component" type="any" required="yes">
	<cfargument name="method" type="string" required="yes">
	<cfargument name="args" type="struct" required="no">
	
	<cfset var result = "">
	<cfset var fMethod = component[method]>
	
	<cfif StructKeyExists(arguments,"args")>
		<cfsavecontent variable="result"><cfoutput>#fMethod(argumentCollection=args)#</cfoutput></cfsavecontent>
	<cfelse>
		<cfsavecontent variable="result"><cfoutput>#fMethod()#</cfoutput></cfsavecontent>
	</cfif>
	
	<cfset result = Trim(result)>
	
	<cfreturn result>
</cffunction>

<cffunction name="getProgramComponentFiles" access="public" returntype="string" output="no">
	<cfargument name="path" type="string" required="yes">
	<cfargument name="ProgramName" type="string" required="no">
	
	<cfset var qFiles = 0>
	<cfset var filter = ".cfc">
	<cfset var FileContents = "">
	<cfset var find = 0>
	<cfset var sInitMethod = 0>
	<cfset var CompXML = "">
	<cfset var result = "">
	<cfset var oComp = 0>
	<cfset var ii = 0>
	
	<cfif StructKeyExists(arguments,"ProgramName") AND Len(Trim(arguments.ProgramName))>
		<cfset filter = "#makeCompName(arguments.ProgramName)#.cfc">
	</cfif>
	
	<cfset qFiles = getMyDirectoryList(directory=arguments.path,filter=filter,recurse=true)>
	
	<cfloop query="qFiles">
		<cffile action="read" file="#Directory##Name#" variable="FileContents">
		<cfset find = Len(Trim(arguments.ProgramName)) OR ReFindNoCase(' extends=#chr(34)#[^#chr(34)#]*ProgramManager#chr(34)#',FileContents)>
		<cfif find>
			<cfset oComp = CreateObject("component","#getComponentPath(Directory)##ListFirst(Name,'.')#")>
			<cfif StructKeyExists(oComp,"init")>
				<cfset sInitMethod = getMetaData(oComp.init)>
				<cfsavecontent variable="CompXML"><cfoutput>
				<component name="#ListFirst(Name,'.')#" path="[path_component]#getComponentPath(ReplaceNoCase(Directory,arguments.path,""))##ListFirst(Name,'.')#">
					<cfloop index="ii" from="1" to="#ArrayLen(sInitMethod.Parameters)#">
						<argument name="#sInitMethod.Parameters[ii].name#"<cfif NOT sInitMethod.Parameters[ii].required IS true> ifmissing="skiparg"</cfif> />
					</cfloop>
				</component>
				</cfoutput></cfsavecontent>
				<cfset result = result & CompXML>
			</cfif>
		</cfif>
	</cfloop>
	
	<cfif Len(Trim(result))>
		<cfsavecontent variable="result"><cfoutput>
		<program>
			<components>
				#result#
			</components>
		</program>
		</cfoutput></cfsavecontent>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="QueryString2Struct" access="private" returntype="struct" output="no">
	<cfargument name="QueryString" type="string" required="true">
	 
	<cfset var sResult = StructNew()>
	<cfset var pair = StructNew()>
	
	<cfloop list="#arguments.QueryString#" index="pair" delimiters="&">
		<cfif NOT StructKeyExists(sResult,ListFirst(pair,"="))>
			<cfset sResult[ListFirst(pair,"=")] = "">
		</cfif>
		<cfset sResult[ListFirst(pair,"=")] = ListAppend(sResult[ListFirst(pair,"=")],ListRest(pair,"="))>
	</cfloop>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="Security_AddPermissions" access="private" returntype="any" output="false">
	<cfargument name="Permissions" type="string" required="yes">
	
	<cfset var oSecurity = 0>
	<cfset var isAdded = false>
	
	<cfif Len(Arguments.Permissions)>
		<cfif hasSpecialService("Security")>
				<cfset oSecurity = getSpecialService('Security')>
				
				<cfif StructKeyExists(oSecurity,"addPermissions")>
					<cfinvoke component="#oSecurity#" method="addPermissions" permissions="#Arguments.Permissions#" onExists="update">
					</cfinvoke>
					<cfset isAdded = true>
				</cfif>
		</cfif>
		<cfif NOT isAdded>
			<cfif NOT StructKeyExists(Variables,"Security_Permissions")>
				<cfset Variables.Security_Permissions = "">
			</cfif>
			<cfset Variables.Security_Permissions = ListAppend(Variables.Security_Permissions,Arguments.Permissions)> 
		</cfif>
	</cfif>
	
</cffunction>

<cffunction name="includePage" access="private" returntype="void" output="true"><cfargument name="page" type="string" required="true"><cfif StructKeyExists(variables.instance,"Proxy")><cfset variables.instance.Proxy.includePage(arguments.page)><cfelse><cfinclude template="#arguments.page#"></cfif></cffunction>

<cfscript>
/**
 * Formats an XML document for readability.
 * update by Fabio Serra to CR code
 * update by Steve Bryant to attribute ordering
 * 
 * @param XmlDoc 	 XML document. (Required)
 * @return Returns a string. 
 * @author Steve Bryant (steve@bryantwebconsulting.com) 
 * @version 2, March 20, 2006 
 * @version 3, March 07, 2010
 */
function XmlHumanReadable(XmlDoc) {
	var elem = "";
	var result = "";
	var tab = "	";
	var att = "";
	var ii = 0;
	var temp = "";
	var cr = createObject("java","java.lang.System").getProperty("line.separator");
	var attorder = "";
	
	if ( ArrayLen(arguments) GT 1 AND isSimpleValue(arguments[2]) ) {
		attorder = arguments[2];
	}
	
	if ( isSimpleValue(XmlDoc) ) {
		if ( Len(Trim(XmlDoc)) ) {
			XmlDoc = XmlParse(XmlDoc);
		} else {
			return "";
		}
	}
	
	if ( isXmlDoc(XmlDoc) ) {
		elem = XmlDoc.XmlRoot;//If this is an XML Document, use the root element
	} else if ( IsXmlElem(XmlDoc) ) {
		elem = XmlDoc;//If this is an XML Document, use it as-as
	} else if ( NOT isXmlDoc(XmlDoc) ) {
		XmlDoc = XmlParse(XmlDoc);//Otherwise, try to parse it as an XML string
		elem = XmlDoc.XmlRoot;//Then use the root of the resulting document
	}
	//Now we are just working with an XML element
	result = "<#elem.XmlName#";//start with the element name
	if ( StructKeyExists(elem,"XmlAttributes") ) {//Add any attributes
		for ( ii=1; ii LTE ListLen(attorder); ii=ii+1 ) {
			att = ListGetAt(attorder,ii);
			if ( StructKeyExists(elem.XmlAttributes,att) AND NOT ( att EQ "xmlns" AND elem.XmlAttributes[att] EQ "" ) ) {
				result = '#result# #att#="#XmlFormat(elem.XmlAttributes[att])#"';
			}
		}
		for ( att in elem.XmlAttributes ) {
			if ( NOT ( att EQ "xmlns" AND elem.XmlAttributes[att] EQ "" ) AND NOT ListFindNoCase(attorder,att) ) {
				result = '#result# #att#="#XmlFormat(elem.XmlAttributes[att])#"';
			}
		}
	}
	if ( Len(elem.XmlText) OR (StructKeyExists(elem,"XmlChildren") AND ArrayLen(elem.XmlChildren)) ) {
		result = "#result#>#cr#";//Add a carriage return for text/nested elements
		if ( Len(Trim(elem.XmlText)) ) {//Add any text in this element
			result = "#result##tab##XmlFormat(Trim(elem.XmlText))##cr#";
		}
		if ( StructKeyExists(elem,"XmlChildren") AND ArrayLen(elem.XmlChildren) ) {
			for ( ii=1; ii lte ArrayLen(elem.XmlChildren); ii=ii+1 ) {
				temp = Trim(XmlHumanReadable(elem.XmlChildren[ii],attorder));
				temp = "#tab##ReplaceNoCase(trim(temp), cr, "#cr##tab#", "ALL")#";//indent
				result = "#result##temp##cr#";
			}//Add each nested-element (indented) by using recursive call
		}
		result = "#result#</#elem.XmlName#>";//Close element
	} else {
		result = "#result# />";//self-close if the element doesn't contain anything
	}
	
	return result;
}
function makeCompName(str) {
	var result = "";
	var find = FindNoCase(" ",result);
	var word = "";
	var ii = 0;
	
	/* Turn all special characters into spaces */
	str = ReReplaceNoCase(str,"[^a-z0-9]"," ","ALL");
	
	/* Remove duplicate spaces */
	while ( find GT 0 ) {
		str = ReplaceNoCase(str,"  "," ","ALL");
		find = FindNoCase("  ",str);
	}
	
	/* Proper case words and remove spaces */
	for ( ii=1; ii LTE ListLen(str," "); ii=ii+1 ) {
		word = ListGetAt(str,ii," ");
		word = UCase(Left(word,1)) & LCase(Mid(word,2,Len(word)-1));
		if ( word EQ "Manager" ) {
			word = "Mgr";
		}
		result = "#result##word#";
	}
	
	return result;
}
</cfscript>
<!---
 Copies a directory.
 
 @param source 	 Source directory. (Required)
 @param destination 	 Destination directory. (Required)
 @param nameConflict 	 What to do when a conflict occurs (skip, overwrite, makeunique). Defaults to overwrite. (Optional)
 @return Returns nothing. 
 @author Joe Rinehart (joe.rinehart@gmail.com) 
 @version 1, July 27, 2005 
--->
<cffunction name="directoryCopy" output="true">
	<cfargument name="source" required="true" type="string">
	<cfargument name="destination" required="true" type="string">
	<cfargument name="nameconflict" required="true" default="overwrite">

	<cfset var contents = "" />
	<cfset var dirDelim = "/">
	
	<cfif server.OS.Name contains "Windows">
		<cfset dirDelim = "\" />
	</cfif>
	
	<cfif NOT DirectoryExists(arguments.destination)>
		<cfdirectory action="create" directory="#arguments.destination#">
	</cfif>
	
	<cfdirectory action="list" directory="#arguments.source#" name="contents">
	
	<cfloop query="contents">
		<cfif contents.type EQ "file">
			<cfif arguments.nameconflict EQ "overwrite" OR NOT FileExists("#arguments.destination##dirDelim##name#")>
				<cffile action="copy" source="#arguments.source##dirDelim##name#" destination="#arguments.destination##dirDelim##name#" nameconflict="#arguments.nameConflict#">
			<cfelseif arguments.nameconflict EQ "Error">
				<cfthrow message="#arguments.destination##dirDelim##name# already exists">
			</cfif>
		<cfelseif contents.type EQ "dir" AND name NEQ ".svn">
			<cfset This.directoryCopy(arguments.source & dirDelim & name, arguments.destination & dirDelim &  name, arguments.nameConflict) />
		</cfif>
	</cfloop>
</cffunction>
<!---
Mimics the cfdirectory, action=&quot;list&quot; command.
Updated with final CFMX var code.
Fixed a bug where the filter wouldn't show dirs.

@param directory      The directory to list. (Required)
@param filter      Optional filter to apply. (Optional)
@param sort      Sort to apply. (Optional)
@param recurse      Recursive directory list. Defaults to false. (Optional)
@return Returns a query.
@author Raymond Camden (ray@camdenfamily.com)
@version 2, April 8, 2004
--->
<cffunction name="getMyDirectoryList" output="false" returnType="query">
    <cfargument name="directory" type="string" required="true">
    <cfargument name="filter" type="string" required="false" default="">
    <cfargument name="sort" type="string" required="false" default="">
    <cfargument name="recurse" type="boolean" required="false" default="false">
    <!--- temp vars --->
    <cfargument name="dirInfo" type="query" required="false">
    <cfargument name="thisDir" type="query" required="false">
	<!--- more vars --->
	<cfargument name="exclude" type="string" default="">
	
	<cfset var delim = variables.dirdelim>
	<cfset var ScriptName = 0>
	<cfset var isExcluded = false>
	<cfset var exdir = false>
	<cfset var qDirs = 0>
	<cfset var qFiles = 0>
	<cfset var cols = "attributes,datelastmodified,mode,name,size,type,directory">
	
	<cfif Right(arguments.directory,1) NEQ delim>
		<cfset arguments.directory = "#arguments.directory##delim#">
	</cfif>
	
    <cfif NOT StructKeyExists(arguments,"dirInfo")>
        <cfset arguments.dirInfo = QueryNew(cols)>
    </cfif>
    
	<cfdirectory name="qFiles" directory="#arguments.directory#" sort="#sort#" filter="#arguments.filter#">
	
	<cfif arguments.recurse>
		<cfdirectory name="qDirs" directory="#arguments.directory#" sort="#sort#">
		<cfloop query="qDirs">
			<cfif type IS "dir">
				<cfif StructKeyExists(variables,"instance") AND StructKeyExists(variables.instance,"RootPath")>
					<cfset ScriptName = "/" & ReplaceNoCase(ReplaceNoCase("#arguments.directory##name#",variables.instance.RootPath,""),"\","/","ALL")>
				</cfif>
				<cfset isExcluded = false>
				<cfif Len(arguments.exclude)>
					<cfloop list="#arguments.exclude#" index="exdir">
						<cfif
								( Len(ScriptName) AND ListLen(exdir,"/") EQ 1 AND exdir EQ ListFindNoCase("#ScriptName#/",exdir,"/") )
							OR	( Len(ScriptName) AND Len(exdir) AND Left(ScriptName,Len(exdir)) EQ exdir )
							OR	( Len(ScriptName) AND Len(exdir) AND Left(exdir,Len(ScriptName)) EQ ScriptName )
							OR	( exdir EQ name )
						>
							<cfset isExcluded = true>
						</cfif>
					</cfloop>
				</cfif>
				<cfif NOT isExcluded>
					<cfset getMyDirectoryList(directory=directory & name,filter=filter,sort=sort,recurse=true,dirInfo=arguments.dirInfo,exclude=exclude)>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>
	<cfoutput query="qFiles">
		<cfset QueryAddRow(arguments.dirInfo)>
		<cfset QuerySetCell(arguments.dirInfo,"attributes",attributes)>
		<cfset QuerySetCell(arguments.dirInfo,"datelastmodified",datelastmodified)>
		<cfset QuerySetCell(arguments.dirInfo,"mode",mode)>
		<cfset QuerySetCell(arguments.dirInfo,"name",name)>
		<cfset QuerySetCell(arguments.dirInfo,"size",size)>
		<cfset QuerySetCell(arguments.dirInfo,"type",type)>
		<cfset QuerySetCell(arguments.dirInfo,"directory",arguments.directory)>
	</cfoutput>
	
    <cfreturn arguments.dirInfo>
</cffunction>

<cffunction name="runFiles" output="true">
	<cfargument name="path" required="true" type="string">
	<cfargument name="root" required="false" type="string">

	<cfset var qFiles = "" />
	<cfset var myurl = "">
	
	<cfif NOT StructKeyExists(arguments,"root")>
		<cfset arguments.root = arguments.path>
	</cfif>
	
	<cfdirectory action="list" directory="#arguments.path#" name="qFiles">
	
	<cfoutput query="qFiles">
		<cfif type eq "file">
			<cfset myurl = ListChangeDelims(ReplaceNoCase(Directory,arguments.root,""),"/","\")>
			<cfif Left(myurl,1) NEQ "/">
				<cfset myurl = "/#myurl#">
			</cfif>
			<cfif Right(myurl,1) NEQ "/">
				<cfset myurl = "#myurl#/">
			</cfif>
			<cfset myurl = "#myurl##Name#">
			<!--- <cfif myurl NEQ CGI.SCRIPT_NAME>
				<cftry> --->
					<cfhttp url="#myurl#"></cfhttp>
				<!--- <cfcatch>
				</cfcatch>
				</cftry>
			</cfif> --->
		<cfelse>
			<cfset runFiles("#Directory#/#Name#",arguments.root)>
		</cfif>
	</cfoutput>
	
	
</cffunction>

<cffunction name="isValidFilePath" access="private" returntype="boolean">
	<cfargument name="path" type="string" required="true">
	
	<cfset var result = false>
	
	<cftry>
		<cfset result = FileExists(Arguments.path)>
	<cfcatch>
		<cfset result = false>
	</cfcatch>
	</cftry>
	
	<cfreturn result>
</cffunction>

</cfcomponent>