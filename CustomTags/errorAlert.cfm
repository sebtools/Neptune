<cfif NOT IsDefined("ThisTag.executionMode")>This must be called as custom tag.<cfabort></cfif>
<cfsilent>

<cfscript>
if ( StructKeyExists(request, "cftags") AND StructKeyExists(request.cftags, "cf_errorAlert") ) {
	StructAppend(Attributes, request.cftags["cf_errorAlert"], "no");
}
</cfscript>

<cfparam name="Attributes.Error">
<cfparam name="Attributes.environment" default="Production">
<cfparam name="Attributes.site" default="#CGI.SERVER_NAME#">
<cfparam name="Attributes.page" default="#CGI.SCRIPT_NAME#">
<cfparam name="Attributes.queryString" default="#CGI.QUERY_STRING#">
<cfparam name="Attributes.email_to" default="">
<cfif Attributes.environment EQ "Local">
	<cfset DefaultSendError = false>
	<cfset DefaultShowError = true>
<cfelseif Attributes.environment EQ "Development">
	<cfset DefaultSendError = true>
	<cfset DefaultShowError = true>
<cfelseif Attributes.environment EQ "Production">
	<cfset DefaultSendError = true>
	<cfset DefaultShowError = false>
</cfif>
<cfparam name="Attributes.sendError" type="boolean" default="#DefaultSendError#">
<cfparam name="Attributes.showError" type="boolean" default="#DefaultShowError#">
<cfparam name="Attributes.MessageVariable" type="string" default="ErrorMessage">

<cfif ThisTag.executionMode IS "End" OR NOT thisTag.hasEndTag>
	<cfset sAlert = StructNew()>
	<cfset sAlert["notice_type"] = "Error!">
	<cfset sAlert["icon_type"] = "failure">
	<cfset sAlert["icon_emoji"] = ":bangbang:">
	<cfset sAlert["email_to"] = Attributes.email_to>
	<cfif StructKeyExists(Attributes,"DefaultWebHookURL")>
		<cfset sAlert["DefaultWebHookURL"] = Attributes.DefaultWebHookURL>
	</cfif>
	<cfif StructKeyExists(Attributes,"WebHookURL")>
		<cfset sAlert["WebHookURL"] = Attributes.WebHookURL>
	</cfif>

	<!--- Get the error message from the error and save to sAlert["message"] --->
	<cfif StructKeyExists(Attributes.Error,"Cause")>
		<cfset sAlert["key"] = Hash(Attributes.Error.Cause)>
		<cfset sAlert["message"] = Attributes.Error.Cause.Message>
	<cfelseif StructKeyExists(Attributes.Error,"Message")>
		<cfset sAlert["key"] = Hash(Attributes.Error.Message)>
		<cfset sAlert["message"] = Attributes.Error.Message>
	<cfelse>
		<cfset sAlert["key"] = CreateUUID()>
		<cfset sAlert["message"] = "Unknown">
	</cfif>

	<cfset Caller[Attributes.MessageVariable] = sAlert["message"]>
	<cfset ErrorURL = Attributes.site & Attributes.page>
	<cfif Len(Attributes.queryString)>
		<cfset ErrorURL = ErrorURL  & "?" & Attributes.queryString>
	</cfif>
	<cfset sAlert["message"] = "An error occurred on " & ErrorURL & ": " & sAlert.Message>

	<cfif Attributes.sendError OR Attributes.showError>
		<!--- Compile the full details about the message, including dumps of CGI,Form,URL scopes and the error itself and save to a local variable --->
		<cfsavecontent variable="ErrorDetails">
			<p><strong>Exception:</strong></p>
			<cftry><cfdump var="#Attributes.Error#"><cfcatch>[Failed to Get exception information]</cfcatch></cftry>
			<cfif isDefined("CGI")>
				<p><strong>CGI:</strong></p>
				<cftry><cfdump var="#CGI#"><cfcatch>[Failed to Get CGI information]</cfcatch></cftry>
			</cfif>
			<cfif isDefined("Form")>
				<p><strong>Form:</strong></p>
				<cftry><cfdump var="#Form#"><cfcatch>[Failed to Get Form information]</cfcatch></cftry>
			</cfif>
			<cfif isDefined("URL")>
				<p><strong>URL:</strong></p>
				<cftry><cfdump var="#URL#"><cfcatch>[Failed to Get URL information]</cfcatch></cftry>
			</cfif>
		</cfsavecontent>
	</cfif>

	<cfif Attributes.sendError>
		<!--- logarithmic scale down of alert --->
		<cf_scaledAlert AttributeCollection="#sAlert#">
			<!--- Opening cf_scaledAlert determines if it will send, allowing us to take appropriate action before closing tag. --->
			<cfif sendAlert>
				<!--- If an "Errors" service can be found, save the whole thing there and get back a UUID for the error --->
				<cfset ErrorUUID = "">
				<cf_service name="Errors">
				<cfif StructKeyExists(Variables,"Errors")>
					<cftry>
						<cfset ErrorUUID = Variables.Errors.saveError(ErrorDetails)>
					<cfcatch>
					</cfcatch>
					</cftry>
				</cfif>
				<!--- If we have a UUID for the error then the extended_message should be the link to the page that will show the details --->
				<!--- If no UUID, then the extended message should be the variable holding the string of the details saved earlier --->
				<cfif Len(ErrorUUID)>
					<cfoutput>http://example.com/?error=#ErrorUUID#</cfoutput>
				<cfelse>
					<cfoutput>#ErrorDetails#</cfoutput>
				</cfif>
			</cfif>
		</cf_scaledAlert>
	</cfif>
	
	<cfif Attributes.showError>
		<cfset Variables.output = ErrorDetails>
	<cfelse>
		<cfsavecontent variable="Variables.output">
			<h1 class="err">Error!</h1>
			<h3>An Error has ocurred on this site.</h3>
			<hr/>
			<p>The error has been reported to our programmers and we are working to correct it. We generally get errors fixed overnight, so please feel free to try this action again tomorrow.</p>
		</cfsavecontent>
	</cfif>

</cfif>

</cfsilent><cfif StructKeyExists(Variables,"output")><cfoutput>#Variables.output#</cfoutput><cfabort></cfif>