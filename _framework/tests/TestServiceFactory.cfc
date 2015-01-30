<cfcomponent DisplayName="Service Factory" extends="com.sebtools.RecordsTester" output="no">

<!---
-Test missing config variables
-Test using value attribute
-Test for arg with name but no value/arg/config/component attribute

-Reorder methods in both components
-Switch to cfscript where sensible

-Test invalid XML
-Test handling of multiple components with same special attribute
-Test ability to refresh any component with changed argument value
-Test ability to inject components defined in properties
--->

<cffunction name="setUp" access="public" returntype="void" output="no">
	
	<cfset var sConfig = StructFromArgs(Value1="TestVal1",Value2="TestVal2",Value3="TestVal3")>
	
	<cfset Variables.ServiceFactory = CreateObject("component","admin.meta.model.ServiceFactory").init(config=sConfig)>
	
</cffunction>

<cffunction name="shouldLoadXmlFile" access="public" returntype="void" output="no"
	hint="Service Factory should load XML from a file path."
>
	
	<cfset var XmlString = getXML()>
	
	<cfset Variables.ServiceFactory.loadXml("#getDirectoryFromPath(getCurrentTemplatePath())#components.xml")>
	
	<cfset assertEquals(ToString(XmlParse(XmlString)),ToString(Variables.ServiceFactory.getXml()),"Service Factory failed to load the XML from a file path.")>
	
</cffunction>

<cffunction name="shouldLoadXmlString" access="public" returntype="void" output="no"
	hint="Service Factory should load XML from a string."
>
	
	<cfset var XmlString = getXML()>
	
	<cfset Variables.ServiceFactory.loadXml(XmlString)>
	
	<cfset assertEquals(ToString(XmlParse(XmlString)),ToString(Variables.ServiceFactory.getXml()),"Service Factory failed to load the XML from a string.")>
	
</cffunction>

<cffunction name="shouldNotLoadXmlInvalid" access="public" returntype="void" output="no"
	hint="Service Factory should throw an exception if provided a value that is neither XML nor a valid file path."
	mxunit:expectedException="ServiceFactory"
>
	
	<cfset Variables.ServiceFactory.loadXml("Useless string")>
	
</cffunction>

<cffunction name="shouldNotLoadNonXmlFile" access="public" returntype="void" output="no"
	hint="Service Factory should throw an exception if provided a value that is neither XML nor a valid file path."
	mxunit:expectedException="ServiceFactory"
>
	
	<cfset Variables.ServiceFactory.loadXml(getCurrentTemplatePath())>
	
</cffunction>

<cffunction name="shouldGetSimpleService" access="public" returntype="void" output="no"
	hint="Service Factory should return a service with no dependencies."
>
	
	<cfset assertCompLoad("Comp","","Failed to load simple service.")>
	
</cffunction>

<cffunction name="shouldGetServiceWithValueArgs" access="public" returntype="void" output="no"
	hint="Service Factory should return a service with value dependencies."
>
	
	<cfset assertCompLoad("CompWithValue","Arg1","Failed to load service with value dependencies.")>
	
</cffunction>

<cffunction name="shouldGetServiceWithDependencies" access="public" returntype="void" output="no"
	hint="Service Factory should return a service with component dependencies."
>
	
	<cfset assertCompLoad("CompWithComp","ArgComp,ArgComp2","Failed to load service with component dependencies.")>
	
</cffunction>

<cffunction name="shouldGetServiceWithDeep" access="public" returntype="void" output="no"
	hint="Service Factory should return a service with deep component dependencies."
>
	
	<cfset assertCompLoad("CompWithDeep","Arg1Comp,Arg2Comp,Arg3Val","Failed to load service with deep component dependencies.")>
	
</cffunction>

<cffunction name="shouldGetServiceWithCircular" access="public" returntype="void" output="no"
	hint="Service Factory should return a service with circular component dependencies."
>
	
	<cfset assertCompLoad("CompWithCircle","Arg1Val,Arg2Comp","Failed to load service with circular component dependencies.")>
	
</cffunction>

<cffunction name="shouldGetServiceWithFactory" access="public" returntype="void" output="no"
	hint="Service Factory should return a service with circular component dependencies."
>
	
	<cfset assertCompLoad("CompWithComp","ArgComp,ArgComp2","Failed to load service with Service Factory.")>
	
</cffunction>

<cffunction name="shouldGetServiceFromPath" access="public" returntype="void" output="no"
	hint="Service Factory should be able to return a service from the service path."
>
	
	<cfset var hasException = false>
	
	<cfset Variables.ServiceFactory.loadXml('
	<site>
		<components>
			<component name="DefinedOnce" path="_framework.tests.ExampleComp">
			</component>
			<component name="DefinedTwice1" path="_framework.tests.ExampleSlow">
			</component>
			<component name="DefinedTwice2" path="_framework.tests.ExampleSlow">
			</component>
		</components>
	</site>
	')>
	
	<!--- hasServicePath() should return true IFF the service path is defined only once --->
	<cfset assertTrue(Variables.ServiceFactory.hasServicePath("_framework.tests.ExampleComp"),"Service Factory failed to indicate that a defined service path exists.")>
	<cfset assertFalse(Variables.ServiceFactory.hasServicePath("_framework.tests.ExampleSlow"),"Service Factory failed to indicate that a twice defined service path doesn't exist.")>
	<cfset assertFalse(Variables.ServiceFactory.hasServicePath("_framework.tests.NonExistent"),"Service Factory failed to indicate that an undefined service path doesn't exist.")>
	
	<!--- getServiceNameByPath() should return a name if the service is defined --->
	<cfset assertEquals("DefinedOnce",Variables.ServiceFactory.getServiceNameByPath("_framework.tests.ExampleComp"))>
	
	<!--- getServiceNameByPath() should throw an exception if no service is defined --->
	<cfset hasException = false>
	<cftry>
		<cfset Variables.ServiceFactory.getServiceNameByPath("_framework.tests.NonExistent")>
	<cfcatch type="ServiceFactory">
		<cfset hasException = True>
	</cfcatch>
	</cftry>
		
	<!--- getServiceNameByPath() should throw an exception if the given path is used for more than one service --->
	<cfset hasException = false>
	<cftry>
		<cfset Variables.ServiceFactory.getServiceNameByPath("_framework.tests.ExampleSlow")>
	<cfcatch type="ServiceFactory">
		<cfset hasException = True>
	</cfcatch>
	</cftry>
	
	<!--- getServiceByPath() should return the component if the service is defined --->
	<cfset assertTrue(isObject(Variables.ServiceFactory.getServiceByPath("_framework.tests.ExampleComp")),"Service Factory failed to return the service for a defined service path.")>
	
	<!--- getServiceNameByPath() should throw an exception if the given path is used for more than one service --->
	<cfset hasException = false>
	<cftry>
		<cfset Variables.ServiceFactory.getServiceByPath("_framework.tests.ExampleSlow")>
	<cfcatch type="ServiceFactory">
		<cfset hasException = True>
	</cfcatch>
	</cftry>
	
	<!--- getServiceByPath() should return the component if the service is not defined but can be found with init, but no properties or arguments in init --->
	<cfset assertTrue(isObject(Variables.ServiceFactory.getServiceByPath("_framework.tests.ExampleWithExtras")),"Service Factory failed to return the service for an existing but undefined service path.")>
	
	<!--- LATER: getServiceByPath() should be more sophisticated about loading undefined services --->
	
	
	
</cffunction>

<cffunction name="shouldNotGetNonService" access="public" returntype="void" output="no"
	hint="Service Factory should throw an exception if asked for an undefined service."
	mxunit:expectedException="ServiceFactory"
>
	
	<cfset var oComp = 0>
	
	<cfset loadXML()>
	
	<cfset oComp = Variables.ServiceFactory.getService("UndefinedComp")>
	
</cffunction>

<cffunction name="shouldNotGetServiceMissingComp" access="public" returntype="void" output="no"
	hint="Service Factory should throw an exception if asked for a component with a missing dependency and no ifmissing attribute."
	mxunit:expectedException="ServiceFactory"
>
	
	<cfset var oComp = 0>
	
	<cfset Variables.ServiceFactory.loadXml('<site><components><component name="CompWithMissingComp" path="ExampleComp"><argument name="Arg" component="MissingComp" /></component></components></site>')>
	
	<cfset oComp = Variables.ServiceFactory.getService("CompWithMissingComp")>
	
</cffunction>

<cffunction name="shouldGetServiceMissingCompEmpty" access="public" returntype="void" output="no"
	hint="Service Factory should return nothing if asked for a component with a missing dependency and ifmissing of skipcomp."
>
	
	<cfset var oComp = 0>
	<cfset var sServices = 0>
	
	<cfset loadXML()>
	
	<cfset oComp = Variables.ServiceFactory.getService("CompWithMissingCompSkipComp")>
	
	<cfset assertFalse(False,isDefined("oComp"),"Service Factory failed to return nothing for a component with a missing dependency and ifmissing=skipcomp.")>
	
	<cfset sServices = Variables.ServiceFactory.getAllServices()>
	
	<cfset assertFalse(StructKeyExists(sServices,"CompWithMissingCompSkipComp"),"Service Factory included a component that it shouldn't have in the services.")>
	
</cffunction>

<cffunction name="shouldGetServiceMissingCompArg" access="public" returntype="void" output="no"
	hint="Service Factory should load a component without the arg for a component missing dependency and ifmissing of skiparg."
>
	
	<cfset assertCompLoad("CompWithMissingCompSkipArg","Arg1","Failed to correctly load service with allowed missing dependency.")>
	
</cffunction>

<cffunction name="shouldGetAllServices" access="public" returntype="void" output="no"
	hint="Service Factory should correctly return all services."
>
	<cfset var sServices = 0>
	
	<cfset loadXML()>
	
	<cfset sServices = Variables.ServiceFactory.getAllServices()>
	
	<cfset assertEquals("Comp,CompWithCircle,CompWithCircle2,CompWithCircle3,CompWithComp,CompWithComp2,CompWithComp3,CompWithDeep,CompWithMissingCompSkipArg,CompWithValue,CompWithValues,ServiceFactory",ListSort(StructKeyList(sServices),"textnocase"),"Service Factory failed to correctly load all defined components.")>
	
</cffunction>

<cffunction name="shouldGetAllServicesFast" access="public" returntype="void" output="no"
	hint="Service Factory should correctly return all services quickly."
>
	
	<cfset var BeginTime = 0>
	<cfset var TotalTime = 0>
	
	<cfset loadXML()>
	
	<cfset BeginTime = getTickCount()>
	<cfset Variables.ServiceFactory.getAllServices()>
	<cfset TotalTime = getTickCount() - BeginTime>
	
	<cfset assertTrue(TotalTime LT 30,"It took more than 30 milliseconds to load all of the services.")>
	
</cffunction>

<cffunction name="shouldGetAllServicesPreloadedFast" access="public" returntype="void" output="no"
	hint="Service Factory should correctly return all services quickly after they have already loaded."
>
	
	<cfset var BeginTime = 0>
	<cfset var TotalTime = 0>
	
	<cfset loadXML()>
	
	<cfset Variables.ServiceFactory.getAllServices()>
	
	<cfset BeginTime = getTickCount()>
	<cfset Variables.ServiceFactory.getAllServices()>
	<cfset TotalTime = getTickCount() - BeginTime>
	
	<cfset assertTrue(TotalTime LT 10,"It took more than 10 milliseconds to load all of the preloaded services.")>
	
</cffunction>

<cffunction name="shouldRefreshServiceFast" access="public" returntype="void" output="no"
	hint="Service Factory should refresh a service quickly."
>
	
	<cfset var BeginTime = 0>
	<cfset var TotalTime = 0>
	
	<cfset loadXML()>
	
	<cfset Variables.ServiceFactory.getAllServices()>
	
	<cfset BeginTime = getTickCount()>
	<cfset Variables.ServiceFactory.refreshService("CompWithComp2")>
	<cfset TotalTime = getTickCount() - BeginTime>
	
	<cfset assertTrue(TotalTime LT 20,"It took more than 20 milliseconds to refresh a service.")>
	
</cffunction>

<cffunction name="shouldRefreshReloadCompAndDeps" access="public" returntype="void" output="no"
	hint="Refreshing a component should reload that component and all of its dependants (but nothing else)."
>
	<cfset var sServices = 0>
	<cfset var DateRefreshed = 0>
	<cfset var Independents = "Comp,CompWithValue,CompWithValues,CompWithComp,CompWithCircle,CompWithCircle2,CompWithCircle3,CompWithMissingCompSkipArg">
	<cfset var Dependents = "CompWithComp3,CompWithDeep">
	<cfset var comp = "">
	
	<cfset loadXML()>
	
	<cfset sServices = Variables.ServiceFactory.getAllServices()>
	
	<cfset sleep(10)>
	
	<cfset DateRefreshed = now()>
	
	<cfset sleep(10)>
	
	<cfset sServices = Variables.ServiceFactory.refreshService("CompWithComp2")>
	
	<cfloop index="comp" list="#Independents#">
		<cfset assertTrue((DateRefreshed.getTime() GT sServices[comp].DateLoaded.getTime()), "A component not dependent on the refreshed component was refreshed (#comp#)." )>
	</cfloop>
	
	<cfset assertTrue((sServices["CompWithComp2"].DateLoaded.getTime() GT DateRefreshed.getTime()), "Service Factory failed to refreshed the component." )>
	<cfloop index="comp" list="#Dependents#">
		<cfset assertTrue((sServices[comp].DateLoaded.getTime() GT DateRefreshed.getTime()), "A component that is dependent on the refreshed component was not refreshed (#comp#)." )>
	</cfloop>
	
</cffunction>

<cffunction name="shouldRemoveServicesRemoveList" access="public" returntype="void" output="no"
	hint="Remove Services should remove a list of services and all dependants from the cache."
>

	<cfset var sServices = 0>
	
	<cfset loadXML()>
	
	<cfset sServices = Variables.ServiceFactory.getAllServices()>
	
	<cfset sServices = Variables.ServiceFactory.removeServices("CompWithComp3,CompWithCircle")>
	
	<cfset assertEquals("Comp,CompWithComp,CompWithComp2,CompWithMissingCompSkipArg,CompWithValue,CompWithValues,ServiceFactory",ListSort(StructKeyList(sServices),"textnocase"),"Calling removeServices() with a list failed to remove the list services and dependants from the cache.")>
	
</cffunction>

<cffunction name="shouldRemoveServicesTrueRemoveAll" access="public" returntype="void" output="no"
	hint="Passing true to removeServices() should remove all services from the cache."
>

	<cfset var sServices = 0>
	
	<cfset loadXML()>
	
	<cfset sServices = Variables.ServiceFactory.getAllServices()>
	
	<cfset sServices = Variables.ServiceFactory.removeServices(True)>
	
	<cfset assertEquals("",StructKeyList(sServices),"Calling removeServices(true) failed to remove all services from the cache.")>
	
</cffunction>

<cffunction name="shouldGetSpecialService" access="public" returntype="void" output="no"
	hint="Should return special component of requested type."
>
	
	<cfset loadXML()>
	
	<cfset assertFalse(Variables.ServiceFactory.hasSpecialService("NoSuchSpecial"),"Service Factory said it had a special of a type for which no special is defined.")>
	
	<cfset assertTrue(Variables.ServiceFactory.hasSpecialService("MySpecial"),"Service Factory said it had no special for a type for which a special is defined.")>
	
	<cfset assertEquals("",Variables.ServiceFactory.getSpecialServiceName("NoSuchSpecial"),"Service Factory said it had a special of a type for which no special is defined.")>
	
	<cfset assertEquals("CompWithComp3",Variables.ServiceFactory.getSpecialServiceName("MySpecial"),"Service Factory said it had no special for a type for which a special is defined.")>
	
	<cfset assertTrue(isObject(Variables.ServiceFactory.getSpecialService("MySpecial")),"Service Factory failed to return a component for a type for which a special is defined.")>
	
</cffunction>

<cffunction name="shouldServiceBeInThis" access="public" returntype="void" output="no"
	hint="A loaded service should be available from THIS scope (backward compatibility only)."
>
	
	<!--- This functionality is for backward compability only. It is *not* recommended to be used. --->
	
	<cfset assertCompLoad("Comp","","Failed to load simple service.")>
	<cfset assertTrue(StructKeyExists(Variables.ServiceFactory,"comp"),"Loaded service is not available in THIS scope.")>
	
</cffunction>

<cffunction name="shouldRegisterService" access="public" returntype="void" output="no"
	hint="Service Factory should allow new services to be registered."
>
	
	<cfset var FilePath = getDirectoryFromPath(getCurrentTemplatePath()) & "TestComponents.xml">
	<cfset var initial = "">
	<cfset var register = "">
	<cfset var expected = "">
	<cfset var actual = "">
	
	<cfsavecontent variable="initial"><cfoutput>
	<site>
		<arguments>
			<argument name="Value1" type="string" />
			<argument name="Value2" type="string" />
			<argument name="Value3" type="string" />
		</arguments>
		<components>
			<component name="Comp" path="ExampleComp">
			</component>
		</components>
	</site>
	</cfoutput></cfsavecontent>
	<cfsavecontent variable="register"><cfoutput>
	<program name="Domains">
		<components>
			<component name="InsertedComp" path="_framework.tests.ExampleComp">
			</component>
			<component name="InsertedComp1" path="_framework.tests.ExampleComp">
				<argument name="Arg1Compe" component="InsertedComp" />
			</component>
		</components>
	</program>
	</cfoutput></cfsavecontent>
	<cfsavecontent variable="expected"><cfoutput>
	<site>
		<arguments>
			<argument name="Value1" type="string" />
			<argument name="Value2" type="string" />
			<argument name="Value3" type="string" />
		</arguments>
		<components>
			<component name="Comp" path="ExampleComp">
			</component>
			<component name="InsertedComp" path="_framework.tests.ExampleComp">
			</component>
			<component name="InsertedComp1" path="_framework.tests.ExampleComp">
				<argument name="Arg1Compe" component="InsertedComp" />
			</component>
		</components>
	</site>
	</cfoutput></cfsavecontent>
	
	<!--- Create a new simple XML file with a few components --->
	<cffile action="write" file="#FilePath#" output="#initial#">
	
	<cfset Variables.ServiceFactory.loadXml(FilePath)>
	
	<!--- Pass an XML string to register --->
	<cfset Variables.ServiceFactory.registerServices(register)>
	
	<!--- Test that the XML file looks correct --->
	<cffile action="read" file="#FilePath#" variable="actual">
	<cfset assertEquals(XmlParse(expected),XmlParse(actual),"The XML file was not correctly updated.")>
	
	<!--- Test that the XML returned from Service Factory is correct --->
	<cfset assertEquals(XmlParse(expected),Variables.ServiceFactory.getXml(),"The internal XML was not correctly updated.")>
	
	<!--- Make sure the new components were automatically loaded --->
	<cfset assertTrue(StructKeyExists(Variables.ServiceFactory,"InsertedComp"),"The registered component was not automatically loaded.")>
	<cfset assertTrue(StructKeyExists(Variables.ServiceFactory,"InsertedComp1"),"The second registered component was not automatically loaded.")>
	
	<!--- Remove the file --->
	<cffile action="delete" file="#FilePath#">
	
</cffunction>

<cffunction name="shouldCheckRefresh" access="public" returntype="void" output="no"
	hint="Service Factory should correctly identify which components would be refreshed from the given list."
>
	
	<cfset loadXml()>
	
	<cfset assertTrue(Variables.ServiceFactory.checkRefresh("Comp","Comp"),"Failed to recognize that component would refresh if only component in the list.")>
	<cfset assertTrue(Variables.ServiceFactory.checkRefresh("CompWithComp","Comp,CompWithComp,CompWithComp2"),"Failed to recognize that component would refresh if it is in the list.")>
	<cfset assertFalse(Variables.ServiceFactory.checkRefresh("Comp","CompWithComp,CompWithComp2"),"Failed to recognize a component would not refresh.")>
	<cfset assertTrue(Variables.ServiceFactory.checkRefresh("CompWithDeep","CompWithComp2"),"Failed to recognize that a component would refresh if it is indirectly dependent on the component being refreshed.")>
	<cfset assertTrue(Variables.ServiceFactory.checkRefresh("CompWithDeep","CompWithComp2,CompWithValues"),"Failed to recognize that a component would refresh if it is indirectly dependent on a component in the list.")>
	<cfset assertTrue(Variables.ServiceFactory.checkRefresh("CompWithDeep",True),"Failed to recognize that a component would refresh if the given list is TRUE.")>
	<cfset assertFalse(Variables.ServiceFactory.checkRefresh("CompWithDeep",False),"Failed to recognize that a component would not refresh if the given list is FALSE.")>
	<cfset assertFalse(Variables.ServiceFactory.checkRefresh("CompWithDeep",""),"Failed to recognize that a component would not refresh if the given list is an empty string.")>
	
</cffunction>

<cffunction name="shouldGetDependants" access="public" returntype="void" output="no"
	hint="Service Factory should correctly return a list of the dependants for a component."
>
	<cfset makePublic(Variables.ServiceFactory,"getDependants")>
	
	<cfset loadXML()>
	
	<cfset assertEquals("CompWithComp3,CompWithDeep",ListSort(Variables.ServiceFactory.getDependants("CompWithComp2"),"TextNoCase"),"Failed to return all of the direct dependencies.")>
	
	<cfset assertEquals("CompWithComp,CompWithComp2,CompWithComp3,CompWithDeep",ListSort(Variables.ServiceFactory.getDependants("Comp,CompWithValues",true),"TextNoCase"),"Failed to return all of the dependencies (direct and indirect).")>
	
	<cfset assertEquals("CompWithComp3,CompWithDeep",ListSort(Variables.ServiceFactory.getDependants("CompWithComp2",true),"TextNoCase"),"Failed to return all of the dependencies (direct and indirect).")>
	
</cffunction>

<cffunction name="shouldGetStaleServices" access="public" returntype="void" output="no"
	hint="Service Factory should report on stale services (where the file has changed since it was instantiated)."
>
	<cfset var FilePathCFC = useSecondaryFile()>
	
	<cfset makePublic(Variables.ServiceFactory,"getServiceLastUpdated")>
	
	<!--- Do: Edit the new component file --->
	<cfset touchFile(FilePathCFC)>
	
	<!--- Test: Service Factory returns any components that use that file --->
	<cfset assertEquals("Comp,CompWithComp3",ListSort(StructKeyList(Variables.ServiceFactory.getStaleServices()),"TextNoCase"),"Failed to retrieve stale services correctly.")>
	
	<cffile action="delete" file="#FilePathCFC#">
	
</cffunction>

<cffunction name="shouldRefreshStaleServices" access="public" returntype="void" output="no"
	hint="Service Factory should be able to refresh any stale services (where the file has changed since it was instantiated)."
>
	
	<cfset var FilePathCFC = useSecondaryFile()>
	<cfset var DateRefreshed = now()>
	<cfset var sServices = 0>
	<cfset var Independents = "CompWithValue,CompWithValues,CompWithCircle,CompWithCircle2,CompWithCircle3,CompWithMissingCompSkipArg">
	<cfset var Dependents = "Comp,CompWithComp,CompWithComp3,CompWithDeep">
	
	<cfset sServices = Variables.ServiceFactory.getAllServices()>
	
	<!--- Do: Edit the new component file --->
	<cfset touchFile(FilePathCFC)>
	
	<!--- Do: Refresh the stale services --->
	<cfset DateRefreshed = now()>
	
	<cfset sServices = Variables.ServiceFactory.refreshStaleServices()>
	
	<!--- Test: Service Factory reloads any components that use that file --->
	<cfloop index="comp" list="#Dependents#">
		<cfset assertTrue((sServices[comp].DateLoaded.getTime() GT DateRefreshed.getTime()), "A stale component (or its dependent) was not refreshed (#comp#)." )>
	</cfloop>
	
	<cfloop index="comp" list="#Independents#">
		<cfset assertTrue((DateRefreshed.getTime() GT sServices[comp].DateLoaded.getTime()), "A fresh component was refreshed (#comp#)." )>
	</cfloop>
	
	<cffile action="delete" file="#FilePathCFC#">
	
</cffunction>

<cffunction name="shouldUseConfigCFC" access="public" returntype="void" output="no"
	hint="Service Factory should have the option to use the Config service for configurations."
>
	
	<cfset var oConfig = CreateObject("component","_framework.Config").init("request")>
	
	<cfset oConfig.paramSetting("fruit","apple")>
	
	<cfset Variables.ServiceFactory.loadConfig(oConfig)>
	
	<cfset oConfig.setSetting("fruit","apple")>
	<cfset oConfig.setSetting("animal","aardvark")>
	
	<cfset assertEquals(oConfig.dump(),Variables.ServiceFactory.getConfig(),"Failed to get the configuration data from the Config service.")>
	
</cffunction>

<cffunction name="shouldCallMethod" access="public" returntype="void" output="no"
	hint="Should be possible to use callMethod to call the method of any existing service."
>
	
	<cfset StructDelete(request,"foo")>
	
	<cfset Variables.ServiceFactory.callMethod("ExampleWithExtras","setRequestFoo",StructFromArgs(FooVal="MyVal"))>
	
	<cfset assertFalse(StructKeyExists(request,"foo"),"Service Factory called a method for a component for which it does not have a definition.")>
	
	<cfset Variables.ServiceFactory.loadXml('<site><components><component name="ExampleWithExtras" path="_framework.tests.ExampleWithExtras"></component></components></site>')>
	
	<cfset Variables.ServiceFactory.callMethod("ExampleWithExtras","setRequestFoo",StructFromArgs(FooVal="MyVal"))>
	
	<cfset assertTrue(StructKeyExists(request,"foo"),"Service Factory failed to call a method for a component for which it has a definition.")>
	
	<cfset assertEquals("MyVal",request.foo,"Service Factory failed to correctly pass in the arguments to the called method.")>
	
	<cfset StructDelete(request,"foo")>
	
</cffunction>

<cffunction name="shouldTrackLoadTime" access="public" returntype="void" output="no"
	hint="Server Factory should track the time it takes to load a service."
>
	
	<cfset var sInfo = 0>
	
	<cfset Variables.ServiceFactory.loadXml('<site><components><component name="ExampleWithExtras" path="_framework.tests.ExampleWithExtras"></component></components></site>')>
	
	<cfset sInfo = Variables.ServiceFactory.getServiceInfo('ExampleWithExtras',True)>
	
	<cfset assertTrue(StructKeyExists(sInfo,"LoadTime") AND Val(sInfo.LoadTime) GTE 20,"Service Factory failed to track a load time for a loaded.")>
	
</cffunction>

<cffunction name="shouldCallObserver" access="public" returntype="void" output="no"
	hint="Server Factory should notify Observer when it loads a service."
>
	
	<cfset var oObserver = 0>
	
	<cfset Variables.ServiceFactory.loadXml('
	<site>
		<components>
			<component name="Example" path="_framework.tests.ExampleComp"></component>
			<component name="Observer" path="com.sebtools.Observer"></component>
			<component name="ExampleWithExtras" path="_framework.tests.ExampleWithExtras">
				<argument name="Observer" component="Observer" />
			</component>
			<component name="ExampleWithExtras2" path="_framework.tests.ExampleWithExtras"></component>
		</components>
	</site>
	')>
	
	<cfset oObserver = Variables.ServiceFactory.getService("Observer")>
	
	<cfset oObserver.registerListener(This,"_framework.tests.TestServiceFactory","listenForServiceLoad","ServiceFactory:loadService")>
	
	<cfset Variables.ServiceFactory.getService("ExampleWithExtras2")>
	
	<cfset assertTrue(StructKeyExists(request,"sServiceLoadArgs"),"Service Factory failed to notify Observer when it loaded a service.")>
	<cfset assertTrue(StructKeyExists(request.sServiceLoadArgs,"ServiceName"),"Service Factory failed to pass the service name to the notification.")>
	<cfset assertTrue(StructKeyExists(request.sServiceLoadArgs,"Service"),"Service Factory failed to pass the service to the notification.")>
	<cfset assertTrue(StructKeyExists(request.sServiceLoadArgs,"Meta"),"Service Factory failed to pass the metadata to the notification.")>
	<cfset assertEquals("ExampleWithExtras2",request.sServiceLoadArgs.ServiceName,"Service Factory failed to correctly pass the service name to the notification.")>
	<cfset assertEquals(Variables.ServiceFactory.getService("ExampleWithExtras2"),request.sServiceLoadArgs.Service,"Service Factory failed to correctly pass the service to the notification.")>
	<cfset StructDelete(request.sServiceLoadArgs.Meta,"LastUpdated")>
	<cfset assertEquals(Variables.ServiceFactory.getServiceInfo("ExampleWithExtras2"),request.sServiceLoadArgs.Meta,"Service Factory failed to correctly pass the metadata to the notification.")>
	
	<cfset StructDelete(request,"sServiceLoadArgs")>
	
</cffunction>

<cffunction name="listenForServiceLoad" access="public" returntype="void" output="no">
	
	<cfset request.sServiceLoadArgs = Arguments>
	
</cffunction>

<cffunction name="shouldGetArray" access="public" returntype="void" output="no"
	hint="Server Factory should be able to return services in an array based on the order in the XML."
>
	
	<cfset var aServices = 0>
	<cfset var ii = 0>
	<cfset var ServicesList = "">
	
	<cfset Variables.ServiceFactory.loadXml('
	<site>
		<components>
			<component name="Example3" path="_framework.tests.ExampleComp"></component>
			<component name="Example1" path="_framework.tests.ExampleComp"></component>
			<component name="Example2" path="_framework.tests.ExampleComp"></component>
			<component name="Example4" path="_framework.tests.ExampleComp"></component>
		</components>
	</site>
	')>
	
	<cfset aServices = Variables.ServiceFactory.getServicesArray()>
	
	<cfloop index="ii" from="1" to="#ArrayLen(aServices)#">
		<cfset ServicesList = ListAppend(ServicesList,aServices[ii].Name)>
	</cfloop>
	
	<cfset assertEquals("Example3,Example1,Example2,Example4",ServicesList,"Service Factory failed to return the services in the order in the XML.")>
	
</cffunction>

<cffunction name="shouldLockInit" access="public" returntype="void" output="no"
	hint="Server Factory not attempt to load the same service more than once at a time."
>
	
	<cfset makePublic(Variables.ServiceFactory,"initService")>
	
	<cfset Variables.ServiceFactory.loadXml('
	<site>
		<components>
			<component name="ExampleSlow" path="_framework.tests.ExampleSlow"></component>
		</components>
	</site>
	')>
	
	<cfset Variables.ServiceFactory.getService("ExampleSlow")>
	
	<cfset StructDelete(request,"Loaded1")>
	<cfset StructDelete(request,"Loaded2")>
	
	<cfthread name="Init1" action="run">
		<cfset Variables.ServiceFactory.initService("ExampleSlow",StructNew())>
	</cfthread>
	<cfset sleep(10)>
	<cfthread name="Init2" action="run">
		<cfset Variables.ServiceFactory.initService("ExampleSlow",StructNew())>
	</cfthread>
	<cfthread action="join" name="Init1,Init2" />
	
	<cfset assertTrue( request.Loaded2["BeginTime"] GT request.Loaded1["EndTime"] , "Service Factory was able to run initialize the same service concurrently." )>
	
	<cfset StructDelete(request,"Loaded1")>
	<cfset StructDelete(request,"Loaded2")>
	
</cffunction>

<cffunction name="shouldGetServiceFactoryInfo" access="public" returntype="void" output="no"
	hint="Server Factory should be able to get information about itself."
>
	
	<cfset loadXml()>
	
	<cfset assertTrue(isDate(Variables.ServiceFactory.getServiceLastUpdated("ServiceFactory")),"Service Factory was unable to retreive a last update date for itself.")>
	
	<cfset assertTrue(isStruct(Variables.ServiceFactory.getServiceInfo("ServiceFactory")),"Service Factory was unable to retreive info on itself.")>

	
</cffunction>

<cffunction name="touchFile" access="private" returntype="void" output="no"
	hint="Service Factory should be able to refresh any stale services (where the file has changed since it was instantiated)."
>
	<cfargument name="FilePath" type="string" required="true">
	
	<cffile action="read" file="#FilePath#" variable="output">
	<cffile action="write" file="#FilePath#" output="#output#">
	
</cffunction>

<cffunction name="useSecondaryFile" access="private" returntype="string" output="no"
	hint="Service Factory should be able to refresh any stale services (where the file has changed since it was instantiated)."
>
	<cfset var FilePathFolder = getDirectoryFromPath(getCurrentTemplatePath())>
	<cfset var oExample = CreateObject("component","_framework.tests.ExampleComp")>
	<cfset var sExample = getMetaData(oExample)>
	<cfset var FilePathCFC = "#getDirectoryFromPath(sExample.Path)#ExampleComp2.cfc">
	<cfset var FilePathXML = "#FilePathFolder#components.xml">
	<cfset var FilePathXML2 = "#FilePathFolder#components2.xml">
	<cfset var before = "">
	<cfset var after = "">
	<cfset var FileContents = '<cfcomponent displayname="Example" extends="ExampleComp" output="no"></cfcomponent>'>
	
	<cffile action="write" file="#FilePathCFC#" output="#FileContents#">
	
	<cffile action="read" file="#FilePathXML#" variable="before">
	
	<cfset after = before>
	<cfset after = ReplaceNoCase(after,'name="Comp" path="ExampleComp"','name="Comp" path="ExampleComp2"')>
	<cfset after = ReplaceNoCase(after,'name="CompWithComp3" path="ExampleComp"','name="CompWithComp3" path="ExampleComp2"')>
	
	<cfset Variables.ServiceFactory.loadXml(after)>
	<cfset Variables.ServiceFactory.getAllServices()>
	
	<cfreturn FilePathCFC>
</cffunction>

<cffunction name="shouldLoadIntoApplication" access="public" returntype="void" output="no"
	hint="Service Factory should be able to load all services into application scope."
>
	
	<cfset var sScope = StructNew()>
	<cfset var sServices = 0>
	<cfset var DateRefreshed = now()>
	
	<cfset loadXML()>
	
	<cfset sServices = Variables.ServiceFactory.getAllServices()>
	
	<!--- Do: Load into scope --->
	<cfset Variables.ServiceFactory.setScope(sScope)>
	
	<!--- Test: Scope matches sServices --->
	<cfset assertEquals(ListSort(StructKeyList(sServices),"TextNoCase"),ListSort(StructKeyList(sScope),"TextNoCase"),"Failed to load the services into the given scope.")>
	
	<!--- Do: Remove some services --->
	<cfset Variables.ServiceFactory.removeService("CompWithValues")>
	
	<!--- Test: Scope matches sServices --->
	<cfset assertFalse(StructKeyExists(sScope,"CompWithValues"),"Failed to remove the service from the given scope.")>
	
	<cfset DateRefreshed = now()>
	
	<cfset sleep(10)>
	
	<!--- Do: refresh some services --->
	<cfset Variables.ServiceFactory.refreshService("CompWithComp")>
	
	<!--- Test: Services refreshed in scope --->
	<cfset assertTrue((StructKeyExists(sScope,"CompWithComp") AND sScope["CompWithComp"].DateLoaded.getTime() GT DateRefreshed.getTime()), "Service Factory failed to refreshed the component in the given scope." )>
	
	<cfset sScope["UnrelatedKey"] = "UnrelatedValue">
	
	<!--- Do: Remove all services --->
	<cfset sServices = Variables.ServiceFactory.removeServices(True)>
	
	<cfset assertTrue(StructCount(sServices) LT 2,"removeServices(True) failed to remove all of the services.")>
	<cfset assertEquals(ListAppend(StructKeyList(sServices),"UnrelatedKey"),StructKeyList(sScope),"Removing services also removed unrelated keys from the scope.")>
	
</cffunction>

<cffunction name="shouldLoadIntoApplicationFast" access="public" returntype="void" output="no"
	hint="Service Factory should be able to load all services into application scope quickly."
>
	
	<cfset var sScope = StructNew()>
	<cfset var sServices = 0>
	<cfset var BeginTime = 0>
	<cfset var TotalTime = 0>
	
	<cfset loadXML()>
	
	<cfset sServices = Variables.ServiceFactory.getAllServices()>
	
	<!--- Do: Load into scope --->
	<cfset BeginTime = getTickCount()>
	<cfset Variables.ServiceFactory.setScope(sScope)>
	<cfset TotalTime = getTickCount() - BeginTime>
	
	<cfset assertTrue(TotalTime LT 10,"It took more than 10 milliseconds to copy all services to a scope.")>
	
</cffunction>

<cffunction name="shouldRecoverMissingServiceError" access="public" returntype="void" output="no"
	hint="Service Factory should be able to recover a missing service given the error message."
>
	
	<cfset var sError = 0>
	<cfset var BeginTime = 0>
	<cfset var TotalTime = 0>
	<cfset var sScope = StructNew()>

	<!--- Do: Load into scope --->
	<cfset Variables.ServiceFactory.setScope(sScope)>

	<cfset loadXML()>

	<cfset Variables.ServiceFactory.removeService("Comp")>
	<cfset Variables.ServiceFactory.removeService("CompWithComp")>

	<cfset assertFalse(StructKeyExists(sScope,"Comp"),"The removed service Comp still exists in the scope.")>
	<cfset assertFalse(StructKeyExists(sScope,"CompWithComp"),"The removed service CompWithComp still exists in the scope.")>

	<!--- Given an unrelated error, ServiceFactory should quickly do nothing --->
	<cfset sError = StructNew()>
	<cfset sError.Message = "Unrelated Error">
	<cfset BeginTime = getTickCount()>
	<cfset Variables.ServiceFactory.handleError(sError)>
	<cfset TotalTime = getTickCount() - BeginTime>
	<cfset assertTrue(TotalTime LT 10,"It took more than 10 milliseconds to respond to an unrelated error.")>

	<!--- Given an error for a non-existent component, ServiceFactory should quickly do nothing --->
		<!--- Using Element key --->
		<cfset sError = StructNew()>
		<cfset sError["Element"] = "NoSuchService">
		<cfset Variables.ServiceFactory.handleError(sError)>
		<cfset TotalTime = getTickCount() - BeginTime>
		<cfset assertTrue(TotalTime LT 15,"It took more than 15 milliseconds to respond to an error on a non-existent service (using element).")>

		<!--- Using message key --->
		<cfset sError = StructNew()>
		<cfset sError["Message"] = "Element NOSUCHSERVICE.NOSUCHCOMP is undefined in a Java object of type class [Ljava.lang.String; referenced as ''">
		<cfset Variables.ServiceFactory.handleError(sError)>
		<cfset TotalTime = getTickCount() - BeginTime>
		<cfset assertTrue(TotalTime LT 20,"It took more than 20 milliseconds to respond to an error on a non-existent service (using message).")>

	<!--- Given an error for a defined service, ServiceFactory should load it into Application scope. --->
		
		<!--- Using Element key --->
		<cfset sError = StructNew()>
		<cfset sError["Message"] = "Element CompWithComp.NOSUCHCOMP is undefined in a Java object of type class [Ljava.lang.String; referenced as ''">
		<cfset sError["Element"] = "Comp.NoSuchComp">
		<cfset Variables.ServiceFactory.handleError(sError)>
		<cfset TotalTime = getTickCount() - BeginTime>
		<cfset assertTrue(StructKeyExists(sScope,"Comp"),"ServiceFactory failed to recover a service from the element key of an exception.")>

		<!--- Using message key --->
		<cfset sError = StructNew()>
		<cfset sError["Message"] = "Element CompWithComp.NOSUCHCOMP is undefined in a Java object of type class [Ljava.lang.String; referenced as ''">
		<cfset Variables.ServiceFactory.handleError(sError)>
		<cfset TotalTime = getTickCount() - BeginTime>
		<cfset assertTrue(StructKeyExists(sScope,"CompWithComp"),"ServiceFactory failed to recover a service from the message string of an exception.")>

	<!--- ServiceFactory should record services still loaded in factory, but missing from scope --->
	<cfset StructDelete(sScope,"Comp")>

	<cfset sError = StructNew()>
	<cfset sError["Message"] = "Element Comp.NOSUCHCOMP is undefined in a Java object of type class [Ljava.lang.String; referenced as ''">
	<cfset sError["Element"] = "Comp.NoSuchComp">
	<cfset Variables.ServiceFactory.handleError(sError)>
	<cfset TotalTime = getTickCount() - BeginTime>
	<cfset assertTrue(StructKeyExists(sScope,"Comp"),"ServiceFactory failed to recover a service into the scope that still exists in ServiceFactory itself.")>

	<!--- Handle "Factory" in variable reference for missing component --->
	<cfset Variables.ServiceFactory.removeService("Comp")>

	<cfset sError = StructNew()>
	<cfset sError["Message"] = "Element Factory.Comp.NOSUCHCOMP is undefined in a Java object of type class [Ljava.lang.String; referenced as ''">
	<cfset sError["Element"] = "Factory.Comp.NoSuchComp">
	<cfset Variables.ServiceFactory.handleError(sError)>
	<cfset TotalTime = getTickCount() - BeginTime>
	<cfset assertTrue(StructKeyExists(sScope,"Comp"),"ServiceFactory failed to recover a service referenced via the generic Factory.")>

</cffunction>

<cffunction name="shouldPassChangedValue" access="public" returntype="void" output="no"
	hint="Service Factory should correctly notice and pass a new value from the XML into a service when loading it."
>
	<cfset var CompPath = "#getDirectoryFromPath(getCurrentTemplatePath())#comp1.xml">
	<cfset var sScope = StructNew()>
	<cfset var oServiceFactory = CreateObject("component","admin.meta.model.ServiceFactory").init()>
	<cfset var CompXml = "">

<cfsavecontent variable="CompXml"><cfoutput>
<site>
	<components>
		<component name="Comp" path="ExampleWithInitArg">
			<argument name="Value" value="Value1" />
		</component>
	</components>
</site>
</cfoutput></cfsavecontent>

	<cfset FileWrite(CompPath,CompXml)>
	
	<cfset oServiceFactory.loadXml(CompPath)>
	<cfset oServiceFactory.setScope(sScope)>
	<cfset oServiceFactory.getAllServices()>

	<cfset assertEquals("value1",sScope.Comp.getValue(),"Service Factory failed to correctly set a hard-coded value from the XML.")>


<cfsavecontent variable="CompXml"><cfoutput>
<site>
	<components>
		<component name="Comp" path="ExampleWithInitArg">
			<argument name="Value" value="Value2" />
		</component>
	</components>
</site>
</cfoutput></cfsavecontent>

	<cfset FileWrite(CompPath,CompXml)>

	<cfset oServiceFactory = CreateObject("component","admin.meta.model.ServiceFactory").init()>
	
	<cfset oServiceFactory.loadXml(CompPath)>
	<cfset oServiceFactory.setScope(sScope)>

	<cfset oServiceFactory.removeServices("Comp")>

	<cfset oServiceFactory.getAllServices()>

	<cfset assertEquals("Value2",sScope.Comp.getValue(),"Service Factory failed to pass the changed value from the XML.")>

	<cfset FileDelete(CompPath)>

</cffunction>

<cffunction name="shouldPassValueWithCase" access="public" returntype="void" output="no"
	hint="Service Factory should pass in values with the original case."
>
	<cfset var oServiceFactory = CreateObject("component","admin.meta.model.ServiceFactory").init()>

	<cfset oServiceFactory.loadXml('<site>
	<components>
		<component name="Comp" path="ExampleWithInitArg">
			<argument name="Value" value="Value1" />
		</component>
	</components>
</site>')>
	<cfset oServiceFactory.getAllServices()>

	<cfset AssertEqualsCase('Value1',oServiceFactory.Comp.getValue(),"Service Factory failed to correctly pass in the case of a value argument.")>
	
</cffunction>

<cffunction name="assertCompLoad" access="private" returntype="void" output="no">
	<cfargument name="CompName" type="string" required="true">
	<cfargument name="ArgList" type="string" required="true">
	<cfargument name="Message" type="string" required="true">
	
	<cfset var oComp = 0>
	
	<cfset loadXML()>
	
	<cfset oComp = Variables.ServiceFactory.getService(Arguments.CompName)>
	
	<cfset assertTrue(isDefined("oComp"),Arguments.Message)>
	<cfset assertTrue(StructKeyExists(oComp,"Args"),Arguments.Message)>
	<cfset assertEquals(ListSort(ArgList,"textnocase"),ListSort(StructKeyList(oComp.Args),"textnocase"),Arguments.Message)>
	
</cffunction>

<cffunction name="getXML" access="private" returntype="string" output="no">
	<cfset var TestXML = "">
	
	<cfsavecontent variable="TestXML"><cfinclude template="components.xml"></cfsavecontent>
	
	<cfreturn TestXML>
</cffunction>

<cffunction name="loadXML" access="private" returntype="void" output="no">
	
	<cfset Variables.ServiceFactory.loadXml(getXML())>
	
</cffunction>

</cfcomponent>