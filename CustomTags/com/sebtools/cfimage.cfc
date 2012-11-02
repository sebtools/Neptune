<cfcomponent output="false">

<cffunction name="init" access="public" returntype="any" output="no">
	
	<cfreturn this>
</cffunction>

<cffunction name="read" access="public" returntype="struct" output="no">
	<cfargument name="source" type="string" required="yes">
	
	<cfset var sResult = StructNew()>
	<cfset var key = "">
	<cfset var image = 0>
	
	<cfimage action="read" source="#arguments.source#" name="image">
	
	<cfset sResult.width = image.width>
	<cfset sResult.height = image.height>
	<cfset sResult.source = image.source>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="scaleToFit" access="public" returntype="void" output="no">
	<cfargument name="source" type="string" required="yes">
	<cfargument name="quality" type="string" required="yes">
	<cfargument name="width" type="string" required="yes">
	<cfargument name="height" type="string" required="yes">
	
	<cfset var myImage = 0>
	<cfset var filename = ListLast(ListLast(arguments.source,"\"),"/")>
	
	<cfimage action="read" source="#arguments.source#" name="myImage">
	<!--- <cfdump var="#arguments#">
	<cfabort> --->
	<!--- Scale image to fit --->
	<cfset ImageScaleToFit(myImage,arguments.width,arguments.height)>
	<!--- <cfset ImageWrite(myImage,filename,arguments.quality)> --->
	<cfimage
		action="write"
		source="#myImage#"
		destination="#filename#"
		overwrite="true"
		quality="#arguments.quality#"
	>
	
</cffunction>

<cffunction name="onMissingMethod" access="public" returntype="any" output="no">
	
	<cfset var fList = StructKeyList(GetFunctionList())>
	<cfset var result = 0>
	<cfset var method = arguments.missingMethodName>
	<cfset var args = arguments.missingMethodArguments>
	<cfset var cfimage = 0>
	<cfset var namedActions = "border,convert,read,resize,rotate">
	
	
	<cfif ListFindNoCase(fList,method)>
		<cfset result = Evaluate("#method#(argumentCollection=args)")>
	<cfelse>
		<cfset args.action = method>
		<cfif ListFindNoCase(namedActions,method)>
			<cfset args.name = "result">
		</cfif>
		<cfimage attributecollection="#args#">
	</cfif>
	
	<cfif isDefined("result")>
		<cfreturn result>
	</cfif>
	
</cffunction>

</cfcomponent>