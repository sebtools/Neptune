<cfcomponent>

<cffunction name="init" access="public" returntype="any" output="no">
    <cfargument name="Manager" type="any" required="true">

    <cfset Variables.aServices = []>

    <cfset Variables.MrECache = CreateObject("component","MrECache").init(
        id="content_service",
        timeSpan=CreateTimeSpan(0,4,0,0)
    )>

     <cfreturn This>
</cffunction>

<cffunction name="addService" access="public" returntype="any" output="no">
    <cfargument name="Component" type="any" required="yes">
    <cfargument name="Method" type="string" required="yes">

    <cfset ArrayAppend(Variables.aServices,Arguments)>

    <cfreturn This>
</cffunction>

<cffunction name="phrase" access="public" returntype="string" output="no">
    <cfargument name="key" type="string" required="yes">
    <cfargument name="locale" type="string" required="no">
    <cfargument name="data" type="struct" required="no">

    <cfset var ii = 0>
    <cfset var result = Arguments.key>

    <cfloop index="ii" from="1" to="#ArrayLen(Variables.aServices)#">
        <cfinvoke
            returnvariable="result"
            component="#Variables.aServices[ii].Component#"
            method="#Variables.aServices[ii].Method#"
            phrase="#result#"
        >
            <cfif StructKeyExists(Arguments,"locale") AND Len(Trim(Arguments.locale))>
                <<cfinvokeargument name="locale" value="#Arguments.locale#">
            </cfif>
            <cfif StructKeyExists(Arguments,"data") AND StructCount(Arguments.data)>
                <<cfinvokeargument name="data" value="#Arguments.data#">
            </cfif>
        </cfinvoke>
    </cfloop>

    <cfreturn result>
</cffunction>

</cfcomponent>
