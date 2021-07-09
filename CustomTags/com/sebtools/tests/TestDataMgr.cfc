<cfcomponent displayname="DataMgr Test Suite" extends="mxunit.framework.TestCase">

<cffunction name="setUp" access="public" returntype="void" output="no">
	
	<cfset variables.DataMgr = CreateObject("component","DataMgr").init("TestSQL")>
	
</cffunction>

<cffunction name="testFilterEqualInteger" access="public" returntype="void" output="no">
</cffunction>

<cffunction name="loadTestDataXml" access="public" returntype="void" output="no">
	
	<cfset var result = "">
	
	<cfsavecontent variable="result">
	</cfsavecontent>
	
	<cfreturn result>
</cffunction>

</cfcomponent>