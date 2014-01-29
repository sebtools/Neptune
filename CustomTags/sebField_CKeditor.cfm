<!--- 
Site Configuration Instructions

1.	Copy the ckeditor folder (including the FileManager plugin) to the site's library folder.
	This must be the same folder as configured in sebField's librarypath attribute.
2.	Copy Free-file-icons to ckeditor skins folder. (https://github.com/teambox/Free-file-icons)
3.	Add a ckeditor attribute to sebField in the site's config.cfm file (or equivalent).
	E.g. request.cftags.cf_sebField.ckeditor = StructNew().
4.	If the folder for file upload using CKEditor FileManager is NOT in the webroot for the site:
		Set request.cftags.cf_sebField.ckeditor.ServerRoot = false in the site's config file. The default value is true.
		Set request.cftags.cf_sebField.ckeditor.FileRoot as a full file path in the config file.
		E.g. request.cftags.cf_sebField.ckeditor.FileRoot = "/home/timd/git/okmrc/www/f/fckeditor/".
		Set request.cftags.cf_sebField.ckeditor.RelPath = the path for outside webroot folders in the config file.
		E.g. request.cftags.cf_sebField.ckeditor.RelPath = "/file.cfm?file=ckeditor/". The default value is false.
5.	If the folder for file upload using CKEditor FileManager IS in the site's webroot, use a webroot path for FileRoot.
		E.g. request.cftags.cf_sebField.ckeditor.FileRoot = "/userfiles/ckeditor/". The default value is "/f/fckeditor/".
6.	Note that you could also pass a struct to the ckeditor attribute in sebField to customize file upload location for
	an individual form. This could allow outside the root uploads for privacy sensitive forms and inside the root
	uploads for standard CMS-type uploads. Some sites may be using both type with FCKEditor already, so be careful
	to take this into consideration when configuring a site.
7.	Add a ckeditor.cfm to the webroot. That file must have both an isCKAuthorized function stored in Application scope, and configCKEditor
	stored in Application scope. See okmrc.org for good examples.
8.	Make admin layout doctype HTML for IE 10. This will also require that the css for the admin must default all td elements to text-align: left.
	IE 10 defaults all td elements to text-align: center when doctype is HTML.
 --->
<cfparam name="attributes.width" type="string" default="520">
<cfparam name="attributes.height" type="numeric" default="700">

<cfparam name="attributes.EnterMode" type="string" default="CKEDITOR.ENTER_P">
<cfparam name="attributes.CKStyles" type="string" default="">

<!--- Provided for easy swap with sebField_FCKEditor --->
<cfparam name="attributes.toolbarset" type="string" default="">
<cfparam name="attributes.toolbarGroups" type="string" default="#attributes.toolbarset#">
<cfset instanceToolbarGroups = "#jsStringFormat(attributes.toolbarGroups)#">
<cfif NOT StructKeyExists(attributes,"ckeditor")>
	<cfset attributes["ckeditor"] = StructNew()>
</cfif>
<cfif NOT StructKeyExists(attributes.ckeditor,"ServerRoot")>
	<cfset attributes.ckeditor["ServerRoot"] = true>
</cfif>
<cfif NOT StructKeyExists(attributes.ckeditor,"FileRoot")>
	<cfset attributes.ckeditor["FileRoot"] = "/f/fckeditor/">
</cfif>
<cfif NOT StructKeyExists(attributes.ckeditor,"RelPath")>
	<cfset attributes.ckeditor["RelPath"] = false>
</cfif>
<cfset attributes.ckeditor["FileRoot"] = Replace(attributes.ckeditor["FileRoot"],"\","/","all")>

<!--- <cfif NOT len(trim(attributes.urlpath))>
	<cfset attributes.urlpath = "/f/fckeditor/">
</cfif>
<cfif isDefined("Application")>
	<cflock scope="Application" type="exclusive" timeout="20">
		<cfset Application.userFilesPath = attributes.urlpath>
	</cflock>
</cfif> --->
<cfif isDefined("Application") AND StructKeyExists(Application,"SessionMgr")>
	<cfset Application.SessionMgr.setValue("CKeditor",true)>
<cfelseif isDefined("Session")>
	<cfset Session.CKeditor = true>
<cfelseif isDefined("Client")>
	<cfset Client.CKeditor = true>
</cfif>


<cfparam name="attributes.CKURL" type="string" default="#ParentAtts.librarypath#ckeditor">
<!--- <cfparam name="attributes.FileBrowserUploadURLBase" type="string" default="#attributes.CKURL#/filemanager/connectors/cfm/filemanager.cfm?mode=add"> --->

<cfparam name="attributes.FileBrowserBrowseURL" type="string" default="#attributes.CKURL#/filemanager/index.html?fileroot=#attributes.ckeditor.FileRoot#&serverroot=#attributes.ckeditor.ServerRoot#&relpath=#URLEncodedFormat(attributes.ckeditor.RelPath)#">
<!--- <cfparam name="attributes.FileBrowserImageBrowseURL" type="string" default="#attributes.FileBrowserBrowseURL#?type=Images&currentFolder=/Image/">
<cfparam name="attributes.FileBrowserFlashBrowseURL" type="string" default="#attributes.FileBrowserBrowseURL#?type=Flash&currentFolder=/Flash/">

<cfparam name="attributes.FileBrowserUploadURL" type="string" default="#attributes.FileBrowserUploadURLBase#&type=Files&currentFolder=/File/">
<cfparam name="attributes.FileBrowserImageUploadURL" type="string" default="#attributes.FileBrowserUploadURLBase#&type=Images&currentFolder=/Image/">
<cfparam name="attributes.FileBrowserFlashUploadURL" type="string" default="#attributes.FileBrowserUploadURLBase#&type=Flash&currentFolder=/Flash/"> --->

<cfparam name="attributes.FileBrowserWindowWidth" type="string" default="840">
<cfparam name="attributes.FileBrowserWindowHeight" type="string" default="555">

<cfparam name="attributes.ExtraPlugins" type="string" default="">

<!--- Provided for easy swap with sebField_FCKEditor --->
<cfparam name="attributes.EditorAreaCSS" type="string" default="">
<cfparam name="attributes.ContentCSS" type="string" default="#attributes.EditorAreaCSS#">

<!--- Ensure that the css file is never cached --->
<cfif len(trim(attributes.ContentCSS))>
	<cfif NOT findNoCase("?",attributes.ContentCSS)>
		<cfset attributes.ContentCSS = "#attributes.ContentCSS#?">
	</cfif>
	<cfset attributes.ContentCSS = "#attributes.ContentCSS#&i=#urlEncodedFormat(randRange(1,99999999))#">
</cfif>

<cfsavecontent variable="input"><cfoutput>
<script type="text/javascript" src="#ParentAtts.librarypath#ckeditor/ckeditor.js"></script>
<script type="text/javascript" src="#ParentAtts.librarypath#ckeditor/config.js"></script>
<cfif structKeyExists(attributes,"ServerPreviewURL")
	AND len(trim(attributes.ServerPreviewURL)) GT 0>
	<input type="hidden" id="server-preview-url" value="#attributes.ServerPreviewURL#">
</cfif>

<!--- Default toolbar --->
<cfif len(trim(attributes.toolbarGroups)) EQ 0>
<script type="text/javascript">
	var instanceToolbarGroups = [
		{ name: 'document', groups: [ 'mode' ] },
		{ name: 'clipboard', groups: [ 'clipboard', 'undo' ] },
		{ name: 'editing', groups: [ 'find', 'selection', 'spellchecker' ] },
		'/',
		{ name: 'basicstyles', groups: [ 'basicstyles', 'cleanup' ] },
		{ name: 'paragraph', groups: [ 'list', 'indent', 'blocks', 'align', 'bidi' ] },
		{ name: 'links' },
		{ name: 'insert' },
		'/',
		{ name: 'styles' },
		{ name: 'colors' },
		{ name: 'tools' },
		{ name: 'others' }
	];
</script>
<cfelse>
<script type="text/javascript">
	var instanceToolbarGroups = [#attributes.toolbarGroups#];
</script>
</cfif>
<cfset instanceToolbarGroups = "instanceToolbarGroups">

<!--- textarea control --->
<textarea id="#attributes.id#" name="#attributes.fieldname#">#attributes.value#</textarea>

<!--- Copied from {ckeditor}/_samples/sample.js --->
<script type="text/javascript">
if (typeof console != "undefined") console.log();

if (window.CKEDITOR) {
	(function()	{
		var showCompatibilityMsg = function() {

			var env = CKEDITOR.env;

			var html = '<p><strong>Your browser is not compatible with CKEditor.</strong>';

			var browsers = {
					gecko:		"Firefox 2.0",
					ie:			"Internet Explorer 6.0",
					opera:		"Opera 9.5",
					webkit:		"Safari 3.0"
				};

			var alsoBrowsers = "";
			for (var key in env) {
				if (browsers[key]) {
					if (env[key]) {
						html += " CKEditor is compatible with " + browsers[key] + " or higher.";
					} else {
						alsoBrowsers += browsers[key] + "+, ";
					}
				}
			}

			alsoBrowsers = alsoBrowsers.replace( /\+,([^,]+), $/, "+ and $1");
			html += " It is also compatible with " + alsoBrowsers + ".";
			html += "</p><p>With non compatible browsers, you should still be able to see and edit the contents (HTML) in a plain text field.</p>";
			document.getElementById("alerts").innerHTML = html;
		};

		var onload = function() {
				// Show a friendly compatibility message as soon as the page is loaded, for those browsers that are not compatible with CKEditor.
				if (!CKEDITOR.env.isCompatible) showCompatibilityMsg();

				// Start the editor

				var oEditor = CKEDITOR.replace("#jsStringFormat(attributes.fieldname)#",{
					contentsCss:					"#jsStringFormat(attributes.ContentCSS)#",
					//customConfig:					"",
					allowedContent:					true,
					height:							#attributes.Height#,
					toolbarGroups:					#instanceToolbarGroups#,
					width:							#attributes.Width#,
					stylesSet:						"#jsStringFormat(attributes.CKStyles)#",
					filebrowserBrowseUrl:			"#jsStringFormat(attributes.FileBrowserBrowseURL)#",
					filebrowserWindowWidth: 		"#jsStringFormat(attributes.FileBrowserWindowWidth)#",
					filebrowserWindowHeight:		"#jsStringFormat(attributes.FileBrowserWindowHeight)#",
					extraPlugins:					"#jsStringFormat(attributes.ExtraPlugins)#",
					enterMode:						#attributes.EnterMode#
				});
			};

		// Register the onload listener.
		if (window.addEventListener)
			window.addEventListener("load",onload,false);
		else if (window.attachEvent)
			window.attachEvent("onload",onload);
	})();
}
</script>
</cfoutput></cfsavecontent>