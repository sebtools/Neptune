<!--- This makes sure it can only be called as a custom tag - one one that has a closing tag --->
<cfif NOT ( isDefined("ThisTag") AND ThisTag.HasEndTag )><cfexit></cfif>

<cfif NOT ListFindNoCase(getBaseTagList(),"cf_Mailer")>
	<cfthrow message="cf_MailerPart must be called inside of cf_Mailer tags">
</cfif>

<cfparam name="Attributes.type" type="string" default="Text">
<cfset types = "HTML,Text">
<cfif NOT ListFindNoCase(types,Attributes.type)>
	<cfthrow message="type attribute of cf_MailerPart must be either 'Text' or 'HTML'.">
</cfif>

<cfif ThisTag.ExecutionMode IS "End">
	<cfset sMailerData = getBaseTagData("cf_Mailer")>
	
	<cfset sMailerData.Attributes[Attributes.type] = ThisTag.GeneratedContent>
	<cfset ThisTag.GeneratedContent = "">
</cfif>