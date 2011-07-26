<cfparam name="attributes.width" type="string" default="520">
<cfparam name="attributes.height" type="numeric" default="700">
<cfparam name="attributes.toolbarset" type="string" default="seb">
<cfparam name="attributes.EditorAreaCSS" type="string" default="">
<cfparam name="attributes.StylesXmlPath" type="string" default="">
<cfparam name="attributes.fmdir" type="string" default="filemanager">
<cfscript>
if ( NOT Len(attributes.urlpath) ) {
	attributes.urlpath = "/f/fckeditor/";
}
Application.userFilesPath = attributes.urlpath;
</cfscript>
<cfsavecontent variable="input"><cfoutput>
<!--- <cf_fckeditor instanceName="#myatts.fieldname#" width="520" height="700" value="#myatts.Value#" basePath="#ParentAtts.librarypath#fckeditor/"> --->
<script type="text/javascript" src="#ParentAtts.librarypath#fckeditor/fckeditor.js"></script>
<textarea name="#attributes.fieldname#" style="width:#attributes.width#px;height:#attributes.height#px">#attributes.value#</textarea>
<cfset UserFilesString = URLEncodedFormat("?UserFiles=#attributes.urlpath#")>
<cfset ConnectorString = "Connector=connectors/cfm/connector.cfm&ServerPath=#attributes.urlpath#"><!---  & UserFilesString --->
<cftry>
	<cfset Session.userFilesPath = attributes.urlpath>
	<cfcatch>
	</cfcatch>
</cftry>
<script type="text/javascript">
function loadFckEditor() {
	var oFCKeditor = new FCKeditor( '#attributes.fieldname#' ) ;
	oFCKeditor.BasePath	= '#ParentAtts.librarypath#fckeditor/';
	oFCKeditor.Config['CustomConfigurationsPath'] = oFCKeditor.BasePath + 'sebconfig.js';
	oFCKeditor.Config.LinkBrowserURL = oFCKeditor.BasePath + 'editor/#attributes.fmdir#/browser/default/browser.html?#ConnectorString#' ;
	oFCKeditor.Config.ImageBrowserURL = oFCKeditor.BasePath + 'editor/#attributes.fmdir#/browser/default/browser.html?Type=Image&#ConnectorString#' ;
	oFCKeditor.Config.FlashBrowserURL = oFCKeditor.BasePath + 'editor/#attributes.fmdir#/browser/default/browser.html?Type=Flash&#ConnectorString#' ;
	oFCKeditor.Config.LinkUploadURL = oFCKeditor.BasePath + 'editor/#attributes.fmdir#/upload/cfm/upload.cfm?UserFiles=#attributes.urlpath#&editorpath=' + oFCKeditor.BasePath ;
	oFCKeditor.Config.ImageUploadURL = oFCKeditor.BasePath + 'editor/#attributes.fmdir#/upload/cfm/upload.cfm?UserFiles=#attributes.urlpath#&Type=Image&editorpath=' + oFCKeditor.BasePath ;
	oFCKeditor.Config.FlashUploadURL = oFCKeditor.BasePath + 'editor/#attributes.fmdir#/upload/cfm/upload.cfm?UserFiles=#attributes.urlpath#&Type=Flash&editorpath=' + oFCKeditor.BasePath ;
	<cfif Len(Trim(attributes.EditorAreaCSS))>oFCKeditor.Config.EditorAreaCSS = '#attributes.EditorAreaCSS#';</cfif>
	<cfif Len(Trim(attributes.StylesXmlPath))>oFCKeditor.Config.StylesXmlPath = '#attributes.StylesXmlPath#';</cfif>
	<cfif Len(Trim(attributes.toolbarset))>oFCKeditor.ToolbarSet = '#attributes.toolbarset#';</cfif>
	oFCKeditor.Width = '#attributes.width#';
	oFCKeditor.Height = '#attributes.height#';
	oFCKeditor.ReplaceTextarea();
	//oFCKeditor.Value = '#JSStringFormat(attributes.value)#';
	//oFCKeditor.Create();
}
loadFckEditor();
</script>
</cfoutput></cfsavecontent>