<cfif NOT IsDefined("ThisTag.executionMode")>This must be called as custom tag.<cfabort></cfif>
<cfsilent>

<cfscript>
if ( StructKeyExists(request, "cftags") AND StructKeyExists(request.cftags, "cf_slack") ) {
	StructAppend(Attributes, request.cftags["cf_slack"], "no");
}
</cfscript>

<cfparam name="Attributes.message" default="">
<cfparam name="Attributes.image_url" default="">
<cfparam name="Attributes.icon_emoji" default="">
<cfparam name="Attributes.icon_type" default="">
<cfparam name="Attributes.DefaultWebHookURL" default=""><!--- Make sure to include this as an attribute or via request.cftags.slack.DefaultWebHookURL --->
<cfparam name="Attributes.WebHookURL" default="">

<cfif StructKeyExists(ThisTag,"GeneratedContent") AND Len(Trim(ThisTag.GeneratedContent)) AND NOT Len(Trim(Attributes.message))>
	<cfset Attributes.message = Trim(ThisTag.GeneratedContent)>

	<cfset thisTag.GeneratedContent = ''>
</cfif>


<cfif ThisTag.executionMode IS "End" OR NOT thisTag.hasEndTag>
	
	<!---- get Slack object --->
	<cf_service name="Slack">
	<cfif NOT StructKeyExists(Variables,"Slack")>
		<cfset Variables.Slack = CreateObject("component","com.sebtools.Slack").init(WebHookURL="#Attributes.DefaultWebHookURL#") />
	</cfif>

	<cfset StructDelete(Attributes,"DefaultWebHookURL")>

	<!--- send message --->
	<cfset Variables.Slack.sendNotice(ArgumentCollection=Attributes)>
</cfif>

</cfsilent>