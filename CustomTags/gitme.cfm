<cfparam name="Attributes.location" type="string" default="#getDirectoryFromPath(getBaseTemplatePath())#">
<cfparam name="Attributes.environment" type="string" default="unknown">
<cfparam name="Attributes.domain" type="string" default="">
<cfparam name="Attributes.action" type="string" default="pull">

<cfset environments = "local,development,production">

<cfif NOT ListFindNocase(environments,Attributes.environment)>
	<cfset Attributes.environment = "unknown">
</cfif>

<cfset isGuessedEnvironment = false>

<!--- Guess at the environment --->
<cfif Len(Trim(Attributes.domain)) AND Attributes.environment EQ "unknown">
	<cfset prefix = ListFirst(Attributes.domain,".")>
	<cfset suffix = ListLast(Attributes.domain,".")>
	<cfif prefix EQ "www">
		<cfset Attributes.environment = "production">
		<cfset isGuessedEnvironment = true>
	<cfelseif prefix EQ "local" OR suffix EQ "local">
		<cfset Attributes.environment = "local">
		<cfset isGuessedEnvironment = true>
	<cfelseif prefix EQ "test" OR prefix EQ "test">
		<cfset Attributes.environment = "development">
		<cfset isGuessedEnvironment = true>
	</cfif>
</cfif>

<cfscript>
folder = GetDirectoryFromPath(Attributes.location);
delim = Right(folder,1);
AvailableActions = "pull,branch";
if ( Attributes.environment EQ "local" OR Attributes.environment EQ "development" AND NOT isGuessedEnvironment ) {
	AvailableActions = ListAppend(AvailableActions,"switch");
}

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

<cfinvoke component="#oGit#" method="#Attributes.action#" environment="#Attributes.environment#" returnvariable="result" argumentCollection="#Attributes#">

<cfoutput>
	<cfif isDefined("result") AND isSimpleValue(result) AND Len(Trim(result))>
		#Trim(result)#
	<cfelse>
		Git #HTMLEditFormat(Attributes.action)# performed (in #Attributes.environment# environment).
	</cfif>
</cfoutput>