<!--- 1.0 Beta 2 (Build 26) --->
<!--- Last Updated: 2012-08-05 --->
<!--- Information: sebtools.com --->
<cfcomponent displayname="Page Controller" output="false">

<cfset me = This>

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="Caller" type="struct" required="false">
	<cfargument name="path" type="string" required="false">
	<cfargument name="Framework" type="any" required="false">
	
	<cfset variables.instance = Arguments>
	
	<cfif StructKeyExists(arguments,"Caller")>
		<cfif StructKeyExists(arguments,"path") AND StructKeyExists(arguments,"path")>
			<cfinvoke method="setScriptName">
				<cfinvokeargument name="ScriptName" value="#arguments.path#">
				<cfif StructKeyExists(arguments,"Framework")>
					<cfinvokeargument name="Framework" value="#arguments.Framework#">
				</cfif>
			</cfinvoke>
		</cfif>
		
		<!---<cfif NOT ( StructKeyExists(arguments,"check") AND arguments.check EQ false )>
			<cfset checkAccess()>
		</cfif>--->
	
		<!---<cfset StructAppend(Arguments.Caller,loadData(VariablesScope=Arguments.Caller))>--->
	</cfif>
	
	<cfreturn This>
</cffunction>

<cffunction name="getDefaultVars" access="public" returntype="struct" output="no">
	<cfargument name="Title" type="string" required="true">
	<cfargument name="type" type="string" default="">
	<cfargument name="filename" type="string" default="">
	<cfargument name="urlvar" type="string" default="id">
	
	<cfset var vars = StructNew()>
	<cfset var sMe = getMetaData(me)>
	<cfset var oComponent = me>
	<cfset var sCompMeta = 0>
	<cfset var vartype = "numeric">
	<cfset var temp = "">
	
	<cfset vars.Title = arguments.Title>
	<cfset vars.TitleBase = arguments.Title>
	<cfset vars.TitleExt = "">
	
	<cfif arguments.type EQ "edit">
		<cfif StructKeyExists(oComponent,"getMetaStruct")>
			<cfset sCompMeta = oComponent.getMetaStruct()>
			<cfif StructKeyExists(sCompMeta,"property_pktype") AND sCompMeta["property_pktype"] NEQ "complex">
				<cfset vartype = sCompMeta["property_pktype"]>
			</cfif>
		</cfif>
		
		<cfset param("URL.#urlvar#",vartype,0)>
		
		<cfset temp = LCase(ReplaceNoCase(arguments.Title," ","_","ALL"))>
		<cfif ReFindNoCase("^\w+$",temp)>
			<cfset param("URL.#temp#",vartype,0)>
			<cfif URL[urlvar] AND NOT URL[temp]>
				<cfset URL[temp] = URL[urlvar]>
			</cfif>
		</cfif>
		
		<cfset temp = LCase(ReplaceNoCase(arguments.Title," ","","ALL"))>
		<cfif ReFindNoCase("^\w+$",temp)>
			<cfset param("URL.#temp#",vartype,0)>
			<cfif URL[urlvar] AND NOT URL[temp]>
				<cfset URL[temp] = URL[urlvar]>
			</cfif>
		</cfif>
		
		<cfset vars.Action = "Add">
		
		<cfif URL[urlvar] GT 0>
			<cfset vars.Action = "Edit">
		</cfif>
		<cfset vars.Title = "#vars.Action# #vars.Title#">
		
		<cfset vars.SebFormAttributes = StructNew()>
		<cfset vars.SebFormAttributes.CFC_Component = oComponent>
		<cfset vars.SebFormAttributes.sendback = true>
		<cfset vars.SebFormAttributes.recordid = URL[urlvar]>
		<cfset vars.SebFields = StructNew()>
	<cfelseif arguments.type EQ "list">
		<cfset vars.sFilters = StructNew()>
		
		<cfset vars.sebTableAttributes = StructNew()>
		<cfif Len(arguments.filename) AND findNoCase("-list",arguments.filename)>
			<cfset vars.sebTableAttributes.editpage = ReplaceNoCase(arguments.filename,"-list","-edit")>
		<cfelse>
			<cfset vars.sebTableAttributes.editpage = "#ListFirst(ListLast(sMe.name,'.'),'-')#-edit.cfm?">
		</cfif>
		
		<!---<cfset vars.sebTableAttributes.label = arguments.Title>--->
		<cfset vars.sebTableAttributes.CFC_Component = oComponent>
		<cfset vars.sebTableAttributes.CFC_GetArgs = vars.sFilters>
		<cfset vars.sebTableAttributes.isDeletable = true>
		
		<cfset addURLFilters(vars,"sFilters")>
	<cfelseif arguments.type EQ "import">
	
		<cfset vars.Action = "Import">
		<cfset vars.Title = "#vars.Action# #vars.Title#">
	
		<cfset vars.SebFormAttributes = StructNew()>
		<cfset vars.SebFormAttributes.CFC_Component = me>
		<cfset vars.SebFormAttributes.sendback = true>
	<cfelseif arguments.type EQ "index" AND isSecuredPage()>
		
		<cfif
				StructKeyExists(Variables,"ScriptName")
			AND	StructKeyExists(Variables.instance,"Framework")
			AND	StructKeyExists(Variables.instance.Framework,"getProgramFromPath")
			AND	StructKeyExists(Variables.instance.Framework,"getProgramLinksArray")
		>
			<cfset vars.sProgram = Variables.instance.Framework.getProgramFromPath(Variables.ScriptName)>
			<cfif StructKeyExists(vars.sProgram,"name")>
				<cfset vars.aLinks = Variables.instance.Framework.getProgramLinksArray(vars.sProgram.name)>
				<cfset vars.Title = vars.sProgram.name>
			<cfelse>
				<cfset vars.aLinks = Variables.instance.Framework.getProgramLinksArray()>
			</cfif>
			
			<cfif ArrayLen(vars.aLinks) EQ 1>
				<cfset go(vars.aLinks[1].link)>
			</cfif>
			
		<cfelse>
			<cfset vars.aLinks = ArrayNew(1)>
		</cfif>
	
	</cfif>
	
	<cfreturn vars>
</cffunction>

<cffunction name="getNoAccessURL" access="public" returntype="string" output="no">
	
	<cfset var oSecurity = 0>
	<cfset var result = "/">
	
	<cfif
			hasSecurityService()
		AND	StructKeyExists(variables,"ScriptName")
	>
		<cfset oSecurity = getSecurityService()>
		<cfif StructKeyExists(oSecurity,"getNoAccessURL")>
			<cfset result = oSecurity.getNoAccessURL(variables.ScriptName)>
		</cfif>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="blockAccess" access="public" returntype="any" output="no">
	
	<cfset go(getNoAccessURL())>
	<cfabort>
	
</cffunction>

<cffunction name="checkAccess" access="public" returntype="void" output="no">
	
	<cfif NOT hasAccess()>
		<cfset blockAccess()>
		<cfabort>
	</cfif>
	
</cffunction>

<cffunction name="isSecuredPage" access="public" returntype="boolean" output="no">
	
	<cfset var result = false>
	<cfset var oSecurity = 0>
	
	<cfif StructKeyExists(variables,"ScriptName")>
		<cfif hasSecurityService()>
			<cfset oSecurity = getSecurityService()>
			<cfif StructKeyExists(oSecurity,"isSecuredPath")>
				<cfset result = oSecurity.isSecuredPath(variables.ScriptName)>
				<cfif NOT isBoolean(result)>
					<cfset result = false>
				</cfif>
			</cfif>
		<cfelse>
			<cfset result = ListFirst(variables.ScriptName,"/") EQ "admin">
		</cfif>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="hasAccess" access="public" returntype="boolean" output="no">
	
	<cfset var result = true>
	<cfset var permissions = "">
	<cfset var sProgram = 0>
	<cfset var oSecurity = 0>
	
	<cfif hasSecurityService() AND isSecuredPage()>
		<cfset oSecurity = getSecurityService()>
		
		<cfif StructKeyExists(oSecurity,"checkUserAllowed")>
			<cfif
					StructKeyExists(variables,"ScriptName")
				AND	StructKeyExists(variables.instance,"Framework")
				AND	StructKeyExists(variables.instance.Framework,"getProgramFromPath")
			>
				<cfset sProgram = variables.instance.Framework.getProgramFromPath(variables.ScriptName)>
				
				<cfif StructKeyExists(sProgram,"permissions") AND Len(sProgram.permissions)>
					<cfset result = oSecurity.checkUserAllowed(sProgram.permissions)>
				</cfif>
			</cfif>
			
			<cfif result AND hasInheritsWithMetaStruct()>
				<cfset sCompMeta = variables.this.getMetaStruct()>
				
				<cfif StructKeyExists(sCompMeta,"method_security_permissions")>
					<cfinvoke
						returnvariable="permissions"
						component="#variables.this#"
						method="#sCompMeta.method_security_permissions#"
					>
					<cfset result = oSecurity.checkUserAllowed(permissions)>
				</cfif>
			</cfif>
		</cfif>
		
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="loadData" access="public" returntype="struct" output="no">
	
	<cfset var vars = StructNew()>
	
	<cfif
			hasInheritsWithMetaStruct()
		AND	StructKeyExists(variables,"ScriptName")
	>
		<cfset vars = getDefaultVars(argumentCollection=getDefaultVarArgs())>
	</cfif>
	
	<cfreturn vars>
</cffunction>

<cffunction name="loadData_File" access="public" returntype="struct" output="no">
	
	<cfset var vars = StructNew()>
	
	<cfset default("URL.file","string","")>
	
	<cfset vars.isValidFile = ( Len(URL.file) GT 0 )>
	<cfif ListFindNoCase(URL.file,"..","/") OR ListFindNoCase(URL.file,"..","\") OR ListFindNoCase(URL.file,"..",",")>
		<cfset vars.isValidFile = false>
	</cfif>
	
	<cfif vars.isValidFile>
		<cfset vars.FilePath = variables.Config.getSetting("UploadPath") & URL.file>
		<cfset vars.ext = ListLast(URL.file,".")>
		<cfset vars.isFileFound = FileExists(vars.FilePath)>
		<cfset vars.isValidFile = vars.isFileFound>
		
		<cfif ListFindNoCase("jpg,gif,png",vars.ext)>
			<cfset vars.disposition = "inline">
		<cfelse>
			<cfset vars.disposition = "attachment">
		</cfif>
	</cfif>
	
	<cfreturn vars>
</cffunction>

<cffunction name="getDefaultVarArgs" access="private" returntype="struct" output="no">
	
	<cfset var pagetype = ListFirst(ListLast(getFileFromPath(variables.ScriptName),"-"),".")>
	<cfset var sMetaStruct = variables.this.getMetaStruct()>
	<cfset var sResult = StructNew()>
	
	<cfset sResult.type = pagetype>
	<cfset sResult.title = "">
	<cfset sResult.filename = variables.ScriptName>
	
	<cfif pagetype EQ "list" AND StructKeyExists(sMetaStruct,"label_Plural")>
		<cfset sResult.title = sMetaStruct.label_Plural>
	<cfelseif pagetype EQ "edit" AND StructKeyExists(sMetaStruct,"label_Singular")>
		<cfset sResult.title = sMetaStruct.label_Singular>
	<cfelseif pagetype EQ "import" AND StructKeyExists(sMetaStruct,"label_Plural")>
		<cfset sResult.title = sMetaStruct.label_Plural>
	</cfif>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="hasInheritsWithMetaStruct" access="private" returntype="boolean" output="no">
	
	<cfset var result = (
			StructKeyExists(variables,"this")
		AND	isObject(variables.this)
		AND	StructKeyExists(variables.this,"getMetaStruct")
	)>
	
	<cfreturn result>
</cffunction>

<cffunction name="setScriptName" access="public" returntype="any" output="no">
	<cfargument name="ScriptName" type="string" required="true">
	<cfargument name="Framework" type="any" required="false">
	
	<cfset var sThis = getMetaData(me)>
	<cfset var sCurrService = getMetaData(variables.this)>
	<cfset var oService = 0>
	
	<cfscript>
	variables.ScriptName = arguments.ScriptName;
	
	if (
			StructKeyExists(sCurrService,"path")
		AND	sThis.path EQ sCurrService.Path
		AND	StructKeyExists(arguments,"Framework")
		AND	StructKeyExists(arguments.Framework,"getService")
	) {
		oService = arguments.Framework.getService(variables.ScriptName);
		if ( isObject(oService) ) {
			setInherits(oService);
		}
	}
	</cfscript>
	
	<cfreturn This>
</cffunction>

<cffunction name="loadExternalVars" access="public" returntype="void" output="no">
	<cfargument name="varlist" type="string" required="true">
	<cfargument name="scope" type="string" default="Application">
	<cfargument name="skipmissing" type="boolean" default="false">
	<cfargument name="inherit" type="string" default="">
	
	<cfset var varname = "">
	<cfset var scopestruct = 0>
	
	<cfif Left(arguments.scope,1) EQ "." AND Len(arguments.scope) GTE 2>
		<cfset variables[Right(arguments.scope,Len(arguments.scope)-1)] = Application[Right(arguments.scope,Len(arguments.scope)-1)]>
		<cfset arguments.scope = "Application#arguments.scope#">
	</cfif>
	
	<cfset scopestruct = StructGet(arguments.scope)>
	
	<cfloop index="varname" list="#arguments.varlist#">
		<cfif StructKeyExists(scopestruct,varname)>
			<cfset variables[varname] = scopestruct[varname]>
		<cfelseif NOT arguments.skipmissing>
			<cfthrow message="#scope#.#varname# is not defined.">
		</cfif>
	</cfloop>
	
	<cfif Len(arguments.inherit)>
		<cfif isNumeric(arguments.inherit) AND arguments.inherit LTE ListLen(arguments.varlist)>
			<cfset arguments.inherit = ListGetAt(arguments.varlist,arguments.inherit)>
		</cfif>
		<cfif StructKeyExists(variables,arguments.inherit) AND isObject(variables[arguments.inherit])>
			<cfset setInherits(variables[arguments.inherit])>
		</cfif>
	</cfif>
	
</cffunction>

<cffunction name="go" access="remote" returntype="any" output="no" hint="I send the browser to the specified location.">
	<cfargument name="location" type="string" required="no">
	
	<cfif NOT ( StructKeyExists(Arguments,"location") AND Len(Trim(Arguments.location)) )>
		<cfset Arguments.location = getNoAccessURL()>
	</cfif>
	
	<cflocation url="#arguments.location#" addtoken="no">
	
</cffunction>

<cffunction name="default" access="public" returntype="any" output="no" hint="I provide a default value if the variable doesn't exist or isn't of the appropriate data type.">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="type" type="string" required="yes">
	<cfargument name="default" type="any" required="yes">
	<cfargument name="valuelist" type="string" default="">
	
	<cfif NOT isVarType(arguments.name,arguments.type,arguments.valuelist)>
		<cfset setVariable(arguments.name,arguments.default)>
	</cfif>
	
</cffunction>

<cffunction name="defaultVar" access="public" returntype="any" output="no" hint="I provide a default value if the variable doesn't exist or isn't of the appropriate data type.">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="type" type="string" required="yes">
	<cfargument name="default" type="any" required="yes">
	<cfargument name="valuelist" type="string" default="">
	
	<cfif NOT isVarType(arguments.name,arguments.type,arguments.valuelist)>
		<cfset setVariable(arguments.name,arguments.default)>
	</cfif>
	
</cffunction>

<cffunction name="addURLFilters" access="public" returntype="void" output="no">
	<cfargument name="vars" type="struct" required="yes">
	<cfargument name="structname" type="string" required="yes">
	
	<cfset var aFields = 0>
	<cfset var ii = 0>
	
	<cfif StructKeyExists(variables,"this") AND StructKeyExists(variables.this,"getFieldsArray")>
		<cfset aFields = variables.this.getFieldsArray()>
		<cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
			<cfif
					StructKeyExists(aFields[ii],"name") AND Len(aFields[ii].name)
				AND	StructKeyExists(aFields[ii],"subcomp") AND Len(aFields[ii].subcomp)
				AND	StructKeyExists(aFields[ii],"urlvar") AND Len(aFields[ii].urlvar)
			>
				<cfinvoke method="addURLFilter">
					<cfinvokeargument name="vars" value="#vars#">
					<cfinvokeargument name="structname" value="#structname#">
					<cfinvokeargument name="urlvar" value="#aFields[ii].urlvar#">
					<cfinvokeargument name="Comp" value="#aFields[ii].subcomp#">
					<cfinvokeargument name="key" value="#aFields[ii].name#">
					<cfif StructKeyExists(aFields[ii],"TitleJoin") AND Len(aFields[ii].TitleJoin)>
						<cfinvokeargument name="TitleJoin" value="#aFields[ii].TitleJoin#">
					</cfif>
				</cfinvoke>
			</cfif> 
		</cfloop>
	</cfif>
	
</cffunction>

<cffunction name="addURLFilter" access="public" returntype="void" output="no">
	<cfargument name="vars" type="struct" required="yes" hint="The variables scope of the page.">
	<cfargument name="structname" type="string" required="yes" hint="The name of the structure into which to insert data.">
	<cfargument name="urlvar" type="string" required="yes" hint="The name of the URL variable to use.">
	<cfargument name="key" type="string" required="yes" hint="The name of the key to add to the structure.">
	<cfargument name="Comp" type="any" required="yes" hint="The name of the component to use.">
	<cfargument name="Method" type="string" default="getLabelFieldValue" hint="A method that will return a string to add to the title. A value will be added to the structure only if this returns a non-empty string.">
	<cfargument name="TitleJoin" type="string" default="for" hint="The word to go between the title and the word returned by the method. Alternately, a string containing [Title] and [Label] that will be used for the title (taking [Title] as a placeholder for the original title and [Label] as the string returned from the method).">
	
	<cfset var label = "">
	
	<!--- If no url val exists, use the struct key --->
	<cfif NOT ( StructKeyExists(arguments,"urlvar") AND Len(arguments.urlvar) )>
		<cfset arguments.urlvar = arguments.key>
	</cfif>
	
	<!--- Make sure struct exists --->
	<cfif NOT StructKeyExists(arguments.vars,arguments.structname)>
		<cfset arguments.vars[arguments.structname] = StructNew()>
	</cfif>
	
	<!--- Convert comp string to object --->
	<cfif isSimpleValue(arguments.Comp)>
		<cfif StructKeyExists(variables,arguments.comp) AND isObject(variables[arguments.comp])>
			<cfset arguments.comp = variables[arguments.comp]>
		<cfelseif StructKeyExists(variables,"this") AND StructKeyExists(variables.this,"getServiceComponent")>
			<cfset arguments.comp = variables.this.getServiceComponent(arguments.comp)>
		</cfif>
	</cfif>
	
	<cfif NOT ( StructKeyExists(arguments.vars,"sebTableAttributes") )>
		<cfset arguments.vars.sebTableAttributes = StructNew()>
	</cfif>
	<cfif NOT ( StructKeyExists(arguments.vars.sebTableAttributes,"urlvars") )>
		<cfset arguments.vars.sebTableAttributes.urlvars = "">
	</cfif>
	<cfif NOT ( StructKeyExists(arguments.vars.sebTableAttributes,"CFC_GetArgs") )>
		<cfset arguments.vars.sebTableAttributes.CFC_GetArgs = StructNew()>
	</cfif>
	
	<cfif
			StructKeyExists(URL,arguments.urlvar)
		AND	isSimpleValue(URL[arguments.urlvar])
		AND	Len(URL[arguments.urlvar])
		AND	URL[arguments.urlvar] NEQ 0
	>
		<cfif Len(arguments.method)>
			<cfinvoke returnvariable="label"  component="#arguments.comp#" method="#arguments.method#">
				<cfinvokeargument name="1" value="#URL[arguments.urlvar]#">
			</cfinvoke>
		<cfelse>
			<cfset label = URL[arguments.urlvar]>
			<cfif isDate(label)>
				<cfset label = DateFormat(label,"mmmm d, yyyy")>
			<cfelse>
				<cfset label = HTMLEditFormat(label)>
			</cfif>
		</cfif>
		<!---<cfset label = arguments.comp.getLabelFieldValue(URL[arguments.urlvar])>--->
		<cfif Len(label)>
			<cfif NOT StructKeyExists(arguments.vars,"TitleBase")>
				<cfset arguments.vars.TitleBase = arguments.vars.Title>
			</cfif>
			<cfif NOT StructKeyExists(arguments.vars,"TitleExt")>
				<cfset arguments.vars.TitleExt = "">
			</cfif>
			<cfif arguments.TitleJoin CONTAINS "[title]" AND arguments.TitleJoin CONTAINS "[label]">
				<cfset arguments.vars.Title = ReplaceNoCase(arguments.TitleJoin,"[title]",arguments.Title)>
				<cfset arguments.vars.Title = ReplaceNoCase(arguments.TitleJoin,"[label]",label)>
			<cfelse>
				<cfif isDate(label)>
					<cfset arguments.vars.TitleExt = "#arguments.vars.TitleExt# #arguments.TitleJoin# #label#">
				<cfelse>
					<cfset arguments.vars.TitleExt = "#arguments.vars.TitleExt# #arguments.TitleJoin# ""#label#""">
				</cfif>
				<cfset arguments.vars.Title = "#arguments.vars.TitleBase# #arguments.vars.TitleExt#">
			</cfif>
			<cfset arguments.vars[arguments.structname][arguments.key] = URL[arguments.urlvar]>
			<cfset StructAppend(arguments.vars.sebTableAttributes.CFC_GetArgs,arguments.vars[arguments.structname],true)>
		</cfif>
		<cfset arguments.vars.sebTableAttributes.urlvars = ListAppend(arguments.vars.sebTableAttributes.urlvars,arguments.urlvar)>
	</cfif>
	
</cffunction>

<cffunction name="getFieldsArray" access="public" returntype="array" output="no">
	
	<cfset var aResult = ArrayNew(1)>
	
	<cfif StructKeyExists(arguments,"1") AND NOT StructKeyExists(arguments,"transformer")>
		<cfset arguments["transformer"] = arguments[1]>
	</cfif>
	
	<cfif isThisValidComp()>
		<cftry>
			<cfset aResult = variables.this.getFieldsArray(argumentCollection=arguments)>
		<cfcatch>
		</cfcatch>
		</cftry>
	</cfif>
	
	<cfreturn aResult>
</cffunction>

<cffunction name="getFieldsStruct" access="public" returntype="struct" output="no">
	
	<cfset var sResult = StructNew()>
	
	<cfif StructKeyExists(arguments,"1") AND NOT StructKeyExists(arguments,"transformer")>
		<cfset arguments["transformer"] = arguments[1]>
	</cfif>
	
	<cfif isThisValidComp()>
		<cftry>
			<cfset sResult = variables.this.getFieldsStruct(argumentCollection=arguments)>
		<cfcatch>
		</cfcatch>
		</cftry>
	</cfif>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="getMetaStruct" access="public" returntype="struct" output="no">
	
	<cfset var sResult = StructNew()>
	
	<cfif isThisValidComp()>
		<cftry>
			<cfset sResult = variables.this.getMetaStruct(argumentCollection=arguments)>
		<cfcatch>
		</cfcatch>
		</cftry>
	</cfif>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="getParentComponent" access="public" returntype="any" output="no">
	
	<cfif isThisValidComp()>
		<cfreturn variables.this.getParentComponent(argumentCollection=arguments)>
	</cfif>
</cffunction>

<cffunction name="param" access="public" returntype="any" output="no" hint="I provide a default value if the variable doesn't exist or isn't of the appropriate data type.">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="type" type="string" required="yes">
	<cfargument name="default" type="any" required="yes">
	<cfargument name="valuelist" type="string" default="">
	
	<cfif NOT isVarType(arguments.name,arguments.type,arguments.valuelist)>
		<cfset setVariable(arguments.name,arguments.default)>
	</cfif>
	
</cffunction>

<cffunction name="require" access="public" returntype="any" output="no" hint="I redirect the browser if the variable doesn't exist of isn't of the appropriate data type.">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="type" type="string" required="yes">
	<cfargument name="redirect" type="string" required="no">
	<cfargument name="valuelist" type="string" default="">
	
	<cfif NOT isVarType(arguments.name,arguments.type,arguments.valuelist)>
		<cfif StructKeyExists(Arguments,"redirect")>
			<cfset go(arguments.redirect)>
		<cfelse>
			<cfset go()>
		</cfif>
	</cfif>
	
</cffunction>

<cffunction name="setInherits" access="public" returntype="any" output="no" hint="I set a component that the page controller should attempt to effectively inherit (by use of onMissingMethod).">
	<cfargument name="component" type="any" required="yes">
	
	<cfset var key = "">
	
	<cfif isSimpleValue(arguments.component) AND StructKeyExists(variables,arguments.component)>
		<cfset arguments.component = variables[arguments.component]>
	</cfif>
	
	<cfif isObject(arguments.component)>
		<cfset variables.this = arguments.component>
		<cfset me["inherits"] = arguments.component>
		<cfloop collection="#variables.this#" item="key">
			<cfif isObject(variables.this[key]) AND NOT StructKeyExists(me,key)>
				<cfset me[key] = variables.this[key]>
			</cfif>
		</cfloop>
	</cfif>
	
</cffunction>

<cffunction name="isVarType" access="private" returntype="boolean" output="no" hint="I check if the given variable both exists and is the appropriate datatype.">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="type" type="string" required="yes">
	<cfargument name="valuelist" type="string" default="">
	
	<cfset var result = false>
	<cfset var varval = 0>
	
	<cfif isDefined(arguments.name)>
		<cfset varval = evaluate(arguments.name)>
		<cfswitch expression="#arguments.type#">
		<cfcase value="array">
			<cfset result = isArray(varval)>
		</cfcase>
		<cfcase value="boolean">
			<cfset result = isBoolean(varval)>
		</cfcase>
		<cfcase value="date">
			<cfset result = isDate(varval)>
		</cfcase>
		<cfcase value="integer">
			<cfif Val(varval) GT 0 AND NOT ListLen(varval) GT 1>
				<cfset varval = Val(varval)>
				<cfset setVariable(arguments.name,Val(varval))>
			</cfif>
			<cfset result = (isNumeric(varval) AND int(varval) EQ varval )>
			<cfif varval GT (2^31)>
				<cfset result = false>
			</cfif>
		</cfcase>
		<cfcase value="numeric">
			<cfif Val(varval) GT 0 AND NOT ListLen(varval) GT 1>
				<cfset varval = Val(varval)>
				<cfset setVariable(arguments.name,Val(varval))>
			</cfif>
			<cfset result = isNumeric(varval)>
		</cfcase>
		<cfcase value="query">
			<cfset result = isQuery(varval)>
		</cfcase>
		<cfcase value="string">
			<cfset result = isSimpleValue(varval)>
		</cfcase>
		<cfcase value="struct">
			<cfset result = isStruct(varval)>
		</cfcase>
		<cfcase value="UUID">
			<!--- Thanks to: http://www.monochrome.co.uk/blog/2004/09/06/isuuid --->
			<cfset result = ( isSimpleValue(varval) AND REFindNoCase("^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{16}$", varval) )>
		</cfcase>
		<cfcase value="GUID,idstamp">
			<!--- Thanks to: http://www.robgonda.com/blog/index.cfm/2007/2/4/ColdFusion-Vs-SQL-UUID --->
			<cfset result = ( isSimpleValue(varval) AND REFindNoCase("^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$", varval) )>
		</cfcase>
		</cfswitch>
		
		<!--- If a value list is passed, make sure value is in it --->
		<cfif result AND Len(arguments.valuelist) AND isSimpleValue(varval) AND NOT ListFindNoCase(arguments.valuelist,varval)>
			<cfset result = false>
		</cfif>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="isThisValidComp" access="private" returntype="boolean" output="no">
	
	<cfset var result = false>
	<cfset var sMeta = 0>
	
	<!--- variables.this is valid if it is a component --->
	<cfif
			StructKeyExists(variables,"this")
		AND	isObject(variables.this)
	>
		<cfset sMeta = getMetaData(variables.this)>
		<cfset result = true>
		<!--- So long as that component doesn't extend this one (because then we put ourselves in an endless loop) --->
		<cfif StructKeyExists(sMeta,"extends") AND StructKeyExists(sMeta.extends,"name")>
			<cfloop condition="#StructKeyExists(sMeta,'extends')#">
				<cfif sMeta.name CONTAINS "_framework.PageController">
					<cfset result = false>
					<cfbreak>
				</cfif>
				<cfset sMeta = sMeta.extends>
			</cfloop>
		</cfif>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getSecurityService" access="public" returntype="any" output="no">
	<cfargument name="type" type="string" required="no">
	
	<cfif hasSecurityService()>
		<cfreturn variables.instance.Framework.getSpecialService("Security")>
	</cfif>
</cffunction>

<cffunction name="hasSecurityService" access="public" returntype="boolean" output="no">
	
	<cfset var result = (
			StructKeyExists(variables,"instance")
		AND	StructKeyExists(variables.instance,"Framework")
		AND	StructKeyExists(variables.instance.Framework,"getSpecialService")
		AND	StructKeyExists(variables.instance.Framework,"hasSpecialService")
		AND	variables.instance.Framework.hasSpecialService("Security")
	)>
	
	<cfreturn result>
</cffunction>

<cffunction name="StructFromArgs" access="private" returntype="struct" output="false" hint="">
	
	<cfset var sTemp = 0>
	<cfset var sResult = StructNew()>
	<cfset var key = "">
	
	<cfif ArrayLen(arguments) EQ 1 AND isStruct(arguments[1])>
		<cfset sTemp = arguments[1]>
	<cfelse>
		<cfset sTemp = arguments>
	</cfif>
	
	<!--- set all arguments into the return struct --->
	<cfloop collection="#sTemp#" item="key">
		<cfif StructKeyExists(sTemp, key)>
			<cfset sResult[key] = sTemp[key]>
		</cfif>
	</cfloop>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="onMissingMethod" access="public" returntype="any" output="no">
	
	<cfset var result = 0>
	<cfset var method = arguments.missingMethodName>
	<cfset var args = StructNew()>
	<cfset var isValid = false>
	
	<cfset args = arguments.missingMethodArguments>
	
	<cfif isThisValidComp()>
		<!--- Method is valid if it exists in component --->
		<cfif StructKeyExists(variables.this,method)>
			<cfset isValid = true>
		</cfif>
		<!--- Method is not valid unless it is acess of "remote" or "public" --->
		<cfif
			NOT (
					StructKeyExists(variables.this,method)
				AND	StructKeyExists(variables.this[method],"access")
				AND	(
							variables.this[method].access EQ "remote"
						OR	variables.this[method].access EQ "public"
					)
			)
		>
			<cfset isValid = false>
		</cfif>
		<cfif StructKeyExists(variables.this,"onMissingMethod")>
			<cfset isValid = true>
		</cfif>
		<!--- Remotely called method must be access="remote" --->
		<!--- <cfif StructKeyExists(URL,"method") AND URL.method EQ method>
			<cfif
				NOT (
						StructKeyExists(variables.this[method],"access")
					AND	variables.this[method].access EQ "remote"
				)
			>
				<cfset isValid = false>
			</cfif>
		</cfif> --->
	<cfelse>
		<cfset isValid = false>
	</cfif>
	
	<cfif StructKeyExists(args,"isPageControllerMissingMethodHandler")>
		<cfset isValid = false>
	</cfif>
	
	<cfif isValid>
		<cfset args["isPageControllerMissingMethodHandler"] = true>
		<cfinvoke
			returnvariable="result"
			component="#variables.this#"
			method="#method#"
			argumentCollection="#args#"
		>
	<cfelse>
		<cfthrow message="The method #arguments.missingMethodName# was not found in component #getMetaData(this).name#" detail=" Ensure that the method is defined, and that it is spelled correctly.">
	</cfif>
	
	<cfif isDefined("result")>
		<cfreturn result>
	</cfif>
	
</cffunction>

</cfcomponent>