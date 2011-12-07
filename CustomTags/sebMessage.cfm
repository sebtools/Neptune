<cfif isDefined("ThisTag.ExecutionMode") AND ThisTag.ExecutionMode EQ "Start">
<cfinclude template="sebUdf.cfm"><cfinclude template="sebtools.cfm">
<cfset message = useSessionMessage()><cfif Len(Trim(message))><p class="sebMessage"><cfoutput>#message#</cfoutput></p></cfif>
<cfif StructKeyExists(Attributes,"set") AND isSimpleValue(Attributes.set)><cfset setSessionMessage(Attributes.set)></cfif>
</cfif>