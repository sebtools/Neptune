<cfif isDefined("ThisTag.ExecutionMode") AND ThisTag.ExecutionMode EQ "Start">
<cfinclude template="sebUdf.cfm"><cfinclude template="sebtools.cfm">
<cfoutput>#showSessionMessage()#</cfoutput>
</cfif>
<cfscript>
//Upshot here is just to set the GeneratedContent if it exists. Use "set" attribute if it exists.
if (
		isDefined("ThisTag.ExecutionMode")
	AND	(
				ThisTag.ExecutionMode EQ "End"
			OR	NOT ThisTag.hasEndTag
		)
) {
	if (
			ThisTag.ExecutionMode EQ "End"
		AND	Len(Trim(ThisTag.GeneratedContent))
		AND	NOT StructKeyExists(Attributes,"set")
	) {
		Attributes.set = Trim(ThisTag.GeneratedContent);
		ThisTag.GeneratedContent = "";
	}
	if ( StructKeyExists(Attributes,"set") AND isSimpleValue(Attributes.set) ) {
		setSessionMessage(Attributes.set);
	}
}
</cfscript>
