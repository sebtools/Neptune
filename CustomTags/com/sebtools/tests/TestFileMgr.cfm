<cfif StructCount(Form)>
	<cfset TestFileMgrPath = "com.sebtools.tests.TestFileMgr">
	<cfif StructKeyExists(Form,"FileMgrType") AND Len(Trim(Form.FileMgrType))>
		<cfset TestFileMgrPath = "#TestFileMgrPath#_#Trim(Form.FileMgrType)#">
	</cfif>
	<cfset oTestFileMgr = CreateObject("component",TestFileMgrPath)>

	<cfset oTestFileMgr.beforeTests()>
	<cfset oTestFileMgr.setUp()>

	<cfset oTestFileMgr.uploadFileTest(ArgumentCollection=Form)>
	Uploaded
<cfelse>
	No Form.<cfabort />
</cfif>