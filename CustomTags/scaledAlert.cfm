<cfif NOT IsDefined("ThisTag.executionMode")>This must be called as custom tag.<cfabort></cfif>
<cfsilent>

<cfparam name="Attributes.message" default="">
<cfparam name="Attributes.extended_message" default="">
<cfparam name="Attributes.icon_type" default="failure">
<cfparam name="Attributes.result" default="sendAlert">
<cfparam name="Attributes.key" default="#Attributes.message#">
<cfparam name="Attributes.email_to" default="">

<cfif ThisTag.executionMode IS "Start">
	<cftry>

		<cfif NOT StructKeyExists(Application,"sAlerts")>
			<cfset Application.sAlerts = {}>
		</cfif>

		<!--- Get the struct key started for this alert message. --->
		<cfif NOT StructKeyExists(Application.sAlerts,Attributes.key)>
			<cfset Application.sAlerts[Attributes.key] = {}>
			<cfset Application.sAlerts[Attributes.key]["Message"] = Attributes["message"]>
			<cfset Application.sAlerts[Attributes.key]["TimeFirst"] = now()>
			<cfset Application.sAlerts[Attributes.key]["TimeLast"] = now()>
			<cfset Application.sAlerts[Attributes.key]["Times"] = 1>
		</cfif>
		<cfset NumMessages = Application.sAlerts[Attributes.key]["Times"]>
		
		<!---
		Increase the number of times the alert has occurred.
		If two hours have passed since this alert was last captured, reset the alert struct for this alert.
		--->
		<cfif DateDiff("h",Application.sAlerts[Attributes.key]["TimeLast"],now()) GTE 2>
			<cfset NumMessages = Application.sAlerts[Attributes.key]["Times"] + 1>
			<cfset StructDelete(Application.sAlerts,Attributes.key)>
		<cfelse>
			<cfset Application.sAlerts[Attributes.key]["TimeLast"] = now()>
			<cfset Application.sAlerts[Attributes.key]["Times"] = Application.sAlerts[Attributes.key]["Times"] + 1>
		</cfif>

		<!---
		Send alerts based on logarithmic scale down.
		If NumMessages is an integer, then it has increased logarithmically (1,10,100,1000,...)
		--->
		<cfif Log10(NumMessages) EQ Round(Log10(NumMessages))>
			<cfset sendAlert = true>
		<cfelse>
			<cfset sendAlert = false>
		</cfif>
	<cfcatch>
		<!--- If anything goes wrong, just send the alert --->
		<cfset sendAlert = true>
	</cfcatch>
	</cftry>
	<!--- Let the caller know if the alert will be sent --->
	<cfset Caller[Attributes.result] = sendAlert>
</cfif>

<cfif ThisTag.executionMode IS "End" OR NOT thisTag.hasEndTag>
	
	<!--- Use the text between the custom tags as default extended_message --->
	<cfif StructKeyExists(ThisTag,"GeneratedContent") AND Len(Trim(ThisTag.GeneratedContent)) AND NOT Len(Trim(Attributes.extended_message))>
		<cfset Attributes.extended_message = Trim(ThisTag.GeneratedContent)>

		<cfset ThisTag.GeneratedContent = ''>
	</cfif>
	
	<cfif sendAlert>
		<cf_alert AttributeCollection="#Attributes#">
	</cfif>

</cfif>

</cfsilent>