<cfcomponent output="no">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="DataMgr" type="any" required="yes">
	
	<cfset Variables.DataMgr = Arguments.DataMgr>
	<cfset Variables.DataMgr.loadXml(getDbXml(),true,true)>
	
	<cfset loadPastDeployments()>
	
	<cfreturn This>
</cffunction>

<cffunction name="loadPastDeployments" access="public" returntype="any" output="no">
	
	<cfset var qDeployments = 0>
	
	<cfif NOT StructKeyExists(Variables,"sPastDeployments")>
		<cfset Variables.sPastDeployments = StructNew()>
		
		<cfset qDeployments = Variables.DataMgr.getRecords(tablename="utilDeployments",fieldlist="ComponentPath,Name,DateRun")>
		
		<cfoutput query="qDeployments">
			<cfset Variables.sPastDeployments[getDeploymentStructKey(Name=Name,ComponentPath=ComponentPath)] = DateRun>
		</cfoutput>
	</cfif>
	
</cffunction>

<cffunction name="deploy" access="public" returntype="any" output="no">
	<cfargument name="Name" type="string" required="yes">
	<cfargument name="ComponentPath" type="string" required="yes">
	<cfargument name="Component" type="any" required="yes">
	<cfargument name="MethodName" type="string" required="yes">
	<cfargument name="Args" type="struct" required="no">
	
	<cfset var TimeMarkBegin = 0>
	<cfset var TimeMarkEnd = 0>
	
	<cfif NOT isDeployed(ArgumentCollection=Arguments)>
		<cftry>
			<cfset TimeMarkBegin = getTickCount()>
			<cfinvoke component="#Arguments.Component#" method="#MethodName#">
				<cfif StructKeyExists(Arguments,"Args")>
					<cfinvokeargument name="ArgumentCollection" value="#Arguments.Args#">
				</cfif>
			</cfinvoke>
			<cfset TimeMarkEnd = getTickCount()>
			<cfset Arguments.Seconds = GetSecondsDiff(TimeMarkBegin,TimeMarkEnd)>
			<cfset recordDeployment(ArgumentCollection=Arguments)>
		<cfcatch>
			<cfrethrow>
		</cfcatch>
		</cftry>
	</cfif>
	
	<cfreturn This>
</cffunction>

<cffunction name="isDeployed" access="public" returntype="boolean" output="no">
	<cfargument name="Name" type="string" required="yes">
	<cfargument name="ComponentPath" type="string" required="yes">
	
	<cfset var sTasks = StructNew()>
	<cfset var result = false>
	
	<cfset sTasks["Name"] = Arguments.Name>
	<cfset sTasks["ComponentPath"] = Arguments.ComponentPath>
	
	<cfset sTasks = Variables.DataMgr.truncate(tablename="utilDeployments",data=sTasks)>
	
	<!--- Look for the run in the local structure --->
	<cfset result = StructKeyExists(Variables.sPastDeployments,getDeploymentStructKey(ArgumentCollection=Arguments))>
	
	<!--- If not found in the local structure, double-check the database --->
	<cfif NOT result>
		<cfset result = Variables.DataMgr.hasRecords(tablename="utilDeployments",data=sTasks)>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="GetSecondsDiff" access="private" returntype="numeric" output="no">
	<cfargument name="begin" type="numeric" required="yes">
	<cfargument name="end" type="numeric" required="yes">
	
	<cfset var result = 0>
	
	<cfif Arguments.end GTE Arguments.begin>
		<cfset result = Int( ( Arguments.end - Arguments.begin ) / 1000 )>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="recordDeployment" access="public" returntype="void" output="no">
	
	<cfset Variables.DataMgr.insertRecord(tablename="utilDeployments",data=Arguments,truncate=true)>
	<cfset Variables.sPastDeployments[getDeploymentStructKey(ArgumentCollection=Arguments)] = now()>
	
</cffunction>

<cffunction name="getDeploymentStructKey" access="private" returntype="string" output="no">
	<cfargument name="Name" type="string" required="true">
	<cfargument name="ComponentPath" type="string" required="true">
	
	<cfset var sArgs = Variables.DataMgr.truncate(tablename="utilDeployments",data=Arguments)>
	
	<cfreturn "#sArgs.Name#:::#sArgs.ComponentPath#">
</cffunction>

<cffunction name="getDbXml" access="private" returntype="string" output="no" hint="I return the XML for the tables needed for Deployer to work.">
	
	<cfset var result = "">
	
	<cfsavecontent variable="result">
	<tables>
		<table name="utilDeployments">
			<field ColumnName="DeploymentID" CF_DataType="CF_SQL_INTEGER" PrimaryKey="true" Increment="true" />
			<field ColumnName="Name" CF_DataType="CF_SQL_VARCHAR" Length="50" />
			<field ColumnName="ComponentPath" CF_DataType="CF_SQL_VARCHAR" Length="50" />
			<field ColumnName="MethodName" CF_DataType="CF_SQL_VARCHAR" Length="50" />
			<field ColumnName="DateRun" CF_DataType="CF_SQL_DATE" Special="CreationDate" />
			<field ColumnName="ErrorMessage" CF_DataType="CF_SQL_VARCHAR" Length="250" />
			<field ColumnName="ErrorDetail" CF_DataType="CF_SQL_VARCHAR" Length="250" />
			<field ColumnName="Success" CF_DataType="CF_SQL_BIT" />
			<field ColumnName="Seconds" CF_DataType="CF_SQL_BIGINT" />
			<field ColumnName="ReturnVar" CF_DataType="CF_SQL_VARCHAR" Length="250" />
		</table>
	</tables>
	</cfsavecontent>
	
	<cfreturn result>
</cffunction>

</cfcomponent>