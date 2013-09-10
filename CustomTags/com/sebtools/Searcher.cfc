<!--- 1.0 RC (Build 9) --->
<!--- Last Updated: 2012-01-24 --->
<!--- Created by Steve Bryant 2005-10-20 --->
<!--- Information: sebtools.com --->
<!---
Desired Features:
Create collections to be searched
Index and repair collections
Run a search and return results
Keep track of searches
Provide Google-like ability to suggest spelling corrections
Optionally run search through google
--->

<cfcomponent displayname="Searcher" hint="I manage search functionality. I will usually be extended by a site-specific search object.">

<cffunction name="init" access="public" returntype="any" output="no" hint="I initialize and return this object.">
	<cfargument name="CollectionPath" type="string" required="yes">
	<cfargument name="DataMgr" type="any" required="yes">
	<cfargument name="sendpage" type="string" default="">
	<cfargument name="excludedirs" type="string" default="">
	<cfargument name="excludefiles" type="string" default="">
	<cfargument name="UseGoogleSyntax" type="boolean" default="false">
	
	<cfreturn initInternal(argumentCollection=arguments)>
</cffunction>

<cffunction name="initInternal" access="private" returntype="any" output="no" hint="I initialize and return this object.">
	<cfargument name="CollectionPath" type="string" required="yes">
	<cfargument name="DataMgr" type="any" required="yes">
	<cfargument name="sendpage" type="string" default="">
	<cfargument name="excludedirs" type="string" default="">
	<cfargument name="excludefiles" type="string" default="">
	<cfargument name="UseGoogleSyntax" type="boolean" default="false">
	
	<cfset var qTest = 0>
	
	<cfscript>
	variables.path = arguments.CollectionPath;
	variables.DataMgr = arguments.DataMgr;
	variables.datasource = variables.DataMgr.getDatasource();
	variables.DataMgr.loadXML(getDbXml(),true);
	variables.Collections = "";
	variables.sendpage = arguments.sendpage;
	variables.excludedirs = arguments.excludedirs;
	variables.excludefiles = arguments.excludefiles;
	variables.UseGoogleSyntax = arguments.UseGoogleSyntax;
	</cfscript>
	
	<cfreturn this>
</cffunction>

<cffunction name="addCollection" access="public" returntype="void" output="no">
	<cfargument name="CollectionName" type="string" required="yes">
	
	<!--- If this collection isn't already known to Searcher, add it. --->
	<cfif NOT ListFindNoCase(variables.Collections, CollectionName)>
		<cfset variables.Collections = ListAppend(variables.Collections, CollectionName)>
	</cfif>

</cffunction>

<cffunction name="create" access="public" returntype="void" output="no" hint="I create the given collection.">
	<cfargument name="CollectionName" type="string" required="yes">
	<cfargument name="recreate" type="boolean" default="false">
	
	<cfset var qCollections = 0>
	<cfset var isExisting = false>
	
	<cflock timeout="120" throwontimeout="No" name="Searcher_CheckCollection_#arguments.CollectionName#" type="EXCLUSIVE">
		<cfcollection action="LIST" name="qCollections">
		<!--- <cfdump var="#qCollections#"><cfabort> --->
		
		<cfif ListFindNoCase(ValueList(qCollections.name),arguments.CollectionName)>
			<!--- <cfquery name="qCollections" dbtype="query">
			SELECT	*
			FROM	qCollections
			WHERE	Name = '#arguments.CollectionName#'
			</cfquery>
			<cfif qCollections.RecordCount>
				<cfif ListFindNoCase(qCollections.ColumnList,"External") AND qCollections.External IS "NOT FOUND">
					<cflock timeout="20" throwontimeout="No" name="Searcher_DeleteCollection" type="EXCLUSIVE">
						<cfcollection action="DELETE" collection="#arguments.CollectionName#">
					</cflock>
				<cfelse>
					<cfset isExisting = true>
				</cfif>
			</cfif> --->
			<cfset isExisting = true>
		</cfif>
		
		<!--- arguments.recreate OR NOT  --->
		<cfif NOT isExisting>
			<cftry>
				<cflock timeout="40" throwontimeout="No" name="Searcher_CreateCollection_#arguments.CollectionName#" type="EXCLUSIVE">
					<cfcollection action="CREATE" collection="#arguments.CollectionName#" path="#variables.path#" language="English">
				</cflock>
				<cfcatch>
					<!---<cfif
							ListFindNoCase(ValueList(qCollections.name),arguments.CollectionName)
						OR	CFCATCH.Detail CONTAINS "has already been registered"
						OR	CFCATCH.Detail CONTAINS "Unable to create collection"
					>--->
						<cfset deleteDirectory("#variables.path#/#LCase(arguments.CollectionName)#")>
						<cfcollection action="LIST" name="qCollections">
						<cfloop query="qCollections">
							<cfif name EQ CollectionName>
								<cflock timeout="40" throwontimeout="Yes" name="Searcher_DeleteCollection_#arguments.CollectionName#" type="EXCLUSIVE">
									<cfset deleteDirectory(path)>
									<cfcollection action="DELETE" collection="#name#">
								</cflock>
							</cfif>
						</cfloop>
						<cflock timeout="40" throwontimeout="No" name="Searcher_CreateCollection_#arguments.CollectionName#" type="EXCLUSIVE">
							<cfcollection action="CREATE" collection="#arguments.CollectionName#" path="#variables.path#" language="English">
						</cflock>
					<!---<cfelse>
						<cfrethrow>
					</cfif>--->
				</cfcatch>
			</cftry>
		</cfif>
	</cflock>
	
	<!--- <cfif arguments.recreate>
		<cftry>
			<cfcollection action="CREATE" collection="#arguments.CollectionName#" path="#variables.path#" language="English">
			<cfcatch>
			
			</cfcatch>
		</cftry>
	<cfelse>
		<cfcollection action="LIST" name="qCollections">
		
		<cfif NOT ListFindNoCase(ValueList(qCollections.name),arguments.CollectionName)>
			<cfcollection action="CREATE" collection="#arguments.CollectionName#" path="#variables.path#" language="English">
		</cfif>
	</cfif> --->
	
	
	<!--- <cftry>
		<cfcollection action="CREATE" collection="#arguments.CollectionName#" path="#variables.path#" language="English">
		<cfcatch>
			<cfif NOT CFCATCH.Detail CONTAINS "has already been registered">
				<cfrethrow>
			</cfif>
		</cfcatch>
	</cftry> --->
	
	<!--- If this collection isn't already known to Searcher, add it. --->
	<cfset addCollection(arguments.CollectionName)>
	
</cffunction>

<cffunction name="getCollections" access="public" returntype="string" output="no" hint="I return a list of all of the collections used by Searcher.">
	<cfreturn variables.Collections>
</cffunction>

<cffunction name="index" access="public" returntype="boolean" output="no" hint="I index the collection(s) to be searched.">
	<cfabort showerror="This Method is Abstract and needs to be overridden">
</cffunction>

<cffunction name="indexPath" access="public" returntype="void" output="no" hint="I index a path collection and add it to the Searcher.">
	<cfargument name="CollectionName" type="string" required="yes">
	<cfargument name="Key" type="string" required="yes">
	<cfargument name="extensions" type="string" default="htm,html,cfm,cfml,dbm,dbml">

	<!--- Try to index the given collection name from the given path --->
	<cflock timeout="120" throwontimeout="yes" name="Searcher_IndexQuery_#arguments.CollectionName#" type="EXCLUSIVE">
		<cftry>
			<cfindex action="REFRESH" collection="#arguments.CollectionName#" key="#arguments.Key#" type="PATH" recurse="Yes" extensions="#Arguments.extensions#">
			<cfcatch>
				<!--- If index fails, try to create it and index again (exception will bubble up if it fails again) --->
				<!--- <cftry> --->
					<cfset create(arguments.CollectionName)>
					<!--- <cfcatch> ---><!--- Try catch so that any exception return will be about cfindex, not cfcollection --->
					<!--- </cfcatch>
				</cftry> --->
				<!--- <cfset indexPath(arguments.CollectionName,arguments.Key)> --->
				<cfindex action="REFRESH" collection="#arguments.CollectionName#" key="#arguments.Key#" type="PATH" recurse="Yes" extensions="#Arguments.extensions#">
			</cfcatch>
		</cftry>
	</cflock>
	
	<!--- If this collection isn't already known to Searcher, add it. --->
	<cfset addCollection(arguments.CollectionName)>

</cffunction>

<cffunction name="indexQuery" access="public" returntype="void" output="no" hint="I index a query collection and add it to the Searcher.">
	<cfargument name="CollectionName" type="string" required="yes">
	<cfargument name="query" type="query" required="yes">
	<cfargument name="Key" type="string" required="yes">
	<cfargument name="Title" type="string" required="yes">
	<cfargument name="Body" type="string" required="yes">
	<cfargument name="URLPath" type="string" default="">
	<cfargument name="Custom1" type="string" default="">
	<cfargument name="Custom2" type="string" default="">
	
	
	<!--- Try to index the given collection name from the given path --->
	<cftry>
		<cflock timeout="120" throwontimeout="yes" name="Searcher_IndexQuery_#arguments.CollectionName#" type="EXCLUSIVE">
			<cfindex action="REFRESH"
				collection="#CollectionName#"
				key="#Key#"
				type="CUSTOM"
				title="#Title#"
				query="arguments.query"
				body="#Body#"
				urlpath="#URLPath#"
				custom1="#Custom1#"
				custom2="#Custom2#"
				>
		</cflock>
		<cfcatch>
			<cftry>
				<cfset create(arguments.CollectionName,true)>
				<cfcatch><!--- Try catch so that any exception return will be about cfindex, not cfcollection --->
				</cfcatch>
			</cftry>
			<cfindex action="REFRESH"
				collection="#CollectionName#"
				key="#Key#"
				type="CUSTOM"
				title="#Title#"
				query="arguments.query"
				body="#Body#"
				urlpath="#URLPath#"
				custom1="#Custom1#"
				custom2="#Custom2#"
				>
		</cfcatch>
	</cftry>

	<!--- If this collection isn't already known to Searcher, add it. --->
	<cfset addCollection(arguments.CollectionName)>
	
	
</cffunction>

<cffunction name="reRun" access="public" returntype="query" output="no" hint="I return results from a search that has already been run (useful for multi-page search results).">
	<cfargument name="searchid" type="numeric" required="yes">
	
	<cfset var qSearchRecord = variables.DataMgr.getRecord('srchSearches',arguments)>
	<cfset var Collections = qSearchRecord.Collections>
	
	<cfreturn runSearch(qSearchRecord.Phrase,arguments.searchid,Collections)>
</cffunction>

<cffunction name="run" access="public" returntype="query" output="no" hint="I run a search on the given search term.">
	<cfargument name="searchterm" type="string" required="yes">
	<cfargument name="collections" type="string" default="#variables.Collections#" hint="A list of collections to search">
	
	<cfset var searchid = saveSearch(arguments.searchterm,now(),arguments.collections)>
	<cfset var qSearch = runSearch(arguments.searchterm,searchid,arguments.collections)>
	
	<cfset updateSearchRecords(searchid,qSearch.RecordCount)>
	
	<cfreturn qSearch>
</cffunction>

<cffunction name="deleteDirectory" access="private" returntype="void" output="no">
	<cfargument name="path" type="string" required="yes">
	
	<cfset var qDirectories = 0>
	<cfset var dirdelim = CreateObject("java", "java.io.File").separator>
	<cfset var item = "">
	
	<cfdirectory action="LIST" directory="#arguments.path#" name="qDirectories">
	
	<cfloop query="qDirectories">
		<cfset item = ListAppend(path,Name,dirdelim)>
		<cfif type eq "Dir">
			<cfset deleteDirectory(item)>
		<cfelse>
			<cffile action="DELETE" file="#item#">
		</cfif>
	</cfloop>
	<cfdirectory action="DELETE" directory="#path#">
	
</cffunction>

<cffunction name="runSearch" access="private" returntype="query" output="no">
	<cfargument name="searchterm" type="string" required="yes">
	<cfargument name="searchid" type="numeric" required="yes">
	<cfargument name="collections" type="string" default="#variables.Collections#" hint="A list of collections to search">
	
	<cfset var qSearch = QueryNew('run')>
	<cfset var liDeleteRows = "">
	<cfset var thisDir = "">
	<cfset var thisFile = "">
	<cfset var specialchars = "()<>@">
	<cfset var i = 0>
	<cfset var char = "">
	<cfset var aSearchID = ArrayNew(1)>
	
	<cfif NOT Len(arguments.collections)>
		<cfset arguments.collections = variables.Collections>
	</cfif>
	
	<cfif NOT Len(arguments.collections)>
		<cfthrow message="Searcher does not have any collections to search." type="Searcher">
	</cfif>
	
	<cfif NOT Len(Trim(arguments.searchterm))>
		<cfreturn qSearch>
	</cfif>
	
	<!--- Fix uneven quotes for potential error --->
	<cfset arguments.searchterm = fixQuotes(arguments.searchterm)>
	
	<!--- Change format from Google-like format to Verity format if UseGoogleSyntax is true --->
	<cfif variables.UseGoogleSyntax>
		<cfset arguments.searchterm = deGooglize(arguments.searchterm)>
	</cfif>
	<cfset arguments.searchterm = Trim(arguments.searchterm)>
	<cfif Right(arguments.searchterm,1) EQ "\">
		<cfset arguments.searchterm = Left(arguments.searchterm,Len(arguments.searchterm)-1)>
	</cfif>
	
	
	<cfif NOT Len(Trim(arguments.searchterm))>
		<cfreturn qSearch>
	</cfif>
	
	<cftry>
		<cfsearch collection="#arguments.collections#" name="qSearch" criteria="#arguments.searchterm#">
	<cfcatch>
		<cfif CFCATCH.Message CONTAINS "Invalid search CRITERIA specified">
			<cfloop index="i" from="1" to="#Len(specialchars)#" step="1">
				<cfset char = Mid(specialchars,i,1)>
				<cfset arguments.searchterm = ReplaceNoCase(arguments.searchterm, char, "\#char#", "ALL")>
			</cfloop>
			<cfsearch collection="#arguments.collections#" name="qSearch" criteria="#arguments.searchterm#">
		<cfelse>
			<cfrethrow>
		</cfif>
	</cfcatch>
	</cftry>
	
	<cfloop query="qSearch">
		
		<!--- If relative URL, start from site root --->
		<cfif Len(URL) AND NOT URL CONTAINS "dummy.txt">
			<cfif FileExists(key)>
				<cfset QuerySetCell(qSearch,"URL",GetFileFromPath(key),CurrentRow)>
			<cfelseif Left(URL,1) neq "/" AND Left(URL,7) neq "http://">
				<cfset QuerySetCell(qSearch,"URL","/#URL#",CurrentRow)>
			</cfif>
		<cfelse>
			<cfif FileExists(key)>
				<cfset QuerySetCell(qSearch,"URL",GetFileFromPath(key),CurrentRow)>
			<cfelse>
				<cfset QuerySetCell(qSearch,"URL","/#Key#",CurrentRow)>
			</cfif>
		</cfif>

		<!--- If any directories should be excluded from the results --->
		<cfif Len(variables.excludedirs)>
			<cfloop index="thisDir" list="#variables.excludedirs#">
				<cfif Left(thisDir,1) neq "/"><cfset thisDir = "/#thisDir#"></cfif>
				<cfif Right(thisDir,1) neq "/"><cfset thisDir = "#thisDir#/"></cfif>
				<cfif URL CONTAINS thisDir>
					<cfset liDeleteRows = ListAppend(liDeleteRows,CurrentRow)>
					<cfbreak>
				</cfif>
			</cfloop>
		</cfif>
		
		<!--- If any files should be excluded from the results --->
		<cfif Len(variables.excludefiles)>
			<cfloop index="thisFile" list="#variables.excludefiles#">
				<cfif URL eq thisFile>
					<cfset liDeleteRows = ListAppend(liDeleteRows,CurrentRow)>
					<cfbreak>
				</cfif>
			</cfloop>
		</cfif>

		<!--- Remove any files that have a meta tag specifying no indexing by robots --->
		<cfif NOT ListFindNoCase(liDeleteRows, CurrentRow) AND FindNoCase("<meta name=#chr(34)#robots#chr(34)# content=#chr(34)#noindex", Summary)>
			<cfset liDeleteRows = ListAppend(liDeleteRows,CurrentRow)>
		</cfif>

		<!--- If not Title, set title to file name --->
		<cfif NOT Len(Title)>
			<cfset QuerySetCell(qSearch,"Title",ListLast(URL,"/"),CurrentRow)>
		</cfif>
		
		<!--- Escape any ampersands in URL --->
		<cfset QuerySetCell(qSearch,"URL",ReplaceNoCase(URL,"&","%26","ALL"),CurrentRow)>
		<cfset QuerySetCell(qSearch,"URL",ReplaceNoCase(URL,"[Key]",KEY,"ALL"),CurrentRow)>
		
		<!--- Send to this component for tracking and redirection --->
		<cfif Len(Trim(variables.sendpage))>
			<cfset QuerySetCell(qSearch,"URL","#variables.sendpage#?searchid=#arguments.searchid#&to=#URL#",CurrentRow)>
		</cfif>

	</cfloop>
	<cfset qSearch = QueryDeleteRows(qSearch,liDeleteRows)>
	
	
	<cfloop query="qSearch">
		<cfset ArrayAppend(aSearchID,arguments.searchid)>
	</cfloop>
	<cfset QueryAddColumn(qSearch,"SearchID",aSearchID)>
	
	<cfreturn qSearch>
</cffunction>

<cffunction name="saveSearch" access="private" returntype="numeric" output="no" hint="I save a search and return the searchid of the saved search.">
	<cfargument name="Phrase" type="string" required="yes">
	<cfargument name="WhenRequested" type="date" required="yes">
	<cfargument name="collections" type="string" default="#variables.Collections#" hint="A list of collections to search">
	
	<cfreturn variables.DataMgr.insertRecord('srchSearches',arguments)>
</cffunction>

<cffunction name="updateSearchRecords" access="private" returntype="void" output="no">
	<cfargument name="SearchID" type="numeric" required="yes">
	<cfargument name="RecordsReturned" type="numeric" required="yes">
	
	<cfset variables.DataMgr.updateRecord('srchSearches',arguments)>
	
</cffunction>

<cffunction name="send" access="remote" returntype="any" output="yes" hint="I track a search selection and the redirect the user to the desired page.">
	<cfargument name="searchid" type="numeric" required="yes">
	<cfargument name="to" type="string" required="yes">
	
	<cfscript>
	var stcMain = StructNew();
	var stcChosen = StructNew();
	
	stcMain.SearchID = arguments.searchid;
	stcMain.LastPageChosen = arguments.to;
	stcChosen.SearchID = arguments.searchid;
	stcChosen.PageChosen = arguments.to;
	stcChosen.WhenChosen = now();
	
	variables.DataMgr.updateRecord('srchSearches',stcMain);
	variables.DataMgr.insertRecord('srchSelections',stcChosen);
	</cfscript>
	
	<cflocation url="#arguments.to#" addtoken="No">
</cffunction>

<cffunction name="getSearchData" access="public" returntype="query" output="no" hint="I return information about past searches.">
	<cfargument name="startdate" type="date" required="no">
	<cfargument name="enddate" type="date" required="no">

	<cfset var qSearches = 0>
	
	<cfquery name="qSearches" datasource="#variables.datasource#">
	SELECT		Phrase, Count(SearchID) AS numSearches
	FROM		srchSearches
	WHERE		0 = 0
	<cfif isDefined("arguments.startdate")>
		AND		WhenRequested >= #CreateODBCDateTime(arguments.startdate)#
	</cfif>
	<cfif isDefined("arguments.enddate")>
		AND		WhenRequested < #CreateODBCDateTime(arguments.enddate)#
	</cfif>
	GROUP BY	Phrase
	ORDER BY	NumSearches DESC
	</cfquery>
	
	<cfreturn qSearches>
</cffunction>

<cffunction name="getLandingPages" access="public" returntype="query" output="no" hint="I return information about the given search phrase.">
	<cfargument name="searchterm" type="string" required="yes">
	<cfargument name="startdate" type="date" required="no">
	<cfargument name="enddate" type="date" required="no">

	<cfset var qSearchData = 0>
	
	<cfquery name="qSearchData" datasource="#variables.datasource#">
	SELECT		Count(SearchID) AS numTimesChosen,LastPageChosen
	FROM		srchSearches
	WHERE		Phrase = <cfqueryparam value="#arguments.searchterm#" cfsqltype="CF_SQL_VARCHAR">
	<cfif isDefined("arguments.startdate")>
		AND		WhenRequested >= #CreateODBCDateTime(arguments.startdate)#
	</cfif>
	<cfif isDefined("arguments.enddate")>
		AND		WhenRequested < #CreateODBCDateTime(arguments.enddate)#
	</cfif>
	GROUP BY	LastPageChosen
	ORDER BY	numTimesChosen DESC
	</cfquery>
	
	<cfreturn qSearchData>
</cffunction>

<cffunction name="getDbXml" access="public" returntype="string" output="no" hint="I return the XML for the tables needed for Searcher to work.">
	
	<cfset var tableXML = "">
	
	<cfsavecontent variable="tableXML">
	<tables>
		<table name="srchSearches">
			<field ColumnName="SearchID" CF_DataType="CF_SQL_INTEGER" PrimaryKey="true" Increment="true" />
			<field ColumnName="Phrase" CF_DataType="CF_SQL_VARCHAR" Length="180" />
			<field ColumnName="WhenRequested" CF_DataType="CF_SQL_DATE" />
			<field ColumnName="RecordsReturned" CF_DataType="CF_SQL_INTEGER" />
			<field ColumnName="LastPageChosen" CF_DataType="CF_SQL_VARCHAR" Length="180" />
			<field ColumnName="Collections" CF_DataType="CF_SQL_VARCHAR" Length="250" />
		</table>
		<table name="srchSelections">
			<field ColumnName="SearchLinkID" CF_DataType="CF_SQL_INTEGER" PrimaryKey="true" Increment="true" />
			<field ColumnName="SearchID" CF_DataType="CF_SQL_INTEGER" />
			<field ColumnName="PageChosen" CF_DataType="CF_SQL_VARCHAR" Length="180" />
			<field ColumnName="WhenChosen" CF_DataType="CF_SQL_DATE" />
		</table>
	</tables>
	</cfsavecontent>
	
	<cfreturn tableXML>
</cffunction>

<cfscript>
/**
 * Removes rows from a query.
 * Added var col = "";
 * No longer using Evaluate. Function is MUCH smaller now.
 * 
 * @param Query 	 Query to be modified 
 * @param Rows 	 Either a number or a list of numbers 
 * @return This function returns a query. 
 * @author Raymond Camden (ray@camdenfamily.com) 
 * @version 2, October 11, 2001 
 */
function QueryDeleteRows(Query,Rows) {
	var tmp = QueryNew(Query.ColumnList);
	var i = 1;
	var x = 1;

	for(i=1;i lte Query.recordCount; i=i+1) {
		if(not ListFind(Rows,i)) {
			QueryAddRow(tmp,1);
			for(x=1;x lte ListLen(tmp.ColumnList);x=x+1) {
				QuerySetCell(tmp, ListGetAt(tmp.ColumnList,x), query[ListGetAt(tmp.ColumnList,x)][i]);
			}
		}
	}
	return tmp;
}
function fixQuotes(str) {
	//Make sure we have an even number of quotes
	var searchstring = ReplaceNoCase(arguments.str,"'","#chr(34)#");
	var sQuotePositions = REFind("""[^""]*""",searchstring,1,"true");
	
	if ( NOT StructIsEmpty(sQuotePositions) AND ArrayLen(sQuotePositions.pos) MOD 2 NEQ 0 ) {
		searchstring = Reverse(searchstring);
		searchstring = Replace(searchstring,"""","");
		searchstring = Reverse(searchstring);
	}
	return searchstring;
}
/**
 * Converts a Google-style search string to Verity style.
 * 
 * @param strSearch 	 string to be modified 
 * @return This function returns a string. 
 * @author Tim DeMoss
 * @version 1, September 10, 2007
 */
function deGooglize(strSearch) {//I convert a Google-style search string to Verity style
	var aSections = ArrayNew(1);
	var cursor = 1;
	var nextQuotePos = 0;
	var shortstring = "";
	var searchstring = arguments.strSearch;
	//Make sure we have an even number of quotes
	var sQuotePositions = REFind("""[^""]*""",searchstring,1,"true");
	if (NOT StructIsEmpty(sQuotePositions) AND ArrayLen(sQuotePositions.pos) MOD 2 NEQ 0) {
		searchstring = Reverse(searchstring);
		searchstring = Replace(searchstring,"""","");
		searchstring = Reverse(searchstring);
	}
	//trim all multiple spaces to single spaces
	searchstring = REReplace(searchstring,"\s+"," ","ALL");
	//convert all ORs to commas
	searchstring = ReplaceNoCase(searchstring," OR ",",");
	//manipulate the resulting string
	while ( cursor LT Len(searchstring) ) {
		shortstring = Mid(searchstring,cursor,Len(searchstring)-cursor+1);
		if ( Left(Trim(shortstring),1) EQ chr(34)  ) {
			//Slap that thing into the array (sans quotes)
			nextQuotePos = Find("""",searchstring,cursor+1);
			ArrayAppend(aSections,Mid(searchstring,cursor+1,nextQuotePos-cursor-1));
			//Move cursor to the end of the string we found
			cursor = nextQuotePos + 1;
		} else {
			//find next quote
			nextQuotePos = Find("""",searchstring,cursor);
			if (nextQuotePos EQ 0) { //no more quotes
				nextQuotePos = Len(searchstring) + 1;
			}
			shortstring = Mid(searchstring,cursor,nextQuotePos-cursor);
			// List manipulation
			shortstring = Replace(shortstring," ","&","all");
			shortstring = ReplaceNoCase(shortstring,"&AND&","&","all");
			// Slap result into array
			ArrayAppend(aSections,shortstring);
			//CFDUMP(aSections);
			//Move cursor to the end of the string we found
			cursor = nextQuotePos;
		}
	}
	//recreate the search string from stored values in the array
	searchstring = ArrayToList(aSections,"&");
	//put ANDs in place of &s
	return ListChangeDelims(searchstring," AND ","&");
}
</cfscript>

</cfcomponent>