<cfif NOT IsDefined("ThisTag.executionMode")>This must be called as custom tag.<cfabort></cfif>
<cfsilent>

<cfscript>
if ( StructKeyExists(request, "cftags") AND StructKeyExists(request.cftags, "cf_alert") ) {
	StructAppend(Attributes, request.cftags["cf_alert"], "no");
}
</cfscript>

<cfparam name="Attributes.message" default="">
<cfparam name="Attributes.extended_message" default="">
<cfparam name="Attributes.icon_type" default="failure">
<cfparam name="Attributes.email_to" default="">

<cfif StructKeyExists(ThisTag,"GeneratedContent") AND Len(Trim(ThisTag.GeneratedContent)) AND NOT Len(Trim(Attributes.message))>
	<cfset Attributes.message = Trim(ThisTag.GeneratedContent)>

	<cfset thisTag.GeneratedContent = ''>
</cfif>


<cfif ThisTag.executionMode IS "End" OR NOT thisTag.hasEndTag>
	<!---- get Mailer object --->
	<cf_service name="Mailer">

	<!--- Send to Slack --->
	<cftry>
		<cfset sSlack = StructCopy(Attributes)>
		<cfif Len(sSlack.extended_message) LT 260>
			<cfset sSlack["message"]  = sSlack["message"] & "\n" & sSlack.extended_message>
		</cfif>
		<cf_slack AttributeCollection="#sSlack#">
	<cfcatch>
	</cfcatch>
	</cftry>
	
	<!--- Send by email --->
	<cfif StructKeyExists(Variables,"Mailer")>
		<cfif NOT Len(Trim(Attributes.Email_To))>
			<cfset Attributes.Email_To = Variables.Mailer.getTo()>
		</cfif>
		<cfif Len(Trim(Attributes.Email_To))>
			<cftry>
				<cfset Variables.Mailer.send(To=Attributes.Email_To,Subject=Attributes.message,Contents=Attributes.extended_message)>
			<cfcatch>
			</cfcatch>
			</cftry>
		</cfif>
	</cfif>

</cfif>

</cfsilent>