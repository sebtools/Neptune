<cfif isDefined("ThisTag.ExecutionMode") AND ThisTag.ExecutionMode EQ "Start">
<cfinclude template="sebUdf.cfm"><cfinclude template="sebtools.cfm">
#showSessionMessage()#
<cfif StructKeyExists(Attributes,"set") AND isSimpleValue(Attributes.set)><cfset setSessionMessage(Attributes.set)></cfif>
</cfif>