<cfsilent>
<cfif ThisTag.ExecutionMode NEQ "Start"><cfexit></cfif>
<cfparam name="request.cf_PageController" default="#StructNew()#">
<cfparam name="request.cf_PageController.isPageControllerLoaded" default="false">
<cffunction name="loadPageController" access="public" returntype="any" output="no">
	<cfargument name="vars" type="struct" required="true">
	<cfargument name="path" type="string" required="true">
	<cfargument name="reload" type="boolean" default="false">
	
	<cfif arguments.reload OR NOT ( StructKeyExists(request.cf_PageController,"isPageControllerLoaded") AND request.cf_PageController.isPageControllerLoaded )>
		<cfset arguments.vars.Controller = getPageController(path=arguments.path,Caller=arguments.vars)>
		<cfset arguments.vars.PageController = arguments.vars.Controller>
		<cfif StructKeyExists(arguments.vars.Controller,"loadData")>
			<cfset StructAppend(arguments.vars,arguments.vars.Controller.loadData(arguments.vars))>
		</cfif>
	</cfif>
	
	<cfset request.cf_PageController.isPageControllerLoaded = true>
	
	<cfreturn arguments.vars.PageController>
</cffunction>

<cffunction name="getBrowserPath" access="public" returntype="string" output="no">
	<cfargument name="FilePath" type="string" required="yes">
	
	<cfset var dirdelim = CreateObject("java", "java.io.File").separator>
	<cfset var result = ReplaceNoCase(arguments.FilePath,ExpandPath("/"),"")>
	
	<!--- Browser paths are always "/", regardless of OS --->
	<cfset result = ListChangeDelims(result,"/","\")>
	
	<!--- Make sure browser path starts and ends with "/" --->
	<cfif Left(result,1) NEQ "/">
		<cfset result = "/#result#">
	</cfif>
	<cfif Right(arguments.FilePath,1) EQ dirdelim AND Right(result,1) NEQ "/">
		<cfset result = "#result#/">
	</cfif>
	
	<cfreturn result>
</cffunction>

<cfscript>
function getPageController(path) {
	
	var ControllerFilePath = "";
	var ControllerBrowserPath = "";
	var oPageController = 0;
	var oService = 0;
	var CompPath = path;
	var RootPath = ExpandPath("/");
	
	//Copy path to ControllerFilePath
	ControllerFilePath = arguments.path;
	
	//Change file extension to .cfc
	if ( ListLen(ControllerFilePath,".") GT 1 ) {
		ControllerFilePath = reverse(ListRest(reverse(ControllerFilePath),"."));
	}
	ControllerFilePath = "#ControllerFilePath#.cfc";
	
	//Make sure ControllerFilePath is a valid file path
	if ( NOT FileExists(ControllerFilePath) ) {
		if ( Left(ControllerFilePath,1) EQ "/" ) {
			ControllerFilePath = ReplaceNoCase(ControllerFilePath,"/",RootPath,"ONE");
		} else {
			ControllerFilePath = getDirectoryFromPath(getBaseTemplatePath()) & arguments.path;
			if ( ListLast(ControllerFilePath,".") NEQ "cfc" ) {
				ControllerFilePath = "#ControllerFilePath#.cfc";;
			}
		}
	}
	
	if ( FileExists(ControllerFilePath) ) {
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
	
	oPageController = CreateObject("component",CompPath).init(path=getBrowserPath(path));
	/*
	if ( FileExists(ControllerFilePath) ) {
		oPageController = CreateObject("component",CompPath);
	} else {
		oPageController = CreateObject("component","_config.PageController");
		oService = getService(getBrowserPath(path));
		if ( isDefined("oService") ) {
			oPageController.setScriptName(getBrowserPath(path));
			oPageController.setInherits(oService);
		}
	}
	*/
	return oPageController;
}
/** http://www.elliottsprehn.com/blog/2007/07/17/getting-the-expected-results-for-getcurrenttemplatepath-in-a-custom-tag/ */
/** Gets the path to the page that called this custom tag. */
function getCallerTemplatePath() {
	var field = getMetaData(Caller).getDeclaredField("pageContext");
	field.setAccessible(true);
	return field.get(caller).getPage().getCurrentTemplatePath();
}
if (  NOT ( StructKeyExists(attributes,"reload") AND isBoolean(attributes.reload) )  ) {
	attributes.reload = true;
}
/** default attributes.page to the path to the calling page */
if (  NOT ( StructKeyExists(attributes,"page") AND Len(Trim(attributes.page)) )  ) {
	attributes.page = getCallerTemplatePath();
}
if ( ListLen(attributes.page,"/") EQ 1 AND ListLen(attributes.page,"\") EQ 1 ) {
	attributes.page = getDirectoryFromPath(getCallerTemplatePath()) & attributes.page;
}
/** default attributes.vars to the variables on the calling page */
if (  NOT ( StructKeyExists(attributes,"vars") AND isStruct(attributes.vars) )  ) {
	attributes.vars = Caller;
}
//loadPageController(attributes.vars,attributes.page,attributes.reload);
if (  StructKeyExists(Application,"Framework") AND isObject(Application.Framework) AND StructKeyExists(Application.Framework,"loadPageController")  ) {
	oPageController = Application.Framework.loadPageController(attributes.vars,attributes.page,attributes.reload);
} else {
	oPageController = loadPageController(attributes.vars,attributes.page,attributes.reload);
}
if ( StructKeyExists(oPageController,"checkAccess") ) {
	oPageController.checkAccess();
}
</cfscript>
</cfsilent>