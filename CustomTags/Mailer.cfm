<cfif NOT isDefined("ThisTag")><cfexit></cfif>

<cfif StructKeyExists(Caller,"Mailer") AND isObject(Caller.Mailer)>
	<cfparam name="Attributes.Mailer" default="#Caller.Mailer#">
<cfelseif isDefined("Application") AND isStruct(Application) AND StructKeyExists(Application,"Mailer") AND isObject(Application.Mailer)>
	<cfparam name="Attributes.Mailer" default="#Application.Mailer#">
</cfif>

<cfif NOT StructKeyExists(Attributes,"Mailer")>
	<cfset Attributes.Mailer = CreateObject("component","com.sebtools.Mailer").init()>
</cfif>

<cfset variables.Mailer = Attributes.Mailer>
<cfset StructDelete(Attributes,"Mailer")>

<cfif Len(Trim(ThisTag.GeneratedContent))>
	<cfset Attributes.Contents = ThisTag.GeneratedContent>
	<cfset ThisTag.GeneratedContent = "">
</cfif>

<cfif ThisTag.ExecutionMode IS "End" OR NOT ThisTag.HasEndTag>
	<cfset variables.Mailer.send(argumentCollection=Attributes)>
</cfif>