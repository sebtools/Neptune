<cfcomponent>

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="SiteRoot" type="string" required="true">
	<cfargument name="MainBranch" type="string" default="master">
	
	<cfset Variables.SiteRoot = Arguments.SiteRoot>
	<cfset Variables.MainBranch = Arguments.MainBranch>
	
	<cfset Variables.oGit = CreateObject("component","model.git").init(Arguments.SiteRoot)>
	
	<cfreturn This>
</cffunction>

<cffunction name="pull" access="remote" returntype="any" output="no">
	
	<cfset checkActiveBranch()>
	
	<cfset oGit.pull()>
	
</cffunction>

<cffunction name="checkActiveBranch" access="private" returntype="string" output="no">
	
	<cfset var ActiveBranch = "">
	
	<cfif Len(Variables.MainBranch)>
		<cfset ActiveBranch = Variables.oGit.branch(active=true)>
		<cfif Variables.MainBranch NEQ ActiveBranch>
			<cfthrow message="#Variables.MainBranch# branch is not currently active.">
		</cfif>
	</cfif>
	
</cffunction>

<cffunction name="getMainBranch" access="private" returntype="string" output="no">
	
	<cfset var oConfig = 0>
	
	<cfif StructKeyExists(Application,"Framework") AND StructKeyExists(Application.Framework,"Config")>
		<cfset oConfig = Application.Framework.Config>
		<cfif oConfig.exists("GitBranch")>
			<cfreturn oConfig.getValue("GitBranch")>
		</cfif>
		<cfif oConfig.exists("Environment")>
			<cfswitch expression="#oConfig.getValue('Environment')#">
			<cfcase value="Dev,Development">
				<cfreturn "Dev">
			</cfcase>
			<cfcase value="Production">
				<cfreturn "master">
			</cfcase>
			<cfdefaultcase>
				<cfreturn "">
			</cfdefaultcase>
			</cfswitch>
		</cfif>
	</cfif>
	
	<cfreturn "">
</cffunction>

</cfcomponent>