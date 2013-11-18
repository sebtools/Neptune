<cflock name="#CreateUUID()#" timeout="120">
	<cfset env = GetProfileString(getDirectoryFromPath(getCurrentTemplatePath()) & 'settings.ini','settings','environment')>
	<cfif Len(env) AND NOT StructKeyExists(Attributes,"environment")>
		<cfset Attributes.environment = env>
	</cfif>
	<cfset sURL = StructCopy(URL)>
	<cfset StructDelete(sURL,"environment")> 
	<cfset StructAppend(Attributes,sURL,false)>
	<cf_gitme AttributeCollection="#Attributes#">
</cflock>