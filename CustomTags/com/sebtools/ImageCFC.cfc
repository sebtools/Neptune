<cfcomponent output="false">

<cffunction name="init" access="public" returntype="any" output="no">
	
	<cfif StructKeyExists(arguments,"Proxy")>
		<cfset variables.imagecfc = arguments.Proxy.createComponent("com.opensourcecf.image")>
	<cfelse>
		<cfset variables.imagecfc = CreateObject("component","com.opensourcecf.image")>
	</cfif>
	
	<cfreturn this>
</cffunction>

<cffunction name="read" access="public" returntype="struct" output="no">
	<cfargument name="source" type="string" required="yes">
	
	<cfset var sResult = StructNew()>
	
	<cftry>
		<cfset sResult = variables.imagecfc.getImageInfo("", arguments.source)>
		<cfset sResult.source = arguments.source>
	<cfcatch>
		<cfif CFCATCH.Message CONTAINS "Java is unable to read">
			<cffile action="delete" file="#arguments.source#">
			<cfset sResult = StructNew()>
		<cfelse>
			<cfrethrow>
		</cfif>
	</cfcatch>
	</cftry>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="scaleToFit" access="public" returntype="void" output="no">
	<cfargument name="source" type="string" required="yes">
	<cfargument name="quality" type="string" required="yes">
	<cfargument name="width" type="string" required="yes">
	<cfargument name="height" type="string" required="yes">
	
	<cfinvoke component="#variables.imagecfc#" method="resize">
		<cfinvokeargument name="objImage" value="">
		<cfinvokeargument name="inputFile" value="#arguments.source#">
		<cfinvokeargument name="outputFile" value="#arguments.source#">
		<cfif isNumeric(arguments.width) AND arguments.width GT 0>
			<cfinvokeargument name="newWidth" value="#Val(arguments.width)#">
		</cfif>
		<cfif isNumeric(arguments.height) AND arguments.height GT 0>
			<cfinvokeargument name="newHeight" value="#Val(arguments.height)#">
		</cfif>
		<cfinvokeargument name="preserveAspect" value="true">
		<cfinvokeargument name="jpegCompression" value="#val(arguments.quality) * 100#">
	</cfinvoke>
	
</cffunction>

</cfcomponent>