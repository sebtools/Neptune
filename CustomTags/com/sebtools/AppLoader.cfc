<!--- 1.0 Alpha (Build 7) --->
<!--- Last Updated: 2007-10-25 --->
<!--- Created by Steve Bryant 2005-08-19 --->
<!--- Information: sebtools.com --->
<cfcomponent displayname="Component Loader" output="false">
<cfset cr = "
">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="SysXML" type="string" required="no">
	<cfargument name="XmlFilePath" type="string" required="no">
	
	<cfset variables.instance = StructNew()>
	<cfset variables.args = StructNew()>
	
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
	
	<cfreturn this>
</cffunction>

<cffunction name="setArgs" access="public" returntype="void" output="no">
	
	<cfif ArrayLen(arguments)>
		<cfset StructAppend(variables.args,Duplicate(arguments),true)>
	</cfif>
	
</cffunction>

<cffunction name="getComponents" access="public" returntype="array" output="no">
	<cfargument name="SysXML" type="string" default="#variables.SysXml#">

	<cfset var Sys = XmlParse(arguments.SysXml,"no")>
	<cfset var arrComponents = 0>
	<cfset var arrComponentsRaw = ArrayNew(1)>
	<cfset var arrComponentsSorted = ArrayNew(1)>
	<cfset var ii = 0>
	<cfset var jj = 0>
	<cfset var complist = "">
	<cfset var dependence = "">
	<cfset var sComponent = StructNew()>

	<cfif StructKeyExists(Sys,"site") AND StructKeyExists(Sys.site,"components") AND StructKeyExists(Sys.site.components,"component")>
		<cfset arrComponents = Sys.site.components.component>
		
		<cfloop index="ii" from="1" to="#ArrayLen(arrComponents)#" step="1">
			<!---  If component has name and path --->
			<cfif StructKeyExists(arrComponents[ii].XmlAttributes,"name") AND StructKeyExists(arrComponents[ii].xmlAttributes,"path")>
				<cfset sComponent = StructNew()>
				<cfset sComponent["name"] = arrComponents[ii].xmlAttributes.name>
				<cfset sComponent["path"] = arrComponents[ii].xmlAttributes.path>
				<cfset sComponent["arguments"] = ArrayNew(1)>
				<cfset sComponent["dependencies"] = "">
				<cfif StructKeyExists(arrComponents[ii],"xmlChildren") AND ArrayLen(arrComponents[ii].xmlChildren)>
					<cfloop index="jj" from="1" to="#ArrayLen(arrComponents[ii].XmlChildren)#" step="1">
						<cfset ArrayAppend(sComponent["arguments"],arrComponents[ii].XmlChildren[jj].XmlAttributes)>
						<cfif StructKeyExists(arrComponents[ii].XmlChildren[jj].XmlAttributes,"component")>
							<cfset sComponent["dependencies"] = ListAppend(sComponent["dependencies"],arrComponents[ii].XmlChildren[jj].XmlAttributes.component)>
						</cfif>
					</cfloop>
				</cfif>
				<cfset ArrayAppend(arrComponentsRaw,sComponent)>
				<cfset complist = ListAppend(complist,sComponent["name"])>
			</cfif>
			<!--- /If component has name and path --->
		</cfloop>
		<!--- Check for orphaned components (ones whose dependents don't exist) --->
		<cfloop index="ii" from="1" to="#ArrayLen(arrComponentsRaw)#" step="1">
			<cfloop list="#arrComponentsRaw[ii].dependencies#" index="dependence">
				<cfif NOT ListFindNoCase(complist,dependence)>
					<cfthrow message="The component #arrComponentsRaw[ii].name# requires the component #dependence#, which does not exist" type="AppLoader" errorcode="MissignDependentComponent">
				</cfif>
			</cfloop>
		</cfloop>
		
		<cfscript>
		complist = "";
		//Resort table list based on dependencies
		jj = 1;
		while ( jj LTE ( ArrayLen(arrComponentsRaw)^2 + 1 ) AND ( ArrayLen(arrComponentsSorted) LT ArrayLen(arrComponentsRaw) ) ) {
			for (ii=1; ii LTE ArrayLen(arrComponentsRaw); ii=ii+1) {
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
		<cfset request.arrComponentsRaw = arrComponentsRaw>
		<!--- <cfdump var="#arrComponentsRaw#"> --->
		<!--- <cfdump var="#arrComponentsSorted#">
		<cfabort> --->
		
	</cfif>
	
	<cfreturn arrComponentsSorted>
</cffunction>

<cffunction name="load" access="public" returntype="void" output="no">
	<cfargument name="SysXML" type="string" default="#variables.SysXml#">
	<cfargument name="refresh" type="string" required="yes">
	<cfargument name="prefix" type="string" default="">
	
	<cfset var Sys = XmlParse(arguments.SysXml,"no")>
	<cfset var arrComponents = 0>
	<cfset var arrPostActions = ArrayNew(1)>
	<cfset var i = 0>
	<cfset var j = 0>
	<cfset var Comp = StructNew()>
	<cfset var Action = StructNew()>
	<cfset var Arg = StructNew()>
	<cfset var refreshed = "">
	
	<!--- Get sorted components --->
	<cfset arrComponents = getComponents(arguments.SysXml)>
	
	<cfif ArrayLen(arrComponents)>
		<cfif Len(arguments.prefix) AND NOT Right(arguments.prefix,1) EQ ".">
			<cfset arguments.prefix = "#arguments.prefix#.">
		</cfif>
		
		<cfset StructAppend(variables.args, Duplicate(arguments), true)>
		
		<cfif StructKeyExists(Sys.site,"postactions") AND StructKeyExists(Sys.site.postactions,"action")>
			<cfset arrPostActions = Sys.site.postactions.action>
		</cfif>
	
		<!--- %%Need to check for required arguments --->
		
		<!--- Make sure that dependent components are refreshed if the components on which they depend or refreshed --->
		<cfset arguments.refresh = recurseRefresh(arguments.SysXml,arguments.refresh)>
		
		<cfloop index="i" from="1" to="#ArrayLen(arrComponents)#" step="1">
			<!---  If refresh includes this component or is true or if this component doesn't yet exist --->
			<cfif checkRefresh(arrComponents[i].name,arguments.refresh)>
				<cfinvoke method="loadComponent">
					<cfinvokeargument name="componentPath" value="#arguments.prefix##arrComponents[i].path#">
					<cfinvokeargument name="method" value="init">
					<cfinvokeargument name="args" value="#arrComponents[i].arguments#">
					<cfinvokeargument name="returncomp" value="#arrComponents[i].name#">
				</cfinvoke>
				<cfset refreshed = ListAppend(refreshed,arrComponents[i].name)>
			</cfif>
			<!--- /If refresh includes this component or is true or if this component doesn't yet exist --->
			<cfset this[arrComponents[i].name] = Application[arrComponents[i].name]>
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
	<cfargument name="returncomp" type="string" default="none">
	
	<cfset var j = 0>
	<cfset var Arg = StructNew()>
	<cfset var component = "">
	<cfset var compName = "">
	
	<cfif StructKeyExists(arguments,"componentPath")>
		<cfset component = arguments.componentPath>
		<cfset compName = arguments.componentPath>
	<cfelseif StructKeyExists(arguments,"componentName")>
		<cfset component = Application[arguments.componentName]>
		<cfset compName = arguments.componentName>
	</cfif>
	
	<cftry>
	
	<cfinvoke component="#component#" method="#arguments.method#" returnvariable="Application.#arguments.returncomp#">
		<cfif StructKeyExists(arguments,"args") AND isArray(arguments.args) AND ArrayLen(arguments.args)>
			<cfloop index="j" from="1" to="#ArrayLen(arguments.args)#" step="1">
				<cfif StructKeyExists(args[j],"XmlAttributes")>
					<cfset Arg = args[j].XmlAttributes>
				<cfelse>
					<cfset Arg = args[j]>
				</cfif>
				<!---  If argument has name and one of value,variable,component --->
				<cfif StructKeyExists(Arg,"name") AND (StructKeyExists(Arg,"value") OR StructKeyExists(Arg,"arg") OR StructKeyExists(Arg,"component"))>
					<cfif StructKeyExists(Arg,"value")>
						<cfinvokeargument name="#Arg.name#" value="#Arg.Value#">
					<cfelse>
						<cfif StructKeyExists(Arg,"component")>
							<cfif StructKeyExists(Application,Arg.component) AND isObject(Application[Arg.component])>
								<cfinvokeargument name="#Arg.name#" value="#Application[Arg.component]#">
							<cfelse>
								<cfthrow message="The component #Arg.component# does not exist." type="AppLoader" errorcode="NoSuchComponent" extendedinfo="#Arg.component#">
							</cfif>
						<cfelseif StructKeyExists(Arg,"arg")>
							<cfif StructKeyExists(variables.args,Arg.arg)>
								<cfinvokeargument name="#Arg.name#" value="#variables.args[Arg.arg]#">
							<cfelse>
								<cfthrow message="The argument #Arg.arg# has not bee set in AppLoader." detail="Pass in a value for the argument #Arg.arg# to the setArgs method of AppLoader" type="AppLoader" errorcode="NoSuchArg" extendedinfo="#Arg.arg#">
							</cfif>
						<cfelse>
							<cfinvokeargument name="#Arg.name#" value="#Evaluate(Arg.variable)#">
						</cfif>
					</cfif>
				</cfif>
				<!--- /If argument has name and one of value,variable,component --->
			</cfloop>
		</cfif>
	</cfinvoke>
	
	<cfcatch type="Any">
		<cfif ReFindNoCase(".*parameter.*function.*required but was not passed in",CFCATCH.Message)>
			<cfthrow message="Error on #compName#: #CFCATCH.Message#" detail="#CFCATCH.Detail#">
		<cfelse>
			<cfthrow message="Error on #compName#: #CFCATCH.Message#" detail="#CFCATCH.Detail#" errorcode="#CFCATCH.ErrorCode#" extendedinfo="#CFCATCH.extendedinfo#">
		</cfif>
		<!--- <cfdump var="#CFCATCH#">
		<cfdump var="#variables.args#">
		<cfdump var="#arguments#">
		<cfabort> --->
	</cfcatch>
	
	</cftry>
	
</cffunction>

<cffunction name="checkRefresh" access="public" returntype="boolean" output="no">
	<cfargument name="components" type="string" required="yes">
	<cfargument name="refresh" type="string" required="yes">
	
	<cfset var result = false>
	<cfset var component = "">
	
	<!--- If refresh is true, then refresh all components --->
	<cfif isBoolean(arguments.refresh) AND arguments.refresh>
		<cfset result = true>
	<cfelse>
		<!--- Otherwise, compare refresh to each component being checked - one match will do. --->
		<cfloop index="component" list="#arguments.components#">
			<!--- If refresh includes component or component doesn't exist, refresh it. --->
			<cfif ListFindNoCase(arguments.refresh,component) OR NOT StructKeyExists(Application,component)>
				<cfset result = true>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="register" access="public" returntype="any" output="no" hint="I register a component with the Component Loader.">
	<cfargument name="ComponentXML" type="string" required="yes">
	<cfargument name="overwrite" type="boolean" default="false">
	
	<cfset var xSys = XmlParse(variables.SysXml)>
	<cfset var xComponent = XmlParse(Trim(arguments.ComponentXML))>
	<cfset var xComponents = XmlSearch(xComponent,"//component")>
	
	<cfset var jj = 0>
	<cfset var ii = 0>
	<cfset var kk = 0>
	<cfset var exists = false>
	<cfset var isUpdated = false>
	
	<cfloop index="jj" from="1" to="#ArrayLen(xComponents)#" step="1">
		<cfset xComponent = xComponents[jj]>
		<cfset arguments.ComponentXML = XmlHumanReadable(xComponent)>
		
		<cfset exists = false>
		
		<!--- Check to see if this component already exists --->
		<cfif StructKeyExists(xSys.site.components,"XmlChildren") AND ArrayLen(xSys.site.components.XmlChildren)>
			<cfloop index="ii" from="1" to="#ArrayLen(xSys.site.components.XmlChildren)#" step="1">
				<cfif StructKeyExists(xSys.site.components.XmlChildren[ii].XmlAttributes,"name")>
					<cfif xSys.site.components.XmlChildren[ii].XmlAttributes.name eq xComponent.XmlAttributes.name>
						<cfif xSys.site.components.XmlChildren[ii].XmlAttributes.path eq xComponent.XmlAttributes.path>
							<cfset exists = true>
						<cfelse>
							<cfif arguments.overwrite>
								<cfset xSys.site.components.XmlChildren[ii].XmlAttributes.path = xComponent.XmlAttributes.path>
								<cfset isUpdated = true>
								<cfset exists = true>
							<cfelse>
								<cfthrow message="Another component of the same name (#xComponent.XmlAttributes.name#) already exists (existing path: #xSys.site.components.XmlChildren[ii].XmlAttributes.path#; new path: #xComponent.XmlAttributes.path#).">
							</cfif>
						</cfif>
						<!--- <cfif xSys.site.components.XmlChildren[ii].XmlAttributes.name EQ "NavMenus">
							<cfdump var="#xSys.site.components.XmlChildren[ii]#">
							<cfdump var="#xComponent#">
						</cfif> --->
						<cfif arguments.overwrite>
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
			
			<cfset variables.SysXml = ReplaceNoCase(variables.SysXml, "</components>", "#arguments.ComponentXML#</components>")>
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
		<cffile action="WRITE" file="#variables.XmlFilePath#" output="#XmlHumanReadable(SysXml)#" addnewline="No">
		<!--- <cfif isXmlDoc(FileContent)>
			<cffile action="WRITE" file="#variables.XmlFilePath#" output="#SysXml#" addnewline="No">
		<cfelse>
			<cfthrow message="I can't yet replace the XML string from within a file that isn't a pure XML document yet, sorry.">
		</cfif> --->
	</cfif>
	
</cffunction>

<cffunction name="recurseRefresh" access="private" returntype="string" output="no">
	<cfargument name="SysXML" type="string" default="#variables.SysXml#">
	<cfargument name="refresh" type="string" required="yes">
	
	<cfset var Sys = XmlParse(arguments.SysXml,"no")>
	<cfset var arrComponents = Sys.site.components.component>
	<cfset var i = 0>
	<cfset var j = 0>
	<cfset var Comp = StructNew()>
	<cfset var Arg = StructNew()>
	<cfset var result = arguments.refresh>
	
	<cfif isBoolean(arguments.refresh) AND arguments.refresh>
		<cfreturn result>
	</cfif>
	
	<cfloop index="i" from="1" to="#ArrayLen(arrComponents)#" step="1">
		<cfset Comp = arrComponents[i].xmlAttributes>
		<!---  If component has name and path --->
		<cfif StructKeyExists(Comp,"name") AND StructKeyExists(Comp,"path")>
			<!---  If this component isn't set to be refreshed --->
			<cfif NOT checkRefresh(Comp.name,arguments.refresh)>
				<cfif StructKeyExists(arrComponents[i],"XmlChildren") AND ArrayLen(arrComponents[i].xmlChildren)>
					<!---  Loop over arguments --->
					<cfloop index="j" from="1" to="#ArrayLen(arrComponents[i].XmlChildren)#" step="1">
						<cfset Arg = arrComponents[i].XmlChildren[j].XmlAttributes>
						<!---  If argument is a component that is being refreshed --->
						<cfif StructKeyExists(Arg,"Component") AND ListFindNoCase(result,Arg.Component)>
							<!--- Refresh this component --->
							<cfset result = ListAppend(result,Comp.name)>
						</cfif>
						<!--- /If argument is a component that is being refreshed --->
					</cfloop>
					<!--- /Loop over arguments --->
				</cfif>
			</cfif>
			<!--- /If this component isn't set to be refreshed --->
		</cfif>
		<!--- /If component has name and path --->
	</cfloop>
	
	<!--- If refresh list changed, check again --->
	<cfif result neq arguments.refresh>
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
 * 
 * @param XmlDoc 	 XML document. (Required)
 * @return Returns a string. 
 * @author Steve Bryant (steve@bryantwebconsulting.com) 
 * @version 2, March 20, 2006 
 */
function xmlHumanReadable(XmlDoc) {
	var elem = "";
	var result = "";
	var tab = "	";
	var att = "";
	var i = 0;
	var temp = "";
	var cr = createObject("java","java.lang.System").getProperty("line.separator");
	
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
		for ( att in elem.XmlAttributes ) {
			if ( NOT ( att EQ "xmlns" AND elem.XmlAttributes[att] EQ "" ) ) {
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
			for ( i=1; i lte ArrayLen(elem.XmlChildren); i=i+1 ) {
				temp = Trim(XmlHumanReadable(elem.XmlChildren[i]));
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
	
	for(i=1; i lte listLen(l1,delim1); i=i+1) {
		if(matchany and ListFindNoCase(l2,listGetAt(l1,i,delim1),delim2)) return true;
		if(not matchany and not ListFindNoCase(l2,listGetAt(l1,i,delim1),delim2)) return false;
	}
	return true;
}
</cfscript>

</cfcomponent>
