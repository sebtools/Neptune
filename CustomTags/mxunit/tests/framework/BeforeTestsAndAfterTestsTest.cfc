<cfcomponent name="BeforeTestsAndAfterTestsTest" extends="mxunit.framework.TestCase">

<cffunction name="beforeTests">
	<cfset assertBeforeTestsAndAfterTestsHaveNotRun() />
	<cfset recordBeforeTestsRun() />
	<cfset assertBeforeTestsHasRunAndAfterTestsHasNot()/>
</cffunction>

<cffunction name="afterTests">
	<cfset assertBeforeTestsHasRunAndAfterTestsHasNot()>
	<cfset recordAfterTestsRun() />
	<cfset assertBeforeTestsAndAfterTestsHaveRun() />
</cffunction>

<cffunction name="setup">
	<cfset assertBeforeTestsHasRunAndAfterTestsHasNot()>
</cffunction>

<cffunction name="teardown">
	<cfset assertBeforeTestsHasRunAndAfterTestsHasNot()>
</cffunction>

<cffunction name="testA">
	<cfset assertBeforeTestsHasRunAndAfterTestsHasNot()>
</cffunction>

<cffunction name="testB">
	<cfset assertBeforeTestsHasRunAndAfterTestsHasNot()>
</cffunction>

<cffunction name="testC">
	<cfset assertBeforeTestsHasRunAndAfterTestsHasNot()>
</cffunction>


<cffunction name="recordBeforeTestsRun" access="private">
	<cfset request.beforeTestsHasRun = true />
</cffunction>

<cffunction name="recordAfterTestsRun" access="private">
	<cfset request.afterTestsHasRun = true />
</cffunction>

<cffunction name="assertBeforeTestsAndAfterTestsHaveNotRun" access="private">
	<cfset assertFalse(isDefined("request.beforeTestsHasRun")) />
	<cfset assertFalse(isDefined("request.afterTestsHasRun")) />
</cffunction>

<cffunction name="assertBeforeTestsHasRunAndAfterTestsHasNot" access="private">
	<cfset assertTrue(isDefined("request.beforeTestsHasRun")) />
	<cfset assertFalse(isDefined("request.afterTestsHasRun")) />
</cffunction>


<cffunction name="assertBeforeTestsAndAfterTestsHaveRun" access="private">
  <cfset assertTrue(isDefined("request.beforeTestsHasRun")) />
  <cfset assertTrue(isDefined("request.afterTestsHasRun")) />
</cffunction>


</cfcomponent>