<cffunction name="display_LineLink">
	<cfargument name="value" type="string" required="yes" hint="The value of this field for this row.">
	<cfargument name="rownum" type="numeric" required="yes">
	<cfargument name="pkid" type="string" required="yes">
	<cfargument name="atts" type="struct" required="yes">
	
	<cfset var result = "">
	<cfset var link = "">
	
	<cfif ListFindNoCase(qTableData.ColumnList,"FileID")>
		<cfif isNumeric(qTableData["FileID"][rownum]) AND qTableData["FileID"][rownum] gt 0>
			<cfset atts.link = "file-view.cfm?id=#FileID#">
		</cfif>
	</cfif>
	
	<cfsavecontent variable="result"><cfoutput><a href="#atts.link###line-#value#" title="Go to this line.">#value#</a></cfoutput></cfsavecontent>
	
	<cfreturn result>
</cffunction>