<!---

	Filemanager Coldfusion connection configuration
	
	filemanager.config.cfm
	config for the filemanager.cfm connector
	
	@license MIT License
	@author James Gibson <james.gibson (at) liquifusion (dot) com>
	@copyright Author

--->
<cfsilent>
	<!--- include our configuration file --->
	<cfset RootPath = ExpandPath('/')>
	<cfset CKEPath = RootPath & "ckeditor.cfm">
	<cfif FileExists(CKEPath)>
		<cfinclude template="/ckeditor.cfm" />
	<cfelse>
	
		<cfsavecontent variable="ckeContents">
This file is used to configure authorization for use of the ckeditor filemanager. If Application scope is not available in this file already,
you need to add a cfapplication tag that matches the one for this site. To configure authorization, you should write a function here that
will be used by the ckeditor filemanager to determine its availability to the current user. Then store the function itself in Application
scope as isCKAuthorized. Here is an example:
<cfset code = '<!---
<cffunction name="isCKAuthorized">
	<cfscript>
	var result = false;
	if ( isDefined("request.SessionInfo.adminid") AND request.SessionInfo.adminid gt 0 ) {
		result = true;
	}
	return result;
	</cfscript>
</cffunction>
<cfset Application.isCKAuthorized = isCKAuthorized>--->'>
<cfoutput>#code#</cfoutput>
		</cfsavecontent>
		
		<cffile action="write" file="#CKEPath#" output="#ckeContents#">
	</cfif>
	
	<cfset config = {
		  language = "en"
	} />
	
	
	<cffunction name="authorize" access="public" output="false" returntype="boolean">
		<cfset var returnValue = false>
		
		<cfif isDefined("Application") AND StructKeyExists(Application,"isCKAuthorized")>
			<cfif isCustomFunction(Application.isCKAuthorized)>
				<cfset returnValue = Application.isCKAuthorized()>
			<cfelse>
				<cfset returnValue = Application.isCKAuthorized>
			</cfif>
		</cfif>

		<cfreturn returnValue />
	</cffunction>
	
	<!--- icon settings --->
	<cfset config.icons = {
		  path = "/lib/ckeditor/skins/Free-file-icons/32px/"
		, directory = "_blank.png"
		, default = "_page.png"
	} />
	
	<!--- upload settings --->
	<cfset config.upload = {
		  nameConflict = "overwrite"
		, size = false 
		, imagesOnly = false
		, exclude = "cfm,cfml,cfc,dbm,jsp,asp,aspx,exe,php,cgi,shtml,rb,msi"
	} />
	
	<!--- allowed image file types --->
	<cfset config.images = {
		  createThumbnail = true
		, thumbnailFolder = "_thumbs"
		, extensions = "jpg,jpeg,gif,png"
	} />
	
	<!--- files and folders to exclude from the tree view --->
	<cfset config.tree = {
		  exclude = ".htaccess,_thumbs"
	} />

	<!--- root folder to use, do not include an ending slash --->
	<cfset config.base = "f/fckeditor" />
	
	<!--- plugins to execute when the coldfusion file manager is run --->
	<cfset config.plugins = [] />
	
	<cfif isDefined("Application") AND StructKeyExists(Application,"configCKEditor")>
		<cfset StructAppend(config,Application.configCKEditor,true)>
		
		<cfif NOT StructKeyExists(config,"ServerRoot")>
			<cfset config["ServerRoot"] = true>
		</cfif>
		<cfif NOT StructKeyExists(config,"FileRoot")>
			<cfif config.ServerRoot>
				<cfset config["FileRoot"] = "/f/fckeditor/">
			<cfelse>
				<cfset config["FileRoot"] = "f/fckeditor/">
			</cfif>
		</cfif>
		
		<cfset config.FileRoot = Replace(config.FileRoot,"\","/","all")>
		<cfset config.base = config.FileRoot>
	</cfif>
	
</cfsilent>
