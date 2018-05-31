<cfcomponent extends="service" output="false">

<cffunction name="init" access="public" returntype="any" output="false" hint="I initialize and return the component.">
	<cfargument name="AWS" type="any" required="true">
	
	<cfset Arguments.subdomain = "s3">

	<cfset initInternal(ArgumentCollection=Arguments)>

	<cfreturn This>
</cffunction>

<cffunction name="GetAPIReferenceURL" access="public" returntype="string" output="no" hint="I return the URL to the API reference.">
	<cfreturn "docs.aws.amazon.com/AmazonS3/latest/API/">
</cffunction>

</cfcomponent>