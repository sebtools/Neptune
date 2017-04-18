<cfsilent>
<cfif ThisTag.ExecutionMode IS "End" OR NOT ThisTag.hasendtag>
	<!--- Use generated content as "Value" attribute --->
	<cfif Len(ThisTag.GeneratedContent)>
		<cfif NOT ( StructKeyExists(Attributes,"Value") AND isSimpleValue(Attributes.Value) AND Len(Attributes.Value) )>
			<cfset Attributes.Value = ThisTag.GeneratedContent>
		</cfif>
		<cfset ThisTag.GeneratedContent = "">
	</cfif>
	<cfassociate basetag="cf_http" datacollection="aParams">
</cfif>
</cfsilent>