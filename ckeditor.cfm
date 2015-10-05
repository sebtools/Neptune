

<cffunction name="isCKAuthorized">
	<cfscript>
	var result = false;
	if ( Application.SessionMgr.exists("AdminID") AND Application.SessionMgr.getValue("AdminID") GT 0 ) {
		result = true;
	}
	return result;
	</cfscript>
</cffunction>
<cfset Application.isCKAuthorized = isCKAuthorized> 
<cfset Application.configCKEditor = Application.Framework.Config.getSetting('ckeditor')>
