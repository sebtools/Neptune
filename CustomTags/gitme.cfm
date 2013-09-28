<cfparam name="Attributes.location" type="string" default="#getDirectoryFromPath(getBaseTemplatePath())#">
<cfparam name="Attributes.action" type="string" default="pull">

<cfscript>
folder = GetDirectoryFromPath(Attributes.location);
delim = Right(folder,1);
AvailableActions = "pull";

attempts = 0;
foundGit = false;
</cfscript>

<cfif NOT ListFindNoCase(AvailableActions,Attributes.action)>
	<cfthrow type="gitme" message="The requested Git command is not available by this method.">
</cfif>

<cfloop condition="DirectoryExists(folder) AND attempts LT 3 AND NOT foundGit">
	<cfset attempts = attempts + 1>
	<cfdirectory action="list" name="qDirs" directory="#folder#" filter=".git" type="dir">
	<cfif qDirs.RecordCount>
		<cfset foundGit = true>
		<cfbreak>
	<cfelse>
		<cfset folder = ListDeleteAt(folder,ListLen(folder,delim),delim)>
	</cfif>
</cfloop>
<cfif NOT foundGit>
	<cfthrow type="gitme" message="Unable to find .git folder for the given location.">
</cfif>

<cfset oGit = CreateObject("component","git.git").init(folder)>

<cfinvoke component="#oGit#" method="#Attributes.action#">

<cfoutput>
Git #HTMLEditFormat(Attributes.action)# performed.
</cfoutput>