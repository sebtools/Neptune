<!--- 1.0 Beta 2 (Build 26) --->
<!--- Last Updated: 2012-08-05 --->
<!--- Information: sebtools.com --->
<!--- 
This application is licensed under the Apache License, Version 2.0 . 
For a copy of the Apache License, Version 2.0, go to 
http://www.apache.org/licenses/
--->
<cfcomponent displayname="Config" output="false" hint="I am a configuration component." >

<cffunction name="init" access="Public" returnType="Config" output="false" hint="I return a new config object">
	<cfargument name="scopes" type="string" default="request,application">
	
	<cfset var key = "">
	
	<cfset variables.scopes = arguments.scopes>
	<cfset variables.instance = StructNew()>
	
	<cfloop collection="#arguments#" item="key">
		<cfset variables.instance[key] = arguments[key]>
	</cfloop>
	
	<cfset This["throw"] = This.throwError>
	
	<cfreturn this />
</cffunction>

<cffunction name="dump" access="public" returntype="any" output="false" hint="">
	
	<cfreturn variables.instance>
</cffunction>

<cffunction name="exists" access="public" returntype="any" output="false" hint="">
	<cfargument name="name" type="string" required="yes">
	
	<cfreturn StructKeyExists(variables.instance,arguments.name)>
</cffunction>

<cffunction name="getSetting" access="Public" returnType="any" output="false">
	<cfargument name="name" type="string" required="yes">
	
	<cfif NOT exists(arguments.name)>
		<cfthrow message="The configuration variable #arguments.name# does not exist." type="Config" errorcode="Config.NotDefined">
	</cfif>
	
	<cfreturn variables.instance[arguments.name]>
</cffunction>

<cffunction name="getSettings" access="Public" returnType="any" output="false">
	
	<cfreturn variables.instance>
</cffunction>

<cffunction name="paramSetting" access="Public" returnType="void" output="false">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="value" type="any" required="yes">
	
	<cfif NOT exists(arguments.name)>
		<cfset variables.instance[arguments.name] = arguments.value>
	</cfif>
	
</cffunction>

<cffunction name="requireSetting" access="Public" returnType="void" output="false">
	<cfargument name="name" type="string" required="yes">
	
	<cfif Len(Trim(arguments.name)) AND NOT exists(arguments.name)>
		<cfthrow message="The configuration variable #arguments.name# is required, but not set." type="Config" errorcode="Config.Required">
	</cfif>
	
</cffunction>

<cffunction name="runConfigFiles" access="Public" returnType="void" output="false">
	<cfargument name="files" type="string" required="yes">
	
	<cfset var file = "">
	
	<cfloop list="#arguments.files#" index="file">
		<cfset includePage(file)>
	</cfloop>
	
</cffunction>

<cffunction name="setSetting" access="Public" returnType="void" output="false">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="value" type="any" required="yes">
	
	<cfset variables.instance[arguments.name] = arguments.value>
	
</cffunction>

<cffunction name="loadSettings" access="Public" returnType="void" output="false">
	
	<cfset var scope = "">
	<cfset var key = "">
	
	<cfloop list="#variables.scopes#" index="scope">
		<cfloop collection="#variables.instance#" item="key">
			<cfset setVariable("#scope#.#key#",variables.instance[key])>
		</cfloop>
	</cfloop>
	
</cffunction>

<cffunction name="setSettings" access="Public" returnType="void" output="false">
	
	<cfset var key = "">
	<cfset var scope = "">
	
	<cfloop collection="#variables.instance#" item="key">
		<cfloop list="#variables.scope#" index="scope">
			<cfset "#scope#.#key#" = variables.instance[key]>
		</cfloop>
	</cfloop>
	
</cffunction>

<cffunction name="throwError" access="public" returntype="void" output="false">
	<cfargument name="errorcode" type="string" required="yes">
	
	<cfswitch expression="#arguments.errorcode#">
	<cfcase value="Required,Config.Required">
		<cfthrow message="The configuration variable #arguments.name# is required, but not set." type="Config" errorcode="Config.Required">
	</cfcase>
	<cfcase value="NotDefined,Config.NotDefined">
		<cfthrow message="The configuration variable #arguments.name# does not exist." type="Config" errorcode="Config.NotDefined">
	</cfcase>
	</cfswitch>
	
</cffunction>

<cffunction name="includePage" access="private" returntype="void" output="true"><cfargument name="page" type="string" required="true"><cfif StructKeyExists(variables.instance,"Proxy")><cfset variables.instance.Proxy.includePage(arguments.page)><cfelse><cfinclude template="#arguments.page#"></cfif></cffunction>

</cfcomponent>