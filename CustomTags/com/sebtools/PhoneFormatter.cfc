<!--- 1.0 Beta Build 04 --->
<!--- Last Updated: 2007-05-27 --->
<!--- Created by Steve Bryant 2007-01-26 --->
<cfcomponent displayname="PhoneFormatter" hint="I ensure that phone numbers are in the correct format.">

<cffunction name="init" access="public" returntype="any" output="no" hint="I initialize and return this component.">
	<cfargument name="DataMgr" type="any" required="yes">
	<cfargument name="Format" type="any" required="yes">
	<cfargument name="DefaultAreaCode" type="string" default="000">
	
	<cfset variables.DataMgr = arguments.DataMgr>
	<cfset variables.Format = arguments.Format>
	<cfset variables.DefaultAreaCode = arguments.DefaultAreaCode>
	
	<cfif Len(variables.DefaultAreaCode) NEQ 3>
		<cfset variables.DefaultAreaCode = "000">
	</cfif>
	
	<cfset variables.phonechars = "()- ext./\">
	<cfset variables.badchars = getBadChars()>
	<cfset variables.goodchars = getGoodChars()>
	
	<cfset variables.datasource = variables.DataMgr.getDatasource()>
	
	<cfreturn this>
</cffunction>

<cffunction name="fixPhoneNumber" access="public" returntype="string" output="no" hint="I return the given phone number in the correct format.">
	<cfargument name="phonenum" type="string" required="yes" hint="The phone number to be formatted.">
	<cfargument name="areacode" type="string" default="#variables.DefaultAreaCode#" hint="The area code to use if none is present">
	
	<cfset var digits = ReReplace(ListFirst(arguments.phonenum,"x"),"[^[:digit:]]","","all")>
	<cfset var result = "">
	
	<cfif Len(arguments.areacode) NEQ 3>
		<cfset arguments.areacode = variables.DefaultAreaCode>
	</cfif>
	
	<cfif Len(digits)>
		<cfif Len(digits) EQ 7 OR ( Len(digits) GT 7 AND Len(digits) LT 10 )>
			<cfset result = PhoneFormat("#arguments.areacode##arguments.phonenum#",variables.Format)>
		<cfelse>
			<cfset result = PhoneFormat(arguments.phonenum,variables.Format)>
		</cfif>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="fixPhoneNumbers" access="public" returntype="void" output="no" hint="I fix all of the phone numbers in the given field of the given table.">
	<cfargument name="table" type="string" required="yes" hint="The table to correct">
	<cfargument name="phonefield" type="string" required="yes" hint="The field holding the phone number (must not have other information).">
	<cfargument name="pkfields" type="string" required="yes" hint="The primary key field of the table (must be exactly one to work).">
	
	<cfset var qPhoneNumbers = getProblemNumbers(arguments.table,arguments.pkfields,arguments.phonefield)>
	<cfset var pkfield = "">
	<cfset var data = 0>
	
	<cfloop query="qPhoneNumbers">
		<cfif PhoneNumber NEQ PhoneNumber_Formatted>
			<cfset data = StructNew()>
			<cfloop index="pkfield" list="#arguments.pkfields#">
				<cfset data[pkfield] = qPhoneNumbers['ID'][CurrentRow]>
			</cfloop>
			<cfset data[arguments.phonefield] = PhoneNumber_Formatted>
			
			<cfset variables.DataMgr.updateRecord(arguments.table,data)>
		</cfif>
	</cfloop>

</cffunction>

<cffunction name="getProblemNumbers" access="public" returntype="query" output="no" hint="I get all of the phone numbers from the given table that are not formatted correctly (as well as the correct formatting for that phone number).">
	<cfargument name="table" type="string" required="yes" hint="The table to correct">
	<cfargument name="idfield" type="string" required="yes" hint="The primary key field of the table (must be exactly one to work).">
	<cfargument name="phonefield" type="string" required="yes" hint="The field holding the phone number (must not have other information).">
	
	<cfset var sqlTable = variables.DataMgr.escape(arguments.table)>
	<cfset var sqlIdField = variables.DataMgr.escape(arguments.idfield)>
	<cfset var sqlPhoneField = variables.DataMgr.escape(arguments.phonefield)>
	<cfset var qPhoneNumbers = QueryNew("ID,PhoneNumber,PhoneNumber_Formatted")>
	<cfset var thisChar = "">
	
	<cftry>
		<cfquery name="qPhoneNumbers" datasource="#variables.datasource#">
		SELECT	#sqlIdField# AS ID, #sqlPhoneField# AS PhoneNumber, '' AS PhoneNumber_Formatted
		FROM	#sqlTable#
		WHERE	(
						#sqlPhoneField# IS NOT NULL
					AND	#sqlPhoneField# <> ''
				)
			AND	(
						1 = 0
				<cfloop index="thisChar" list="#variables.badchars#">
					OR	#sqlPhoneField# LIKE '%#thisChar#%'
				</cfloop>
				<cfloop index="thisChar" list="#variables.goodchars#">
					OR	NOT #sqlPhoneField# LIKE '%#thisChar#%'
				</cfloop>
				)
		</cfquery>
		
		<cfloop query="qPhoneNumbers">
			<cfset QuerySetCell(qPhoneNumbers, "PhoneNumber_Formatted", fixPhoneNumber(PhoneNumber), CurrentRow)>
		</cfloop>
	<cfcatch>
	</cfcatch>
	</cftry>
	
	<cfreturn qPhoneNumbers>
</cffunction>

<cffunction name="getBadChars" access="private" returntype="string" output="no" hint="I return a list of all of the unacceptable characters for phone numbers.">
	<cfargument name="Format" type="string" default="#variables.Format#">
	
	<cfset var i = 0>
	<cfset var thischar = "">
	<cfset var result = "">
	
	<!--- Loop through all phone characters --->
	<cfloop index="i" from="1" to="#Len(variables.phonechars)#" step="1">
		<!--- Get the character --->
		<cfset thisChar = Mid(variables.phonechars,i,1)>
		<!--- If the character isn't in the format, add it to the list of unacceptable characters --->
		<cfif NOT FindNoCase(thisChar, arguments.Format)>
			<cfset result = ListAppend(result,thisChar)>
		</cfif>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<cffunction name="getGoodChars" access="private" returntype="string" output="no" hint="I return a list of all of the acceptable non-numeric characters for phone numbers.">
	<cfargument name="Format" type="string" default="#variables.Format#">
	
	<cfset var i = 0>
	<cfset var thischar = "">
	<cfset var result = "">
	
	<!--- Loop through the format --->
	<cfloop index="i" from="1" to="#Len(arguments.Format)#" step="1">
		<!--- Get the character --->
		<cfset thisChar = Mid(arguments.Format,i,1)>
		<!--- If the character isn't numeric and isn't already in the list of good characters, add it to the list --->
		<cfif NOT isNumeric(thisChar) AND NOT ListFindNoCase(result,thisChar)>
			<cfset result = ListAppend(result,thisChar)>
		</cfif>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<cfscript>
function PhoneFormat (input, mask) {
	var curPosition = "";
	var newFormat = "";
	var i = 0;//counter
	var area = "   ";
	var numsonly = reReplace(input,"[^[:digit:]]","","all");//numbers extraced from input
	var digits = 0;//number of digits in mask
	
	//If third argument is passed in, set srea code to value of third argument
	if ( ArrayLen(arguments) gt 2 ) {
		area = arguments[3];
	}
	
	if ( Len(numsonly) GT 10 ) {
		mask = mask & "x";
	}
	
	//count number of numbers
	for (i=1; i lte len(trim(mask)); i=i+1) {
		curPosition = mid(mask,i,1);
		if ( isNumeric(curPosition) ) {
			digits = digits + 1;
		}
	}
	//prepend three numbers to mask if it has less than 10 digits (they will be ditched out later anyway)
	if ( digits lt 10 ) {
		mask = "000" & mask;
	}
	
	newFormat = " " & numsonly;//new format is numbers stripped from input prepended with a space
	
	if ( Len(newFormat) lt 10 ) {
		newFormat = " #area##trim(newFormat)#";
	}
	
	while ( Len(newFormat) LT 10 ) {
		newFormat = "0#trim(newFormat)#";
	}
	
	newFormat = " #trim(newFormat)#";
	
	//Loop through mask and replace digits with numbers from input
	for (i=1; i lte len(trim(mask)); i=i+1) {
		curPosition = mid(mask,i,1);
		if( NOT isNumeric(curPosition) ) newFormat = insert(curPosition,newFormat, i) & " ";
	}

	//If this is a 7-digit number (no area code passed or in input), start with a number
	if ( NOT Len(Trim(area)) AND Len(numsonly) lt 10 AND Len(newFormat) ) {
		while ( NOT isNumeric(Left(newFormat,1)) ) {
			if ( Len(newFormat) gt 1 ) {
				newFormat = Right(newFormat,Len(newFormat)-1);
			}  else {
				newFormat = "";
				break;
			}
		}
	}
	
	return trim(newFormat);
}
</cfscript>

</cfcomponent>