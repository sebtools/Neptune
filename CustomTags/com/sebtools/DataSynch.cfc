<!--- 0.2 Development2 Build 4 --->
<!--- Last Updated: 2008-12-09 --->
<!--- Created by Steve Bryant 2006-09-18 --->
<cfcomponent displayname="Data Synchronizer">

<cffunction name="init" access="public" returntype="any" output="no" hint="I initialize and return this component.">
	<cfargument name="DataMgr" type="any" required="yes">
	
	<cfset variables.DataMgr = arguments.DataMgr>
	
	<!--- To hold any DataMgr receivers --->
	<cfset variables.aReceivers = ArrayNew(1)>
	
	<cfreturn this>
</cffunction>

<cffunction name="addDataMgr" access="public" returntype="void" output="no" hint="I add a DataMgr to be synchronized.">
	<cfargument name="DataMgr" type="any" required="yes">
	
	<cfset ArrayAppend(variables.aReceivers,arguments.DataMgr)>
	
</cffunction>

<cffunction name="getXml" access="public" returntype="string" output="no" hint="I get the XML for the given tables.">
	<cfargument name="tables" type="string" default="">
	<cfargument name="withdata" type="boolean" default="true">
	<cfargument name="indexes" type="boolean" default="false">
	<cfargument name="regex" type="string" required="no">
	<cfargument name="relatedata" type="boolean" default="true">
	
	<cfset var TableData = variables.DataMgr.getTableData()>
	<cfset var i = 0>
	<cfset var jj = 0>
	<cfset var table = "">
	<cfset var column = 0>
	<cfset var qRecords = 0>
	<cfset var col = "">
	<cfset var fdata = StructNew()>
	<cfset var fcol = StructNew()>
	<cfset var fromtablelist = "">
	<cfset var sortedtablelist = "">
	<cfset var sDependencies = StructNew()>
	
	<!--- If no tables are indicated, get them all. --->
	<cfif NOT Len(arguments.tables)>
		<cfset arguments.tables = StructKeyList(TableData)>
		<cfif NOT Len(arguments.tables)>
			<cfset arguments.tables = variables.DataMgr.getDatabaseTables()>
		</cfif>
	</cfif>
	
	<cfif StructKeyExists(arguments,"regex")>
		<cfset arguments.tables = filterTables(arguments.tables,arguments.regex)>
	</cfif>
	
	<!--- Make sure all requested tables are loaded in DataMgr --->
	<cfloop index="table" list="#arguments.tables#">
		<cfif NOT StructKeyExists(TableData,table)>
			<cfset variables.DataMgr.loadTable(table)>
			<cfset TableData = variables.DataMgr.getTableData()>
		</cfif>
	</cfloop>
	
	<!--- Look for foreign keys --->
	<cfloop index="table" list="#arguments.tables#">
		<cfset sDependencies[table] = "">
		<cfif arguments.relatedata>
			<cfloop index="i" from="1" to="#ArrayLen(TableData[table])#" step="1"><cfset column = TableData[table][i]>
				<cfif StructKeyExists(column,"CF_DataType")><cfset col = column.ColumnName>
					<cfset rtable = getRelatedTable(arguments.tables,table,column)>
					<cfif Len(rtable)>
						<cfset TableData[table][i]["rtable"] = rtable>
						<!--- Make sure rtable is in depencies list --->
						<cfif NOT ListFindNoCase(sDependencies[table],rtable)>
							<cfset sDependencies[table] = ListAppend(sDependencies[table],rtable)>
						</cfif>
					</cfif>
				</cfif>
			</cfloop>
		</cfif>
	</cfloop>
	
	<cfscript>
	fromtablelist = arguments.tables;
	//Resort table list based on dependencies
	while ( jj LTE ( ListLen(arguments.tables) * ListLen(arguments.tables) ) AND ( ListLen(sortedtablelist) LT ListLen(arguments.tables) ) ) {
		jj = jj + 1;
		for (i=1; i LTE ListLen(arguments.tables); i=i+1) {
			table = ListGetAt(arguments.tables,i);
			if ( Len(sDependencies[table]) EQ 0 OR isListInList(sDependencies[table],sortedtablelist) ) {
				if ( NOT ListFindNoCase(sortedtablelist,table) ) {
					sortedtablelist = ListAppend(sortedtablelist,table);
				}
				if ( ListFindNoCase(fromtablelist,table) ) {
					fromtablelist = ListDeleteAt(fromtablelist,ListFindNoCase(fromtablelist,table));
				}
			}
		}
	}
	arguments.tables = sortedtablelist;
	</cfscript>
	
	<cfif jj GT 1 AND jj GTE ( ListLen(arguments.tables) * ListLen(arguments.tables) )>
		<cfthrow message="DataSynch encountered a bidirectional dependency that it was unable to resolve: Each of two tables were both dependent on each other (#fromtablelist#)." type="DataSynch" errorcode="CrossDependency">
	</cfif>
	
<cfsavecontent variable="result"><cfoutput><?xml version="1.0" encoding="utf-8"?>
<tables>
<cfloop index="table" list="#arguments.tables#">
	<!--- Verifying the table exists (shouldn't really be needed since we made sure to check for it above --->
	<cfif StructKeyExists(TableData,table)>
		<!--- Create the table --->
		#variables.DataMgr.getXml(tablename=table,indexes=arguments.indexes,showroot=false)#
	</cfif>
</cfloop>
<cfloop index="table" list="#arguments.tables#">
	<!--- Verifying the table exists (shouldn't really be needed since we made sure to check for it above --->
	<cfif StructKeyExists(TableData,table)>
		<!--- Now let's get all of the data (assuming we are asked to do so) --->
		<cfif arguments.withdata>
			<cfset qRecords = variables.DataMgr.getRecords(table)>
			<cfif qRecords.RecordCount>
				<data table="#table#" permanentRows="true"><!--- permanentRows tells DataMgr to insert the record even if the table already exists --->
					<!--- Output each row of data --->
					<cfloop query="qRecords">
						<row>
							<!--- Output each column --->
							<cfloop index="i" from="1" to="#ArrayLen(TableData[table])#" step="1"><cfset column = TableData[table][i]>
								<!--- Only output a column if it has a datatype (all column should, but one never knows what the future holds... --->
								<cfif StructKeyExists(column,"CF_DataType")><cfset col = column.ColumnName>
									<!--- If we show a related table, put in reference to that instead of value --->
									<cfif StructKeyExists(column,"rtable")>
										<!--- Get the data for the related record --->
										<cfset fdata = getRelatedData(column["rtable"],column,qRecords[col][CurrentRow])>
										<cfif StructCount(fdata)>
											<field name="#col#" reltable="#column.rtable#">
												<cfloop collection="#fdata#" item="fcol">
													<relfield name="#fcol#" value="#XmlFormat(fdata[fcol])#" />
												</cfloop>
											</field>
										</cfif>
									<cfelse>
										<field name="#col#" value="#XmlCleanString(qRecords[col][CurrentRow])#" />
									</cfif>
								</cfif>
							</cfloop>
						</row>
					</cfloop>
				</data>
			</cfif>
		</cfif>
	</cfif>
</cfloop>
</tables>
</cfoutput></cfsavecontent>

	<!--- <cfreturn XmlHumanReadable(result)> --->
	<cfreturn result>
</cffunction>

<cffunction name="XmlCleanString" access="public" returntype="string" output="no" hint="I return a clean version (stripped of MS-Word characters) of the given structure.">
	<cfargument name="string" type="string" required="yes">
	
	<cfscript>
	// Replace the special characters that Microsoft uses.
	arguments.string = Replace(arguments.string, Chr(8216), Chr(39), "ALL");// apostrophe / single-quote
	arguments.string = Replace(arguments.string, Chr(8217), Chr(39), "ALL");// apostrophe / single-quote
	arguments.string = Replace(arguments.string, Chr(8220), Chr(34), "ALL");// quotes
	arguments.string = Replace(arguments.string, Chr(8221), Chr(34), "ALL");// quotes
	arguments.string = Replace(arguments.string, Chr(8211), "-", "ALL");// dashes
	arguments.string = Replace(arguments.string, Chr(8212), "-", "ALL");// dashes
	arguments.string = Replace(arguments.string, Chr(8213), "-", "ALL");// dashes
	arguments.string = Replace(arguments.string, Chr(8230), "...", "ALL");
	arguments.string = Replace(arguments.string, "“", Chr(34), "ALL");
	arguments.string = Replace(arguments.string, "”", Chr(34), "ALL");
	
	arguments.string = XmlFormat(arguments.string);
	//arguments.string = CreateObject('java', 'org.apache.commons.lang.StringEscapeUtils').escapeXml(arguments.string); 
	</cfscript>
	
	<cfreturn arguments.string>
</cffunction>

<cffunction name="synchTables" access="public" returntype="void" output="no" hint="I synchronize the given tables.">
	<cfargument name="tables" type="string" default="">
	<cfargument name="withdata" type="boolean" default="true">
	<cfargument name="regex" type="string" required="no">
	
	<cfset var i = 0>
	<cfset var dbxml = getXml(argumentcollection=arguments)>
	
	<cfloop index="i" from="1" to="#ArrayLen(variables.aReceivers)#" step="1">
		<cfset variables.aReceivers[i].loadXml(dbxml,true,true)>
	</cfloop>
	
</cffunction>

<cffunction name="synchXML" access="public" returntype="void" output="no" hint="I synchronize the given XML structure/data.">
	<cfargument name="dbxml" type="string" required="yes">
	
	<cfset var i = 0>
	
	<cfloop index="i" from="1" to="#ArrayLen(variables.aReceivers)#" step="1">
		<cfset variables.aReceivers[i].loadXml(dbxml,true,true)>
	</cfloop>
	
</cffunction>


<cffunction name="filterTables" access="public" returntype="string" output="false" hint="">
	<cfargument name="tables" type="string" required="yes">
	<cfargument name="regex" type="string" required="yes">
	
	<cfset var result = "">
	<cfset var table = "">
	
	<cfloop list="#arguments.tables#" index="table">
		<cfif ReFindNoCase(arguments.regex,table)>
			<cfset result = ListAppend(result,table)>
		</cfif>
	</cfloop>
	
	<cfreturn result>
</cffunction>


<cffunction name="getRelatedTable" access="private" returntype="string" output="no">
	<cfargument name="tables" type="string" default="">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="Field" type="struct" required="yes">
	
	<cfset var result = "">
	<cfset var TableData = variables.DataMgr.getTableData()>
	<cfset var table = "">
	<cfset var pkfields = 0>
	
	<cfif NOT Len(arguments.tables)>
		<cfset arguments.tables = StructKeyList(TableData)>
	</cfif>
	
	<!--- Make sure the fields is a real field (has a datatype) --->
	<cfif StructKeyExists(Field,"CF_DataType")>
		<!--- Look through all tables for a matching primary key --->
		<cfloop index="table" list="#arguments.tables#">
			<!--- Only look at loaded tables that aren't the one our field is in. --->
			<cfif StructKeyExists(TableData,table) AND table NEQ arguments.tablename>
				<cfset pkfields = variables.DataMgr.getPKFields(table)>
				<!--- Only look at tables with simple primary keys --->
				<cfif ArrayLen(pkfields) eq 1>
					<!--- If the column name matches, this is our table --->
					<cfif pkfields[1].ColumnName eq Field["ColumnName"]>
						<cfset result = table>
						<cfbreak>
					</cfif>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getRelatedData" access="private" returntype="struct" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="field" type="struct" required="yes">
	<cfargument name="value" type="string" required="yes">
	
	<cfset var data = StructNew()>
	<cfset var colname = Field["ColumnName"]>
	<cfset var table = arguments.tablename>
	<cfset var result = StructNew()>
	
	<!--- Make sure variables["RelatedData"] exists --->
	<cfif NOT StructKeyExists(variables,"RelatedData")>
		<cfset variables["RelatedData"] = StructNew()>
	</cfif>
	
	<!--- Make sure variables["RelatedData"] has a key for this table --->
	<cfif NOT StructKeyExists(variables["RelatedData"],table)>
		<cfset variables["RelatedData"][table] = StructNew()>
	</cfif>
	
	<!--- Get the structure --->
	<cfif StructKeyExists(variables["RelatedData"][table],arguments.value)>
		<!--- If the data has already been retrieved for this key use it --->
		<cfset result = variables["RelatedData"][table][arguments.value]>
	<cfelse>
		<!--- Get the record and load up he struct --->
		<cfset data[colname] = arguments.value>
		<cftry>
			<cfset qRecord = variables.DataMgr.getRecord(tablename=table,data=data,fieldlist=getFieldList(table))>
			<!--- Convert the record to a struct --->
			<cfset result = QueryToStruct(qRecord)>
			<!--- The struct shouldn't include the primary key field (defeats the purpose of by reference) --->
			<cfset StructDelete(result,colname)>
			<cfset variables["RelatedData"][table][arguments.value] = result>
		<cfcatch>
		</cfcatch>
		</cftry>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getFieldList" access="private" returntype="string" output="no" hint="I get the list of primary key fields.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfset var aFields = variables.DataMgr.getUpdateableFields(arguments.tablename)>
	<cfset var result = "">
	<cfset var i = 0>
	
	<cfloop index="i" from="1" to="#ArrayLen(aFields)#" step="1">
		<cfset result = ListAppend(result,aFields[i].ColumnName)>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<cffunction name="QueryToStruct" access="private" returntype="struct" output="no" hint="I convert a row of a query to a struct.">
	<cfargument name="query" type="query" required="yes">
	<cfargument name="rownum" type="numeric" default="1">
	
	<cfset var result = StructNew()>
	
	<cfloop index="col" list="#query.ColumnList#">
		<cfset result[col] = query[col][rownum]>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<cfscript>
/**
 * Checks is all elements of a list X is found in a list Y.
 * v2 by Raymond Camden
 * v3 idea by Bill King
 * 
 * @param l1 	 The first list. (Required)
 * @param l2 	 The second list. UDF checks to see if all of l1 is in l2. (Required)
 * @param delim1 	 List delimiter for l1. Defaults to a comma. (Optional)
 * @param delim2 	 List delimiter for l2. Defaults to a comma. (Optional)
 * @param matchany 	 If true, UDF returns true if at least one item in l1 exists in l2. Defaults to false. (Optional)
 * @return Returns a boolean. 
 * @author Daniel Chicayban (daniel@chicayban.com.br) 
 * @version 3, August 28, 2003 
 */
function isListInList(l1,l2) {
	var delim1 = ",";
	var delim2 = ",";
	var i = 1;
	var matchany = false;
	
	if(arrayLen(arguments) gte 3) delim1 = arguments[3];
	if(arrayLen(arguments) gte 4) delim2 = arguments[4];
	if(arrayLen(arguments) gte 5) matchany = arguments[5];
	
	for(i=1; i lte listLen(l1,delim1); i=i+1) {
		if(matchany and listFind(l2,listGetAt(l1,i,delim1),delim2)) return true;
		if(not matchany and not listFind(l2,listGetAt(l1,i,delim1),delim2)) return false;
	}
	return true;
}
</cfscript>

<cfscript>
/**
 * Formats an XML document for readability.
 * update by Fabio Serra to CR code
 * 
 * @param XmlDoc 	 XML document. (Required)
 * @return Returns a string. 
 * @author Steve Bryant (steve@bryantwebconsulting.com) 
 * @version 2, March 20, 2006 
 */
function XmlHumanReadable(XmlDoc) {
	var elem = "";
	var result = "";
	var tab = "	";
	var att = "";
	var i = 0;
	var temp = "";
	var cr = createObject("java","java.lang.System").getProperty("line.separator");
	
	if ( isXmlDoc(XmlDoc) ) {
		elem = XmlDoc.XmlRoot;//If this is an XML Document, use the root element
	} else if ( IsXmlElem(XmlDoc) ) {
		elem = XmlDoc;//If this is an XML Document, use it as-as
	} else if ( NOT isXmlDoc(XmlDoc) ) {
		XmlDoc = XmlParse(XmlDoc);//Otherwise, try to parse it as an XML string
		elem = XmlDoc.XmlRoot;//Then use the root of the resulting document
	}
	//Now we are just working with an XML element
	result = "<#elem.XmlName#";//start with the element name
	if ( StructKeyExists(elem,"XmlAttributes") ) {//Add any attributes
		for ( att in elem.XmlAttributes ) {
			result = '#result# #att#="#XmlFormat(elem.XmlAttributes[att])#"';
		}
	}
	if ( Len(elem.XmlText) OR (StructKeyExists(elem,"XmlChildren") AND ArrayLen(elem.XmlChildren)) ) {
		result = "#result#>#cr#";//Add a carriage return for text/nested elements
		if ( Len(Trim(elem.XmlText)) ) {//Add any text in this element
			result = "#result##tab##XmlFormat(Trim(elem.XmlText))##cr#";
		}
		if ( StructKeyExists(elem,"XmlChildren") AND ArrayLen(elem.XmlChildren) ) {
			for ( i=1; i lte ArrayLen(elem.XmlChildren); i=i+1 ) {
				temp = Trim(XmlHumanReadable(elem.XmlChildren[i]));
				temp = "#tab##ReplaceNoCase(trim(temp), cr, "#cr##tab#", "ALL")#";//indent
				result = "#result##temp##cr#";
			}//Add each nested-element (indented) by using recursive call
		}
		result = "#result#</#elem.XmlName#>";//Close element
	} else {
		result = "#result# />";//self-close if the element doesn't contain anything
	}
	
	return result;
}
</cfscript>

</cfcomponent>