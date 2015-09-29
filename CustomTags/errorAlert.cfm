<cfif NOT IsDefined("ThisTag.executionMode")>This must be called as custom tag.<cfabort></cfif>
<cfsilent>

<cfparam name="Attributes.Error">
<cfparam name="Attributes.environment" default="Production">
<cfparam name="Attributes.site" default="#CGI.SERVER_NAME#">
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
	<cfset sAlert["message"] = "">
	<cfset sAlert["extended_message"] = "">
	<cfset sendAlert = false>

	<!--- Get Error Hash and do logarithmic scale down of needed action --->

	<!--- Get the error message from the error and save to sAlert["message"] --->
	<cfif StructKeyExists(Attributes.Error,"Cause")>
		<cfset ErrorHash = Hash(Attributes.Error.Cause)>
		<cfset sAlert["message"] = Attributes.Error.Cause.Message>
	<cfelseif StructKeyExists(Attributes.Error,"Message")>
		<cfset ErrorHash = Hash(Attributes.Error.Message)>
		<cfset sAlert["message"] = Attributes.Error.Message>
	<cfelse>
		<cfset ErrorHash = CreateUUID()>
		<cfset sAlert["message"] = "Unknown">
	</cfif>

	<cfset Caller[Attributes.MessageVariable] = sAlert["message"]>
	<cfset sAlert["message"] = "An error occurred on " & Attributes.site & ": " & sAlert.Message>
		
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

	<cfif Attributes.sendError>
		<cftry>
			<cfset NumErrors = 1>
			<cfif NOT StructKeyExists(Application,"sErrors")>
				<cfset Application.sErrors = {}>
			</cfif>
			<cfif NOT StructKeyExists(Application.sErrors,ErrorHash)>
				<cfset Application.sErrors[ErrorHash] = {}>
				<cfset Application.sErrors[ErrorHash]["Message"] = sAlert["message"]>
				<cfset Application.sErrors[ErrorHash]["Time"] = now()>
				<cfset Application.sErrors[ErrorHash]["Times"] = 1>
			</cfif>
			<cfset NumErrors = Application.sErrors[ErrorHash]["Times"]>
			
			<!---
			Increase the number of times the error has occurred.
			If two hours have passed since this error was first captured, reset the errors struct for this error.
			--->
			<cfif DateDiff("h",Application.sErrors[ErrorHash]["Time"],now()) GTE 2>
				<cfset NumErrors = Application.sErrors[ErrorHash]["Times"] + 1>
				<cfset StructDelete(Application.sErrors,ErrorHash)>
			<cfelse>
				<cfset Application.sErrors[ErrorHash]["Times"] = Application.sErrors[ErrorHash]["Times"] + 1>
			</cfif>

			<!--- Send alerts based on logarithmic scale down --->
			<!--- If NumErrors is an integer, then it has increased logarithmically (1,10,100,1000,...) --->
			<cfif Log10(NumErrors) EQ Round(Log10(NumErrors))>
				<cfset sendAlert = true>
			<cfelse>
				<cfset sendAlert = false>
			</cfif>
		<cfcatch>
			<cfset sendAlert = true>
		</cfcatch>
		</cftry>

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
				<cfset sAlert["extended_message"] = "http://example.com/?error=#ErrorUUID#">
			<cfelse>
				<cfset sAlert["extended_message"] = ErrorDetails>
			</cfif>
			<cfset sAlert["notice_type"] = "Error!">
			<cfset sAlert["icon_type"] = "failure">
			<cfset sAlert["icon_emoji"] = ":bangbang:">

			<cftry>
				<cf_alert AttributeCollection="#sAlert#">
			<cfcatch>
			</cfcatch>
			</cftry>
			
		</cfif>
	</cfif>

	<cfif Attributes.showError>
		<cfset Variables.output = ErrorDetails>
	</cfif>

</cfif>

</cfsilent><cfif StructKeyExists(Variables,"output")><cfoutput>#Variables.output#</cfoutput><cfabort></cfif>