<!--- 1.0 Beta 3 (Build 35) --->
<!--- Last Updated: 2011-11-23 --->
<!--- Created by Steve Bryant 2007-09-13 --->
<!--- Information: http://www.bryantwebconsulting.com/docs/com-sebtools/records.cfm?version=Build%2012 --->
<cfcomponent output="false">

<cfset variables.sSpecifyingValues = StructNew()>
<cfset variables.OnExists = "save">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="Manager" type="any" required="yes">
	
	<cfset initInternal(argumentCollection=arguments)>
	
	<cfreturn this>
</cffunction>

<cffunction name="initInternal" access="private" returntype="any" output="no">
	<cfargument name="Manager" type="any" required="yes">
	
	<cfset var key = "">
	<cfset var metaXml = "">
	
	<cfset StructAppend(variables,arguments)>
	
	<!--- Get all components from Manager --->
	<cfloop collection="#variables.Manager#" item="key">
		<cfif isObject(variables.Manager[key])>
			<cfset variables[key] = variables.Manager[key]>
		</cfif>
	</cfloop>
	
	<!--- Get all components from arguments --->
	<cfloop collection="#arguments#" item="key">
		<cfif isObject(arguments[key])>
			<cfset variables[key] = arguments[key]>
			<cfset This[key] = arguments[key]>
		</cfif>
	</cfloop>
	
	<cfset metaXml = getMethodOutputValue(variables,"xml")>
	
	<cfif NOT isDefined("metaXml")>
		<cfthrow type="Records" message="Your xml method must return the XML that it creates.">
	</cfif>
	<cfif Len(metaXml)>
		<cfset variables.xDef = variables.Manager.loadXml(metaXml)>
	</cfif>
	
	<cfset variables.sMetaData = variables.Manager.getMetaStruct()>
	<cfset variables.cachedata = StructNew()>
	<cfset variables.datasource = variables.DataMgr.getDatasource()>
	<cfset variables.table = getTableVariable(metaXml)>
	
	<cfif StructKeyExists(variables.sMetaData,variables.table)>
		<cfset variables.labelSingular = variables.sMetaData[variables.table].labelSingular>
		<cfset variables.labelPlural = variables.sMetaData[variables.table].labelPlural>
		<cfif StructKeyExists(variables.sMetaData[variables.table],"methodSingular")>
			<cfset variables.methodSingular = variables.sMetaData[variables.table].methodSingular>
		</cfif>
		<cfif StructKeyExists(variables.sMetaData[variables.table],"methodPlural")>
			<cfset variables.methodPlural = variables.sMetaData[variables.table].methodPlural>
		</cfif>
	</cfif>
	
	<cfif NOT StructKeyExists(variables,"labelSingular")>
		<cfset variables.labelSingular = "Record">
	</cfif>
	<cfif NOT StructKeyExists(variables,"labelPlural")>
		<cfset variables.labelPlural = "Records">
	</cfif>
	<cfif NOT StructKeyExists(variables,"methodSingular")>
		<cfset variables.methodSingular = variables.labelSingular>
	</cfif>
	<cfif NOT StructKeyExists(variables,"methodPlural")>
		<cfset variables.methodPlural = variables.labelPlural>
	</cfif>
	<cfset variables.methodSingular = makeCompName(variables.methodSingular)>
	<cfset variables.methodPlural = makeCompName(variables.methodPlural)>
	
	<cfset setMetaStruct()>
	
	<cfset addMethods()>
	
</cffunction>

<cffunction name="getFieldList" access="public" returntype="string" output="no">
	<cfreturn variables.sMetaData[variables.table].fieldlist>
</cffunction>

<cffunction name="getPrimaryKeyValues" access="public" returntype="string" output="no">
	
	<cfset var sMetaStruct = getMetaStruct()>
	
	<cfif StructKeyExists(sMetaStruct,"arg_pk")>
		<cfset Arguments.field = sMetaStruct["arg_pk"]>
		<cfinvoke returnvariable="result" method="getTableFieldValue" argumentcollection="#Arguments#">
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getTableFieldValue" access="public" returntype="string" output="no">
	
	<cfset var sMetaStruct = getMetaStruct()>
	<cfset var sFields = getFieldsStruct()>
	<cfset var qRecords= 0>
	<cfset var result = "">
	
	<cfif NOT (
			StructKeyExists(Arguments,"field")
		AND	Len(arguments.field)
		AND	ListLen(Arguments.field) EQ 1
		AND	StructKeyExists(sFields,Arguments.field)
	)>
		<cfset throwError("getTableFieldValue must have a field argument with one and only one field from this table.")>
	</cfif>
	
	<cfset Arguments.fieldlist = Arguments.field>
	<cfinvoke component="#This#" method="#sMetaStruct.method_gets#" returnvariable="qRecords" argumentcollection="#Arguments#">
	
	<cfif qRecords.RecordCount>
		<cfset result = ArrayToList(qRecords[Arguments.field])>
	<cfelseif StructKeyExists(sFields[Arguments.field],"default")>
		<cfset result = sFields[Arguments.field]["default"]>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getTableVariable" access="public" returntype="string" output="no">
	<cfargument name="metaXml" type="string" default="">
	
	<cfset var result = "">
	<cfset var xDef = 0>
	
	<cfif StructKeyExists(variables,"table")>
		<cfset result = variables.table>
	<cfelse>
		<!--- Allow component to be created init(Manager=Manager,table=tablename) --->
		<cfif StructKeyExists(arguments,"table") AND isSimpleValue(arguments.table)>
			<cfset result = arguments.table>
		<cfelseif StructKeyExists(variables,"xDef")>
			<cfset result = variables.xDef.tables.table[1].XmlAttributes.name>
		<!---<cfelseif Len(metaXml)>
			<cfset xDef = XmlParse(metaXml)>
			<cfset result = xDef.tables.table[1].XmlAttributes.name>--->
		<cfelseif StructKeyExists(variables,"Parent") AND isObject(variables.Parent) AND StructKeyExists(variables.Parent,"getComponentTableName")>
			<cfset result = variables.Parent.getComponentTableName(This)>
		</cfif>
	</cfif>
	
	<cfif Len(result)>
		<cfset variables.table = result>
	<cfelse>
		<cfthrow type="Records" message="If xml method is not provided, variables.table must be set.">
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="copyRecord" access="public" returntype="string" output="no">
	
	<cfset var result = Variables.Manager.copyRecord(tablename=Variables.table,data=Arguments)>
	
	<cfset notifyEvent(EventName=variables.sMetaStruct["method_copy"],Args=Arguments,result=result)>
	
	<cfreturn result>
</cffunction>

<cffunction name="getFieldsArray" access="public" returntype="array" output="no">
	<cfargument name="transformer" type="string" required="no">
	
	<cfif StructKeyExists(variables,"cachedata") AND StructKeyExists(variables.cachedata,"FieldsArray") AND isArray(variables.cachedata["FieldsArray"]) AND NOT StructCount(arguments)>
		<cfreturn variables.cachedata["FieldsArray"]>
	<cfelse>
		<cfset arguments["tablename"] = variables.table>
		<cfreturn variables.Manager.getFieldsArray(argumentCollection=arguments)>
	</cfif>
</cffunction>

<cffunction name="getFieldsStruct" access="public" returntype="struct" output="no">
	<cfargument name="transformer" type="string" required="no">
	
	<cfif StructKeyExists(variables,"cachedata") AND StructKeyExists(variables.cachedata,"FieldsStruct") AND isStruct(variables.cachedata["FieldsStruct"]) AND NOT StructCount(arguments)>
		<cfreturn variables.cachedata["FieldsStruct"]>
	<cfelse>
		<cfset arguments["tablename"] = variables.table>
		<cfreturn variables.Manager.getFieldsStruct(argumentCollection=arguments)>
	</cfif>
</cffunction>

<cffunction name="getFolder" access="public" returntype="string" output="no">
	<cfargument name="field" type="string" required="yes">
	
	<cfset var sFields = getFieldsStruct()>
	<cfset var result = "">
	
	<cfif StructKeyExists(sFields,arguments.field) AND StructKeyExists(sFields[arguments.field],"folder")>
		<cfset result = sFields[arguments.field]["folder"]>
	</cfif>
	
	<cfreturn variables.FileMgr.convertFolder(result,"/")>
</cffunction>

<cffunction name="getLabelFieldValue" access="public" returntype="string" output="no">
	
	<cfset var qRecord = 0>
	<cfset var sManagerData = variables.Manager.getMetaStruct(variables.table)>
	<cfset var sArgs = StructNew()>
	<cfset var result = "">
	
	<cfif NOT StructKeyExists(sManagerData,"labelField")>
		<cfthrow message="getLabelFieldValue can only be used against tables with a defined labelField." type="Records">
	</cfif>
	
	<cfset qRecord = variables.Manager.getRecord(tablename=variables.table,data=arguments,fieldlist=sManagerData.labelField)>
	
	<cfif qRecord.RecordCount>
		<cfset result = qRecord[sManagerData.labelField][1]>
	</cfif>
	
	<!---<cfset sArgs.field = sManagerData.labelField>
	<cfset Arguments.tablename = Variables.table>
	<cfset sArgs.data = Variables.Manager.alterArgs(ArgumentCollection=Arguments)>
	<cfdump var="#sArgs#"><cfabort>
	<cfreturn getTableFieldValue(ArgumentCollection=sArgs)>--->
	
	<cfreturn result>
</cffunction>

<cffunction name="getMetaStruct" access="public" returntype="struct" output="no">
	
	<cfif NOT StructKeyExists(variables,"sMetaStruct")>
		<cfset setMetaStruct()>
	</cfif>
	
	<cfreturn variables.sMetaStruct>
</cffunction>

<cffunction name="getServiceComponent" access="public" returntype="any" output="no">
	<cfargument name="name" type="string" required="true">
	
	<cfset var result = arguments.name>
	
	<cfif StructKeyExists(variables,"Parent") AND isObject(variables.Parent) AND StructKeyExists(variables.Parent,arguments.name)>
		<cfset result = variables.Parent[arguments.name]>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getParentComponent" access="public" returntype="any" output="no">
	<cfif StructKeyExists(variables,"Parent") AND isObject(variables.Parent)>
		<cfreturn variables.Parent>
	</cfif>
</cffunction>

<cffunction name="getPKRecord" access="public" returntype="query" output="no">
	
	<cfreturn variables.Manager.getPKRecord(tablename=arguments.table,data=arguments)>
</cffunction>

<cffunction name="getRecord" access="public" returntype="query" output="no">
	
	<cfset StructAppend(alterArgs(argumentCollection=arguments),getSpecifyingValues())>
	
	<cfreturn variables.Manager.getRecord(tablename=variables.table,data=arguments)>
</cffunction>

<cffunction name="getRecords" access="public" returntype="query" output="no">
	
	<cfset StructAppend(alterArgs(argumentCollection=arguments),getSpecifyingValues(),"no")>
	
	<cfreturn variables.Manager.getRecords(tablename=variables.table,data=arguments)>
</cffunction>

<cffunction name="getTableMetaStruct" access="public" returntype="struct" output="false" hint="">
	<cfreturn variables.Manager.getMetaStruct(variables.table)>
</cffunction>

<cffunction name="hasRecords" access="public" returntype="boolean" output="no">
	
	<cfset var result = false>
	
	<cfif StructKeyExists(variables.DataMgr,"hasRecords")>
		<cfset arguments.tablename = variables.table>
		<cfset arguments.alterargs_for = "has">
		<cfset arguments.data = alterArgs(argumentCollection=arguments)>
		
		<cfset result = variables.DataMgr.hasRecords(argumentCollection=variables.Manager.alterArgs(argumentCollection=arguments))>
	<cfelse>
		<cfset result = (numRecords(argumentCollection=arguments) GT 0)>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="numRecords" access="public" returntype="numeric" output="no">
	
	<cfset var sArgs = StructNew()>
	<cfset var qRecords = 0>
	
	<cfset sArgs["tablename"] = variables.table>
	<cfset sArgs["Function"] = "count">
	<cfset sArgs["FunctionAlias"] = "NumRecords">
	<cfset sArgs["data"] = alterArgs(argumentCollection=arguments)>
	<cfset sArgs["fieldlist"] = "">
	
	<cfset qRecords = variables.Manager.getRecords(argumentCollection=sArgs)>
	
	<cfreturn Val(qRecords.NumRecords)>
</cffunction>

<cffunction name="deleteRecord" access="public" returntype="void" output="no">
	<cfset removeRecord(argumentCollection=arguments)>
</cffunction>

<cffunction name="removeRecord" access="public" returntype="void" output="no">
	
	<cfset variables.Manager.removeRecord(variables.table,arguments)>
	
	<cfset notifyEvent(EventName=variables.sMetaStruct["method_remove"],Args=Arguments)>
	
</cffunction>

<cffunction name="RecordObject" access="public" returntype="any" output="no">
	<cfargument name="Record" type="any" required="yes">
	<cfargument name="fields" type="string" default="">
	
	<cfset Arguments.Service = This>
	
	<cfreturn CreateObject("component","RecordObject").init(ArgumentCollection=Arguments)>
</cffunction>

<cffunction name="saveRecord" access="public" returntype="string" output="no">
	
	<cfset var sArgs = 0>
	<cfset var sSpecifyingValues = getSpecifyingValues()>
	<cfset var result = 0>
	
	<cfif StructCount(sSpecifyingValues) AND NOT isUpdate()>
		<cfset StructAppend(Arguments,sSpecifyingValues,"no")>
	</cfif>
	
	<cfinvoke component="#This#" method="validate#variables.methodSingular#" argumentCollection="#arguments#" returnvariable="Arguments">
	
	<cfif NOT StructKeyExists(Arguments,"OnExists")>
		<cfset Arguments.OnExists = Variables.OnExists>
	</cfif>
	
	<cfset result = variables.Manager.saveRecord(variables.table,Arguments)>
	
	<cfset notifyEvent(EventName=variables.sMetaStruct["method_save"],Args=Arguments,result=result)>
	
	<cfreturn result>
</cffunction>

<cffunction name="saveRecordOnly" access="public" returntype="string" output="no">
	
	<cfset var sSpecifyingValues = getSpecifyingValues()>
	
	<cfif StructCount(sSpecifyingValues) AND NOT isUpdate()>
		<cfset StructAppend(Arguments,sSpecifyingValues,"no")>
	</cfif>
	
	<cfreturn variables.Manager.saveRecord(variables.table,Arguments)>
</cffunction>

<cffunction name="Security_getPermissions" access="public" returntype="string" output="no">
	<cfreturn Variables.Manager.Security_getPermissions(variables.table)>
</cffunction>

<cffunction name="sortRecords" access="public" returntype="void" output="no">
	
	<cfset var sortfield = getSortField()>
	
	<cfif Len(sortfield)>
		<cfif StructKeyExists(arguments,variables.methodPlural)>
			<cfset variables.DataMgr.saveSortOrder(variables.table,sortfield,arguments[variables.methodPlural])>
		<cfelseif ArrayLen(arguments) AND ListLen(arguments[1]) GT 1>
			<cfset variables.DataMgr.saveSortOrder(variables.table,sortfield,arguments[1])>
		</cfif>
	</cfif>
	
	<cfset notifyEvent(EventName=variables.sMetaStruct["method_sort"],Args=Arguments)>
	
</cffunction>

<cffunction name="validateRecord" access="public" returntype="struct" output="no">
	
	<cfreturn Arguments>
</cffunction>

<cffunction name="addMethods" access="private" returntype="void" output="no">
	
	<cfset var singular = variables.methodSingular>
	<cfset var plural = variables.methodPlural>
	<cfset var methods = "get#singular#,get#plural#,remove#singular#,save#singular#,sort#plural#,copy#singular#,num#plural#,has#plural#,validate#singular#">
	<cfset var rmethods = "getRecord,getRecords,removeRecord,saveRecord,sortRecords,copyRecord,numRecords,hasRecords,validateRecord">
	<cfset var method = "">
	<cfset var rmethod = "">
	<cfset var ii = 0>
	<cfset var sMetaStruct = getMetaStruct()>
	
	<cfif StructKeyExists(sMetaStruct,"arg_pk")>
		<cfset methods = ListAppend(methods,"get#sMetaStruct.arg_pk#s")>
		<cfset rmethods = ListAppend(rmethods,"getPrimaryKeyValues")>
	</cfif>
	
	<cfloop index="ii" from="1" to="#ListLen(methods)#" step="1">
		<cfset method = ListGetAt(methods,ii)>
		<cfset rmethod = ListGetAt(rmethods,ii)>
		<cfif NOT StructKeyExists(This,method)>
			<cfset This[method] = variables[rmethod]>
		</cfif>
		<cfif NOT StructKeyExists(variables,method)>
			<cfset variables[method] = variables[rmethod]>
		</cfif>
	</cfloop>
	
</cffunction>

<cffunction name="alterArgs" access="private" returntype="struct" output="no">
	<cfreturn arguments>
</cffunction>

<!---<cffunction name="adjustImages" access="private" returntype="struct" output="no">
	
	<cfreturn variables.Manager.adjustImages(variables.table,arguments)>
</cffunction>--->

<!---<cffunction name="getFieldsArrayInternal" access="private" returntype="array" output="no">
	<cfargument name="transformer" type="string" default="">
	<cfargument name="table" type="string" default="#variables.table#">
	
	<cfreturn variables.Manager.getFieldsArrayInternal(transformer=arguments.transformer,tablename=arguments.table)>
</cffunction>--->

<!---<cffunction name="fixFileNames" access="private" returntype="any" output="false" hint="">
	
	<cfset var FileFields = getFieldsOfTypes("file,image,thumb")>
	<cfset var PKFields = getFieldsOfTypes("pk:integer,pk:text")>
	<cfset var Fields = ListAppend(PKFields,FileFields)>
	<cfset var qRecords = 0>
	<cfset var field = "">
	<cfset var folder = "">
	<cfset var path = "">
	<cfset var NewFileName = "">
	<cfset var sData = StructNew()>
	<cfset var pkfield = "">
	
	<cfset qRecords = variables.DataMgr.getRecords(tablename=variables.table,fieldlist=Fields)>
	
	<cfloop list="#FileFields#" index="field">
		<cfset folder = getFolder(field)>
		<cfset path = variables.FileMgr.getDirectory(folder)>
		<cfloop query="qRecords">
			<cfset NewFileName = variables.Manager.fixFileName(qRecords[field][CurrentRow],path)>
			<!-- If file name changed, update record -->
			<cfif NewFileName NEQ qRecords[field][CurrentRow]>
				<cfset sData = StructNew()>
				<cfloop list="#PKFields#" index="pkfield">
					<cfset sData[pkfield] = qRecords[pkfield][CurrentRow]>
				</cfloop>
				<cfset sData[field] = NewFileName>
				<cfset variables.DataMgr.updateRecord(variables.table,sData)>
			</cfif>
		</cfloop>
	</cfloop>
	
</cffunction>--->

<cffunction name="getFieldsOfTypes" access="public" returntype="string" output="false" hint="">
	<cfargument name="Types" type="string" required="yes">
	
	<cfset var aFields = getFieldsArray()>
	<cfset var ii = 0>
	<cfset var result = "">
	
	<cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
		<cfif StructKeyExists(aFields[ii],"type") AND ListFindNoCase(arguments.Types,aFields[ii].type)>
			<cfset result = ListAppend(result,aFields[ii].name)>
		</cfif>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<!---<cffunction name="getFieldsStructInternal" access="private" returntype="struct" output="no">
	<cfargument name="transformer" type="string" required="no">
	
	<cfset var sFields = StructNew()>
	<cfset var aFields = getFieldsArrayInternal(argumentCollection=arguments)>
	<cfset var ii = 0>
	
	<cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
		<cfif StructKeyExists(aFields[ii],"name")>
			<cfset sFields[aFields[ii]["name"]] = aFields[ii]>
		</cfif>
	</cfloop>
	
	<cfreturn sFields>
</cffunction>--->

<cffunction name="getMethodOutputValue" access="private" returntype="string" output="no" hint="DEPRECATED">
	<cfargument name="component" type="any" required="yes">
	<cfargument name="method" type="string" required="yes">
	<cfargument name="args" type="struct" required="no">
	
	<cfset var result = "">
	<cfset var fMethod = component[method]>
	
	<cfif StructKeyExists(arguments,"args")>
		<cfsavecontent variable="result"><cfoutput>#fMethod(argumentCollection=args)#</cfoutput></cfsavecontent>
	<cfelse>
		<cfsavecontent variable="result"><cfoutput>#fMethod()#</cfoutput></cfsavecontent>
	</cfif>
	
	<cfset result = Trim(result)>
	
	<cfreturn result>
</cffunction>

<cffunction name="getSortField" access="private" returntype="string" output="no">
	<cfif StructKeyExists(variables,"cachedata") AND StructKeyExists(variables.cachedata,"SortField") AND isSimpleValue(variables.cachedata["SortField"])>
		<cfreturn variables.cachedata["SortField"]>
	<cfelse>
		<cfreturn getSortFieldInternal(argumentCollection=arguments)>
	</cfif>
</cffunction>

<cffunction name="getSortFieldInternal" access="private" returntype="string" output="no">
	
	<cfset var aFields = getFieldsArray()>
	<cfset var ii = 0>
	<cfset var result = "">
	
	<cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
		<cfif StructKeyExists(aFields[ii],"type") AND aFields[ii].type EQ "Sorter">
			<cfset result = aFields[ii].name>
			<cfbreak>
		</cfif>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<cffunction name="getSpecifyingValues" access="public" returntype="struct" output="no">
	<cfreturn variables.sSpecifyingValues>
</cffunction>

<cffunction name="getTableList" access="private" returntype="string" output="no" hint="I return a list of tables being referenced in this component.">
	
	<cfset var ii = 0>
	<cfset var result = "">
	
	<cfif StructKeyExists(variables,"xDef")>
		<cfloop index="ii" from="1" to="#ArrayLen(variables.xDef.tables.table)#" step="1">
			<cfset result = ListAppend(result,variables.xDef.tables.table[ii].XmlAttributes.name)>
		</cfloop>
	<cfelse>
		<cfset result = variables.table>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="isUpdate" access="public" returntype="boolean" output="no">
	
	<cfset var result = false>
	
	<cfreturn Variables.DataMgr.isMatchingRecord(tablename=variables.table,data=StructFromArgs(arguments),pksonly=(variables.OnExists EQ "save"))>
</cffunction>

<cffunction name="setMetaStruct" access="public" returntype="struct" output="no">
	
	<cfset var sMethods = StructNew()>
	<cfset var aPKFields = variables.Manager.DataMgr.getPKFields(getTableVariable())>
	<cfset var sManagerData = variables.Manager.getMetaStruct(getTableVariable())>
	<cfset var single = variables.methodSingular>
	<cfset var plural = variables.methodSingular>
	<cfset var sParent = 0>
	
	<cfif StructKeyExists(sManagerData,"labelField")>
		<cfset sMethods["field_label"] = "#sManagerData.labelField#">
	</cfif>
	<cfif StructKeyExists(sManagerData,"entity")>
		<cfset sMethods["entity"] = "#sManagerData.entity#">
		<cfset sMethods["entities"] = "#variables.Manager.pluralize(sManagerData.entity)#">
		<cfset single = sMethods["entity"]>
		<cfset plural = sMethods["entities"]>
	</cfif>
	<cfset sMethods["label_Singular"] = "#variables.labelSingular#">
	<cfset sMethods["label_Plural"] = "#variables.labelPlural#">
	<cfset sMethods["method_Singular"] = "#variables.methodSingular#">
	<cfset sMethods["method_Plural"] = "#variables.methodPlural#">
	<cfset sMethods["method_copy"] = "copy#variables.methodSingular#">
	<cfset sMethods["method_get"] = "get#variables.methodSingular#">
	<cfset sMethods["method_gets"] = "get#variables.methodPlural#">
	<cfset sMethods["method_remove"] = "remove#variables.methodSingular#">
	<cfset sMethods["method_save"] = "save#variables.methodSingular#">
	<cfset sMethods["method_sort"] = "sort#variables.methodPlural#">
	<cfset sMethods["method_delete"] = "remove#variables.methodSingular#">
	<cfset sMethods["method_validate"] = "validate#variables.methodSingular#">
	<cfset sMethods["method_security_permissions"] = "Security_GetPermissions">
	<cfif StructKeyExists(sManagerData,"deletable")>
		<cfset sMethods["property_deletable"] = "#sManagerData.deletable#">
	</cfif>
	<cfset sMethods["property_hidecols"] = true>
	<cfset sMethods["property_pktype"] = variables.Manager.getPrimaryKeyType(getTableVariable())>
	<cfset sMethods["message_save"] = "#variables.labelSingular# Saved.">
	<cfset sMethods["message_remove"] = "#variables.labelSingular# Deleted.">
	<cfset sMethods["message_sort"] = "#variables.labelPlural# Sorted.">
	
	<cfset sMethods["arg_sort"] = "#variables.methodPlural#">
	<cfset sMethods["catch_types"] = "#variables.methodPlural#">
	<cfif StructKeyExists(Variables,"Parent") AND isObject(Variables.Parent)>
		<cfif StructKeyExists(Variables.Parent,"getErrorType")>
			<cfset sMethods["catch_types"] = ListAppend(sMethods["catch_types"],Variables.Parent.getErrorType())>
		<cfelse>
			<cfset sParent = getMetaData(Variables.Parent)>
			<cfset sMethods["catch_types"] = ListAppend(sMethods["catch_types"],ListFirst(ListLast(sParent.name,'.')),'_')>
		</cfif>
	</cfif>
	
	<cfset sMethods["pkfields"] = variables.Manager.getPrimaryKeyFields(getTableVariable())>
	<cfif ArrayLen(aPKFields) EQ 1>
		<cfset sMethods["arg_pk"] = aPKFields[1].ColumnName>
	</cfif>
	
	<cfset variables.sMetaStruct = sMethods>
	
	<cfreturn sMethods>
</cffunction>

<cffunction name="StructFromArgs" access="private" returntype="struct" output="false" hint="">
	
	<cfset var sTemp = 0>
	<cfset var sResult = StructNew()>
	<cfset var key = "">
	
	<cfif StructCount(arguments) EQ 1 AND isStruct(arguments[1])>
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

<!---<cffunction name="loadFolders" access="private" returntype="void" output="no" hint="I make sure that any needed folders exist.">
	
	<cfset var aFields = getFieldsArray()>
	<cfset var ii = 0>
	
	<cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
		<cfif StructKeyExists(aFields[ii],"Folder") AND Len(aFields[ii].Folder)>
			<cfset variables.FileMgr.makeFolder(aFields[ii].Folder)>
		</cfif>
	</cfloop>
	
</cffunction>--->

<cffunction name="dbXml" access="public" returntype="string" output="no">
	
	<cfset var result = "">
	<cfset var aFields = 0>
	<cfset var ii = 0>
	<cfset var jj = 0>
	<cfset var col = "">
	<cfset var att = "">
	<cfset var attlist = "ColumnName,CF_DataType,PrimaryKey,Increment,Length">
	<cfset var noshowatts = "name,type">
	<cfset var tables = getTableList()>
	<cfset var table = "">
	
	<cfsavecontent variable="result"><cfoutput>
	<tables><cfloop list="#tables#" index="table"><cfset aFields = variables.Manager.getFieldsArray(transformer="DataMgr",tablename=table)>
		<table name="#table#"><cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
			<field ColumnName="#aFields[ii].name#"<cfloop list="#attlist#" index="col"><cfif StructKeyExists(aFields[ii],col)> #col#="#aFields[ii][col]#"</cfif></cfloop><cfloop collection="#aFields[ii]#" item="col"><cfif isSimpleValue(aFields[ii][col]) AND NOT ListFindNoCase(noshowatts,col) AND NOT ListFindNoCase(attlist,col)> #col#="#aFields[ii][col]#"</cfif></cfloop><cfif NOT StructKeyExists(aFields[ii],"relation")> /><cfelse>>
				<relation<cfloop collection="#aFields[ii].relation#" item="col"><cfif isSimpleValue(aFields[ii].relation[col])> #col#="#XmlFormat(aFields[ii].relation[col])#"</cfif></cfloop><cfif NOT StructKeyExists(aFields[ii].relation,"filters")> /</cfif>><cfif StructKeyExists(aFields[ii].relation,"filters")><cfloop index="jj" from="1" to="#ArrayLen(aFields[ii].relation.filters)#" step="1">
					<filter<cfloop collection="#aFields[ii].relation.filters[jj]#" item="att"> #att#="#XmlFormat(aFields[ii].relation.filters[jj][att])#"</cfloop> /></cfloop>
				</relation></cfif>
			</field></cfif></cfloop>
		</table></cfloop><cfif StructKeyExists(variables,"xDef")><cfloop index="ii" from="1" to="#ArrayLen(variables.xDef.tables.XmlChildren)#" step="1">
			<cfif variables.xDef.tables.XmlChildren[ii].XmlName NEQ "table">
				#XmlAsString(variables.xDef.tables.XmlChildren[ii])#
			</cfif>
		</cfloop></cfif>
	</tables>
	</cfoutput></cfsavecontent>
	
	<cfreturn result>
</cffunction>

<cffunction name="XmlAsString" access="public" returntype="any" output="false" hint="">
	<cfargument name="XmlElem" type="any" required="yes">
	
	<cfreturn variables.Manager.XmlAsString(arguments.XmlElem)>
</cffunction>

<cffunction name="xml" access="public" returntype="string" output="no">
	
	<cfset var result = "">
	
	<cfreturn result>
</cffunction>

<cffunction name="onMissingMethod" access="public" returntype="any" output="no">
	
	<cfset var result = 0>
	<cfset var method = arguments.missingMethodName>
	<cfset var args = arguments.missingMethodArguments>
	<cfset var newmethod = "">
	<cfset var isValid = false>
	
	<cfif arguments.missingMethodName CONTAINS variables.methodPlural>
		<cfset newmethod = ReplaceNoCase(arguments.missingMethodName,variables.methodPlural,"Records")>
		<cfif StructKeyExists(this,newmethod)>
			<cfset isValid = true>
		</cfif>
	</cfif>
	<cfif NOT isValid AND arguments.missingMethodName CONTAINS variables.methodSingular>
		<cfset newmethod = ReplaceNoCase(arguments.missingMethodName,variables.methodSingular,"Record")>
		<cfif StructKeyExists(this,newmethod)>
			<cfset isValid = true>
		</cfif>
	</cfif>
	<cfif isValid>
		<cfinvoke
			returnvariable="result"
			method="#newmethod#"
			argumentCollection="#args#"
		>
	<cfelse>
		<cfthrow message="The method #arguments.missingMethodName# was not found in component #getCurrentTemplatePath()#" detail=" Ensure that the method is defined, and that it is spelled correctly.">
	</cfif>
	
	<cfif isDefined("result")>
		<cfreturn result>
	</cfif>
	
</cffunction>

<cffunction name="notifyEvent" access="package" returntype="void" output="false" hint="">
	<cfargument name="EventName" type="string" required="true">
	<cfargument name="Args" type="struct" required="false">
	<cfargument name="result" type="any" required="false">
	
	<cfif StructKeyExists(variables,"Parent") AND isObject(variables.Parent) AND StructKeyExists(variables.Parent,"notifyEvent")>
		<cfset variables.Parent.notifyEvent(ArgumentCollection=Arguments)>
	</cfif>
	
	<cfif StructKeyExists(Variables,"Observer")>
		<cfset Variables.Observer.notifyEvent(ArgumentCollection=Arguments)>
	</cfif>
	
</cffunction>

<cffunction name="throwError" access="public" returntype="void" output="false" hint="">
	<cfargument name="message" type="string" required="yes">
	<cfargument name="errorcode" type="string" default="">
	<cfargument name="detail" type="string" default="">
	<cfargument name="extendedinfo" type="string" default="">
	
	<cfset var html = "">
	
	<cfif StructKeyExists(variables,"Parent") AND isObject(variables.Parent) AND StructKeyExists(variables.Parent,"throwError")>
		<cfset variables.Parent.throwError(argumentCollection=arguments)>
	<cfelse>
		<cfthrow
			type="#variables.methodPlural#"
			message="#arguments.message#"
			errorcode="#arguments.errorcode#"
			detail="#arguments.detail#"
			extendedinfo="#arguments.extendedinfo#"
		>
	</cfif>
	
</cffunction>

<cfscript>
function makeCompName(str) { return variables.Manager.makeCompName(str); }
</cfscript>

<cfif NOT StructKeyExists(variables,"QueryRowToStruct")>
	<cfscript>
	/**
	* Makes a row of a query into a structure.
	*
	* @param query      The query to work with.
	* @param row      Row number to check. Defaults to row 1.
	* @return Returns a structure.
	* @author Nathan Dintenfass (nathan@changemedia.com)
	* @version 1, December 11, 2001
	*/
	function QueryRowToStruct(query){
	    //by default, do this to the first row of the query
	    var row = 1;
	    //a var for looping
	    var ii = 1;
	    //the cols to loop over
	    var cols = listToArray(query.columnList);
	    //the struct to return
	    var stReturn = structnew();
	    //if there is a second argument, use that for the row number
	    if(arrayLen(arguments) GT 1)
	        row = arguments[2];
	    //loop over the cols and build the struct from the query row    
	    for(ii = 1; ii lte arraylen(cols); ii = ii + 1){
	        stReturn[cols[ii]] = query[cols[ii]][row];
	    }        
	    //return the struct
	    return stReturn;
	}
	</cfscript>
</cfif>

</cfcomponent>