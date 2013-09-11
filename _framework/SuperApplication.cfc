<!--- 1.0 Beta 2 (Build 26) --->
<!--- Last Updated: 2012-08-05 --->
<cfcomponent hint="Application.cfc for Neptune Framework: http://www.bryantwebconsulting.com/docs/neptune/">

<cfif ListLast(CGI.SCRIPT_NAME,".") EQ "cfc">
	<cfsetting showDebugOutput="no">
</cfif>

<cfscript>
sSuper = getMetaData(This);
This["ClientManagement"] = "Yes";
This["SessionManagement"] = "Yes";
setMappings(getDirectoryFromPath(sSuper.Path));
</cfscript>

<cffunction name="onRequestStart">
	<cfset var sLocal = getMetaData(This)>
	
	<cfinclude template="/_config/invoke.cfm">
	<cfif ListFirst(CGI.SCRIPT_NAME,"/") EQ "admin">
		<cf_layout switch="Admin">
	</cfif>
</cffunction>

<cffunction name="onRequest"><cfinclude template="#arguments[1]#"></cffunction>

<cfscript>
if( ListLast(CGI.SCRIPT_NAME, ".") is "cfc" ) {
	StructDelete(THIS, "onRequest");
	StructDelete(VARIABLES, "onRequest");
}
</cfscript>

<cffunction name="setMappings" access="public">
	<cfargument name="FrameworkDir" type="string" required="yes">
	<!---<cfargument name="SiteDir" type="string" required="yes">--->
	
	<cfscript>
	var dirdelim = Right(Arguments.FrameworkDir,1);
	var CTDir = ListDeleteAt(Arguments.FrameworkDir,ListLen(Arguments.FrameworkDir,dirdelim),dirdelim) & dirdelim;
	var CTSubDir =  "#CTDir#CustomTags#dirdelim#";
	var FrameworkCTDir =  "#Arguments.FrameworkDir#CustomTags#dirdelim#";
	if ( NOT ListFindNoCase(CTDir,"CustomTags",dirdelim) ) {
		//writeDump(CTDir);
		
		if ( DirectoryExists(CTSubDir) ) {
			CTDir = CTSubDir;
		} else if ( DirectoryExists(FrameworkCTDir) ) {
			CTDir = FrameworkCTDir;
		}
	}
	
	This["Mappings"] = StructNew();
	if ( DirectoryExists(CTDir) ) {
		This.CustomTagPaths = CTDir;
	}
	This["Mappings"]["/" & ListLast(Arguments.FrameworkDir,dirdelim)] = Arguments.FrameworkDir;
	if ( DirectoryExists("#CTDir#com#dirdelim#") ) {
		This["Mappings"]["/com"] = "#CTDir#com#dirdelim#";
	}// else {
	//	This["Mappings"]["/com"] = "#Arguments.SiteDir#com#dirdelim#";
	//}
	
	//This["Name"] = Hash(Arguments.SiteDir);
	//This["Mappings"]["/layouts"] = Arguments.SiteDir & "layouts" & dirdelim;
	</cfscript><!---<cfdump var="#This.CustomTagPaths#"><cfabort>--->
	
</cffunction>

<!---<cffunction name="onError">
	<cfdump var="#arguments#"><cfabort>
</cffunction>

<cffunction name="onMissingTemplate">
	<cfdump var="#arguments#"><cfabort>
</cffunction>--->

</cfcomponent>