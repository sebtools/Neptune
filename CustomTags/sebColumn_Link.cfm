<cffunction name="display_Link">
	<cfargument name="value" type="string" required="yes" hint="The value of this field for this row.">
	<cfargument name="rownum" type="numeric" required="yes">
	<cfargument name="pkid" type="string" required="yes">
	<cfargument name="atts" type="struct" required="yes">
	
	<cfset var result = "">
	<cfset var cLink = "">
	
	<cfif NOT structKeyExists(arguments.atts,"urlvar")>
		<cfset arguments.atts.urlvar = "id">
	</cfif>
	
	<cfif arguments.atts.link NEQ "">
		<cfset cLink = arguments.atts.Link>
	</cfif>
	<cfif FindNoCase("?",cLink)>
		<cfset cLink = "#cLink#&#arguments.atts.urlvar#=#arguments.pkid#">
	<cfelse>
		<cfset cLink = "#cLink#?#arguments.atts.urlvar#=#arguments.pkid#">
	</cfif>
	
	<cfsavecontent variable="result">
		<cfoutput>
			<a href="#cLink#" <cfif isDefined("arguments.atts.Target") AND arguments.atts.Target NEQ "">target="#arguments.atts.Target#"</cfif> <cfif isDefined("arguments.atts.onLinkClick") AND arguments.atts.onLinkClick NEQ "">onClick="#arguments.atts.onLinkClick#"</cfif>>#arguments.atts.Text#</a>
		</cfoutput>
	</cfsavecontent>
	
	<cfreturn result>
</cffunction>