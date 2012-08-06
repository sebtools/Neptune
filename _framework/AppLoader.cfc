<!--- 1.0 Beta 2 (Build 26) --->
<!--- Last Updated: 2012-08-05 --->
<!--- Information: sebtools.com --->
<!--- Created by Steve Bryant 2005-08-19 --->
<cfcomponent displayname="Component Loader" output="false">
<cfset cr = "
">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="SysXML" type="string" required="no">
	<cfargument name="XmlFilePath" type="string" required="no">
	<cfargument name="Proxy" type="any" required="no">
	
	<cfset variables.instance = StructNew()>
	<cfset variables.args = StructNew()>
	
	<cfif StructKeyExists(request,"Apploader_Args") AND isStruct(request.Apploader_Args)>
		<cfset variables.args = request.Apploader_Args>
	</cfif>
	
	<cfif StructKeyExists(arguments,"Proxy")>
		<cfset variables.Proxy = arguments.Proxy>
	</cfif>
	<cfif StructKeyExists(arguments,"XmlFilePath")>
		<cfset variables.XmlFilePath = arguments.XmlFilePath>
	</cfif>
	<cfif StructKeyExists(arguments,"SysXml")>
		<cfset variables.SysXml = arguments.SysXml>
	<cfelseif StructKeyExists(arguments,"XmlFilePath")>
		<cffile action="READ" file="#variables.XmlFilePath#" variable="variables.SysXml">
		<!--- <cfif Left(variables.SysXml,5) eq "<?xml">
			<cfset variables.SysXml = ListRest(variables.SysXml,cr)>
		</cfif> --->
	</cfif>
	
	<cfset variables.xSys = XmlParse(variables.SysXml)>
	
	<cfset variables.attorder = "name,component,config,arg">
	
	<cfset variables.sComponents = StructNew()>
	
	<cfreturn this>
</cffunction>

<cffunction name="getService" access="public" returntype="any" output="no">
	<cfargument name="service" type="string" required="true">
	
	<cfreturn This[arguments.service]>
</cffunction>

<cffunction name="getSpecialService" access="public" returntype="any" output="no">
	<cfargument name="type" type="string" required="true">
	
	<cfset var service = getSpecialServiceName(arguments.type)>
	<cfset var oResult = 0>
	
	<cfif StructKeyExists(This,service)>
		<cfset oResult = This[service]>
	</cfif>
	
	<cfreturn oResult>
</cffunction>

<cffunction name="getSpecialServiceName" access="public" returntype="any" output="no">
	<cfargument name="type" type="string" required="true">
	
	<cfset var aSpecialComponents = XmlSearch(variables.xSys,"//component[string-length(@name)>0][string-length(@special)>0]")>
	<cfset var service = "">
	<cfset var ii = 0>
	
	<cfloop index="ii" from="1" to="#ArrayLen(aSpecialComponents)#">
		<cfif aSpecialComponents[ii].XmlAttributes["special"] EQ Arguments.type>
			<cfset service = ListAppend(service,aSpecialComponents[ii].XmlAttributes["name"])>
		</cfif>
	</cfloop>
	
	<!---<cfif ListLen(service) NEQ 1>
		<cfset service = Arguments.type>
	</cfif>--->
	
	<cfreturn service>
</cffunction>

<cffunction name="hasSpecialService" access="public" returntype="any" output="no">
	<cfargument name="type" type="string" required="true">
	
	<cfset var service = getSpecialServiceName(arguments.type)>
	<cfset var oResult = 0>
	
	<cfreturn ( Len(service) AND StructKeyExists(This,service) )>
</cffunction>

<cffunction name="getArgs" access="public" returntype="any" output="no">
	
	<cfreturn variables.args>
</cffunction>

<cffunction name="getComponentsXML" access="public" returntype="any" output="no">
	
	<cfreturn variables.SysXml>
</cffunction>

<cffunction name="hasArgChanged" access="public" returntype="boolean" output="no">
	<cfargument name="key" type="string" required="yes">
	<cfargument name="value" type="any" required="yes">
	
	<cfset var result = false>
	
	<cfif StructKeyExists(variables.args,key) AND isSimpleValue(variables.args[key])>
		<cftry>
			<cfset result = NOT ( ToScript(variables.args[key],"a") EQ ToScript(Arguments.value,"a") )>
		<cfcatch>
			<cfset result = false>
		</cfcatch>
		</cftry>
	<cfelse>
		<cfset result = true>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="setArgs" access="public" returntype="string" output="no">
	
	<cfset var result = "">
	<cfset var key = "">
	
	<cfif StructCount(Arguments)>
		<cfloop collection="#Arguments#" item="key">
			<cfif hasArgChanged(key,Arguments[key])>
				<cftry>
					<cfset variables.args[key] = Duplicate(Arguments[key])>
				<cfcatch>
					<cfset variables.args[key] = Arguments[key]>
				</cfcatch>
				</cftry>
				<cfif isSimpleValue(variables.args[key])>
					<cfset result = ListAppend(result,key)>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getComponents" access="public" returntype="array" output="no">
	<cfargument name="SysXML" type="string" default="#variables.SysXml#">
	<cfargument name="args" type="struct" required="no">
	
	<cfset var Sys = XmlParse(arguments.SysXml,"no")>
	<cfset var arrComponents = 0>
	<cfset var arrComponentsRaw = ArrayNew(1)>
	<cfset var arrComponentsSorted = ArrayNew(1)>
	<cfset var hh = 0>
	<cfset var ii = 0>
	<cfset var jj = 0>
	<cfset var complistraw = "">
	<cfset var complist = "">
	<cfset var dependence = "">
	<cfset var sComponent = StructNew()>
	<cfset var sCompArg = 0>
	<cfset var ArgValAtts = "value,arg,config,component">
	
	<cfif StructKeyExists(arguments,"args")>
		<cfset StructAppend(variables.args, Duplicate(arguments.args), true)>
	</cfif>
	
	<cfif StructKeyExists(Sys,"site") AND StructKeyExists(Sys.site,"components") AND StructKeyExists(Sys.site.components,"component")>
		<cfset arrComponents = Sys.site.components.component>
		
		<!--- Create arrComponentsRaw --->
		<cfloop index="ii" from="1" to="#ArrayLen(arrComponents)#" step="1">
			<!---  If component has name and path --->
			<cfif StructKeyExists(arrComponents[ii].XmlAttributes,"name") AND StructKeyExists(arrComponents[ii].xmlAttributes,"path")>
				<cfset sComponent = StructNew()>
				<cfset sComponent["name"] = arrComponents[ii].xmlAttributes.name>
				<cfset sComponent["path"] = arrComponents[ii].xmlAttributes.path>
				<cfset sComponent["arguments"] = ArrayNew(1)>
				<cfset sComponent["dependencies"] = "">
				<cfset sComponent["use"] = true>
				<cfif StructKeyExists(arrComponents[ii],"XmlChildren") AND ArrayLen(arrComponents[ii].XmlChildren)>
					<cfloop index="jj" from="1" to="#ArrayLen(arrComponents[ii].XmlChildren)#" step="1">
						<cfset sCompArg = StructNew()>
						<cfset sCompArg = arrComponents[ii].XmlChildren[jj].XmlAttributes>
						<cfif NOT StructKeyExists(sCompArg,"ifmissing")>
							<cfset sCompArg["ifmissing"] = "error">
						</cfif>
						<!--- If no attribute is provided for argument value, provide one --->
						<cfif StructKeyExists(sCompArg,"name") AND NOT isListInCommon(ArgValAtts,StructKeyList(sCompArg))>
							<cfif StructKeyExists(variables.args,sCompArg.name)>
								<cfset sCompArg["config"] = sCompArg.name>
							<cfelse>
								<cfset sCompArg["component"] = sCompArg.name>
							</cfif>
						</cfif>
						<cfset sCompArg["missing"] = false>
						<cfif StructKeyExists(sCompArg,"arg") AND NOT StructKeyExists(variables.Args,sCompArg["arg"])>
							<cfset sCompArg["missing"] = true> 
						<cfelseif StructKeyExists(sCompArg,"config") AND NOT StructKeyExists(variables.Args,sCompArg["config"])>
							<cfset sCompArg["missing"] = true>
						</cfif>
						<!--- Don't use comp is config is missing and ifmissing is "skipcomp" --->
						<cfif sCompArg["missing"] AND sCompArg["ifmissing"] EQ "skipcomp">
							<cfset sComponent["use"] = false>
						</cfif>
						<!--- Add the argument unless the config is missing and the ifmissing is "skiparg" --->
						<cfif NOT ( sCompArg["missing"] AND sCompArg["ifmissing"] EQ "skiparg" )>
							<!--- Add argument --->
							<cfset StructDelete(sCompArg,"missing")>
							<cfset ArrayAppend(sComponent["arguments"],sCompArg)>
						</cfif>
						<!--- If this is a component, add it to the dependency list --->
						<cfif StructKeyExists(arrComponents[ii].XmlChildren[jj].XmlAttributes,"component")>
							<cfset sComponent["dependencies"] = ListAppend(sComponent["dependencies"],arrComponents[ii].XmlChildren[jj].XmlAttributes.component)>
						</cfif>
					</cfloop>
				</cfif>
				<!--- Don't include component if it required a missing configuration --->
				<cfif sComponent["use"]>
					<cfset StructDelete(sComponent,"use")>
					<cfset ArrayAppend(arrComponentsRaw,sComponent)>
					<cfset complist = ListAppend(complist,sComponent["name"])>
				</cfif>
			</cfif>
			<!--- /If component has name and path --->
		</cfloop>
		
		<!--- Check for orphaned components (ones whose dependents don't exist) --->
		<cfloop index="hh" from="1" to="2">
			<cfloop index="ii" from="#ArrayLen(arrComponentsRaw)#" to="1" step="-1">
				<cfif StructKeyExists(arrComponentsRaw[ii],"arguments") AND ArrayLen(arrComponentsRaw[ii]["arguments"])>
					<!--- Check arguments for components --->
					<cfloop index="jj" from="#ArrayLen(arrComponentsRaw[ii].arguments)#" to="1" step="-1">
						<cfif StructKeyExists(arrComponentsRaw[ii].arguments[jj],"component") AND Len(Trim(arrComponentsRaw[ii].arguments[jj]["component"]))>
							<!--- Take action for missing component --->
							<cfset dependence = arrComponentsRaw[ii].arguments[jj]["component"]>
							<cfif NOT ListFindNoCase(complist,dependence)>
								<cfif arrComponentsRaw[ii].arguments[jj]["ifmissing"] EQ "skiparg">
									<cfset ArrayDeleteAt(arrComponentsRaw[ii].arguments,jj)>
									<cfset arrComponentsRaw[ii]["dependencies"] = ListDeleteAt(arrComponentsRaw[ii]["dependencies"],ListFindNoCase(arrComponentsRaw[ii]["dependencies"],dependence))>
								<cfelseif arrComponentsRaw[ii].arguments[jj]["ifmissing"] EQ "skipcomp">
									<cfset complist = ListDeleteAt(complist,ListFindNoCase(complist,arrComponentsRaw[ii].name))>
									<cfset ArrayDeleteAt(arrComponentsRaw,ii)>
									<cfbreak>
								<cfelse>
									<cfthrow message="The component #arrComponentsRaw[ii].name# requires the component #dependence#, which does not exist. (#complist#)" type="AppLoader" errorcode="MissignDependentComponent">
								</cfif>
							</cfif>
						</cfif>
					</cfloop>
				</cfif>
			</cfloop>
		</cfloop>
		
		<cfscript>
		complist = "";
		//Re-sort table list based on dependencies
		jj = 1;
		while ( jj LTE ( ArrayLen(arrComponentsRaw)^2 + 1 ) AND ( ArrayLen(arrComponentsSorted) LT ArrayLen(arrComponentsRaw) ) ) {
			for (ii=1; ii LTE ArrayLen(arrComponentsRaw); ii=ii+1) {
				if ( NOT ListFindNoCase(complistraw,arrComponentsRaw[ii].name) ) {
					complistraw = ListAppend(complistraw,arrComponentsRaw[ii].name);
				}
				if (
							Len(arrComponentsRaw[ii].dependencies) EQ 0
						OR	( jj GT 1 AND isListInList(arrComponentsRaw[ii].dependencies,complist) )
					) {
					if ( NOT ListFindNoCase(complist,arrComponentsRaw[ii].name) ) {
						complist = ListAppend(complist,arrComponentsRaw[ii].name);
						ArrayAppend(arrComponentsSorted,arrComponentsRaw[ii]);
					}
					/*
					if ( ListFindNoCase(fromtablelist,table) ) {
						fromtablelist = ListDeleteAt(fromtablelist,ListFindNoCase(fromtablelist,table));
					}
					*/
				}
			}
			jj = jj + 1;
		}
		</cfscript>
		
		<!--- Look for circular dependencies --->
		<cfloop index="ii" from="1" to="#ArrayLen(arrComponentsRaw)#" step="1">
			<!--- Only need to check on components that weren't put into the returned array --->
			<cfif NOT ListFindNoCase(complist,arrComponentsRaw[ii].name)>
				<cfloop list="#arrComponentsRaw[ii].dependencies#" index="jj">
					<!--- If a dependency is in the raw list, but not in the returned list, that is a circle --->
					<cfif ListFindNoCase(complistraw,jj) AND NOT ListFindNoCase(complist,jj)>
						<cfthrow message="The component #arrComponentsRaw[ii].name# cannot be loaded as it has a circular dependency (probably with #jj#)." type="AppLoader" errorcode="CircularDepency" detail="A circular dependency exists two components must each wait for the other to be created before they can be created.">
					</cfif>
				</cfloop>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfreturn arrComponentsSorted>
</cffunction>

<!--- SEB 2010-06-26: IN PROGRESS --->
<cffunction name="getWhenComponentsUpdated" access="public" returntype="struct" output="no">
	
	<cfset var sDirectories = getDirectories()>
	<cfset var qComponents = 0>
	<cfset var key = "">
	<cfset var sResult = StructNew()>
	
	<cfloop collection="#sDirectories#" item="key">
		<cfdirectory action="list" directory="#key#" name="qComponents" filter="*.cfc">
		<cfloop query="qComponents">
			<cfset sResult[Directory & name] = DateLastModified>
		</cfloop>
	</cfloop>
	
	<cfif StructCount(sResult)>
		<cfdump var="#sResult#"><cfabort>
	</cfif>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="getDirectories" access="public" returntype="struct" output="no">
	
	<cfset var key = "">
	<cfset var dir = "">
	<cfset var sResult = StructNew()>
	
	<cfloop collection="#variables.sComponents#" item="key">
		<cfset dir = getDirectoryFromPath(variables.sComponents[key]["FilePath"])>
		<cfset sResult[dir] = true>
	</cfloop>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="load" access="public" returntype="void" output="no">
	<cfargument name="SysXML" type="string" default="#variables.SysXml#">
	<cfargument name="refresh" type="string" required="yes">
	<cfargument name="prefix" type="string" default="">
	<cfargument name="ChangedSettings" type="string" default="">
	
	<cfset var Sys = XmlParse(arguments.SysXml,"no")>
	<cfset var arrComponents = 0>
	<cfset var arrPostActions = ArrayNew(1)>
	<cfset var i = 0>
	<cfset var j = 0>
	<cfset var Comp = StructNew()>
	<cfset var Action = StructNew()>
	<cfset var Arg = StructNew()>
	<cfset var refreshed = "">
	<cfset var isRefreshing = false>
	<cfset var sWhenUpdated = StructNew()>
	<cfset var sArgs = Duplicate(Arguments)>
	
	<cfset StructDelete(sArgs,"SysXML")>
	<cfset StructDelete(sArgs,"refresh")>
	<cfset StructDelete(sArgs,"prefix")>
	<cfset StructDelete(sArgs,"ChangedSettings")>
	
	<!--- Get sorted components --->
	<cfset arrComponents = getComponents(arguments.SysXml,sArgs)>
	
	<!---<cfset sWhenUpdated = getWhenComponentsUpdated()>--->
	
	<cfif ArrayLen(arrComponents)>
		<!--- Prefix must end with "." --->
		<cfif Len(arguments.prefix) AND NOT Right(arguments.prefix,1) EQ ".">
			<cfset arguments.prefix = "#arguments.prefix#.">
		</cfif>
		
		<!---<cfset StructAppend(variables.args, Duplicate(arguments), true)>--->
		
		<cfif StructKeyExists(Sys.site,"postactions") AND StructKeyExists(Sys.site.postactions,"action")>
			<cfset arrPostActions = Sys.site.postactions.action>
		</cfif>
	
		<!--- %%Need to check for required arguments --->
		
		<!--- Make sure that dependent components are refreshed if the components on which they depend or refreshed --->
		<cfset arguments.refresh = recurseRefresh(arguments.SysXml,arguments.refresh,arguments.ChangedSettings)>
		<!---<cfdump var="#arguments.ChangedSettings#"><br><br>
		<cfdump var="#arguments.refresh#"><cfabort>--->
		<cfloop index="i" from="1" to="#ArrayLen(arrComponents)#" step="1">
			<!---  If refresh includes this component or is true or if this component doesn't yet exist --->
			<!---<cfif checkDirectRefresh(arrComponents[i].name,arguments.refresh)>
				<cfset isRefreshing = true>
			</cfif>--->
			<cfif checkDirectRefresh(arrComponents[i].name,arguments.refresh)>
				<cfinvoke method="loadComponent">
					<cfinvokeargument name="componentPath" value="#arguments.prefix##arrComponents[i].path#">
					<cfinvokeargument name="method" value="init">
					<cfinvokeargument name="args" value="#arrComponents[i].arguments#">
					<cfinvokeargument name="returncomp" value="#arrComponents[i].name#">
				</cfinvoke>
				<cfset refreshed = ListAppend(refreshed,arrComponents[i].name)>
				<cfset variables.sComponents[arrComponents[i].name] = StructNew()>
				<cfset variables.sComponents[arrComponents[i].name]["Component"] = Application[arrComponents[i].name]>
				<cfset variables.sComponents[arrComponents[i].name]["WhenLoaded"] = now()>
				<cfif StructKeyExists(variables.sComponents[arrComponents[i].name],"Component")>
					<cfset variables.sComponents[arrComponents[i].name]["sMetaData"] = getMetaData(variables.sComponents[arrComponents[i].name]["Component"])>
					<cfset variables.sComponents[arrComponents[i].name]["FilePath"] = variables.sComponents[arrComponents[i].name]["sMetaData"].path>
				</cfif>
			</cfif>
			<!--- /If refresh includes this component or is true or if this component doesn't yet exist --->
			<cfif arrComponents[i].name NEQ "Framework">
				<cfset this[arrComponents[i].name] = Application[arrComponents[i].name]>
			</cfif>
		</cfloop>
		
		<cfif ArrayLen(arrPostActions)>
			<cfloop index="i" from="1" to="#ArrayLen(arrPostActions)#" step="1">
				<cfset Action = arrPostActions[i].xmlAttributes>
				<!---  If any of the onload components are being loaded --->
				<cfif StructKeyExists(Action,"onload") AND ListFindOneOf(refreshed,Action.onload)><!---  checkRefresh(Action.onload,arguments.refresh) --->
					<!--- Load the component method --->
					<cfinvoke method="loadComponent">
						<cfinvokeargument name="componentName" value="#Action.component#">
						<cfinvokeargument name="method" value="#Action.method#">
						<cfif StructKeyExists(arrPostActions[i],"xmlChildren") AND ArrayLen(arrPostActions[i].xmlChildren)>
							<cfinvokeargument name="args" value="#arrPostActions[i].xmlChildren#">
						</cfif>
					</cfinvoke>
				</cfif>
				<!--- /If any of the onload components are being loaded --->
			</cfloop>
		</cfif>
	</cfif>
	
</cffunction>

<cffunction name="loadComponent" access="private" returntype="any" output="no">
	<cfargument name="componentName" type="any" required="no">
	<cfargument name="componentPath" type="any" required="no">
	<cfargument name="method" type="string" required="yes">
	<cfargument name="args" type="any" required="no">
	<cfargument name="returncomp" type="string" default="">
	
	<cfset var j = 0>
	<cfset var Arg = StructNew()>
	<cfset var component = "">
	<cfset var compName = "">
	<cfset var sArgs = StructNew()>
	
	<!--- Get component name and path --->
	<cfif StructKeyExists(arguments,"componentPath")>
		<cfset component = arguments.componentPath>
		<cfset compName = arguments.componentPath>
	<cfelseif StructKeyExists(arguments,"componentName")>
		<cfset component = Application[arguments.componentName]>
		<cfset compName = arguments.componentName>
	</cfif>
	
	<!--- Determine arguments --->
	<cfif StructKeyExists(arguments,"args") AND isArray(arguments.args) AND ArrayLen(arguments.args)>
		<cfloop index="j" from="1" to="#ArrayLen(arguments.args)#" step="1">
			<cfif StructKeyExists(args[j],"XmlAttributes")>
				<cfset Arg = args[j].XmlAttributes>
			<cfelse>
				<cfset Arg = args[j]>
			</cfif>
			<!---  If argument has name and one of value,variable,component --->
			<cfif StructKeyExists(Arg,"name") AND (StructKeyExists(Arg,"value") OR StructKeyExists(Arg,"config") OR StructKeyExists(Arg,"arg") OR StructKeyExists(Arg,"component"))>
				<cfif StructKeyExists(Arg,"value")>
					<cfset sArgs[Arg.name] = Arg.Value>
				<cfelse>
					<cfif StructKeyExists(Arg,"component")>
						<cfif StructKeyExists(Application,Arg.component) AND isObject(Application[Arg.component])>
							<cfset sArgs[Arg.name] = Application[Arg.component]>
						<cfelse>
							<cfthrow message="The component #Arg.component# does not exist." type="AppLoader" errorcode="NoSuchComponent" extendedinfo="#Arg.component#">
						</cfif>
					<cfelseif StructKeyExists(Arg,"arg")>
						<cfif StructKeyExists(variables.args,Arg.arg)>
							<cfset sArgs[Arg.name] = variables.args[Arg.arg]>
						<cfelse>
							<cfthrow message="The argument #Arg.arg# has not been set in AppLoader." detail="Pass in a value for the argument #Arg.arg# to the setArgs method of AppLoader" type="AppLoader" errorcode="NoSuchArg" extendedinfo="#Arg.arg#">
						</cfif>
					<cfelseif StructKeyExists(Arg,"config")>
						<cfif StructKeyExists(variables.args,Arg.config)>
							<cfset sArgs[Arg.name] = variables.args[Arg.config]>
						<cfelse>
							<cfthrow message="The configuration #Arg.config# has not been set." detail="Set a value for the configuration #Arg.config#." type="AppLoader" errorcode="NoSuchConfig" extendedinfo="#Arg.config#">
						</cfif>
					<cfelse>
						<cfset sArgs[Arg.name] = Evaluate(Arg.variable)>
					</cfif>
				</cfif>
			</cfif>
			<!--- /If argument has name and one of value,variable,component --->
		</cfloop>
	</cfif>
	
	<cftry>
		<cfif StructKeyExists(variables,"Proxy")>
			<cfif NOT StructKeyExists(sArgs,"Proxy")>
				<cfset sArgs.Proxy = variables.Proxy>
			</cfif>
			<cfif Len(Trim(arguments.returncomp))>
				<cfset Application[arguments.returncomp] = variables.Proxy.invokeMethod(component,method,sArgs)>
			</cfif>
		<cfelseif Len(Trim(arguments.returncomp))>
			<!---<cftry>--->
				<cfinvoke
					returnvariable="Application.#arguments.returncomp#"
					component="#component#"
					method="#arguments.method#"
					argumentCollection="#sArgs#"
				>
				</cfinvoke>
			<!---<cfcatch>
				<cfthrow message="#arguments.returncomp#: #CFCATCH.Message#" type="AppLoader">
			</cfcatch>
			</cftry>--->
		</cfif>
	<cfcatch type="Any">
		<cfif ReFindNoCase(".*parameter.*function.*required but was not passed in",CFCATCH.Message) AND FindNoCase("init",CFCATCH.Message)>
			<cfthrow message="Error on #compName#: #CFCATCH.Message#" detail="#CFCATCH.Detail#">
		<cfelse>
			<!---<cfthrow message="Error on #compName#: #CFCATCH.Message#" detail="#CFCATCH.Detail#">--->
			<cfrethrow>
		</cfif>
	</cfcatch>
	</cftry>
	
</cffunction>

<cffunction name="checkRefresh" access="public" returntype="boolean" output="no">
	<cfargument name="components" type="string" required="yes">
	<cfargument name="refresh" type="string" required="yes">
	<cfargument name="SysXML" type="string" default="#variables.SysXml#">

	<cfset var result = false>
	<cfset var component = "">
	
	<!--- Make sure that dependent components are refreshed if the components on which they depend or refreshed --->
	<cfset arguments.refresh = recurseRefresh(arguments.SysXml,arguments.refresh)>
	
	<cfreturn checkDirectRefresh(arguments.components,arguments.refresh)>
</cffunction>

<cffunction name="checkDirectRefresh" access="public" returntype="boolean" output="no">
	<cfargument name="components" type="string" required="yes">
	<cfargument name="refresh" type="string" required="yes">
	
	<cfset var result = false>
	<cfset var component = "">
	
	<!--- If refresh is true, then refresh all components --->
	<cfif arguments.refresh IS true>
		<cfset result = true>
	<cfelse>
		<!--- Otherwise, compare refresh to each component being checked - one match will do. --->
		<cfloop index="component" list="#arguments.components#">
			<!--- If refresh includes component or component doesn't exist, refresh it. --->
			<cfif ListFindNoCase(arguments.refresh,component) OR NOT StructKeyExists(Application,component)>
				<cfset result = true>
				<cfbreak>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="register" access="public" returntype="any" output="no" hint="I register a component with the Component Loader.">
	<cfargument name="ComponentXML" type="string" required="yes">
	<cfargument name="overwrite" type="boolean" default="false">
	
	<cfset var xSys = XmlParse(variables.SysXml)>
	<cfset var MyComponentXML = "">
	<cfset var xComponent = XmlParse(Trim(arguments.ComponentXML))>
	<cfset var xComponents = XmlSearch(xComponent,"//component")>
	<cfset var RootPath = "">
	<cfset var dirdelim = CreateObject("java", "java.io.File").separator>
	
	<cfset var jj = 0>
	<cfset var ii = 0>
	<cfset var kk = 0>
	<cfset var exists = false>
	<cfset var isUpdated = false>
	
	<cfset var writeComp = arguments.overwrite>
	
	<cfif StructKeyExists(variables.args,"RootPath") AND Len(Trim(variables.args.RootPath))>
		<cfset RootPath = variables.args.RootPath>
	<cfelse>
		<cfset RootPath = ExpandPath("/")>
	</cfif>
	
	<cfloop index="jj" from="1" to="#ArrayLen(xComponents)#" step="1">
		<cfset xComponent = xComponents[jj]>
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
							<!--- <cfelseif
									FileExists( ExpandPath('/' & ListChangeDelims(xComponent.XmlAttributes.path,'/','.') & ".cfc") )
								AND	NOT FileExists( ExpandPath('/' & ListChangeDelims(xSys.site.components.XmlChildren[ii].XmlAttributes.path,'/','.') & ".cfc") )
							> --->
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
						<!--- <cfif xSys.site.components.XmlChildren[ii].XmlAttributes.name EQ "NavMenus">
							<cfdump var="#xSys.site.components.XmlChildren[ii]#">
							<cfdump var="#xComponent#">
						</cfif> --->
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
							<cfset variables.SysXml = xSys>
							<!--- <cfif xSys.site.components.XmlChildren[ii].XmlAttributes.name EQ "NavMenus">
							<cfdump var="#xSys.site.components.XmlChildren[ii].XmlChildren#">
							</cfif> --->
						</cfif>
						<!--- <cfif xSys.site.components.XmlChildren[ii].XmlAttributes.name EQ "NavMenus">
							<cfdump var="#arguments.overwrite#">
							<cfdump var="#xSys.site.components.XmlChildren[ii].XmlChildren#">
							<cfdump var="#xComponent.XmlChildren#">
							<cfabort>
						</cfif> --->
					</cfif>
				</cfif>
			</cfloop>
		</cfif>
		
		<!--- If component doesn't exist, add it --->
		<cfif NOT exists>
			<!--- <cfset xSys.site.components = XmlAppendElem(xSys,xSys.site.components,xComponent.XmlRoot)> --->
			<!--- %%Need to check for existence of argument variables --->
			
			<cfset variables.SysXml = ReplaceNoCase(variables.SysXml, "</components>", "#MyComponentXML#</components>")>
			<cfset xSys = XmlParse(variables.SysXml)>
			<cfset isUpdated = true>
		</cfif>
		
	</cfloop>
	
	<cfif isUpdated>
		<cfset updateXmlFile(variables.SysXml)>
		
		<cfset load(refresh=false)>
	</cfif>
	
	
	<cfreturn xSys>
</cffunction>

<cffunction name="updateXmlFile" access="public" returntype="void" output="yes">
	<cfargument name="SysXml" type="string" required="yes">
	
	<cfset var FileContent = "">
	
	<cfif isDefined("variables.XmlFilePath")>
		<cffile action="READ" file="#variables.XmlFilePath#" variable="FileContent">
		<cffile action="WRITE" file="#variables.XmlFilePath#" output="#XmlHumanReadable(SysXml,variables.attorder)#" addnewline="No">
		<!--- <cfif isXmlDoc(FileContent)>
			<cffile action="WRITE" file="#variables.XmlFilePath#" output="#SysXml#" addnewline="No">
		<cfelse>
			<cfthrow message="I can't yet replace the XML string from within a file that isn't a pure XML document yet, sorry.">
		</cfif> --->
	</cfif>
	
</cffunction>

<cffunction name="recurseRefresh" access="public" returntype="string" output="no">
	<cfargument name="SysXML" type="string" default="#variables.SysXml#">
	<cfargument name="refresh" type="string" required="yes">
	<cfargument name="ChangedSettings" type="string" default="">
	
	<cfset var Sys = XmlParse(arguments.SysXml,"no")>
	<cfset var arrComponents = Sys.site.components.component>
	<cfset var i = 0>
	<cfset var j = 0>
	<cfset var Comp = StructNew()>
	<cfset var Arg = StructNew()>
	<cfset var result = arguments.refresh>
	
	<cfif arguments.refresh IS true>
		<!---<cfset result = "">
		<cfloop index="i" from="1" to="#ArrayLen(arrComponents)#" step="1">
			<cfset Comp = arrComponents[i].xmlAttributes>
			<cfif StructKeyExists(Comp,"name") AND StructKeyExists(Comp,"path")>
				<cfset result = ListAppend(result,comp.name)>
			</cfif>
		</cfloop>--->
		<cfreturn result>
	</cfif>
	
	<cfloop index="i" from="1" to="#ArrayLen(arrComponents)#" step="1">
		<cfset Comp = arrComponents[i].xmlAttributes>
		<!---  If component has name and path --->
		<cfif StructKeyExists(Comp,"name") AND StructKeyExists(Comp,"path")>
			<!---  If this component isn't set to be refreshed --->
			<cfif NOT checkDirectRefresh(Comp.name,arguments.refresh) AND NOT ListFindNoCase(result,Comp.name)>
				<cfif StructKeyExists(arrComponents[i],"XmlChildren") AND ArrayLen(arrComponents[i].xmlChildren)>
					<!---  Loop over arguments --->
					<cfloop index="j" from="1" to="#ArrayLen(arrComponents[i].XmlChildren)#" step="1"><cfif NOT ListFindNoCase(result,Comp.name)>
						<cfset Arg = arrComponents[i].XmlChildren[j].XmlAttributes>
						<!---  If argument is a component that is being refreshed --->
						<cfif StructKeyExists(Arg,"Component")>
							<cfif ListFindNoCase(result,Arg.Component)>
								<!--- Refresh this component --->
								<cfset result = ListAppend(result,Comp.name)>
							</cfif>
						<cfelseif
								StructKeyExists(Arg,"Name")
							AND	ListFindNoCase(result,Arg.Name)
							AND	NOT StructKeyExists(Arg,"arg")
							AND	NOT StructKeyExists(Arg,"config")
							AND	NOT StructKeyExists(Arg,"value")
						>
							<cfset result = ListAppend(result,Comp.name)>
						<cfelseif
								Len(Trim(Arguments.ChangedSettings))
							AND	(
										false
									OR	( StructKeyExists(Arg,"arg") AND ListFindNoCase(Arguments.ChangedSettings,Arg.arg) )
									OR	( StructKeyExists(Arg,"config") AND ListFindNoCase(Arguments.ChangedSettings,Arg.config) )
									OR	(
												StructKeyExists(Arg,"Name")
											AND	NOT StructKeyExists(Arg,"arg")
											AND	NOT StructKeyExists(Arg,"config")
											AND	NOT StructKeyExists(Arg,"value")
											AND	ListFindNoCase(Arguments.ChangedSettings,Arg.name)
									)
								)
						>
							<cfset result = ListAppend(result,Comp.name)>
						</cfif>
						<!--- /If argument is a component that is being refreshed --->
					</cfif></cfloop>
					<!--- /Loop over arguments --->
				</cfif>
			</cfif>
			<!--- /If this component isn't set to be refreshed --->
		</cfif>
		<!--- /If component has name and path --->
	</cfloop>
	
	<!--- If refresh list changed, check again --->
	<cfif result NEQ arguments.refresh>
		<cfset result = recurseRefresh(arguments.SysXml,result)>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="XmlAppendElem" access="private" returntype="any" output="no">
	<cfargument name="XmlDoc">
	<cfargument name="parentnode">
	<cfargument name="newelem">
	
	<cfset var currElem = 0>
	<cfset var i = 0>
	
	<cfset ArrayAppend(parentnode.XmlChildren,XmlElemNew(XmlDoc,newelem.XmlName))>
	<cfset currElem = parentnode.XmlChildren[ArrayLen(parentnode.XmlChildren)]>
	<cfset currElem.XmlAttributes = newelem.XmlAttributes>
	
	<cfif StructKeyExists(newelem,"XmlChildren") AND ArrayLen(newelem.XmlChildren)>
		<cfloop index="i" from="1" to="#ArrayLen(newelem.XmlChildren)#" step="1">
			<cfset currElem = XmlAppendElem(XmlDoc,currElem,newelem.XmlChildren[i])>
		</cfloop>
	</cfif>
	
	<cfreturn parentnode>
</cffunction>

<!---
 returns true if one of the values in the values list is found in the list.
 
 @param list 	 List of to search. (Required)
 @param values 	 List of values to search for. (Required)
 @param delimiters 	 List delimiter. Defaults to a comma. (Optional)
 @return Returns a boolean. 
 @author Sam Curren (telegramsam@byu.edu) 
 @version 1, August 5, 2005 
--->
<cffunction name="listFindOneOf" output="false" returntype="boolean">
	<cfargument name="list" type="string" required="yes">
	<cfargument name="values" type="string" required="yes">
	<cfargument name="delimiters" type="string" required="no" default=",">
	
	<cfset var value = 0>
	
	<cfloop list="#arguments.values#" index="value" delimiters="#arguments.delimiters#">
		<cfif ListFindNoCase(arguments.list, value, arguments.delimiters)>
			<cfreturn true>
		</cfif>
	</cfloop>
	
	<cfreturn false>
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

<cfscript>
/**
 * Checks is all elements of a list X is found in a list Y.
 * v2 by Raymond Camden
 * v3 idea by Bill King
 * 
 * @param l1 	 The first list. (Required)
 * @param l2 	 The second list. UDF checks to see if all of l1 is in l2. (Required)
 * @param delim1 	 List delimiter for l1. Defaults to a comma. (Optional)
 * @param delim2 	 List delimiter for l2. Defaults to a comma. (Optional)
 * @param matchany 	 If true, UDF returns true if at least one item in l1 exists in l2. Defaults to false. (Optional)
 * @return Returns a boolean. 
 * @author Daniel Chicayban (daniel@chicayban.com.br) 
 * @version 3, August 28, 2003 
 */
function isListInList(l1,l2) {
	var delim1 = ",";
	var delim2 = ",";
	var i = 1;
	var matchany = false;
	
	if(arrayLen(arguments) gte 3) delim1 = arguments[3];
	if(arrayLen(arguments) gte 4) delim2 = arguments[4];
	if(arrayLen(arguments) gte 5) matchany = arguments[5];
	
	for(i=1; i lte ListLen(l1,delim1); i=i+1) {
		if(matchany and ListFindNoCase(l2,listGetAt(l1,i,delim1),delim2)) return true;
		if(not matchany and not ListFindNoCase(l2,listGetAt(l1,i,delim1),delim2)) return false;
	}
	return true;
}
</cfscript>
<cfscript>
function isListInCommon(List1, List2) {
	return ( Len(ListInCommon(List1=List1,List2=List2)) GT 0 );
}
/**
* Returns elements in list1 that are found in list2.
* Based on ListCompare by Rob Brooks-Bilson (rbils@amkor.com)
*
* @param List1      Full list of delimited values.
* @param List2      Delimited list of values you want to compare to List1.
* @param Delim1      Delimiter used for List1. Default is the comma.
* @param Delim2      Delimiter used for List2. Default is the comma.
* @param Delim3      Delimiter to use for the list returned by the function. Default is the comma.
* @return Returns a delimited list of values.
* @author Michael Slatoff (rbils@amkor.commichael@slatoff.com)
* @version 1, August 20, 2001
*/
function ListInCommon(List1, List2)
{
var TempList = "";
var Delim1 = ",";
var Delim2 = ",";
var Delim3 = ",";
var i = 0;
// Handle optional arguments
switch(ArrayLen(arguments)) {
case 3:
{
Delim1 = Arguments[3];
break;
}
case 4:
{
Delim1 = Arguments[3];
Delim2 = Arguments[4];
break;
}
case 5:
{
Delim1 = Arguments[3];
Delim2 = Arguments[4];
Delim3 = Arguments[5];
break;
}
}
/* Loop through the second list, checking for the values from the first list.
* Add any elements from the second list that are found in the first list to the
* temporary list
*/
for (i=1; i LTE ListLen(List2, "#Delim2#"); i=i+1) {
if (ListFindNoCase(List1, ListGetAt(List2, i, "#Delim2#"), "#Delim1#")){
TempList = ListAppend(TempList, ListGetAt(List2, i, "#Delim2#"), "#Delim3#");
}
}
Return TempList;
}
</cfscript>
</cfcomponent>
