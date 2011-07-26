<!--- 1.0 Alpha 1 (Build 3) --->
<!--- Last Updated: 2010-10-11 --->
<!--- Created by Steve Bryant 2009-07-14 --->
<cfcomponent displayname="Records" extends="mxunit.framework.TestCase">

<cffunction name="setUp" access="public" returntype="void" output="no">
	
	<cfscript>
	var key = "";
	
	for (key in arguments) {
		variables[key] = arguments[key];
	}
	</cfscript>
	
</cffunction>

<cffunction name="assertRecent" access="public" returntype="void" output="no" hint="I assert that email can be tested using isEmailTestable().">
	<cfargument name="date" type="date" required="true">
	<cfargument name="message" type="string" default="">
	<cfargument name="range" type="numeric" default="3">
	<cfargument name="interval" type="string" default="n">
	
	<cfset assert("#arguments.date# GTE #getRecentDateTime(range=arguments.range,interval=arguments.interval)#",arguments.message)>
	
</cffunction>

<cffunction name="assertEmailTestable" access="public" returntype="void" output="no" hint="I assert that email can be tested using isEmailTestable().">
	<cfif NOT isEmailTestable()>
		<cfset fail("Email is not currently testable")>
	</cfif>
</cffunction>

<cffunction name="assertEmailSent" access="public" returntype="void" output="no" hint="I assert than an email has been sent. Arguments will match the keys of the email.">
	<cfargument name="when" type="date" default="#now()#">
	
	<cfset var message = "Email was not sent">
	
	<cfset assertEmailTestable()>
	
	<cfif NOT isEmailSent(argumentCollection=arguments)>
		<cfset fail(message)>
	</cfif>
	
</cffunction>

<cffunction name="assertEmailNotSent" access="public" returntype="void" output="no">
	<cfargument name="when" type="date" default="#now()#">
	
	<cfset var message = "Email was sent">
	
	<cfif isEmailSent(argumentCollection=arguments)>
		<cfset fail(message)>
	</cfif>
	
</cffunction>

<cffunction name="assertNoticeSent" access="public" returntype="void" output="no">
	<cfargument name="notice" type="string" required="true">
	<cfargument name="to" type="string" required="false">
	<cfargument name="when" type="date" default="#now()#">
	
	<cfset var message = "Notice (#arguments.notice#) was not sent">
	
	<cfif StructKeyExists(arguments,"to")>
		<cfset message = "#message# to #arguments.to#">
	</cfif>
	<cfset message = "#message#.">
	
	<cfif NOT isNoticeSent(argumentCollection=arguments)>
		<cfset fail(message)>
	</cfif>
	
</cffunction>

<cffunction name="assertNoticeNotSent" access="public" returntype="void" output="no">
	<cfargument name="notice" type="string" required="true">
	<cfargument name="to" type="string" required="false">
	<cfargument name="when" type="date" default="#now()#">
	
	<cfset var message = "Notice (#arguments.notice#) was sent">
	
	<cfif StructKeyExists(arguments,"to")>
		<cfset message = "#message# to #arguments.to#">
	</cfif>
	<cfset message = "#message#.">
	
	<cfif isNoticeSent(argumentCollection=arguments)>
		<cfset fail(message)>
	</cfif>
	
</cffunction>

<cffunction name="getRandomData" access="public" returntype="struct" output="no">
	<cfargument name="comp" type="any" required="yes">
	<cfargument name="data" type="struct" required="no">
	
	<cfset var aFields = arguments.comp.getFieldsArray()>
	<cfset var sResult = StructNew()>
	<cfset var ii = 0>
	<cfset var sArgs = StructCopy(arguments)>
	<cfset var skiptypes = "DeletionMark,Sorter,DeletionDate,UUID">

	<!--- Create test data --->
	<cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
		<cfif
				StructKeyExists(aFields[ii],"datatype")
			AND	ListFirst(aFields[ii].type,":") NEQ "pk"
			AND	ListFirst(aFields[ii].type,":") NEQ "fk"
			AND	ListFirst(aFields[ii].type,":") NEQ "fk"
			AND	NOT ListFindNoCase(skiptypes,aFields[ii].type)
			AND	NOT ( StructKeyExists(aFields[ii],"Special") AND ListFindNoCase(skiptypes,aFields[ii].Special) )
			AND	NOT ( StructKeyExists(aFields[ii],"test") AND aFields[ii].test IS false )
		>
			<cfset sResult[aFields[ii]["name"]] = getRandomFieldValue(aFields[ii])>
		</cfif>
	</cfloop>
	
	<cfif StructKeyExists(arguments,"data")>
		<cfset StructAppend(sResult,arguments.data,"yes")>
	</cfif>
	
	<!--- Ability to pass in named arguments directly without loading into data struct --->
	<cfset StructDelete(sArgs,"comp")>
	<cfset StructDelete(sArgs,"data")>
	<cfif StructCount(sArgs)>
		<cfset StructAppend(sResult,sArgs,"yes")>
	</cfif>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="getRandomFieldValue" access="public" returntype="string" output="no">
	<cfargument name="field" type="any" required="yes">
	
	<cfset var sField = arguments.field>
	<cfset var result = getRandomValue(sField.datatype)>
	<cfset var length = 0>
	<cfset var email_suffix = "@example.com">
	
	<cfif StructKeyExists(sField,"Length")>
		<cfset length = sField.Length>
		<cfif StructKeyExists(sField,"type") AND sField.type EQ "email">
			<cfset length = length - Len(email_suffix)>
		</cfif>
		<cfif Len(result) GT length>
			<cfset result = Left(result,length)>
		</cfif>
	</cfif>
	
	<cfif StructKeyExists(sField,"type") AND sField.type EQ "email">
		<cfset result = "#result##email_suffix#">
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getRandomValue" access="public" returntype="string" output="no">
	<cfargument name="datatype" type="string" required="yes">
	
	<cfset var result = "">
	
	<cfswitch expression="#arguments.datatype#">
	<cfcase value="boolean">
		<cfset result = RandRange(0,1)>
	</cfcase>
	<cfcase value="date">
		<cfset result = DateFormat(DateAdd("d",RandRange(30,1095),now()),"yyyy-mm-dd")>
	</cfcase>
	<cfcase value="integer,number">
		<cfset result = RandRange(1,100)>
	</cfcase>
	<cfcase value="text">
		<cfset result = "Test#RandRange(1,10000)#">
	</cfcase>
	<cfcase value="email">
		<cfset result = "Test#RandRange(1,10000)#@example.com">
	</cfcase>
	</cfswitch>
	
	<cfreturn result>
</cffunction>

<cffunction name="isEmailTestable" access="public" returntype="boolean" output="no">
	
	<cfset var result = false>
	<cfset var oMailer = 0>
	
	<cfif StructKeyExists(variables,"NoticeMgr")>
		<cfset oMailer = variables.NoticeMgr.getMailer()>
		<cfif oMailer.getIsLogging()>
			<cfset result = true>
		</cfif>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="isEmailSent" access="public" returntype="boolean" output="no">
	<cfargument name="when" type="date" default="#now()#">
	
	<cfset var result = false>
	
	<cfif NumEmailsSent(argumentCollection=arguments)>
		<cfset result = true>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="isNoticeSent" access="public" returntype="boolean" output="no">
	<cfargument name="notice" type="string" required="true">
	<cfargument name="to" type="string" required="false">
	<cfargument name="when" type="date" default="#now()#">
	
	<cfreturn isEmailSent(argumentCollection=arguments)>
</cffunction>

<cffunction name="getRecentDateTime" access="public" returntype="date" output="no">
	<cfargument name="date" type="date" default="#now()#">
	<cfargument name="range" type="numeric" default="3">
	<cfargument name="interval" type="string" default="n">
	
	<cfreturn DateAdd(arguments.interval,-Abs(arguments.range),arguments.date)>
</cffunction>

<cffunction name="NumEmailsSent" access="public" returntype="boolean" output="no">
	<cfargument name="when" type="date" default="#now()#">
	
	<cfset var result = 0>
	<cfset var aFilters = ArrayNew(1)>
	<cfset var sFilter = StructNew()>
	<cfset var qSentMessages = 0>
	<cfset var oDataMgr = 0>
	
	<cfset assertEmailTestable()>
	
	<cfset oDataMgr = variables.NoticeMgr.getDataMgr()>
	
	<cfset sFilter["field"] = "DateSent">
	<cfset sFilter["operator"] = ">=">
	<cfset sFilter["value"] = DateAdd("n",-3,arguments.when)>
	
	<cfset ArrayAppend(aFilters,sFilter)>
	
	<cfset qSentMessages = oDataMgr.getRecords(tablename=variables.NoticeMgr.getMailer().getLogTable(),data=arguments,filters=aFilters,fieldlist="LogID")>
	
	<cfset result = qSentMessages.RecordCount>
	
	<cfreturn result>
</cffunction>

<cffunction name="loadExternalVars" access="public" returntype="void" output="no">
	<cfargument name="varlist" type="string" required="true">
	<cfargument name="scope" type="string" default="Application">
	<cfargument name="skipmissing" type="boolean" default="false">
	
	<cfset var varname = "">
	<cfset var scopestruct = StructGet(arguments.scope)>
	
	<cfloop index="varname" list="#arguments.varlist#">
		<cfif StructKeyExists(scopestruct,varname)>
			<cfset variables[varname] = scopestruct[varname]>
		<cfelseif NOT arguments.skipmissing>
			<cfthrow message="#scope#.#varname# is not defined.">
		</cfif>
	</cfloop>
	
</cffunction>

<cffunction name="runInRollbackTransaction" access="public" returntype="any" output="no">
	<cfargument name="method" type="any" required="yes">
	<cfargument name="comp" type="any" required="no">
	<cfargument name="args" type="struct" default="#StructNew()#">
	
	<cfset var result = 0>
	<cfset var fMethod = 0>
	
	<cfif StructKeyExists(arguments,"comp") AND isSimpleValue(arguments.method)>
		<cfset fMethod = arguments.com[arguments.method]>
	<cfelseif isCustomFunction(arguments.method)>
		<cfset fMethod = arguments.method>
	<cfelse>
		<cfthrow message="Method must be either the name of a method in a component or the method itself.">
	</cfif>
	
	<cftransaction>
		<cftry>
			<cfset result = fMethod(argumentCollection=arguments.args)>
		<cfcatch type="any">
			<cftransaction action="rollback">
			<cfrethrow>
		</cfcatch>
		</cftry>
		
		<cftransaction action="rollback">
	</cftransaction>
	
	<cfif isDefined("result")>
		<cfreturn result>
	</cfif>
</cffunction>

<cffunction name="getTestRecord" access="public" returntype="query" output="no">
	<cfargument name="comp" type="any" required="yes">
	<cfargument name="data" type="struct" required="no">
	
	<cfset var sCompMeta = arguments.comp.getMetaStruct()>
	<cfset var id = saveTestRecord(argumentCollection=arguments)>
	<cfset var qRecord = 0>
	
	<cfinvoke
		returnvariable="qRecord"
		component="#arguments.comp#"
		method="#sCompMeta.method_get#"
	>
		<cfinvokeargument name="#sCompMeta.arg_pk#" value="#id#">
	</cfinvoke>
	
	<cfreturn qRecord>
</cffunction>

<cffunction name="saveTestRecord" access="public" returntype="string" output="no">
	<cfargument name="comp" type="any" required="yes">
	<cfargument name="data" type="struct" required="no">
	
	<cfset var sCompMeta = arguments.comp.getMetaStruct()>
	<cfset var sData = getRandomData(argumentCollection=arguments)>
	<cfset var result = 0>
	
	<cfinvoke
		returnvariable="result"
		component="#arguments.comp#"
		method="#sCompMeta.method_save#"
		argumentCollection="#sData#"
	>
	</cfinvoke>
	
	<cfreturn result>
</cffunction>

<cffunction name="QueryGetRandomRow" access="public" returntype="query" output="no">
	<cfargument name="query" type="any" required="yes">
	
	<cfset var cols = arguments.query.ColumnList>
	<cfset var qResult = QueryNew(cols)>
	<cfset var rownum = 0>
	<cfset var col = "">
	
	<cfif arguments.query.RecordCount>
		<cfset rownum = RandRange(1,arguments.query.RecordCount)>
		<cfset QueryAddRow(qResult)>
		<cfloop list="#cols#" index="col">
			<cfset QuerySetCell(qResult,col,arguments.query[col][rownum])>
		</cfloop>
	</cfif> 
	
	<cfreturn qResult>
</cffunction>

<cfscript>
function QueryFromArgs() {
	return Struct2Query(arguments);
}
/**
 * Makes a row of a query into a structure.
 * 
 * @param query 	 The query to work with. 
 * @param row 	 Row number to check. Defaults to row 1. 
 * @return Returns a structure. 
 * @author Nathan Dintenfass (nathan@changemedia.com) 
 * @version 1, December 11, 2001 
 */
function QueryRowToStruct(query){
	var row = 1;//by default, do this to the first row of the query
	var ii = 1;//a var for looping
	var cols = listToArray(query.columnList);//the cols to loop over
	var stReturn = structnew();//the struct to return
	
	if(arrayLen(arguments) GT 1) row = arguments[2];//if there is a second argument, use that for the row number
	
	//loop over the cols and build the struct from the query row
	for(ii = 1; ii lte arraylen(cols); ii = ii + 1){
		stReturn[cols[ii]] = query[cols[ii]][row];
	}		
	
	return stReturn;//return the struct
}
//By Charlie Griefer
function Struct2Query(struct) {
	var key = "";
	var qResult = 0;
	
	if (NOT isStruct(arguments.struct)) return false;
	
	qResult = QueryNew(StructKeyList(arguments.struct));
	QueryAddRow(qResult, 1);
	for (key in arguments.struct) {
		QuerySetCell(qResult, key, arguments.struct[key]);
	}
	
	return qResult;
}
/**
* Accepts a specifically formatted chunk of text, and returns it as a query object.
* v2 rewrite by Jamie Jackson
*
* @param queryData      Specifically format chunk of text to convert to a query. (Required)
* @return Returns a query object.
* @author Bert Dawson (bert@redbanner.com)
* @version 2, December 18, 2007
*/
function QuerySim(queryData) {
	var fieldsDelimiter="|";
	var colnamesDelimiter=",";
	var listOfColumns="";
	var tmpQuery="";
	var numLines="";
	var cellValue="";
	var cellValues="";
	var colName="";
	var lineDelimiter=chr(10) & chr(13);
	var lineNum=0;
	var colPosition=0;
	
	// the first line is the column list, eg "column1,column2,column3"
	listOfColumns = Trim(ListGetAt(queryData, 1, lineDelimiter));
	
	// create a temporary Query
	tmpQuery = QueryNew(listOfColumns);
	
	// the number of lines in the queryData
	numLines = ListLen(queryData, lineDelimiter);
	
	// loop though the queryData starting at the second line
	for(lineNum=2; lineNum LTE numLines; lineNum = lineNum + 1) {
		cellValues = ListGetAt(queryData, lineNum, lineDelimiter);
		
		if (ListLen(cellValues, fieldsDelimiter) IS ListLen(listOfColumns,",")) {
			QueryAddRow(tmpQuery);
			for (colPosition=1; colPosition LTE ListLen(listOfColumns); colPosition = colPosition + 1){
				cellValue = Trim(ListGetAt(cellValues, colPosition, fieldsDelimiter));
				colName = Trim(ListGetAt(listOfColumns,colPosition));
				QuerySetCell(tmpQuery, colName, cellValue);
			}
		}
	}
	
	return( tmpQuery );
}
</cfscript>
<cffunction name="StructFromArgs" access="public" returntype="struct" output="false" hint="">
	
	<cfset var sTemp = 0>
	<cfset var sResult = StructNew()>
	<cfset var key = "">
	
	<cfif ArrayLen(arguments) EQ 1 AND isStruct(arguments[1])>
		<cfset sTemp = arguments[1]>
	<cfelse>
		<cfset sTemp = arguments>
	</cfif>
	
	<!--- set all arguments into the return struct --->
	<cfloop collection="#sTemp#" item="key">
		<cfif StructKeyExists(sTemp, key)>
			<cfset sResult[key] = sTemp[key]>
		</cfif>
	</cfloop>
	
	<cfreturn sResult>
</cffunction>

</cfcomponent>