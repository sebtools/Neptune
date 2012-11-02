<cfcomponent displayname="Capitalizer">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="DataMgr" type="any" required="yes">
	
	<cfset variables.DataMgr = arguments.DataMgr>
	<cfset variables.datasource = variables.Datamgr.getDatasource()>
	
	<cfreturn this>
</cffunction>

<cffunction name="fixCase" access="public" returntype="string" output="no">
	<cfargument name="string" type="string" required="yes">
	<cfargument name="forcefix" type="boolean" default="false">
	
	<cfset var lcasewords = "for,of,the,a,an,of,or,and">
	<cfset var directions = "N,E,S,W,NE,SE,SW,NW,NNE,ENE,ESE,SSE,SSW,WSW,WNW,NNW">
	<cfset var word = "">
	<cfset var titlewords = TitleCaseList(string,"., ('")>
	<cfset var result = "">
	
	<!--- Only change if string is all one case, unless "forcefix" is true --->
	<cfif arguments.forcefix OR Compare(arguments.string,LCase(arguments.string)) EQ 0 OR Compare(arguments.string,UCase(arguments.string)) EQ 0>
		<cfloop index="word" list="#titlewords#" delimiters=" ">
			<cfif ListFindNoCase(lcasewords,word)>
				<!--- lower-case words that are always lower-case --->
				<cfset result = ListAppend(result,LCase(word)," ")>
			<cfelseif ListFindNoCase(directions,word)>
				<!--- upper-case directions --->
				<cfset result = ListAppend(result,UCase(word)," ")>
			<cfelseif Len(word) gt 3 AND Left(word,2) eq "mc">
				<!--- Special capitalization for words starting with "mc" --->
				<cfset word = "Mc" & UCase(Mid(word,3,1)) & LCase(Mid(word,4,Len(word)-3))>
				<cfset result = ListAppend(result,word," ")>
			<cfelse>
				<!--- Keep the corrected case for everything else --->
				<cfset result = ListAppend(result,word," ")>
			</cfif>
		</cfloop>
		<cfset result = ReReplace(result,"'S\b","'s","ALL")>
	<cfelse>
		<cfset result = arguments.string>
	</cfif>
	
	<cfreturn trim(result)>
</cffunction>

<cffunction name="fixFieldCase" access="public" returntype="void" output="no">
	<cfargument name="table" type="string" required="yes">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="pkfields" type="string" required="yes">
	<cfargument name="forcefix" type="boolean" default="false">
	
	<cfset var qRecords = getSuspectRecords(argumentCollection=arguments)>
	<cfset var pkfield = "">
	<cfset var data = 0>
	
	<cfloop query="qRecords">
		<cfset data = StructNew()>
		<cfloop index="pkfield" list="#arguments.pkfields#">
			<cfset data[pkfield] = qRecords[pkfield][CurrentRow]>
		</cfloop>
		<cfset data[arguments.field] = fixCase(qRecords[arguments.field][CurrentRow],arguments.forcefix)>
		<cfset variables.DataMgr.updateRecord(tablename=arguments.table,data=data)>
	</cfloop>
	
</cffunction>

<cffunction name="getSuspectRecords" access="public" returntype="query" output="no">
	<cfargument name="table" type="string" required="yes">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="pkfields" type="string" required="yes">
	
	<cfset var qSuspectRecords = 0>
	<cfset var sArgs = Duplicate(arguments)>
	<cfset var FieldSQL = Variables.DataMgr.escape(arguments.field)>
	
	<cfset StructDelete(sArgs,"table")>
	<cfset StructDelete(sArgs,"field")>
	<cfset StructDelete(sArgs,"pkfields")>
	<cfset sArgs["fieldlist"] = "#arguments.field#,#arguments.pkfields#">
	<cfset sArgs["tablename"] = arguments.table>
	<cfif NOT StructKeyExists(sArgs,"AdvSQL")>
		<cfset sArgs["AdvSQL"] = StructNew()>
	</cfif>
	<cfif NOT StructKeyExists(sArgs.AdvSQL,"WHERE")>
		<cfset sArgs["AdvSQL"]["WHERE"] = "">
	</cfif>
	
	<cfset sArgs["AdvSQL"]["WHERE"] = "
		#sArgs.AdvSQL.WHERE#
	AND	(
				1 = 0
			OR	#arguments.field# = UPPER(#FieldSQL#) COLLATE Latin1_General_BIN
			OR	#arguments.field# = LOWER(#FieldSQL#) COLLATE Latin1_General_BIN
			OR	#arguments.field# LIKE '% %'
			OR	#arguments.field# = ( SUBSTRING(LOWER(#FieldSQL#), 1, 1) + SUBSTRING(UPPER(#FieldSQL#), 2, LEN(#FieldSQL#)-1) ) COLLATE Latin1_General_BIN
		)
	">
	
	<cfset qSuspectRecords = Variables.DataMgr.getRecords(argumentCollection=sArgs)>
	
	<!---<cfquery name="qSuspectRecords" datasource="#variables.datasource#">
	SELECT	#arguments.field#,#arguments.pkfields#
	FROM	#arguments.table#
	WHERE	1 = 1
	AND	(
			1 = 0
		OR	#arguments.field# = UPPER(#arguments.field#) COLLATE Latin1_General_BIN
		OR	#arguments.field# = LOWER(#arguments.field#) COLLATE Latin1_General_BIN
		OR	#arguments.field# LIKE '% %'
		OR	#arguments.field# = ( SUBSTRING(LOWER(#arguments.field#), 1, 1) + SUBSTRING(UPPER(#arguments.field#), 2, LEN(#arguments.field#)-1) ) COLLATE Latin1_General_BIN
		)
	</cfquery>--->
	
	<cfreturn qSuspectRecords>
</cffunction>

<cfscript>
/**
 * Title cases all elements in a list.
 * 
 * @param list 	 List to modify. (Required)
 * @param delimiters 	 Delimiters to use. Defaults to a space. (Optional)
 * @return Returns a string. 
 * @author Adrian Lynch (adrian.l@thoughtbubble.net) 
 * @version 1, November 3, 2003 
 */
function TitleCaseList( list, delimiters ) {

	var returnString = "";
	var isFirstLetter = true;
	
	// Loop through each character in list
	for ( i = 1; i LTE Len( list ); i = i + 1 ) {
	
		// Check if character is a delimiter
		if ( Find( Mid(list, i, 1 ), delimiters, 1 ) ) {
			
			//	Add character to variable returnString unchanged
			returnString = returnString & Mid(list, i, 1 );
			isFirstLetter = true;
				
		} else {
		
			if ( isFirstLetter ) {
			
				// Uppercase
			 	returnString = returnString & UCase(Mid(list, i, 1 ) );
				isFirstLetter = false;
					
			} else {
				
				// Lowercase
				returnString = returnString & LCase(Mid(list, i, 1 ) );
				
			}
			
		}
		
	}
	
	return returnString;
}
</cfscript>

</cfcomponent>