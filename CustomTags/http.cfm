<cfsilent>
<cfif ThisTag.ExecutionMode EQ "Start">
	<cfparam name="Attributes.url" type="string">
	<cfparam name="Attributes.method" default="get">
	<cfparam name="Attributes.result" default="CFHTTP">
	<cfparam name="Attributes.log" type="boolean" default="true">
	<cfparam name="Attributes.log_result" type="boolean" default="true">
	<cfparam name="Attributes.stripBodyWhitespace" type="boolean" default="false">
	<cfparam name="Attributes.setContentLength" type="boolean" default="false">
</cfif>
<cfif ThisTag.ExecutionMode EQ "End" OR NOT ThisTag.HasEndTag>

	<!--- Default to cache get requests, but not other requests. --->
	<cfif NOT (StructKeyExists(Attributes,"cache") AND isBoolean(Attributes.cache) )>
		<!---
		If cache isn't specified, we will cache only if:
		- Method is "get"
			OR
			- HTTP request has no incoming data (No http parameters or URL variables).
			OR
			- Cache attributes are specified
		--->
		<cfset Attributes.cache = (
				Attributes.method EQ "get"
			AND	(
						false
					OR	(
								ListLen(Attributes.url,"?") EQ 1
							AND	NOT ( StructKeyExists(ThisTag,"aParams") AND ArrayLen(ThisTag.aParams) )
						)
					OR	(
								StructKeyExists(Attributes,"CacheTimeSpan")
							OR	StructKeyExists(Attributes,"CacheIdleTime")
						)
				)
		)>
	</cfif>

	<!--- Make sure not attempting to cache non-GET methods. --->
	<cfif Attributes.cache AND NOT Attributes.method EQ "get">
		<cfthrow type="cf_http" message="Only get requests can be cached.">
	</cfif>

	<!--- Handle stuff related to caching. --->
	<cfif Attributes.cache>
		<!--- Defaults and set up for Mister ECache. --->
		<cfif NOT StructKeyExists(Attributes,"CacheTimeSpan")>
			<cfset Attributes.CacheTimeSpan = CreateTimeSpan(0,0,10,0)>
		</cfif>
		<cfif NOT StructKeyExists(Attributes,"CacheIdleTime")>
			<cfset Attributes.CacheIdleTime = CreateTimeSpan(1,0,0,0)>
		</cfif>
		<cfset Variables.oMrECache = CreateObject("component","com.sebtools.MrECache").init(
			"http",
			Attributes.CacheTimeSpan,
			Attributes.CacheIdleTime
		)>
		<cfset Variables.CacheHash = SerializeJSON(Attributes)>
		<cfif StructKeyExists(ThisTag,"aParams")>
			<cfset Variables.CacheHash &= SerializeJSON(ThisTag.aParams)>
		</cfif>
		<cfset Variables.CacheHash = Hash(Variables.CacheHash)>
	</cfif>

	<!--- This is needed because calling cfhttp seems to ditch most attributes. --->
	<cfset Variables.result = Attributes.result>
	<cfif Attributes.cache AND Variables.oMrECache.exists(Variables.CacheHash)>
		<!--- Get the data from the cache --->
		<cfset Caller[Variables.result] = Variables.oMrECache.get(Variables.CacheHash)>
		<!---
		The exit is essential because later code bases the belief of no cache found
		because it couldn't be reached if it was - thanks to this exit.
		--->
		<cfexit>
	</cfif>
	<!--- Handle whitespace stripping and/or Content-Length calculation --->
	<cfset loc = {}>
	<cfset loc.body = "">
	<cfset loc.bodyIdx = 0>
	<cfif StructKeyExists(ThisTag,"aParams") AND ArrayLen(ThisTag.aParams)>
		<cfloop index="ii" from="1" to="#ArrayLen(ThisTag.aParams)#">
			<cfif StructKeyExists(ThisTag.aParams[ii],"type") AND ThisTag.aParams[ii]["type"] EQ "body">
				<cfset loc.body = ThisTag.aParams[ii]["value"]>
				<cfset loc.bodyIdx = ii>
				<cfbreak>
			</cfif>
		</cfloop>
	</cfif>

	<cfif Attributes.stripBodyWhitespace AND Len(loc.body)>
		<cfset loc.body = REReplaceNoCase(loc.body,"[\s]+(?![^><]*(?:>|<\/))","","All")>
		<cfset ThisTag.aParams[loc.bodyIdx]["value"] = loc.body>
	</cfif>
	<cfif Attributes.setContentLength AND Len(loc.body)>
		<cfset loc.ContentLengthIdx = 0>
			<cfloop index="ii" from="1" to="#ArrayLen(ThisTag.aParams)#">
			<cfif StructKeyExists(ThisTag.aParams[ii],"type") AND ThisTag.aParams[ii]["type"] EQ "Content-Length">
				<cfset loc.ContentLengthIdx = ii>
				<cfbreak>
			</cfif>
		</cfloop>
		<cfif loc.ContentLengthIdx>
			<cfset ThisTag.aParams[loc.ContentLengthIdx]["value"] = Len(loc.body)>
		<cfelse>
			<cfset loc.sContentLength = {type="Content-Length",value=Len(loc.body)}>
			<cfset ArrayAppend(ThisTag.aParams,loc.sContentLength)>
		</cfif>
	</cfif>

	<cfset sArgs = StructCopy(Attributes)>
	<cfset begin = getTickCount()>
	<cfhttp attributeCollection="#Attributes#">
		<cfif StructKeyExists(ThisTag,"aParams")>
			<cfloop index="ii" from="1" to="#ArrayLen(ThisTag.aParams)#">
				<cfhttpparam attributeCollection="#ThisTag.aParams[ii]#">
			</cfloop>
		</cfif>
	</cfhttp>
	<cfset end = getTickCount()>
	<cfif Attributes.log>
		<cf_service name="DataMgr">
		<!--- If unable to get DataMgr service then no point in logging request. --->
		<cfif StructKeyExists(Variables,"DataMgr")>
			<cf_service name="HTTPRequestLogger">
			<!--- If logger doesn't exist, create it. --->
			<cfif NOT StructKeyExists(Variables,"HTTPRequestLogger")>
				<cfset Variables.HTTPRequestLogger = CreateObject("component","com.sebtools.utils.HTTPRequestLogger").init(DataMgr=Variables.DataMgr) />
			</cfif>
			<!--- Log the request --->
			<cfset sLogArgs = {}>
			<cfset sLogArgs["Attribs"] = sArgs>
			<cfset sLogArgs["ProcessTimeMS"] = end - begin>
			<cfif StructKeyExists(ThisTag,"aParams")>
				<cfset sLogArgs["Params"] = ThisTag.aParams>
				<!--- Hash values with hash=true attribute --->
				<cfloop index="ii" from="1" to="#ArrayLen(sLogArgs.Params)#">
					<cfif
							StructKeyExists(sLogArgs.Params[ii],"hash")
						AND	sLogArgs.Params[ii]["hash"] IS true
						AND	StructKeyExists(sLogArgs.Params[ii],"value")
						AND	Len(sLogArgs.Params[ii]["value"])
					>
						<cfset sLogArgs.Params[ii]["value"] = Hash(sLogArgs.Params[ii]["value"])>
					</cfif>
				</cfloop>
			<cfelse>
				<cfset sLogArgs["Params"] = ArrayNew(1)>
			</cfif>
			<cfif Attributes.log_result>
				<cfset sLogArgs["Result"] = Variables[Variables.result]>
			</cfif>

			<cfset Variables.HTTPRequestLogger.logRequest(ArgumentCollection=sLogArgs)>
		</cfif>
	</cfif>

	<!---
	If the code reaches here then we need to cache but don't have the data.
	Save that data for next time.
	--->
	<cfif Attributes.cache>
		<cfset Variables.oMrECache.put(Variables.CacheHash,Variables[Variables.result])>
	</cfif>
	<cfset Caller[Variables.result] = Variables[Variables.result]>

</cfif>
</cfsilent>
