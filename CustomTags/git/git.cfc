<cfcomponent>

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="SiteRoot" type="string" required="true">
	<cfargument name="MainBranch" type="string" default="master">
	
	<cfset Variables.SiteRoot = Arguments.SiteRoot>
	<cfset Variables.MainBranch = Arguments.MainBranch>
	
	<cfset Variables.oGit = CreateObject("component","model.git").init(Arguments.SiteRoot)>
	
	<cfreturn This>
</cffunction>

<cffunction name="branch" access="public" returntype="string" output="no">
	
	<cfreturn getActiveBranch()>
</cffunction>

<cffunction name="switch" access="public" returntype="string" output="no">
	
	<cfset oGit.checkout(Arguments.branch)>
	<cfset pull(environment=Arguments.environment)>
	
	<cfreturn getActiveBranch()>
</cffunction>

<cffunction name="pull" access="remote" returntype="any" output="no">
	
	<cfif Arguments.environment EQ "production">
		<cfset checkActiveBranch()>
		
		<cfset oGit.pull()>
	<cfelse>
		<cfset oGit.pull("origin " & Variables.oGit.branch(active=true))>
	</cfif>
	
</cffunction>

<cffunction name="checkActiveBranch" access="private" returntype="string" output="no">
	
	<cfif Len(Variables.MainBranch) AND Variables.MainBranch NEQ getActiveBranch()>
		<cfthrow message="#Variables.MainBranch# branch is not currently active.">
	</cfif>
	
</cffunction>

<cffunction name="getActiveBranch" access="private" returntype="string" output="no">
	
	<cfreturn Variables.oGit.branch(active=true)>
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