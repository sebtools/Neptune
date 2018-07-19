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
function makeCompPath(Path,RootPath) {
    var CompPath = Arguments.Path;

    if ( Left(CompPath,Len(RootPath)) EQ RootPath ) {
        CompPath = ReplaceNoCase(CompPath,RootPath,"");
    }

    CompPath = ListChangeDelims(CompPath,"/","\");

    if ( ListLen(CompPath,".") GT 1 ) {
        CompPath = reverse(ListRest(reverse(CompPath),"."));// Remove file extension
    }

    CompPath = ListChangeDelims(CompPath,".","/");// Change from browser path to component path

    return CompPath;
}
function makeFilePath(Path,RootPath) {
    var FilePath = Arguments.Path;

    //Make sure ControllerFilePath is a valid file path
	if ( NOT ( FileExists(FilePath) OR DirectoryExists(getDirectoryFromPath(FilePath)) ) ) {
        if ( Left(FilePath,1) EQ "/" ) {
            FilePath = ReplaceNoCase(FilePath,"/",RootPath,"ONE");
            FilePath = ListChangeDelims(FilePath,Right(RootPath,1),"/");
        } else {
            FilePath = getDirectoryFromPath(getBaseTemplatePath()) & Arguments.path;
            if ( ListLast(FilePath,".") NEQ "cfc" ) {
                FilePath = "#FilePath#.cfc";;
            }
        }
    }

    return FilePath;
}
function FolderUp(FilePath,RootPath) {
    var result= GetDirectoryFromPath(makeFilePath(Arguments.FilePath,Arguments.RootPath));
    var delim = Right(result,1);

    //Ditch last folder to move up a level
    if ( ListLen(result,delim) ) {
        result = ListDeleteAt(result,ListLen(result,delim),delim) & delim;
    }

    //Make sure not to go outside of the RootPath
    if (
        NOT
        (
                Len( result ) GT Len(Arguments.RootPath)
            AND Left(result,Len(Arguments.RootPath)) EQ Arguments.RootPath
        )
    ) {
        result = Arguments.RootPath;
    }

    return result;
}
function getPageControllerCompPath(Path,RootPath) {
	var ControllerFilePath = arguments.Path;//Copy path to ControllerFilePath
    var ii = 0;

	//Change file extension to .cfc
	if ( ListLen(ControllerFilePath,".") GT 1 ) {
		ControllerFilePath = reverse(ListRest(reverse(ControllerFilePath),"."));
	}
	ControllerFilePath = "#ControllerFilePath#.cfc";
    ControllerFilePath = makeFilePath(ControllerFilePath,RootPath);

	if ( FileExists(ControllerFilePath) ) {
		return makeCompPath(ControllerFilePath,RootPath);
	} else {
        ControllerFilePath = getDirectoryFromPath(ControllerFilePath) & "PageController.cfc";
		//Go up the tree until you find a PageController (or fail to)
        while ( ii LTE 16 ) {
            if ( FileExists(ControllerFilePath) ) {
                return makeCompPath(ControllerFilePath,RootPath);
            } else if ( ControllerFilePath EQ "#RootPath#PageController.cfc" ) {
                return "_config.PageController";
            }
            ii++;
            ControllerFilePath = FolderUp(ControllerFilePath,RootPath) & "PageController.cfc";
        }
        //Only if 16 levels were reached without finding a PageController or the site root.
        return "_config.PageController";
	}

    //Shouldn't be a way to get here.
	return "_config.PageController";
}
function getPageController(path) {
	return CreateObject("component",getPageControllerCompPath(path)).init(path=getBrowserPath(path));
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
