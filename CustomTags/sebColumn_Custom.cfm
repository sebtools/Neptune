<cffunction name="display_Custom">
	<cfargument name="value" type="string" required="yes" hint="The value of this field for this row.">
	<cfargument name="rownum" type="numeric" required="yes">
	<cfargument name="pkid" type="string" required="yes">
	<cfargument name="atts" type="struct" required="yes">

	<cfset var result = ThisTag.GeneratedContent>

	<cfif Arguments.rownum>
		<cfset result = populateMarkers(result,qTableData,rownum)>
	</cfif>

	<cfreturn result>
</cffunction>
