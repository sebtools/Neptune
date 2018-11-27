<cfsilent>
<cfif ThisTag.ExecutionMode IS "End" OR NOT ThisTag.hasendtag>
	<!--- Use generated content as "Value" attribute --->
	<cfif Len(ThisTag.GeneratedContent)>
		<cfif NOT ( StructKeyExists(Attributes,"Value") AND isSimpleValue(Attributes.Value) AND Len(Attributes.Value) )>
			<cfset Attributes.Value = ThisTag.GeneratedContent>
		</cfif>
		<cfset ThisTag.GeneratedContent = "">
	</cfif>
	<cfif
			StructKeyExists(Attributes,"type")
		AND	Attributes.type EQ "header"
		AND	StructKeyExists(Attributes,"name")
		AND	Attributes.name EQ "Authorization"
		AND	NOT StructKeyExists(Attributes,"hash")
	>
		<cfset Attributes.hash = true>
	</cfif>
	<cfassociate basetag="cf_http" datacollection="aParams">
</cfif>
</cfsilent>
