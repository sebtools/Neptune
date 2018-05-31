<cfcomponent extends="service" output="false">

<cffunction name="init" access="public" returntype="any" output="false" hint="I initialize and return the component.">
	<cfargument name="AWS" type="any" required="true">
	
	<cfset Arguments.subdomain = "sns">

	<cfset initInternal(ArgumentCollection=Arguments)>

	<cfreturn This>
</cffunction>

<cffunction name="GetAPIReferenceURL" access="public" returntype="string" output="no" hint="I return the URL to the API reference.">
	<cfreturn "http://docs.aws.amazon.com/sns/latest/api/">
</cffunction>

<cffunction name="PublishToPhone" access="public" returntype="any" output="no" hint="I publish a message.">
	<cfargument name="Message" type="string" required="true">
	<cfargument name="PhoneNumber" type="string" required="true">
	
	<cfreturn Publish(ArgumentCollection=Arguments)>
</cffunction>

<cffunction name="PublishToTarget" access="public" returntype="any" output="no" hint="I publish a message.">
	<cfargument name="Message" type="string" required="true">
	<cfargument name="TargetArn" type="string" required="true">
	<cfargument name="Subject" type="string" required="false">
	<cfargument name="MessageStructure" type="struct" required="false">
	
	<cfreturn Publish(ArgumentCollection=Arguments)>
</cffunction>

<cffunction name="PublishToTopic" access="public" returntype="any" output="no" hint="I publish a message.">
	<cfargument name="Message" type="string" required="true">
	<cfargument name="TopicArn" type="string" required="true">
	<cfargument name="Subject" type="string" required="false">
	<cfargument name="MessageStructure" type="struct" required="false">
	
	<cfreturn Publish(ArgumentCollection=Arguments)>
</cffunction>

<cffunction name="Publish" access="private" returntype="any" output="no" hint="I publish a message.">
	<cfargument name="Message" type="string" required="true">

	<!--- Make sure MessageStructure is passed to API as JSON --->
	<cfif StructKeyExists(Arguments,"MessageStructure")>
		<cfset Arguments.MessageStructure = SerializeJSON(Arguments.MessageStructure)>
	</cfif>
	
	<cfreturn callAPI(
		Action="Publish",
		Parameters=Arguments
	)>
</cffunction>

</cfcomponent>