<cfcomponent DisplayName="Service Factory" output="no">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="Config" type="struct" required="no">
	<cfargument name="Components" type="string" required="no">
	
	<cfset var BeginTime = getTickCount()>
	
	<cfset Variables.UUID = CreateUUID()>
	<cfset Variables.cache = StructNew()>
	<cfset Variables.metadata = StructNew()>
	<cfset Variables.sConfig = StructNew()>
	<cfset Variables.xComponents = XmlNew()>
	<cfset Variables.xLCaseComponents = XmlNew()>
	<cfset Variables.sScope = StructNew()>
	<cfset Variables.sInternalCache = StructNew()>
	
	<cfset Variables.attorder = "name,component,config,arg">
	
	<cfif StructKeyExists(Arguments,"Config")>
		<cfset loadConfig(Arguments.Config)>
	</cfif>
	
	<cfif StructKeyExists(Arguments,"Components")>
		<cfset loadXml(Arguments.Components)>
	</cfif>
	
	<!--- Just for backwards compatibility with AppLoader --->
	<cfset This.getComponentsXML = getXml()>
	<cfset This["register"] = registerServices>
	
	<cfset Variables.LoadTime = getTickCount() - BeginTime>
	
	<cfset loadServiceFactory()>
	
	<cfreturn This>
</cffunction>

<cffunction name="checkRefresh" access="public" returntype="boolean" output="no" hint="I indicate if the given component would be refreshed based on the given list">
	<cfargument name="components" type="string" required="yes">
	<cfargument name="refresh" type="string" required="yes">
	
	<cfset var result = false>
	<cfset var comp = "">
	<cfset var dependants = "">
	
	<cfif isBoolean(Arguments.refresh)>
		<cfreturn Arguments.refresh>
	<cfelseif Len(Arguments.refresh)>
		<!--- See if the component is in the list itself. --->
		<cfloop index="comp" list="#Arguments.Components#">
			<cfif ListFindNoCase(Arguments.refresh,comp)>
				<cfreturn True>
			</cfif>
		</cfloop>
		<cfset dependants = getDependants("CompWithComp2",true)>
		<cfloop index="comp" list="#Arguments.Components#">
			<cfif ListFindNoCase(dependants,comp)>
				<cfreturn True>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getConfig" access="public" returntype="any" output="no" hint="I return the requested config value.">
	<cfargument name="name" type="string" required="no">
	
	<cfif StructKeyExists(Variables,"oConfig")>
		<cfif StructKeyExists(Arguments,"name")>
			<cfreturn Variables.oConfig.getSetting(Arguments.name)>
		<cfelse>
			<cfreturn Variables.oConfig.dump()>
		</cfif>
	<cfelse>
		<cfif StructKeyExists(Arguments,"name")>
			<cfreturn Variables.sConfig[Arguments.name]>
		<cfelse>
			<cfreturn Variables.sConfig>
		</cfif>
	</cfif>
</cffunction>

<cffunction name="getFileLastUpdated" access="public" returntype="date" output="no" hint="I tell when the file for a service was last updated.">
	<cfargument name="FilePath" type="string" required="no">
	
	<!--- Thanks Kevan Stannard! http://blog.stannard.net.au/2006/10/03/getting-a-files-timestamp-using-coldfusion/ --->
	
	<cfset var fileObj = CreateObject("java","java.io.File").init(Arguments.FilePath)>
	<cfset var result = CreateObject("java","java.util.Date").init(fileObj.lastModified())>
	
	<cfreturn result>
</cffunction>

<cffunction name="getXml" access="public" returntype="any" output="no" hint="I return the XML used to define the components.">
	<cfreturn Variables.xComponents>
</cffunction>

<cffunction name="loadService" access="public" returntype="any" output="no" hint="I load up the requested service component if it is defined.">
	<cfargument name="ServiceName" type="string" required="no">
	
	<cfset var result = true>
	
	<cfif NOT StructKeyExists(Variables.cache,Arguments.ServiceName)>
		<cfif hasService(Arguments.ServiceName)>
			<cfset getService(Arguments.ServiceName)>
		<cfelse>
			<cfset result = false>
		</cfif>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="loadXml" access="public" returntype="any" output="no" hint="I load the component information from XML.">
	<cfargument name="ComponentsXml" type="string" required="no">
	
	<cfset var CompXml = "">
	
	<cfif NOT isXml(Arguments.ComponentsXml)>
		<cfif FileExists(Arguments.ComponentsXml)>
			<cftry>
				<cffile action="read" file="#Arguments.ComponentsXml#" variable="CompXml">
				<cfset Variables.ComponentsPath = Arguments.ComponentsXml>
				<cfset Arguments.ComponentsXml = CompXml>
			<cfcatch>
				<cfset throwError("Unable to read the file for loadXml.","loadXml:UnableToReadFile")>
			</cfcatch>
			</cftry>
			<cfif NOT isXml(Arguments.ComponentsXml)>
				<cfset throwError("The file path for loadXml must point to a file with valid XML.","loadXml:FileNotXml")>
			</cfif>
		<cfelse>
			<cfset throwError("The loadXml method of ServiceFactory requires an XML string or the path to an XML file.","loadXml:NoXmlNoFile")>
		</cfif>
	</cfif>
	
	<!--- Assert: Should be no way to get this far without valid XML --->
	<cfset Variables.xComponents = XmlParse(Arguments.ComponentsXml)>
	<cfset Variables.xLCaseComponents = XmlParse(LCase(Arguments.ComponentsXml))>
	
</cffunction>

<cffunction name="callMethod" access="public" returntype="any" output="false" hint="">
	<cfargument name="component" type="string" required="yes">
	<cfargument name="method" type="string" required="yes">
	<cfargument name="args" type="struct" required="yes">
	
	<cfset var comp = arguments.component>
	<cfset var meth = arguments.method>
	<cfset var sArgs = Arguments.Args>
	<cfset var result = 0>
	<cfset var isService = true>
	<cfset var oService = 0>
	
	<cfset StructDelete(sArgs,"component")>
	<cfset StructDelete(sArgs,"method")>
	<cfset StructDelete(sArgs,"arguments")>
	
	<!--- Just to make sure the component is loaded, if it exists --->
	<cfset isService = loadService(comp)>
	
	<cfif isService>
		<cfset oService = getService(comp)>
		<cfif StructKeyExists(oService,meth)>
			<cfinvoke
				returnvariable="result"
				component="#oService#"
				method="#meth#"
				argumentCollection="#sArgs#"
			>
			</cfinvoke>
			
			<cfif isDefined("result")>
				<cfreturn result>
			</cfif>
		</cfif>
	</cfif>
</cffunction>

<cffunction name="ditchScope" access="public" returntype="any" output="no" hint="I disconnect Service Factory from the scope.">
	
	<cfset var key = "">
	
	<cfloop item="key" collection="#Variables.cache#">
		<cfset StructDelete(Variables.sScope,key)>
	</cfloop>
	
	<cfset Variables.sScope = StructNew()>
	
</cffunction>

<cffunction name="seedServices" access="public" returntype="struct" output="no" hint="I return all of the service components as a structure.">
	
	<cfif StructKeyExists(Variables,"DateSeededBegin") AND NOT StructKeyExists(Variables,"DateSeededEnd")>
		<!--- If Service Factory is loading all services, single thread the request. --->
		Site is currently loading. Please check back in a few seconds...
		<cfabort>
	</cfif>

	<cfif NOT StructKeyExists(Variables,"DateSeededEnd")>
		<cfset Variables.DateSeededBegin = now()>
		<cftry>
			<cfset getAllServices()>
		<cfcatch>
			<cfset StructDelete(Variables,"DateSeededBegin")>
			<cfrethrow>
		</cfcatch>
		</cftry>
		<cfset Variables.DateSeededEnd = now()>
	</cfif>
	
	<cfreturn Variables.cache>
</cffunction>

<cffunction name="getAllServices" access="public" returntype="struct" output="no" hint="I return all of the service components as a structure.">
	
	<cfset var ii = 0>
	<cfset var xComponent = 0>
	
	<cflock name="#getLockNamePrefix()#:GetAllServices" timeout="30">
		<cfloop index="ii" from="1" to="#ArrayLen(Variables.xComponents.site.components.component)#">
			<cfset xComponent = Variables.xComponents.site.components.component[ii]>
			<cfif StructKeyExists(xComponent.XmlAttributes,"name")>
				<cfset getService(xComponent.XmlAttributes["name"])>
			</cfif>
		</cfloop>
	</cflock>
	
	<cfreturn Variables.cache>
</cffunction>

<cffunction name="getService" access="public" returntype="any" output="no" hint="I return the requested service component.">
	<cfargument name="ServiceName" type="string" required="yes">
	
	<cfset var axServices = 0>
	<cfset var sArgs = 0>
	<cfset var ii = 0>
	<cfset var doLoad = true>
	<cfset var doLoadTemp = true>
	<cfset var oService = 0>
	<cfset var BeginTime = 0>
	<cfset var EndTime = 0>
	<cfset var sObserverArgs = 0>
	<cfset var ArgLen = 0>
	
	<cfif Arguments.ServiceName EQ "ServiceFactory">
		<cfset loadServiceFactory()>
		<cfreturn This>
	</cfif>
	
	<cfif NOT StructKeyExists(Variables.cache,Arguments.ServiceName)>
		<cfset axServices = XmlSearch(Variables.xComponents,"//component[translate(@name,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')='#LCase(Arguments.ServiceName)#']")>
			<cfif ArrayLen(axServices) AND StructKeyExists(axServices[1].XmlAttributes,"path") AND Len(axServices[1].XmlAttributes["path"])>
			<cfset Variables.cache[Arguments.ServiceName] = CreateObject("component",axServices[1].XmlAttributes["path"])>
			<!--- Make Init Arguments --->
			<cfset sArgs = StructNew()>
			<cfif StructKeyExists(axServices[1],"argument")>
				<cfset ArgLen = ArrayLen(axServices[1].argument)>
				<cfloop index="ii" from="1" to="#ArgLen#">
					<!--- Separate variable so that we won't have to worry about a short circuit --->
					<cfset doLoadTemp = makeInitArg(Arguments.ServiceName,sArgs,axServices[1].argument[ii].XmlAttributes)>
					<cfset doLoad = doLoad AND doLoadTemp>
				</cfloop>
			</cfif>
			<cfif doLoad>
				
				<!--- Notify Observer (if available) --->
				<cfif StructKeyExists(Variables.cache,"Observer") AND StructKeyExists(Variables.cache["Observer"],"announceEvent")>
					<cfset sObserverArgs = StructNew()>
					<cfset sObserverArgs["ServiceName"] = Arguments.ServiceName>
					<cftry>
						<cfset Variables.cache.Observer.announceEvent(EventName="ServiceFactory:beforeLoadService",Args=sObserverArgs)>
					<cfcatch>
					</cfcatch>
					</cftry>
				</cfif>

				<!--- Initialize service (and track init time) --->
				<cfset BeginTime = getTickCount()>
				<cfset oService = initService(ServiceName=Arguments.ServiceName,sArgs=sArgs)>
				<cfset EndTime = getTickCount()>
				
				<cfset storeServiceReference(Arguments.ServiceName,oService)>
				<cfset Variables.metadata[Arguments.ServiceName]["DateLoaded"] = now()>
				<cfset Variables.metadata[Arguments.ServiceName]["LoadTime"] = EndTime - BeginTime>
				
				<!--- Notify Observer (if available) --->
				<cfif StructKeyExists(Variables.cache,"Observer") AND StructKeyExists(Variables.cache["Observer"],"announceEvent")>
					<cfset sObserverArgs = StructNew()>
					<cfset sObserverArgs["ServiceName"] = Arguments.ServiceName>
					<cfset sObserverArgs["Service"] = Variables.cache[Arguments.ServiceName]>
					<cfset sObserverArgs["Meta"] = Variables.metadata[Arguments.ServiceName]>
					<cfset Variables.cache.Observer.announceEvent(EventName="ServiceFactory:loadService",Args=sObserverArgs)>
				</cfif>
				
			<cfelse>
				<!--- If loading of component was skipped, ditch all references to it so that no stale references will be used. --->
				<cfset StructDelete(Variables.cache,Arguments.ServiceName)>
				<cfset StructDelete(This,Arguments.ServiceName)>
				<cfset StructDelete(Variables.sScope,Arguments.ServiceName)>
				<cfset StructDelete(Variables.metadata,Arguments.ServiceName)>
				<cfreturn>
			</cfif>
		<cfelse>
			<cfset throwError("Unable to find service '#Arguments.ServiceName#'.")>
		</cfif>
	</cfif>
	
	<cfreturn Variables.cache[Arguments.ServiceName]>
</cffunction>

<cffunction name="getServiceByPath" access="public" returntype="any" output="no" hint="I return service for the given path.">
	<cfargument name="Path" type="string" required="no">
	
	<cfset var oResult = 0>
	<cfset var sService = 0>
	
	<cfif hasServicePath(Arguments.Path)>
		<cfset oResult = getService(getServiceNameByPath(Arguments.Path))>
		<cfreturn oResult>
	</cfif>
	
	<cfset oResult = CreateObject("component",Arguments.Path)>
	<cfset sService = getMetaData(oResult.init)>
	
	<cfif
				StructKeyExists(oResult,"init")
			AND	NOT ArrayLen(sService["Parameters"])
			AND NOT (
						StructKeyExists(oResult,"Properties")
					AND	ArrayLen(oResult["Properties"])
				)
	>
		<cfreturn oResult>
	<cfelse>
		<cfset throwError(Message="Service Factory was unable to instantiate the service for #Arguments.Path#. It either has properties, or no init method that doesn't have arguments.")>
	</cfif>
	
	<cfreturn oResult>
</cffunction>

<cffunction name="getServiceInfo" access="public" returntype="struct" output="no" hint="I return information about the requested service component.">
	<cfargument name="ServiceName" type="string" required="no">
	<cfargument name="WithLastUpdated" type="boolean" default="false">
	
	<cfset var sResult = 0>
	
	<cfset getService(Arguments.ServiceName)>
	
	<cfset sResult = StructCopy(Variables.metadata[Arguments.ServiceName])>
	<cfif Arguments.WithLastUpdated>
		<cfset sResult["LastUpdated"] = getServiceLastUpdated(Arguments.ServiceName)>
	</cfif>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="getServiceLastUpdated" access="public" returntype="date" output="no" hint="I tell when the file for a service was last updated.">
	<cfargument name="ServiceName" type="string" required="no">
	
	<cfset getService(Arguments.ServiceName)>
	
	<cfif Arguments.ServiceName EQ "ServiceFactory" AND NOT StructKeyExists(Variables.metadata,Arguments.ServiceName)>
		<cfreturn getFileLastUpdated(getCurrentTemplatePath())>
	</cfif>
	
	<cfreturn getFileLastUpdated(Variables.metadata[Arguments.ServiceName].Path)>
</cffunction>

<cffunction name="getServicesMeta" access="public" returntype="struct" output="no" hint="I return internal metadata about services (without file updated dates).">
	
	<cfreturn Variables.metadata>
</cffunction>

<cffunction name="getServiceNameByPath" access="public" returntype="string" output="no" hint="I return the name of the service with the given path.">
	<cfargument name="Path" type="string" required="no">
	
	<cfset var result = "">
	<cfset var axServices = 0>
	
	<cfset axServices = XmlSearch(Variables.xLCaseComponents,"//component[@name][@path='#LCase(Arguments.Path)#']")>
	<cfif ArrayLen(axServices) EQ 1>
		<cfreturn axServices[1].XmlAttributes["name"]>
	</cfif>
	
	<cfset throwError("Unable to find service path: #Arguments.Path#")>
	
	<cfreturn False>
</cffunction>

<cffunction name="getServicesArray" access="public" returntype="array" output="no" hint="I return all of the service components as an Array.">
	
	<cfset var ii = 0>
	<cfset var xComponent = 0>
	<cfset var ServiceName = "">
	<cfset var aResult = ArrayNew(1)>
	<cfset var sService = 0>
	<cfset var xLocalComponents = 0><!--- So that we can copy to local scope in case the value changes while we are looking at it. --->
	
	<!--- The services array won't change unless more components are loaded, so cache it. --->
	<cfif NOT StructKeyExists(Variables.sInternalCache,"aServices")>
		<cflock name="#getLockNamePrefix()#:getServicesArray" timeout="30">
			<!--- Variable could have gotten set while waiting for lock. --->
			<cfif NOT StructKeyExists(Variables.sInternalCache,"aServices")>
				<cfset xLocalComponents = Variables.xComponents>
				<cfif StructKeyExists(xLocalComponents,"site") AND StructKeyExists(xLocalComponents.site,"components")>
					<cfloop index="ii" from="1" to="#ArrayLen(xLocalComponents.site.components.component)#">
						<cfset xComponent = xLocalComponents.site.components.component[ii]>
						<cfif StructKeyExists(xComponent.XmlAttributes,"name")>
							<cfset ServiceName = xComponent.XmlAttributes["name"]>
							<cfset getService(ServiceName)>
							<cfif StructKeyExists(Variables.cache,ServiceName)>
								<cfset sService = StructNew()>
								<cfset sService["name"] = ServiceName>
								<cfset ArrayAppend(aResult,sService)>
							</cfif>
						</cfif>
					</cfloop>
				</cfif>
				<cfset Variables.sInternalCache.aServices = aResult>
			</cfif>
		</cflock>
	</cfif>
	
	<cfreturn Variables.sInternalCache.aServices>
</cffunction>

<cffunction name="getSpecialService" access="public" returntype="any" output="no">
	<cfargument name="type" type="string" required="true">
	
	<cfset var oResult = 0>
	<cfset var ServiceName = getSpecialServiceName(Arguments.type)>
	
	<cfif Len(ServiceName)>
		<cfset oResult = getService(ServiceName)>
	</cfif>
	
	<cfreturn oResult>
</cffunction>

<cffunction name="getSpecialServiceName" access="public" returntype="any" output="no">
	<cfargument name="type" type="string" required="true">
	
	<cfset var axSpecialComponents = 0>
	<cfset var ii = 0>
	<cfset var service = "">

	<cfif NOT StructKeyExists(Variables.sInternalCache,"sSpecialsNames")>
		<cflock name="#getLockNamePrefix()#:sSpecialsNames:#Arguments.type#" timeout="10">
			<cfset Variables.sInternalCache["sSpecialsNames"] = StructNew()>
			<cfset axSpecialComponents = XmlSearch(variables.xLCaseComponents,"//component[string-length(@name)>0][string-length(@special)>0]")>
			<cfloop index="ii" from="1" to="#ArrayLen(axSpecialComponents)#">
				<cfset Variables.sInternalCache["sSpecialsNames"][axSpecialComponents[ii].XmlAttributes["special"]] = axSpecialComponents[ii].XmlAttributes["name"]>
			</cfloop>
		</cflock>
	</cfif>
	
	<cfif StructKeyExists(Variables.sInternalCache["sSpecialsNames"],Arguments.type)>
		<cfset service = Variables.sInternalCache["sSpecialsNames"][Arguments.type]>
	</cfif>
	
	<cfreturn service>
</cffunction>

<cffunction name="getStaleServices" access="public" returntype="struct" output="no" hint="I return a structure of services for which the files have changed since they were instantiated.">
	
	<cfset var sResult = StructNew()>
	<cfset var comp = "">
	
	<cfloop item="comp" collection="#Variables.cache#">
		<cfif getServiceLastUpdated(comp).getTime() GT Variables.metadata[comp].DateLoaded.getTime()>
			<cfset sResult[comp] = Variables.cache[comp]>
		</cfif>
	</cfloop>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="handleError" access="public" returntype="void" output="no" hint="I handle errors from missing services by reloading them.">
	<cfargument name="Exception" type="struct" required="yes">
	
	<cfset var isMissingServiceError = StructKeyExists(Exception,"Message") AND REFindNoCase("^Element \w[\d\w\.]* is undefined in a Java object of type class",Exception.Message)>
	<cfset var ServiceName = "">

	<cfif isMissingServiceError>
		<cfif StructKeyExists(Exception,"Element")>
			<cfset ServiceName = Exception.Element>
		<cfelse>
			<cfset ServiceName = Trim(REReplaceNoCase(REReplaceNoCase(Exception.Message,"^Element ","")," is undefined.*",""))>
		</cfif>

		<!--- Handle "Factory" reference --->
		<cfset ServiceName = ReReplaceNoCase(ServiceName,"^Factory\.","")>

		<cfset ServiceName = ListFirst(ServiceName,".")>

		<cfif Len(ServiceName) AND hasService(ServiceName)>
			<cfset loadService(ServiceName)>
			<cfset storeServiceReference(ServiceName,getService(ServiceName))>
		</cfif>

	</cfif>

</cffunction>

<cffunction name="hasConfig" access="public" returntype="boolean" output="no" hint="I indicate if the given service exists (or could exist).">
	<cfargument name="name" type="string" required="yes">
	
	<cfif StructKeyExists(Variables,"oConfig")>
		<cfreturn Variables.oConfig.exists(Arguments.name)>
	<cfelse>
		<cfreturn StructKeyExists(Variables.sConfig,Arguments.name)>
	</cfif>
</cffunction>

<cffunction name="hasService" access="public" returntype="boolean" output="no" hint="I indicate if the given service exists (or could exist).">
	<cfargument name="ServiceName" type="string" required="no">
	
	<cfset var result = false>
	<cfset var axServices = 0>
	
	<cfif Arguments.ServiceName EQ "ServiceFactory">
		<cfreturn True>
	</cfif>
	
	<cfif StructKeyExists(Variables.cache,Arguments.ServiceName)>
		<cfreturn true>
	</cfif>
	
	<cfset axServices = XmlSearch(Variables.xLCaseComponents,"//component[@name='#LCase(Arguments.ServiceName)#']")>
	<cfif ArrayLen(axServices)>
		<cfreturn true>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="hasServiceLoaded" access="public" returntype="boolean" output="no" hint="I indicate if the given service is already loaded.">
	<cfargument name="ServiceName" type="string" required="no">
	
	<cfreturn StructKeyExists(Variables.cache,Arguments.ServiceName)>
</cffunction>

<cffunction name="hasServicePath" access="public" returntype="boolean" output="no" hint="I indicate if the given service path is defined once (and only once).">
	<cfargument name="Path" type="string" required="no">
	
	<cfset var result = false>
	<cfset var axServices = 0>
	
	<cfif Arguments.Path EQ "ServiceFactory">
		<cfreturn True>
	</cfif>
	
	<cfset axServices = XmlSearch(Variables.xLCaseComponents,"//component[@path='#LCase(Arguments.Path)#']")>
	<cfif ArrayLen(axServices) EQ 1>
		<cfreturn true>
	</cfif>
	
	<cfreturn False>
</cffunction>

<cffunction name="hasSpecialService" access="public" returntype="any" output="no">
	<cfargument name="type" type="string" required="true">
	
	<cfreturn Len(getSpecialServiceName(arguments.type))>
</cffunction>

<cffunction name="loadConfig" access="public" returntype="any" output="no" hint="I load the configuration arguments that will be used as data for the components.">
	<cfargument name="Config" type="any" required="yes">
	
	<cfset var key = "">
	
	<cfif isObject(Arguments.Config)>
		<cfif StructKeyExists(Arguments.Config,"dump") AND StructKeyExists(Arguments.Config,"getsetting")>
			<cfset Variables.oConfig = Arguments.Config>
			<cfset This["Config"] = Variables.oConfig> 
			<cfif StructCount(Variables.sConfig)>
				<cfloop item="key" collection="#Variables.sConfig#">
					<cfset Variables.oConfig.paramSetting(key,Variables.sConfig[key])>
				</cfloop>
			</cfif>
			<cfset StructAppend(Variables.sConfig,Variables.oConfig.dump(),true)>
		<cfelse>
		</cfif>
	<cfelseif StructKeyExists(Arguments,"Config")>
		<cfset StructAppend(Variables.sConfig,Arguments.Config,true)>
	</cfif>
	
</cffunction>

<cffunction name="refreshService" access="public" returntype="any" output="no" hint="I refresh the given service component.">
	<cfargument name="ServiceName" type="string" required="no">
	
	<cfset var dependants = "">
	<cfset var comp = "">
		
	<!--- Remove the service --->
	<cfset removeService(Arguments.ServiceName)>
	
	<!--- Refresh missing services --->
	<cfif NOT StructKeyExists(Variables.cache,Arguments.ServiceName)>
		<cfset getService(Arguments.ServiceName)>
		
		<cfset dependants = getDependants(Arguments.ServiceName)>
		
		<cfloop index="comp" list="#dependants#">
			<cfset getService(comp)>
		</cfloop>
	</cfif>
	
	<cfreturn Variables.cache>
</cffunction>

<cffunction name="refreshServices" access="public" returntype="any" output="no" hint="I refresh the given services.">
	<cfargument name="Services" type="string" required="no">

	<cfset removeServices(Arguments.Services)>

	<cfset getAllServices()>

	<cfreturn Variables.cache>
</cffunction>

<cffunction name="refreshStaleServices" access="public" returntype="struct" output="no" hint="I refresh all stale services (those )for which the files have changed since they were instantiated).">
	
	<cfset var StaleServices = StructKeyList(getStaleServices())>
	<cfset var comp = "">
	<cfset var dependants = "">
	<cfset var dep = "">
	
	<cfloop list="#StaleServices#" index="comp">
		<cfset refreshService(comp)>
		<cfset dependants = getDependants(comp)>
		
		<cfloop index="dep" list="#dependants#">
			<cfset refreshService(dep)>
		</cfloop>
	</cfloop>
	
	<cfreturn Variables.cache>
</cffunction>

<cffunction name="registerServices" access="public" returntype="any" output="no" hint="I register new services.">
	<cfargument name="Components" type="string" required="no">
	<cfargument name="overwrite" type="boolean" default="false">
	
	<cfset var xSys = variables.xComponents>
	<cfset var ComponentsXml = ToString(variables.xComponents)>
	<cfset var MyComponentXML = "">
	<cfset var xComponent = XmlParse(Trim(arguments.Components))>
	<cfset var xNewComponents = XmlSearch(xComponent,"//component")>
	<cfset var RootPath = "">
	<cfset var dirdelim = CreateObject("java", "java.io.File").separator>
	
	<cfset var jj = 0>
	<cfset var ii = 0>
	<cfset var kk = 0>
	<cfset var exists = false>
	<cfset var isUpdated = false>
	
	<cfset var writeComp = arguments.overwrite>
	
	<cfif StructKeyExists(variables.sConfig,"RootPath") AND Len(Trim(variables.sConfig.RootPath))>
		<cfset RootPath = getConfig("RootPath")>
	<cfelse>
		<cfset RootPath = ExpandPath("/")>
	</cfif>
	
	<cfloop index="jj" from="1" to="#ArrayLen(xNewComponents)#" step="1">
		<cfset xComponent = xNewComponents[jj]>
		<cfset MyComponentXML = XmlHumanReadable(xComponent,variables.attorder)>
		
		<cfset exists = false>
		
		<!--- Check to see if this component already exists --->
		<cfif StructKeyExists(xSys.site.components,"XmlChildren") AND ArrayLen(xSys.site.components.XmlChildren)>
			<cfloop index="ii" from="1" to="#ArrayLen(xSys.site.components.XmlChildren)#" step="1">
				<cfset writeComp = arguments.overwrite>
				<cfif StructKeyExists(xSys.site.components.XmlChildren[ii].XmlAttributes,"name")>
					<cfif xSys.site.components.XmlChildren[ii].XmlAttributes.name eq xComponent.XmlAttributes.name>
						<cfif xSys.site.components.XmlChildren[ii].XmlAttributes.path eq xComponent.XmlAttributes.path>
							<cfset exists = true>
						<cfelse>
							<cfif arguments.overwrite>
								<cfset xSys.site.components.XmlChildren[ii].XmlAttributes.path = xComponent.XmlAttributes.path>
								<cfset isUpdated = true>
								<cfset exists = true>
							<cfelseif
									FileExists( ListAppend(RootPath,ListChangeDelims(xComponent.XmlAttributes.path,dirdelim,'.'),dirdelim)  & ".cfc" )
								AND	NOT FileExists( ListAppend(RootPath,ListChangeDelims(xSys.site.components.XmlChildren[ii].XmlAttributes.path,dirdelim,'.'),dirdelim) & ".cfc" )
							>
								<cfset xSys.site.components.XmlChildren[ii].XmlAttributes.path = xComponent.XmlAttributes.path>
								<cfset isUpdated = true>
								<cfset exists = true>
								<cfset writeComp = true>
							<cfelse>
								<cfthrow message="Another component of the same name (#xComponent.XmlAttributes.name#) already exists (existing path: #xSys.site.components.XmlChildren[ii].XmlAttributes.path#; new path: #xComponent.XmlAttributes.path#).">
							</cfif>
						</cfif>
						<cfif writeComp>
							<!--- <cfset xSys.site.components.XmlChildren[ii].XmlChildren = xComponent.XmlChildren> --->
							<cfset xSys.site.components.XmlChildren[ii].XmlChildren = ArrayNew(1)>
							<cfscript>
							while ( ArrayLen(xSys.site.components.XmlChildren[ii].XmlChildren) ) {
								ArrayDeleteAt(xSys.site.components.XmlChildren[ii].XmlChildren,1);
							}
							</cfscript>
							<cfloop index="kk" from="1" to="#ArrayLen(xComponent.XmlChildren)#" step="1">
								<cfset xSys.site.components.XmlChildren[ii].XmlChildren[ArrayLen(xSys.site.components.XmlChildren[ii].XmlChildren)+1] = XMLElemNew(xSys,"","argument")>
								<cfset xSys.site.components.XmlChildren[ii].XmlChildren[ArrayLen(xSys.site.components.XmlChildren[ii].XmlChildren)].XmlAttributes = xComponent.XmlChildren[kk].XmlAttributes>
							</cfloop>
							<cfset isUpdated = true>
							<cfset variables.xComponents = xSys>
						</cfif>
					</cfif>
				</cfif>
			</cfloop>
		</cfif>
		
		<!--- If component doesn't exist, add it --->
		<cfif NOT exists>
			<!--- %%Need to check for existence of argument variables --->
			
			<cfset ComponentsXml = ReplaceNoCase(ComponentsXml, "</components>", "#MyComponentXML#</components>")>
			<cfset xSys = XmlParse(ComponentsXml)>
			<cfset variables.xComponents = xSys>
			<cfset isUpdated = true>
		</cfif>
		
	</cfloop>
	
	<cfif isUpdated AND StructKeyExists(Variables,"ComponentsPath") AND FileExists(Variables.ComponentsPath)>
		<cffile action="write" file="#Variables.ComponentsPath#" output="#XmlHumanReadable(ComponentsXml)#">
	</cfif>
	
	<cfset loadXml(Variables.ComponentsPath)>
	<cfset getAllServices()>
	
</cffunction>

<cffunction name="removeService" access="public" returntype="any" output="no" hint="I remove the given service component from the internal cache.">
	<cfargument name="ServiceName" type="string" required="no">
	
	<cfset var dependants = "">
	<cfset var comp = "">
	
	<!--- Remove the service --->
	<cfif StructKeyExists(Variables.cache,Arguments.ServiceName)>
		<cfset StructDelete(Variables.cache,Arguments.ServiceName)>
		<cfset StructDelete(This,Arguments.ServiceName)>
		<cfset StructDelete(Variables.sScope,Arguments.ServiceName)>
		<cfset StructDelete(Variables.metadata,Arguments.ServiceName)>
		
		<!--- Only go down the rabbit whole if this hasn't been removed already to avoid infinite looping --->
		
		<cfset dependants = getDependants(Arguments.ServiceName)>
		
		<cfloop index="comp" list="#dependants#">
			<cfset removeService(comp)>
		</cfloop>
	</cfif>
	
	<cfset StructClear(Variables.sInternalCache)>
	
</cffunction>

<cffunction name="removeServices" access="public" returntype="any" output="no" hint="I remove the given service components from the internal cache.">
	<cfargument name="Services" type="string" required="no">
	
	<cfset var comp = "">
	
	<!--- True removes all services, otherwise remove each from the list. --->
	<cfif Arguments.Services EQ True>
		<cfif StructCount(Variables.sScope)>
			<cfloop item="comp" collection="#Variables.cache#">
				<cfset StructDelete(Variables.sScope,comp)>
			</cfloop>
		</cfif>
		<cfset StructClear(Variables.cache)>
		<cfset StructClear(Variables.metadata)>
	<cfelseif Len(Arguments.Services)>
		<cfloop index="comp" list="#Arguments.Services#">
			<cfset removeService(comp)>
		</cfloop>
	</cfif>
	
	<cfset StructClear(Variables.sInternalCache)>
	
	<cfreturn Variables.cache>
</cffunction>

<cffunction name="setArgs" access="public" returntype="any" output="no" hint="I load the configuration arguments that will be used as data for the components.">
	
	<cfset loadConfig(Arguments)>
	
</cffunction>

<cffunction name="setScope" access="public" returntype="any" output="no" hint="I set a scope to which all service references should be copied.">
	<cfargument name="Scope" type="struct" required="yes">
	
	<cfset var key = "">
	
	<cfset Variables.sScope = Arguments.Scope>
	
	<cfloop item="key" collection="#Variables.sScope#">
		<cfif hasService(key) AND NOT hasServiceLoaded(key)>
			<cfset storeServiceReference(key,Variables.sScope[key])>
		</cfif>
	</cfloop>
	
	<cfloop item="key" collection="#Variables.cache#">
		<cfif NOT StructKeyExists(Variables.sScope,key)>
			<cfset Variables.sScope[key] = Variables.cache[key]>
		</cfif> 
	</cfloop>
	
	<cfset StructClear(Variables.sInternalCache)>
	
</cffunction>

<cffunction name="getDependants" access="public" returntype="string" output="no" hint="I get a list of services that directly depend on the given service.">
	<cfargument name="ServiceName" type="string" required="no">
	<cfargument name="recurse" type="boolean" default="false">
	<cfargument name="listed" type="string" default="">
	
	<cfset var axDependants = 0>
	<cfset var ii = 0>
	<cfset var service = 0>
	<cfset var comp = 0>
	<cfset var result = Arguments.listed>
	
	<cfloop index="service" list="#Arguments.ServiceName#">
		<!--- Find services dependent on this service with component attribute --->
		<cfset axDependants = XmlSearch(Variables.xLCaseComponents,"//component[@name][argument[@component='#LCase(service)#']]")>
		
		<cfloop index="ii" from="1" to="#ArrayLen(axDependants)#">
			<cfset comp = axDependants[ii].XmlAttributes["name"]>
			<cfif NOT ListFindNoCase(result,comp)>
				<cfset result = ListAppend(result,comp)>
				<cfif Arguments.recurse>
					<cfset result = getDependants(comp,true,result)>
				</cfif>
			</cfif>
		</cfloop>

		<!--- Find services dependent on this service with name attribute only --->
		<cfset axDependants = XmlSearch(Variables.xLCaseComponents,"//component[@name][argument[@name='#LCase(service)#']]")>
		
		<cfloop index="ii" from="1" to="#ArrayLen(axDependants)#">
			<cfif
				NOT (
							StructKeyExists(axDependants[ii].XmlAttributes,"component")
						OR	StructKeyExists(axDependants[ii].XmlAttributes,"value")
						OR	StructKeyExists(axDependants[ii].XmlAttributes,"config")
						OR	StructKeyExists(axDependants[ii].XmlAttributes,"arg")
				)
			>
				<cfset comp = axDependants[ii].XmlAttributes["name"]>
				<cfif NOT ListFindNoCase(result,comp)>
					<cfset result = ListAppend(result,comp)>
					<cfif Arguments.recurse>
						<cfset result = getDependants(comp,true,result)>
					</cfif>
				</cfif>
			</cfif>
		</cfloop>

	</cfloop>
	
	<cfreturn result>
</cffunction>

<cffunction name="getLockNamePrefix" access="private" returntype="string" output="no" hint="I return the prefix for locks on this instance.">
	<cfreturn "ServiceFactory(#Variables.UUID#)">
</cffunction>

<cffunction name="initService" access="private" returntype="any" output="false" hint="">
	<cfargument name="ServiceName" type="string" required="no">
	<cfargument name="sArgs" type="struct" required="no">
	
	<cfset var oService = 0>
	
	<cflock name="#getLockNamePrefix()#:Init:#Arguments.ServiceName#" timeout="30" throwontimeout="true">
		<cfset oService = Variables.cache[Arguments.ServiceName].init(ArgumentCollection=sArgs)>
	</cflock>
	
	<cfreturn oService>
</cffunction>

<cffunction name="loadServiceFactory" access="private" returntype="any" output="no" hint="I put a reference to ServiceFactory as a servicee within Service Factory.">
	
	<!--- Ability to pass ServiceFactory into other components (not recommended) --->
	<cfif NOT StructKeyExists(Variables.cache,"ServiceFactory")>
		<cfset Variables.cache["ServiceFactory"] = This>
		<cfset Variables.sScope["ServiceFactory"] = This>
	</cfif>
	<cfif NOT StructKeyExists(Variables.metadata,"ServiceFactory")>
		<cfset Variables.metadata["ServiceFactory"] = getMetaData(variables.cache["ServiceFactory"])>
		<cfset Variables.metadata["ServiceFactory"]["DateLoaded"] = now()>
		<cfset Variables.metadata["ServiceFactory"]["LoadTime"] = Variables.LoadTime>
	</cfif>
	
</cffunction>

<cffunction name="makeInitArg" access="private" returntype="boolean" output="no" hint="I make init arguments for a component. Return true/false on whether we should load this component.">
	<cfargument name="ServiceName" type="string" required="no">
	<cfargument name="sArgs" type="struct" required="yes">
	<cfargument name="sAttribs" type="any" required="yes">
	
	<cfset var result = true>
	<cfset var str = "">
	
	<cfif StructKeyExists(Arguments.sAttribs,"component")>
		<cfset str = 'component="#sAttribs.component#"'>
		<cfif hasService(Arguments.sAttribs["component"])>
			<cfset Arguments.sArgs[Arguments.sAttribs["name"]] = getService(Arguments.sAttribs["component"])>
		</cfif>
	<cfelseif StructKeyExists(Arguments.sAttribs,"arg")>
		<cfset str = 'arg="#sAttribs.arg#"'>
		<cfif hasConfig(Arguments.sAttribs["arg"])>
			<cfset Arguments.sArgs[Arguments.sAttribs["name"]] = getConfig(Arguments.sAttribs["arg"])>
		</cfif>
	<cfelseif StructKeyExists(Arguments.sAttribs,"config")>
		<cfset str = 'config="#Arguments.sAttribs.config#"'>
		<cfif hasConfig(Arguments.sAttribs["config"])>
			<cfset Arguments.sArgs[Arguments.sAttribs["name"]] = getConfig(Arguments.sAttribs["config"])>
		</cfif>
	<cfelseif StructKeyExists(Arguments.sAttribs,"value")>
		<cfset str = 'value="#sAttribs.value#"'>
		<cfset Arguments.sArgs[Arguments.sAttribs["name"]] = Arguments.sAttribs["value"]>
	<cfelse>
		<cfset str = 'name="#Arguments.sAttribs.name#"'>
		<cfif hasService(Arguments.sAttribs["name"])>
			<cfset Arguments.sArgs[Arguments.sAttribs["name"]] = getService(Arguments.sAttribs["name"])>
		<cfelseif hasConfig(Arguments.sAttribs["name"])>
			<cfset Arguments.sArgs[Arguments.sAttribs["name"]] = getConfig(Arguments.sAttribs["name"])>
		</cfif>
	</cfif>
	<cfif NOT StructKeyExists(Arguments.sArgs,Arguments.sAttribs["name"])>
		<cfif StructKeyExists(Arguments.sAttribs,"ifmissing")>
			<cfif Arguments.sAttribs.ifmissing EQ "skiparg">
				<!--- Do nothing, just skip the argument --->
			<cfelseif sAttribs.ifmissing EQ "skipcomp">
				<cfset result = false>
			<cfelse>
				<cfset throwError("The service #Arguments.ServiceName# requires the argument #Arguments.sAttribs.name#, the value for which (#str#) is not available.")>
			</cfif>
		<cfelse>
			<cfset throwError("The service #Arguments.ServiceName# requires the argument #Arguments.sAttribs.name#, the value for which (#str#) is not available.")>
		</cfif>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="storeServiceReference" access="private" returntype="any" output="no">
	<cfargument name="ServiceName" type="string" required="no">
	<cfargument name="oService" type="any" required="no">
	
	<cflock name="#getLockNamePrefix()#:storeServiceReference:#ServiceName#" timeout="15">
		<!--- Store reference to service in needed spaces --->
		<cfset Variables.cache[Arguments.ServiceName] = oService>
		<cfset This[Arguments.ServiceName] = oService>
		<cfset Variables.sScope[Arguments.ServiceName] = oService>
		
		<!--- Store metadata about service (include when it was loaded and how long it took to initialize) --->
		<cfset Variables.metadata[Arguments.ServiceName] = StructCopy(getMetaData(oService))>
	</cflock>
	
</cffunction>

<cffunction name="throwError" access="private" returntype="void" output="no">
	<cfargument name="message" type="string" required="yes">
	<cfargument name="errorcode" type="string" default="">
	<cfargument name="detail" type="string" default="">
	<cfargument name="extendedinfo" type="string" default="">
	
	<cfthrow message="#arguments.message#" errorcode="#arguments.errorcode#" detail="#arguments.detail#" type="ServiceFactory" extendedinfo="#arguments.extendedinfo#">
	
</cffunction>
<cfscript>
/**
 * Formats an XML document for readability.
 * update by Fabio Serra to CR code
 * update by Steve Bryant to attribute ordering
 * 
 * @param XmlDoc 	 XML document. (Required)
 * @return Returns a string. 
 * @author Steve Bryant (steve@bryantwebconsulting.com) 
 * @version 2, March 20, 2006 
 * @version 3, March 07, 2010
 */
function XmlHumanReadable(XmlDoc) {
	var elem = "";
	var result = "";
	var tab = "	";
	var att = "";
	var ii = 0;
	var temp = "";
	var cr = createObject("java","java.lang.System").getProperty("line.separator");
	var attorder = "";
	
	if ( ArrayLen(arguments) GT 1 AND isSimpleValue(arguments[2]) ) {
		attorder = arguments[2];
	}
	
	if ( isSimpleValue(XmlDoc) ) {
		XmlDoc = XmlParse(XmlDoc);
	}
	
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
		for ( ii=1; ii LTE ListLen(attorder); ii=ii+1 ) {
			att = ListGetAt(attorder,ii);
			if ( StructKeyExists(elem.XmlAttributes,att) AND NOT ( att EQ "xmlns" AND elem.XmlAttributes[att] EQ "" ) ) {
				result = '#result# #att#="#XmlFormat(elem.XmlAttributes[att])#"';
			}
		}
		for ( att in elem.XmlAttributes ) {
			if ( NOT ( att EQ "xmlns" AND elem.XmlAttributes[att] EQ "" ) AND NOT ListFindNoCase(attorder,att) ) {
				result = '#result# #att#="#XmlFormat(elem.XmlAttributes[att])#"';
			}
		}
	}
	if ( Len(elem.XmlText) OR (StructKeyExists(elem,"XmlChildren") AND ArrayLen(elem.XmlChildren)) ) {
		result = "#result#>#cr#";//Add a carriage return for text/nested elements
		if ( Len(Trim(elem.XmlText)) ) {//Add any text in this element
			result = "#result##tab##XmlFormat(Trim(elem.XmlText))##cr#";
		}
		if ( StructKeyExists(elem,"XmlChildren") AND ArrayLen(elem.XmlChildren) ) {
			for ( ii=1; ii lte ArrayLen(elem.XmlChildren); ii=ii+1 ) {
				temp = Trim(XmlHumanReadable(elem.XmlChildren[ii],attorder));
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