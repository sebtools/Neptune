<cffunction name="display_DeleteLink">
	<cfargument name="value" type="string" required="yes" hint="The value of this field for this row.">
	<cfargument name="rownum" type="numeric" required="yes">
	<cfargument name="pkid" type="string" required="yes">
	<cfargument name="atts" type="struct" required="yes">
	
	<cfset var result = "">
	
	<cfsavecontent variable="result"><cfoutput><input type="submit" name="delete_#rownum#" value="delete" class="delete" style="height:20px;background:transparent;border:0;text-decoration:underline;cursor:pointer;" onclick="return confirm('Are you sure you want to delete this item?')"/></cfoutput></cfsavecontent>
	
	<cfreturn result>
</cffunction>