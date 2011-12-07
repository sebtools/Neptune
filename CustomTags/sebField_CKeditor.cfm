<cfparam name="attributes.width" type="string" default="520">
<cfparam name="attributes.height" type="numeric" default="700">

<cfparam name="attributes.EnterMode" type="string" default="CKEDITOR.ENTER_P">

<!--- Provided for easy swap with sebField_FCKEditor --->
<cfparam name="attributes.toolbarset" type="string" default="">
<cfparam name="attributes.toolbar" type="string" default="#attributes.toolbarset#">
<cfset instanceToolbar = "#jsStringFormat(attributes.toolbar)#">

<cfif NOT len(trim(attributes.urlpath))>
	<cfset attributes.urlpath = "/f/fckeditor/">
</cfif>
<cfif isDefined("Application")>
	<cflock scope="Application" type="exclusive" timeout="20">
		<cfset Application.userFilesPath = attributes.urlpath>
	</cflock>
</cfif>
<cfif isDefined("Application") AND StructKeyExists(Application,"SessionMgr")>
	<cfset Application.SessionMgr.setValue("CKeditor",true)>
<cfelseif isDefined("Session")>
	<cfset Session.CKeditor = true>
<cfelseif isDefined("Client")>
	<cfset Client.CKeditor = true>
</cfif>


<cfparam name="attributes.CKURL" type="string" default="#ParentAtts.librarypath#ckeditor">
<cfparam name="attributes.FileBrowserUploadURLBase" type="string" default="#attributes.CKURL#/filemanager/connectors/cfm/filemanager.cfm?mode=add">

<cfparam name="attributes.FileBrowserBrowseURL" type="string" default="#attributes.CKURL#/filemanager/index.html">
<cfparam name="attributes.FileBrowserImageBrowseURL" type="string" default="#attributes.FileBrowserBrowseURL#?type=Images&currentFolder=/Image/">
<cfparam name="attributes.FileBrowserFlashBrowseURL" type="string" default="#attributes.FileBrowserBrowseURL#?type=Flash&currentFolder=/Flash/">

<cfparam name="attributes.FileBrowserUploadURL" type="string" default="#attributes.FileBrowserUploadURLBase#&type=Files&currentFolder=/File/">
<cfparam name="attributes.FileBrowserImageUploadURL" type="string" default="#attributes.FileBrowserUploadURLBase#&type=Images&currentFolder=/Image/">
<cfparam name="attributes.FileBrowserFlashUploadURL" type="string" default="#attributes.FileBrowserUploadURLBase#&type=Flash&currentFolder=/Flash/">

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
<cfif structKeyExists(attributes,"ServerPreviewURL")
	AND len(trim(attributes.ServerPreviewURL)) GT 0>
	<input type="hidden" id="server-preview-url" value="#attributes.ServerPreviewURL#">
</cfif>

<!--- Default toolbar --->
<cfif len(trim(attributes.toolbar)) EQ 0>
<script type="text/javascript">
	var instanceToolbar = [
		["Source"],
		["Cut","Copy","Paste","PasteText","PasteFromWord","-"],
		["Undo","Redo","-","Find","Replace","-","SelectAll","RemoveFormat"],
		["Image","Flash","Table","HorizontalRule","SpecialChar","PageBreak"],
		"/",
		["Styles","Format"],
		["Bold","Italic","Strike"],
		["NumberedList","BulletedList","-","Outdent","Indent","Blockquote"],
		["Link","Unlink","Anchor"],
		["Maximize"]
	];
</script>
<cfelse>
<script type="text/javascript">
	var instanceToolbar = [#attributes.toolbar#];
</script>
</cfif>
<cfset instanceToolbar = "instanceToolbar">

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
					customConfig:					"",
					height:							#attributes.Height#,
					toolbar:						#instanceToolbar#,
					width:							#attributes.Width#,
					filebrowserBrowseUrl:			"#jsStringFormat(attributes.FileBrowserBrowseURL)#",
					filebrowserUploadUrl:			"#jsStringFormat(attributes.FileBrowserUploadURL)#",
					filebrowserImageBrowseUrl:		"#jsStringFormat(attributes.FileBrowserImageBrowseURL)#",
					filebrowserImageUploadUrl:		"#jsStringFormat(attributes.FileBrowserImageUploadURL)#",
					filebrowserFlashBrowseUrl:		"#jsStringFormat(attributes.FileBrowserFlashBrowseURL)#",
					filebrowserFlashUploadUrl:		"#jsStringFormat(attributes.FileBrowserFlashUploadURL)#",
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