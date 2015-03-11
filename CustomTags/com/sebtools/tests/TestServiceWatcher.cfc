<cfcomponent DisplayName="Service Watcher" extends="com.sebtools.RecordsTester" output="no">

<!---
Service Watcher should return times for service since the last time the service was changed if no date is specified.
Store hash of file with every file change.
Store boolean of whether hash has changed.
--->

<cffunction name="setUp" access="public" returntype="void" output="no">
	
	<cfset var sConfig = StructFromArgs(datasource="#Application.DataMgr.getDatasource()#")>

	<cfset Variables.ServiceFactory = CreateObject("component","admin.meta.model.ServiceFactory").init(config=sConfig)>
	
</cffunction>

<cffunction name="shouldListenForServiceLoad" access="public" returntype="void" output="no"
	hint="Service Watcher should have Observer listen for any service being loaded."
>
	
	<cfset var sListeners = 0>

	<cfset loadServices()>

	<cfset sListeners = Variables.Observer.getListeners('ServiceFactory:loadService')>

	<cfset assertTrue(
		StructKeyExists(sListeners,"ServiceWatcher"),
		"Observer is not set to tell ServiceWatcher about service loads.")
	>
	
</cffunction>

<cffunction name="shouldStoreLoadTime" access="public" returntype="void" output="no"
	hint="Service Watcher should record the load time for a service."
	mxunit:transaction="rollback"
>
	
	<cfset var aa = loadServices()>
	<cfset var qServiceDataExample = Variables.ServiceWatcher.getLastLoadData("Example")>
	<cfset var qServiceDataExampleWithExtras = Variables.ServiceWatcher.getLastLoadData("ExampleWithExtras")>
	<cfset var DateLoaded = DateAdd("n",-2,now())>

	<!--- Verify we got a record for Example and it was under 10 ms --->
	<cfif NOT ( qServiceDataExample.RecordCount AND qServiceDataExample.DateTracked GTE DateLoaded )>
		<cfset fail("Service Watcher failed to record the Example service.")>
	</cfif>
	<cfset assertTrue( qServiceDataExample.loadTime LTE 10 ,"Service Watcher failed to correctly record the Example service.")>

	<!--- Verify we got a record for ExampleWithExtras and it was 20 ms or more --->
	<cfif NOT ( qServiceDataExampleWithExtras.RecordCount AND qServiceDataExampleWithExtras.DateTracked GTE DateLoaded )>
		<cfset fail("Service Watcher failed to record the ExampleWithExtras service.")>
	</cfif>
	<cfset assertTrue( qServiceDataExampleWithExtras.loadTime GTE 20 ,"Service Watcher failed to correctly record the ExampleWithExtras service.")>
	
</cffunction>

<cffunction name="shouldSaveServiceState" access="public" returntype="void" output="no"
	hint="Service Watcher should correctly save the current state of the service."
	mxunit:transaction="rollback"
>
	
	<cfset var sReport = 0>
	<cfset var DateTestStart = now()>
	<cfset var ExampleContents = "">

	<!--- Load the services --->
	<cfset loadServices()>

	<!---
	Verify that a record for each of the services exists.
	It should store the LastUpdateDate, the name of the service, the path to the service, and ideally the hash of the file.
	--->
	<cfset sReport = Variables.ServiceWatcher.getServicesReport()>
	<cfset assertTrue(StructKeyExists(sReport,"Example"),"Service Report failed to return a key for a loaded service.")>
	<cfset assertEquals("AvgLoadTime,FileHash,FilePath,LastLoadTime,LastUpdateDate,ServiceName",ListSort(StructKeyList(sReport["Example"]),"text"),"Service Report failed to return all of the data it should return.")>

	<!--- Edit ExampleWatched.cfc --->
	<cfset ExampleContents = FileRead(sReport["Example"].FilePath)>
	<cfset assertEquals(Hash(ExampleContents),sReport["Example"].FileHash,"Service Report did not contain accurate hash of file.")>
	<cfset FileWrite(sReport["Example"].FilePath, ExampleContents)>

	<!--- reload services --->
	<cfset Variables.ServiceFactory.refreshServices(true)>
	
	<!---
	Verify that a record for each of the services exists.
	It should store the LastUpdateDate, the name of the service, the path to the service, and ideally the hash of the file.
	The date and and hash of ExampleWatched should both reflect the changes to the file.
	--->
	<cfset sReport = Variables.ServiceWatcher.getServicesReport()>
	<cfset assertTrue( sReport["Example"].LastUpdateDate.getTime() GTE DateTestStart.getTime() ,"Service Report failed to notice that a service file had been updated.")>
		
</cffunction>

<cffunction name="shouldReturnCorrectTime" access="public" returntype="void" output="no"
	hint="Service Watcher should correctly return the average load time for a service."
	mxunit:transaction="rollback"
>
	
	<cfset var sReport = 0>
	<cfset var AvgLoadTime = 0>

	<!--- Load all services multiple times --->
	<cfset loadServices()>
	<cfset Variables.ServiceFactory.refreshServices(true)>
	<cfset Variables.ServiceFactory.refreshServices(true)>

	<cfset sReport = Variables.ServiceWatcher.getServicesReport()>

	<!--- Verify that Service Watcher correctly returns the average load time for a service --->
	<cfset assertTrue(StructKeyExists(sReport,"Example"),"Service Report failed to return a key for a loaded service.")>
	<cfset assertEquals("AvgLoadTime,FileHash,FilePath,LastLoadTime,LastUpdateDate,ServiceName",ListSort(StructKeyList(sReport["Example"]),"text"),"Service Report failed to return all of the data it should return.")>
	<cfset AvgLoadTime = sReport["ExampleWithExtras"]["AvgLoadTime"]>
	<cfset assertTrue( AvgLoadTime GTE 20 AND AvgLoadTime LTE 50, "Failed to return correct average load time (returned #AvgLoadTime# instead)." )>

</cffunction>

<cffunction name="getXML" access="private" returntype="string" output="no">
	<cfset var TestXML = "">
	
	<cfsavecontent variable="TestXML"><cfoutput><site>
		<components>
			<component name="Observer" path="com.sebtools.Observer"></component>
			<component name="DataMgr" path="com.sebtools.DataMgr">
				<argument name="datasource" arg="datasource" />
			</component>
			<component name="ServiceWatcher" path="watcher.ServiceWatcher">
				<argument name="ServiceFactory" component="ServiceFactory" />
				<argument name="Observer" component="Observer" />
				<argument name="DataMgr" component="DataMgr" />
			</component>
			<component name="Example" path="_framework.tests.ExampleComp"></component>
			<component name="ExampleWithExtras" path="_framework.tests.ExampleWithExtras">
				<argument name="Observer" component="Observer" />
			</component>
			<component name="ExampleWithExtras2" path="_framework.tests.ExampleWithExtras"></component>
			<component name="ExampleWatched" path="watcher.ExampleWatched"></component>
		</components>
	</site></cfoutput></cfsavecontent>
	
	<cfreturn TestXML>
</cffunction>

<cffunction name="loadServices" access="private" returntype="void" output="no">
	
	<cfset Variables.ServiceFactory.loadXml(getXML())>
	<cfset Variables.ServiceFactory.getAllServices()>

	<cfset Variables.Observer = Variables.ServiceFactory.getService("Observer")>
	<cfset Variables.ServiceWatcher = Variables.ServiceFactory.getService("ServiceWatcher")>
	
</cffunction>

<cffunction name="loadXML" access="private" returntype="void" output="no">
	
	<cfset Variables.ServiceFactory.loadXml(getXML())>
	
</cffunction>

</cfcomponent>