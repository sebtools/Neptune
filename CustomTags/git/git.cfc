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

<cffunction name="getLast" access="public" returntype="any" output="yes">
	
	<cfset var result = oGit.log("-1")>
	<cfset var sCommit = StructNew()>
	
	<cfset sCommit["id"] = Trim(ReplaceNoCase(REGet(result,"commit\s*[\w\d]+")[1],"commit",""))>
	<cfset sCommit["Author"] = Trim(ReplaceNoCase(REGet(result,"Author:([^\r\n])*")[1],"Author:",""))>
	<cfset sCommit["Date"] = Trim(ReplaceNoCase(REGet(result,"Date:([^\r\n])*")[1],"Date:",""))>
	
	<cfset result = ReReplaceNoCase(result,"\s{2,}"," ","ALL")>
	<cfset result = ReplaceNoCase(result,"commit #sCommit.id#","")>
	<cfset result = ReplaceNoCase(result,"Author: #sCommit.Author#","")>
	<cfset result = ReplaceNoCase(result,"Date: #sCommit.Date#","")>
	
	<cfset sCommit["Message"] = Trim(result)>
	
	<cfreturn result>
</cffunction>

<cffunction name="showLast" access="remote" returntype="any" output="no">
	
	<cfset var result = oGit.log("-1")>
	
	<cfreturn result>
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

<cfscript>
/**
 * Returns all the matches of a regex from a string.
 * Bug fix by  Ruben Pueyo (ruben.pueyo@soltecgroup.com)
 * 
 * @param str      The string to search. (Required)
 * @param regex      The regular expression to search for. (Required)
 * @return Returns an array. 
 * @author Raymond Camden (ruben.pueyo@soltecgroup.comray@camdenfamily.com) 
 * @version 2, June 6, 2003 
 */
function REGet(str,regex) {
    var results = arrayNew(1);
    var test = REFind(regex,str,1,1);
    var pos = test.pos[1];
    var oldpos = 1;
    while(pos gt 0) {
        arrayAppend(results,mid(str,pos,test.len[1]));
        oldpos = pos+test.len[1];
        test = REFind(regex,str,oldpos,1);
        pos = test.pos[1];
    }
    return results;
}
</cfscript>

</cfcomponent>