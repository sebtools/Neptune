<!--- ///////////////////////////////////////////////////
	//////	cf_timer
			Based on cf_timer by Mike Nimer (
				created by: Mike Nimer <mnimer@allaire.com>
				created on: 9/16/2000

				This tag is using the GetTickCount() function in ColdFusion. to get an exact ms time a
				section of code took to execute.

				Modeled after the <cfa_ExecutionTime> tag found in Spectra. But this does a little more.
				for instance you activate it with an attribute so you can leave it in your code and use
				a request scope variable to turn on debugging for a page, when needed. You can also have
				the tag draw a box around the section it's timing. (IE only)
			)
	////// --->

<!--- //	set defaults	//---><cfsilent>
<cfscript>
if ( StructKeyExists(request, "cftags") AND StructKeyExists(request.cftags, "cf_timer") ) {
	StructAppend(Attributes, request.cftags["cf_timer"], "no");
}
</cfscript>
<cfparam name="Attributes.Label" default="execution time" type="string">
<cfparam name="Attributes.Active" default="true" type="boolean">
<cfparam name="Attributes.Name" type="string" default="">
<cfparam name="Attributes.Type" type="string" default="comment"><!--- Possible Values: comment,hidden,inline,outline,log,database --->
<cfparam name="Attributes.tablename" default="cf_timer" type="string">
<cfparam name="Attributes.data" default="#StructNew()#" type="struct">

<cfif NOT Attributes.Active>
	<cfexit method="exitTemplate">
</cfif>

<!--- <cfif ThisTag.ExecutionMode EQ "Start" AND Attributes.Active>
	<cfscript>
	Attributes.CodeTemplate = "";
	function getCallerTemplatePath() {
		var field = getMetaData(Caller).getDeclaredField("pageContext");
		field.setAccessible(true);
		return field.get(caller).getPage().getCurrentTemplatePath();
	}
	function getFileURL(FilePath) {
		var delim = Right(getDirectoryFromPath(getCurrentTemplatePath()),1);
		var RootFilePath = ReplaceNoCase(ListChangeDelims(CGI.CF_TEMPLATE_PATH,delim,"/"),ListChangeDelims(CGI.SCRIPT_NAME,delim,"/"),"");
		var result = "";

		if ( FilePath CONTAINS RootFilePath ) {
			result = "/" & ListChangeDelims(ReplaceNoCase(FilePath,RootFilePath,""),"/",delim);
		}

		return result;
	}
	</cfscript>
	<cftry>
		<cfset Attributes.CodeTemplate = getFileURL(getCallerTemplatePath())>
	<cfcatch>
	</cfcatch>
	</cftry>
</cfif> --->


<!--- We only need DataMgr and table stuff if we are storing the time to the database --->
<cfif ThisTag.ExecutionMode EQ "Start" AND Attributes.Active AND Attributes.Type EQ "database">

	<!--- Make sure we have a structure for the timer objects. This allows us to cache it and avoid calling the loadXml() on every request. Caching is done by datasource in case more than one datasource is in use. --->
	<cfif NOT StructKeyExists(Application,"cf_timers")>
		<cfset Application.cf_timers = StructNew()>
	</cfif>

	<!--- Make sure we have a datasource --->
	<cfif NOT StructKeyExists(attributes,"datasource")>

		<cfif StructKeyExists(Caller,"DataMgr")>
			<cfparam name="Attributes.DataMgr" default="#Caller.DataMgr#">
		<cfelseif StructKeyExists(Application,"DataMgr")>
			<cfparam name="Attributes.DataMgr" default="#Application.DataMgr#">
		</cfif>

		<!--- If DataMgr isn't provided then we will need to find one. --->
		<cfif NOT StructKeyExists(Attributes,"DataMgr")>
			<cfthrow type="CFTimer" message="Type 'database' requires database or DataMgr and neither was found.">
		</cfif>

		<!--- Make sure we have a datasource attribute. --->
		<cfset Attributes.datasource = Attributes.DataMgr.getDatasource()>

	</cfif>

	<!--- ASSERT: Should be no way for datasource not to be set here, but we'll verify just in case. --->
	<!--- If DataMgr isn't provided then we will need to find one. --->
	<cfif NOT StructKeyExists(Attributes,"datasource")>
		<cfthrow type="CFTimer" message="Type 'database' requires database or DataMgr and neither was found.">
	</cfif>

	<!--- Make sure we have newer version of timer component loaded. Later we can test using the time and reload using the getDataMgr method. --->
	<cfif
				StructKeyExists(attributes,"datasource")
			AND	StructKeyExists(Application.cf_timers,attributes.datasource)
			AND	NOT (
						StructKeyExists(Application.cf_timers[attributes.datasource],"getDateLoaded")
					AND	Application.cf_timers[attributes.datasource].getDateLoaded() GTE '2015-07-29'
				)
	>
		<cfset StructDelete(Application.cf_timers,Attributes.datasource)>
	</cfif>

	<!--- Make sure we have a timers component.. --->
	<cfif NOT StructKeyExists(Application.cf_timers,Attributes.datasource)>

		<!--- Make sure we have a DataMgr --->
		<cfif NOT StructKeyExists(Attributes,"DataMgr")>
			<cfparam name="Attributes.path" default="com.sebtools.DataMgr">
			<cfset Attributes.DataMgr = CreateObject("component",Attributes.path).init(ArgumentCollection=Attributes)>
		</cfif>

		<cfset Application.cf_timers[attributes.datasource] = CreateObject("component","timer").init(Attributes.DataMgr)>
	</cfif>

	<!--- Just a handy reference for the timers component needed in this tag. --->
	<cfset oTimer = Application.cf_timers[attributes.datasource]>

	<!--- Pull "data_" attributes into "data" attribute --->
	<cfloop item="key" collection="#Attributes#">
		<cfif ListLen(key,"_") GTE 2 AND ListFirst(key,"_") EQ "data">
			<cfset Attributes.data[ListRest(key,"_")] = Attributes[key]>
		</cfif>
	</cfloop>

	<!--- To identify when the page was loaded --->
	<cfif NOT StructKeyExists(request,"cf_timer_page_loaded")>
		<cfset request["cf_timer_page_loaded"] = now()>
	</cfif>

</cfif>

</cfsilent><cfif Attributes.Active>
	<cfswitch expression="#ThisTag.ExecutionMode#">
	<cfcase value="start">
		<cfset startTime = getTickCount()>
	</cfcase>
	<!--- //	Process Body	//--->
	<cfcase value="end">
		<!--- <cfdump var="#getCallerTemplatePath()#" /><cfabort /> --->
		<cfset endTime = getTickCount()>
		<cfset Value = endTime - startTime>
		<cfset Output = "#Attributes.Label#: #Value#ms">
		<cfif Len(Attributes.Name)>
			<cfset Caller[Attributes.Name] = Value>
		</cfif>
		<cfoutput>
		<cfswitch expression="#Attributes.Type#">
		<cfcase value="comment">
			<!-- #Output# -->
		</cfcase>
		<cfcase value="database">
			<cfset oTimer.logTime(
				Name=Attributes.Name,
				Label=Attributes.Label,
				Template=CGI.SCRIPT_NAME,
				data=Attributes.data,
				Time_ms=Value,
				DatePageLoaded=request["cf_timer_page_loaded"]
			)>
		</cfcase>
		<cfcase value="inline">
			#Output#
		</cfcase>
		<cfcase value="log">
			<cflog text="#Output#">
		</cfcase>
		<cfcase value="outline">
			<fieldset class="cftimer">
					<legend>#Output#</legend>
				#ThisTag.GeneratedContent#
			</fieldset>
			<cfset ThisTag.GeneratedContent = "">
		</cfcase>
		</cfswitch>
		</cfoutput>
	</cfcase>
	</cfswitch>
</cfif>
