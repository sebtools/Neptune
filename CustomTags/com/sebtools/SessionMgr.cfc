<cfcomponent displayname="SessionMgr" hint="I handle setting and retreiving session-related variables. Enabling storage mechanism for the variables to be changed.">
<!--- %%Must add time-out. --->
<cffunction name="init" access="public" returntype="SessionMgr" output="no" hint="I instantiate and return this object.">
	<cfargument name="scope" type="string" default="Session">
	<cfargument name="requestvar" type="string" default="SessionInfo">
	
	<cfset var scopes = "Client,Session">
	
	<cfif Not ListFindNoCase(scopes, arguments.scope)>
		<cfthrow message="The scope argument for SessionMgr must be a valid scope (#scopes#)." type="MethodErr">
	</cfif>
	
	<cfset variables.scope = arguments.scope>
	<cfset variables.requestvar = arguments.requestvar>
	<cfset updateRequestVar()>
	
	<cfreturn this>
</cffunction>

<cffunction name="paramVar" access="public" returntype="any" output="no" hint="I set a default value for the given variable.">
	<cfargument name="variablename" type="string" required="yes">
	<cfargument name="value" type="any" required="yes">
	
	<cfparam name="#variables.scope#.#arguments.variablename#" default="#arguments.value#">
	<cfset updateRequestVar()>

</cffunction>

<cffunction name="deleteVar" access="public" returntype="void" output="no" hint="I delete the given variable.">
	<cfargument name="variablename" type="string" required="yes">
	
	<cflock timeout="20" throwontimeout="Yes" name="SessionMgr" type="READONLY">
		<cfset StructDelete(Evaluate(variables.scope), arguments.variablename)>
	</cflock>
	<cfset updateRequestVar()>

</cffunction>

<cffunction name="killSession" access="public" returntype="void" output="no" hint="I delete all of the variables from this session.">
	
	<cfset var itms = dump()>
	<cfset var itm = "">
	
	<!--- Delete selected keys from struct to prevent problems when calling deleteVar on each key --->
	<cfset StructDelete(itms,"timecreated")>
	<cfset StructDelete(itms,"urltoken")>
	<cfset StructDelete(itms,"cftoken ")>
	<cfset StructDelete(itms,"cfid")>
	<cfset StructDelete(itms,"hitcount")>
	<cfset StructDelete(itms,"lastvisit")>
	
	<!--- Ditch all variables (except as already removed above) --->
	<cfloop collection="#itms#" item="itm">
		<cfset variables.deleteVar(itm)>
	</cfloop>
	
</cffunction>

<cffunction name="dump" access="public" returntype="struct" output="no" hint="I dump the scope holding SessionMgr data.">
	<cfreturn Duplicate(Evaluate(variables.scope))>
</cffunction>

<cffunction name="getSessionData" access="public" returntype="struct" output="no" hint="I return session data ( deprecated in favor of dump() ).">
	<cfreturn dump()>
</cffunction>

<cffunction name="getValue" access="public" returntype="any" output="no" hint="I get the value of the given user-specific variable.">
	<cfargument name="variablename" type="string" required="yes">

	<cfset var result = 0>
	
	<cflock timeout="20" throwontimeout="Yes" name="SessionMgr" type="READONLY">
		<cfset result = Evaluate(variables.scope & "." & arguments.variablename)>
	</cflock>
	
	<cfif IsWDDX(result)>
		<cfwddx action="WDDX2CFML" input="#result#" output="result">
	</cfif>
	
	<!--- <cfif variables.scope eq "Client">
		<cfwddx action="WDDX2CFML" input="#result#" output="result">
	</cfif> --->
	
	<cfreturn result>
</cffunction>

<cffunction name="exists" access="public" returntype="boolean" output="no" hint="I check if the given variable exists in the SessionMgr scope.">
	<cfargument name="variablename" type="string" required="yes">
	
	<cfreturn StructKeyExists(Evaluate(variables.scope),arguments.variablename)>
</cffunction>

<cffunction name="setValue" access="public" returntype="void" output="no" hint="I set the value of the given user-specific variable.">
	<cfargument name="variablename" type="string" required="yes">
	<cfargument name="value" type="any" required="yes">
	
	<cfset var val = arguments.value>
	
	<cfif variables.scope eq "Client" AND NOT isSimpleValue(arguments.value)>
		<cfwddx action="CFML2WDDX" input="#arguments.value#" output="val">
	</cfif>
	
	<cflock timeout="20" throwontimeout="Yes" name="SessionMgr" type="EXCLUSIVE">
		<cfset SetVariable("#variables.scope#.#arguments.variablename#", val)>
	</cflock>
	<cfset updateRequestVar()>

</cffunction>

<cffunction name="updateRequestVar" access="public" returntype="void" output="no" hint="I update the request variable to match the contents of the scope.">
	<cfset request[variables.requestvar] = dump()>
</cffunction>
<cfscript>
/**
 * Gets all the session keys and session ids for an application.
 * 
 * @return Returns an array. 
 * @author Rupert de Guzman (rndguzmanjr@yahoo.com) 
 * @version 2, September 23, 2004 
 */
function getSessionList(){
 	var obj = "";
	var i = 1;
	var sessionlist = ArrayNew(1);
	var enum = "";
	
 	obj = CreateObject("java","coldfusion.runtime.SessionTracker");
	enum = obj.getSessionKeys();
	
	for(;i lte obj.getSessionCount(); i=i+1){
			arrayAppend(sessionlist,obj.getSession(enum.next()));	
	}
	return sessionlist;
}
</cfscript>
</cfcomponent>