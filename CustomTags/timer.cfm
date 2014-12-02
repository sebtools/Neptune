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
<cfparam name="Attributes.Label" default="execution time" type="string">
<cfparam name="Attributes.Active" default="true" type="boolean">
<cfparam name="Attributes.Name" type="string" default="">
<cfparam name="Attributes.Type" type="string" default="comment"><!--- Possible Values: comment,hidden,inline,outline,log,database --->
<cfparam name="Attributes.tablename" default="cf_timer" type="string">
<cfparam name="Attributes.data" default="#StructNew()#" type="struct">

<!--- We only need DataMgr and table stuff if we are storing the time to the database --->
<cfif Attributes.Type EQ "database">
	<!--- Make sure we have a structure for the timer objects. This allows us to cache it and avoid calling the loadXml() on every request. Caching is done by datasource in case more than one datasource is in use. --->
	<cfif NOT StructKeyExists(Application,"cf_timers")>
		<cfset Application.cf_timers = StructNew()>
	</cfif>
	<!--- Make sure we have newer version of timer component loaded. Later we can test using the time and reload using the getDataMgr method. --->
	<cfif StructKeyExists(Application.cf_timers,attributes.datasource) AND NOT ( StructKeyExists(Application.cf_timers[attributes.datasource],"getDateLoaded") )>
		<cfset StructDelete(Application.cf_timers,attributes.datasource)>
	</cfif>
	<!--- If a datasource is explicitely provided and a component already exists for it, then we are ready. No need for extra work. --->
	<cfif NOT ( StructKeyExists(attributes,"datasource") AND StructKeyExists(Application.cf_timers,attributes.datasource) )>
		<!--- If DataMgr isn't provided then we will need to find one or make one. --->
		<cfif NOT StructKeyExists(Attributes,"DataMgr")>
			<cfif StructKeyExists(Caller,"DataMgr")>
				<cfparam name="attributes.DataMgr" default="#Caller.DataMgr#">
			<cfelseif StructKeyExists(Application,"DataMgr")>
				<cfparam name="attributes.DataMgr" default="#Application.DataMgr#">
			</cfif>
			
			<cfparam name="attributes.path" default="com.sebtools.DataMgr">
			<cfif NOT StructKeyExists(attributes,"DataMgr")>
				<cfinvoke returnvariable="attributes.DataMgr" component="#attributes.path#" method="init" argumentCollection="#attributes#">
				</cfinvoke>
			</cfif>
			
			<cfif NOT StructKeyExists(attributes,"DataMgr")>
				<cfthrow type="CFTimer" message="Type 'database' requires DataMgr and none was found.">
			</cfif>
		</cfif>
		
		<!--- Make sure we have a datasource attribute. --->
		<cfset attributes.datasource = attributes.DataMgr.getDatasource()>
		
		<!--- Make sure we have a timers component. TODO: Will need a way to refresh this at some point. --->
		<cfif NOT StructKeyExists(Application.cf_timers,attributes.datasource)>
			<cfset Application.cf_timers[attributes.datasource] = CreateObject("component","timer").init(attributes.DataMgr)>
		</cfif>
	</cfif>
	
	<cfif NOT ( StructKeyExists(Application.cf_timers[attributes.datasource],"getDateLoaded") )>
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