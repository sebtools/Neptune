<cfcomponent output="false">

<cffunction name="init" access="public" returntype="any" output="no">
	
	<cfreturn this>
</cffunction>

<cffunction name="read" access="public" returntype="struct" output="no">
	<cfargument name="source" type="string" required="yes">
	
	<cfset var sResult = StructNew()>
	<cfset var key = "">
	
	<cflock name="cfx_image" timeout="60">
		<cfx_image Action="READ" file="#arguments.source#">
		<cfset sResult.width = img_width>
		<cfset sResult.height = img_height>
		<cfset sResult.source = arguments.source>
		<!--- <cfloop collection="#variables#" item="key">
			<cfif Left(key,4) EQ "img_">
				<cfset sResult[ReplaceNoCase(key,"img_","")] = variables[key]>
			</cfif>
		</cfloop> --->
	</cflock>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="scaleToFit" access="public" returntype="void" output="no">
	<cfargument name="source" type="string" required="yes">
	<cfargument name="quality" type="string" required="yes">
	<cfargument name="width" type="string" required="yes">
	<cfargument name="height" type="string" required="yes">

	<!--- Decimal must be converted to number 0 - 100 --->
	<cfx_image Action="RESIZE" 
		file="#arguments.source#" 
		y="#val(arguments.height)#" 
		quality="#val(arguments.quality) * 100#" 
		output="#arguments.source#"
		x="#val(arguments.width)#"
	>
</cffunction>

</cfcomponent>