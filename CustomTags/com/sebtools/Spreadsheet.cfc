<cfcomponent>

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="POIUtility" type="any" required="yes">
	
	<cfset Variables.POIUtility = Arguments.POIUtility>
	
	<cfif ListFirst(Server.ColdFusion.ProductVersion,",") GTE 9>
		<cfset Variables.oCFSpreadsheet = CreateObject("component","cfspreadsheet")>
	</cfif>
	
	<cfreturn This>
</cffunction>

<cffunction name="readExcel" access="public" returntype="query" output="no">
	<cfargument name="src" type="string" required="yes">
	<cfargument name="CompactionDelim" type="string" default="">
	
	<cfset var result = 0>
	
	<cfif StructKeyExists(Variables,"oCFSpreadsheet")>
		<cfreturn readExcelCF(ArgumentCollection=Arguments)>
	</cfif>
	
	<cfreturn readExcelPOI(ArgumentCollection=Arguments)>
</cffunction>

<cffunction name="readExcelCF" access="public" returntype="query" output="no">
	<cfargument name="src" type="string" required="yes">
	<cfargument name="CompactionDelim" type="string" default="">
	
	<cfset var qResults = Variables.oCFSpreadsheet.read(ArgumentCollection=Arguments)>
	
	<cfreturn QueryCompact(qResults)>
</cffunction>

<cffunction name="readExcelPOI" access="public" returntype="query" output="no">
	<cfargument name="src" type="string" required="yes">
	<cfargument name="CompactionDelim" type="string" default="">
	<cfargument name="sheet" type="numeric" default="1">
	
	<cfset var result = 0>
	<cfset var aSheets = 0>
	
	<cftry>
		<cfset Arguments.HasHeaderRow = true>
		<cfset Arguments.FilePath = Arguments.src>
		<cfset aSheets = variables.POIUtility.ReadExcel(ArgumentCollection=arguments)>
	<cfcatch>
		<cfif
				StructKeyExists(CFCATCH,"Cause")
			AND StructKeyExists(CFCATCH.Cause,"Cause")
			AND StructKeyExists(CFCATCH.Cause.Cause,"Message")
			AND	CFCATCH.Cause.Cause.Message CONTAINS "Invalid header signature"
		>
			<cfthrow message="Unable to read spreadsheet. Ensure that it is saved in the Excel '97 - 2003 format in MS Excel." type="Importer" errorcode="InvalidFormat">
		<cfelse>
			<cfrethrow>
		</cfif>
	</cfcatch>
	</cftry>
	
	<cfreturn getNamedQuery(aSheets[Arguments.sheet],Arguments.CompactionDelim)>
</cffunction>

<cffunction name="writeExcel" access="public" returntype="any" output="no">
	<cfargument name="FileName" type="string" required="yes">
	<cfargument name="query" type="query" required="yes">
	
	<cfset var result = 0>
	
	<cfif StructKeyExists(Variables,"oCFSpreadsheet")>
		<cfreturn writeExcelCF(ArgumentCollection=Arguments)>
	</cfif>
	
	<cfreturn writeExcelPOI(ArgumentCollection=Arguments)>
</cffunction>

<cffunction name="writeExcelCF" access="public" returntype="any" output="no">
	<cfargument name="FileName" type="string" required="yes">
	<cfargument name="query" type="query" required="yes">
	
	<cfreturn Variables.oCFSpreadsheet.write(ArgumentCollection=Arguments)>
</cffunction>

<cffunction name="writeExcelPOI" access="private" returntype="any" output="no">
	<cfargument name="FileName" type="string" required="yes">
	<cfargument name="query" type="query" required="yes">
	
	<cfset var aSheets = ArrayNew(1)>
	
	<cfset ArrayAppend(aSheets,StructNew())>
	<cfset aSheets[1].ColumnList = Arguments.query.ColumnList>
	<cfset aSheets[1].ColumnNames = Arguments.query.ColumnList>
	<cfset aSheets[1].Query = Arguments.query>
	<cfset aSheets[1].SheetName = "sheet 1">
	
	<cfset variables.POIUtility.WriteExcel(FilePath=Arguments.FileName,Sheets=aSheets)>
	
</cffunction>

<cffunction name="getNamedQuery" access="public" returntype="query" output="false" hint="I return a query that uses the header row of the spreadsheet for the column names in the query.">
	<cfargument name="sheet" type="struct" required="true">
	<cfargument name="CompactionDelim" type="string" default="">
	
	<cfset var aColumns = arguments.sheet.ColumnNames>
	<cfset var qRawData = arguments.sheet.Query>
	<cfset var qData = QueryNew(ListCompact(ArrayToList(aColumns),arguments.CompactionDelim))>
	<cfset var NumColumns = ArrayLen(aColumns)>
	<cfset var ii = 0>
	
	<cfif ArrayLen(aColumns) AND qRawData.RecordCount>
		<cfset QueryAddRow(qData,qRawData.RecordCount)>
		
		<cfloop query="qRawData">
			<cfloop index="ii" from="1" to="#NumColumns#" step="1">
				<cfif Len(Trim(Compact(aColumns[ii],arguments.CompactionDelim)))>
					<cfset QuerySetCell(qData,Compact(aColumns[ii],arguments.CompactionDelim),qRawData["Column#ii#"][CurrentRow],CurrentRow)>
				</cfif>
			</cfloop>
		</cfloop>
	<cfelse>
		<cfset qData = qRawData> 
	</cfif>
	
	<cfreturn qData>
</cffunction>

<cffunction name="addNamedQuery" access="private" returntype="void" output="false" hint="I add a NamedQuery key to a sheet as a column with column headers coming from the header row.">
	<cfargument name="sheet" type="struct" required="true">
	<cfargument name="CompactionDelim" type="string" default="">
	
	<cfif arguments.sheet.HasheaderRow IS true AND ArrayLen(arguments.sheet.ColumnNames)>
		<cfset arguments.sheet.NamedQuery = getNamedQuery(arguments.sheet,arguments.CompactionDelim)>
	</cfif>
	
</cffunction>

<cffunction name="addNamedQueries" access="private" returntype="void" output="false" hint="I add a NamedQuery key to each sheet in the spreadsheet as a column with column headers coming from the header row.">
	<cfargument name="sheets" type="array" required="true">
	<cfargument name="CompactionDelim" type="string" default="">
	
	<cfset var ii = 0>
	
	<cfloop index="ii" from="1" to="#ArrayLen(arguments.sheets)#" step="1">
		<cfset addNamedQuery(arguments.sheets[ii],arguments.CompactionDelim)>
	</cfloop>
	
</cffunction>

<cffunction name="Compact" access="private" returntype="string" output="false">
	<cfargument name="str" type="string" required="true">
	<cfargument name="CompactionDelim" type="string" default="">
	
	<cfreturn ReReplaceNoCase(str,"[^a-z0-9]","#arguments.CompactionDelim#","ALL")>
</cffunction>

<cffunction name="ListCompact" access="private" returntype="string" output="false">
	<cfargument name="list" type="string" required="true">
	<cfargument name="CompactionDelim" type="string" default="">
	<cfargument name="delimiter" type="string" default=",">
	
	<cfset var result = "">
	<cfset var word = "">
	
	<cfloop list="#arguments.list#" delimiters="#arguments.delimiter#" index="word">
		<cfset result = ListAppend(result,Compact(word,arguments.CompactionDelim),arguments.delimiter)>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<cffunction name="ArrayCompact" access="private" returntype="array" output="false">
	<cfargument name="array" type="array" required="true">
	<cfargument name="CompactionDelim" type="string" default="">
	
	<cfset var result = "">
	<cfset var ii = "">
	
	<cfloop index="ii" from="1" to="#ArrayLen(arguments.array)#" step="1">
		<cfif isSimpleValue(arguments.array[ii])>
			<cfset arguments.array[ii] = Compact(arguments.array[ii],arguments.CompactionDelim)>
		</cfif>
	</cfloop>
	
	<cfreturn arguments.array>
</cffunction>

<cffunction name="QueryCompact" access="public" returntype="query" output="false">
	<cfargument name="query" type="query" required="true">
	<cfargument name="CompactionDelim" type="string" default="">
	
	<cfset var qResults = QueryNew(ListCompact(Arguments.query.ColumnList,Arguments.CompactionDelim))>
	<cfset var col = "">
	
	<cfset QueryAddRow(qResults,Arguments.query.RecordCount)>
	
	<cfoutput query="Arguments.query">
		<cfloop list="#ColumnList#" index="col">
			<cfset QuerySetCell(qResults,Compact(col),Arguments.query[col][CurrentRow],CurrentRow)>
		</cfloop>
	</cfoutput>
	
	<cfreturn qResults>
</cffunction>

<cffunction name="StructCompactKeys" access="private" returntype="struct" output="false">
	<cfargument name="struct" type="struct" required="true">
	<cfargument name="CompactionDelim" type="string" default="">
	
	<cfset var sResult = StructNew()>
	<cfset var key = "">
	
	<cfloop collection="#arguments.struct#" item="key">
		<cfset sResult[Compact(key,arguments.CompactionDelim)] = arguments.struct[key]>
	</cfloop>
	
	<cfset arguments.struct = sResult>
	
	<cfreturn arguments.struct>
</cffunction>

<cffunction name="QueryAddRecord" access="private" returntype="void" output="false" hint="I add a row to a query with data from a structure.">
	<cfargument name="query" type="query" required="true">
	<cfargument name="struct" type="struct" required="true">
	
	<cfset var col = "">
	
	<cfset QueryAddRow(arguments.query)>
	
	<cfloop list="#arguments.query.ColumnList#" index="col">
		<cfif StructKeyExists(arguments.struct,col) AND isSimpleValue(arguments.struct[col])>
			<cftry>
				<cfset QuerySetCell(arguments.query,col,arguments.struct[col])>
			<cfcatch>
			</cfcatch>
			</cftry>
		</cfif>
	</cfloop>
	
</cffunction>

</cfcomponent>