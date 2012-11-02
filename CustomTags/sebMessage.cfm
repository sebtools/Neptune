<cfif isDefined("ThisTag.ExecutionMode") AND ThisTag.ExecutionMode EQ "Start">
<cfinclude template="sebUdf.cfm"><cfinclude template="sebtools.cfm">
<cfoutput>#showSessionMessage()#</cfoutput>
<cfif StructKeyExists(Attributes,"set") AND isSimpleValue(Attributes.set)><cfset setSessionMessage(Attributes.set)></cfif>
</cfif>