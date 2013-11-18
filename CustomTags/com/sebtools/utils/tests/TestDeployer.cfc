<cfcomponent extends="mxunit.framework.TestCase" output="no">

<cffunction name="beforeTests" access="public" returntype="void">
	<cfset Variables.DataMgr = CreateObject("component","com.sebtools.DataMgr").init("TestSQL")>
	<cfset Variables.Deployer = CreateObject("component","com.sebtools.utils.Deployer").init(Variables.DataMgr)>
	
</cffunction>

<cffunction name="shouldDeployRunFirstTime" access="public" returntype="void"
	hint="The deploy method should run if it hasn't run before.">
	
	<cftransaction>
		<cfset Variables.Deployer.deploy(
			Name="Test Deployment #CreateUUID()#",
			ComponentPath="#CreateUUID()#",
			Component="#This#",
			MethodName="runDeployingMethod"
		)>
		<cfset assertTrue(StructKeyExists(request,"DeployMethodRun"),"Deployment method did not run.")>
		<cftransaction action="rollback">
	</cftransaction>
	
</cffunction>

<cffunction name="shouldDeployNotRunAgain" access="public" returntype="void"
	hint="The deploy method should not run if it has run before.">
	
	<cfset var Name = "Test Deployment #CreateUUID()#">
	<cfset var ComponentPath = "#CreateUUID()#">
		
	<cftransaction>
		<cfset Variables.Deployer.deploy(
			Name="#Name#",
			ComponentPath="#ComponentPath#",
			Component="#This#",
			MethodName="runDeployingMethod"
		)>
		<cfset assertTrue(StructKeyExists(request,"DeployMethodRun"),"Deployment method did not run.")>
		<cfset StructDelete(request,"DeployMethodRun")>
		
		<cfset assertTrue(Variables.Deployer.isDeployed(Name=Name,ComponentPath=ComponentPath),"Deployer doesn't show the deployment has having been run.")>
		
		<cfset Variables.Deployer.deploy(
			Name="#Name#",
			ComponentPath="#ComponentPath#",
			Component="#This#",
			MethodName="runDeployingMethod"
		)>
		<cfset assertFalse(StructKeyExists(request,"DeployMethodRun"),"Deployment method ran depite having already been run.")>
		
		<cftransaction action="rollback">
	</cftransaction>
	
	
</cffunction>

<cffunction name="runDeployingMethod" access="public" returntype="void">
	<cfset request.DeployMethodRun = now()>
</cffunction>

</cfcomponent>