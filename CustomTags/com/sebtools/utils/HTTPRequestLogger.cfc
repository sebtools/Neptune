<cfcomponent output="no">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="DataMgr" type="any" required="true">
	
	<cfset Variables.DataMgr = Arguments.DataMgr>
	<cfset Variables.tablename = "logHTTPs">
	
	<cfset Variables.DataMgr.loadXML(LogTableXML(),true,true)>

	<cfreturn This>
</cffunction>

<cffunction name="logRequest" access="public" returntype="numeric" output="no">
	<cfargument name="Attribs" type="struct" required="true">
	<cfargument name="Params" type="array" required="true">
	
	<cfreturn variables.DataMgr.insertRecord(
		variables.tableName, getLoggingStruct(ArgumentCollection=Arguments)
	)>
</cffunction>

<cffunction name="runRequest">
	<cfargument name="Attribs" type="struct" required="true">
	<cfargument name="Params" type="array" required="true">
	
	<cfset var cfhttp = 0>
	<cfset var ii = 0>
	<cfset var resultkey = "CFHTTP">
	
	<cfset logRequest(ArgumentCollection=Arguments)>
	
	<cfif StructKeyExists(Arguments.Attribs,"result") AND isSimpleValue(Arguments.Attribs["result"]) AND Len(Trim(Arguments.Attribs["result"]))>
		<cfset resultkey = Arguments.Attribs["result"]>
	</cfif>
	<cfset StructDelete(Arguments.Attribs,"result")>
	
	<cfhttp attributeCollection="#Arguments.Attribs#">
		<cfif StructKeyExists(Arguments,"Params")>
			<cfloop index="ii" from="1" to="#ArrayLen(Arguments.Params)#">
				<cfhttpparam attributeCollection="#Arguments.Params[ii]#">
			</cfloop>
		</cfif>
	</cfhttp>
	
	<cfset Arguments.Attribs["result"] = resultkey>
	
	<cfreturn cfhttp>
</cffunction>

<cffunction name="getLoggingStruct" access="private">
	<cfargument name="Attribs" type="struct" required="true">
	<cfargument name="Params" type="array" required="false">
	
	<cfset var sLog = {}>
	<cfset var sRequest = {}>
	
	<cfset sRequest["cfhttpAttrs"] = Arguments.Attribs>
	<cfif StructKeyExists(Arguments,"Params") AND ArrayLen(Arguments.Params)>
		<cfset sRequest["cfhttpParams"] = Arguments.Params>
	</cfif>
	
	<cfset sLog.URL = sRequest.cfhttpAttrs.url>
	<cfset sLog.request = SerializeJSON(sRequest)>
	
	<cfif StructKeyExists(sRequest.cfhttpAttrs,'method')>
		<cfset sLog["requestMethod"] = sRequest.cfhttpAttrs.method>
	<cfelse>
		<cfset sLog["requestMethod"] = "GET">
	</cfif>
	
	<cfset sLog["isMultiPart"] = 0>
	<cfif StructKeyExists(sRequest.cfhttpAttrs,'multipart') and
		sRequest.cfhttpAttrs.multipart>
		<cfset sLog["isMultiPart"] = 1>
	</cfif>
	
	<cfreturn sLog>
</cffunction>

<cffunction name="LogTableXML" access="public" returntype="string" output="no">
	
	<cfset var result = "">
	
	<cfsavecontent variable="result"><cfoutput>
	<tables>
		<table name="logHTTPs">
			<field ColumnName="LogID" CF_DataType="CF_SQL_INTEGER" PrimaryKey="true" Increment="true" />
			<field ColumnName="URL" CF_DataType="CF_SQL_VARCHAR" Length="255" />
			<field ColumnName="Request" CF_DataType="CF_SQL_LONGVARCHAR" />
			<field ColumnName="RequestMethod" CF_DataType="CF_SQL_VARCHAR" Length="10" />
			<field ColumnName="isMultiPart" CF_DataType="CF_SQL_BIT" Default="false" />
			<field ColumnName="RequestDate" CF_DataType="CF_SQL_DATE" Special="CreationDate" />
		</table>
	</tables>
	</cfoutput></cfsavecontent>
	
	<cfreturn result>
</cffunction>

</cfcomponent>