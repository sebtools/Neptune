<!--- 1.0 Beta 3 (Build 35) --->
<!--- Last Updated: 2011-11-23 --->
<cfcomponent>

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="Service" type="any" required="yes">
	<cfargument name="Record" type="any" required="yes">
	<cfargument name="fields" type="string" default="">
	<cfargument name="row" type="numeric" default="1">
	
	<cfset var oMe = initInternal(argumentCollection=arguments)>
	
	<cfreturn oMe>
</cffunction>

<cffunction name="initInternal" access="private" returntype="any" output="no">
	<cfargument name="Service" type="any" required="yes">
	<cfargument name="Record" type="any" required="yes">
	<cfargument name="fields" type="string" default="">
	<cfargument name="row" type="numeric" default="1">
	
	<cfset var key = "">
	<cfset var qRecord = 0>
	<cfset var sArgs = StructNew()>
	<cfset var err = "">
	
	
	<!--- If a single length array is passed in, use that --->
	<cfif isArray(Arguments.Record) AND ArrayLen(Arguments.Record) EQ 1>
		<cfset Arguments.Record = Arguments.Record[1]>
	</cfif>
	
	<cfset Variables.oService = Arguments.Service>
	<cfset Variables.sServiceInfo = Variables.oService.getMetaStruct()>
	<cfset Variables.ObjectName = "#Variables.sServiceInfo.Method_Singular#Object">
	
	<!--- Use RecordObject that is passed in. --->
	<cfif isObject(Arguments.Record) AND StructKeyExists(Arguments.Record,"loadFields")>
		<cfreturn Arguments.Record.loadFields(Arguments.fields)>
	<cfelseif
			isStruct(Arguments.Record)
		AND	StructKeyExists(Arguments.Record,Variables.ObjectName)
		AND	isObject(Arguments.Record[Variables.ObjectName])
		AND	StructKeyExists(Arguments.Record[Variables.ObjectName],"loadFields")
	>
		<cfreturn Arguments.Record[Variables.ObjectName].loadFields(Arguments.fields)>
	</cfif>
	
	<cfset Variables.instance = StructNew()>
	<cfset Variables.sFields = Variables.oService.getFieldsStruct()>
	<cfset Variables.sKeys = StructNew()>
	
	<!--- If a primary key value is passed in, use that. --->
	<cfif isSimpleValue(Arguments.Record) AND ListLen(Variables.sServiceInfo.pkfields) EQ 1>
		<cfset sArgs = StructNew()>
		<cfset sArgs[Variables.sServiceInfo.pkfields] = Arguments.Record>
		<cfset sArgs["fieldlist"] = Arguments.fields>
		<cfset Arguments.Record = StructNew()>
		<cfset Arguments.Record[Variables.sServiceInfo.pkfields] = sArgs[Variables.sServiceInfo.pkfields]>
		<!---<cfinvoke
			returnvariable="Arguments.Record"
			component="#Variables.oService#"
			method="#variables.sServiceInfo.method_get#"
			argumentCollection="#sArgs#"
		>--->
	</cfif>
	
	<!--- If a query is passed in, convert it to a structure. --->
	<cfif isQuery(Arguments.Record)>
		<cfset Arguments.Record = QueryRowToStruct(Arguments.Record,Arguments.row)>
	</cfif>
	
	<!--- If a struct is passed in, use that --->
	<cfif isStruct(Arguments.Record)>
		<cfloop collection="#Arguments.Record#" item="key">
			<cfif Len(key) AND StructKeyExists(Arguments.Record,key)>
				<cfset Variables.instance[key] = Arguments.Record[key]>
				<cfif ListFindNoCase(Variables.sServiceInfo.pkfields,key)>
					<cfset Variables.sKeys[key] = Arguments.Record[key]>
				</cfif>
			</cfif>
		</cfloop>
	<cfelse>
		<cfset err = "Record argument of RecordObject method must be a">
		<cfif ListLen(Variables.sServiceInfo.pkfields) EQ 1>
		<cfset err = "#err# primary key value,">
		</cfif>
		<cfset err = "#err# query or structure - or another RecordObject of the same type.">
		<cfset Variables.oService.throwError(err)>
	</cfif>
	
	<!--- Make sure all primary key values are stored internally --->
	<cfif StructCount(Variables.sKeys) LT ListLen(Variables.sServiceInfo.pkfields)>
		<cfset sArgs = Duplicate(Variables.instance)>
		<cfset sArgs.fieldlist = Variables.sServiceInfo.pkfields>
		<cfinvoke
			returnvariable="qRecord"
			component="#Variables.oService#"
			method="#variables.sServiceInfo.method_get#"
			argumentCollection="#sArgs#"
		>
		<cfset StructAppend(variables.sKeys,QueryRowToStruct(qRecord),true)>
	</cfif>
	
	<!--- If a fieldlist is passed in and only primary key values are initially loaded, load up the requested data. --->
	<cfif StructCount(Variables.instance) EQ ListLen(Variables.sServiceInfo.pkfields) AND Len(Arguments.fields)>
		<cfset sArgs = Duplicate(Variables.instance)>
		<cfset sArgs.fieldlist = Arguments.fields>
		<cfloop list="#Arguments.fields#" index="key">
			<cfif ListFindNoCase(StructKeyList(Variables.instance),key)>
				<cfset sArgs.fieldlist = ListDeleteAt(sArgs.fieldlist,ListFindNoCase(sArgs.fieldlist,key))>
			</cfif>
		</cfloop>
		<cfif ListLen(sArgs.fieldlist)>
			<cfinvoke
				returnvariable="qRecord"
				component="#Variables.oService#"
				method="#variables.sServiceInfo.method_get#"
				argumentCollection="#sArgs#"
			>
			<cfset StructAppend(variables.instance,QueryRowToStruct(qRecord),true)>
		</cfif>
	</cfif>
	
	<cfset This.loadFields(Arguments.Fields)>
	
	<cfreturn This>
</cffunction>

<cffunction name="dump" access="public" returntype="any" output="no">
	<cfreturn Variables.Instance>
</cffunction>

<cffunction name="get" access="public" returntype="any" output="no">
	<cfargument name="field" type="string" required="true">
	
	<cfset var result = "">
	<cfset var sArgs = 0>
	<cfset var sFields = 0>
	<cfset var FieldBase = "">
	
	<cfif NOT StructKeyExists(Variables.sFields,Arguments.field)>
		<cfset FieldBase = ReReplaceNoCase(Arguments.field,"(File$)|(URL$)","")>
		<cfif NOT ( StructKeyExists(Variables.sFields,FieldBase) AND Variables.sFields[FieldBase].type EQ "file" )>
			<cfthrow message="#Variables.sServiceInfo.label_Singular# does not have a property named #Arguments.field#.">
		</cfif>
	</cfif>
	
	<cfif NOT StructKeyExists(Variables.instance,Arguments.field)>
		<cfset sArgs = StructNew()>
		<cfset StructAppend(sArgs,Variables.sKeys)>
		<cfset sArgs["field"] = Arguments.field>
		
		<cfif isQueryable()>
			<cfinvoke
				returnvariable="result"
				component="#Variables.oService#"
				method="getTableFieldValue"
				argumentcollection="#sArgs#"
			>
		<cfelseif StructKeyExists(Variables.oService,"getFieldsStruct")>
			<cfset sFields = Variables.oService.getFieldsStruct()>
			<cfif StructKeyExists(sFields[Arguments.Field],"Default")>
				<cfset result = sFields[Arguments.Field].Default>
			</cfif>
		</cfif>
		<cfset Variables.instance[Arguments.field] = result>
	</cfif>
	
	<cfreturn Variables.instance[Arguments.field]>
</cffunction>

<cffunction name="getInstance" access="public" returntype="any" output="no">
	<cfreturn Variables.Instance>
</cffunction>

<cffunction name="getVariables" access="public" returntype="any" output="no">
	<cfreturn Variables>
</cffunction>

<cffunction name="isNewRecord" access="public" returntype="boolean" output="no">
	
	<cfif NOT StructKeyExists(Variables,"isNew")>
		<cfset Variables.isNew = NOT ( Variables.oService.isUpdate(ArgumentCollection=Variables.Instance) )>
	</cfif>
	
	<cfreturn Variables.isNew>
</cffunction>

<cffunction name="isValidRecord" access="public" returntype="boolean" output="no">
	
	<cfset var result = true>
	
	<cftry>
		<cfset validate(ArgumentCollection=Arguments)>
	<cfcatch>
		<cfset result = false>
	</cfcatch>
	</cftry>
	
	<cfreturn result>
</cffunction>

<cffunction name="loadFields" access="public" returntype="any" output="no">
	<cfargument name="fields" type="string" default="">
	
	<cfset var Field = "">
	<cfset var LoaddedFields = StructKeyList(Variables.instance)>
	<cfset var MissingFields = "">
	<cfset var sArgs = 0>
	<cfset var qRecord = 0>
	<cfset var ServiceFields = "">
	
	<cfloop list="#Arguments.fields#" index="Field">
		<cfif NOT ListFindNoCase(LoaddedFields,Field)>
			<cfset MissingFields = ListAppend(MissingFields,Field)> 
		</cfif>
	</cfloop>
	
	<!--- Ditch any fields that don't actually exist in the service --->
	<cfif Len(MissingFields)>
		<cfset ServiceFields = Variables.oService.getFieldList()>
		<cfloop list="#Arguments.fields#" index="Field">
			<cfif ListFindNoCase(MissingFields,Field) AND NOT ListFindNoCase(ServiceFields,Field)>
				<cfset MissingFields = ListDeleteAt(MissingFields,ListFindNoCase(MissingFields,Field))> 
			</cfif>
		</cfloop>
	</cfif>
	
	<cfif Len(MissingFields)>
		<cfset sArgs = StructNew()>
		<cfset StructAppend(sArgs,Variables.sKeys)>
		<cfset sArgs["fieldlist"] = MissingFields>
		<cfif isQueryable()>
			<cfinvoke
				returnvariable="qRecord"
				component="#Variables.oService#"
				method="#Variables.sServiceInfo.method_get#"
				argumentcollection="#sArgs#"
			>
		</cfif>
		<cfif isQuery(qRecord) AND qRecord.RecordCount>
			<cfloop list="#MissingFields#" index="Field">
				<cfif ListFindNoCase(qRecord.ColumnList,Field)>
					<cfset Variables.instance[Field] = qRecord[Field][1]>
				</cfif>
			</cfloop>
		<cfelse>
			<cfloop list="#MissingFields#" index="Field">
				<cfset get(Field)>
			</cfloop>
		</cfif>
	</cfif>
	
	<cfreturn This>
</cffunction>

<cffunction name="remove" access="public" returntype="void" output="no">
	
	<cfinvoke
		component="#Variables.oService#"
		method="#variables.sServiceInfo.method_remove#"
		argumentCollection="#Variables.sKeys#"
	>
	
	<cfset StructClear(Variables.Instance)>
	<cfset StructClear(Variables.sKeys)>
	
</cffunction>

<cffunction name="save" access="public" returntype="any" output="no">
	
	<cfset var id = 0>
	<cfset var sArgs = Duplicate(Arguments)>
	
	<cfset StructAppend(sArgs,Variables.sKeys,true)>
	<cfset sArgs[Variables.ObjectName] = This>
	
	<cfinvoke
		returnvariable="id"
		component="#Variables.oService#"
		method="#variables.sServiceInfo.method_save#"
		argumentCollection="#sArgs#"
	>
	
	<cfset StructAppend(variables.instance,Arguments,true)>
	<cfset Variables.isNew = false>
	
	<cfif StructKeyExists(variables.sServiceInfo,"arg_pk")>
		<cfif isDefined("id") AND isSimpleValue(id) AND Len(Trim(id))>
			<cfset Variables.sKeys[variables.sServiceInfo.arg_pk] = id>
		</cfif>
	</cfif>
	
	<cfreturn This>
</cffunction>

<cffunction name="validate" access="public" returntype="any" output="no">
	
	<cfset var sArgs = Duplicate(Variables.instance)>
	
	<cfset StructAppend(sArgs,ArgumentCollection,true)>
	
	<cfinvoke
		returnvariable="sArgs"
		component="#Variables.oService#"
		method="#variables.sServiceInfo.method_validate#"
		argumentCollection="#sArgs#"
	>
	
	<cfreturn This>
</cffunction>

<cffunction name="isQueryable" access="private" returntype="boolean" output="no" hint="I check to see if I can query the Service component for data.">
	
	<cfset var result = ( StructKeyExists(Variables,"sKeys") AND StructCount(Variables.sKeys) GT 0 )>
	<cfset var key = "">
	
	<cfif result>
		<cfloop collection="#Variables.sKeys#" item="key">
			<cfif NOT ( StructKeyExists(Variables.sKeys,key) AND Len(Variables.sKeys[key]) )>
				<cfreturn false>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfreturn result>
</cffunction>

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
    var sReturn = structnew();
    //if there is a second argument, use that for the row number
    if(arrayLen(arguments) GT 1)
        row = arguments[2];
    //loop over the cols and build the struct from the query row    
    for(ii = 1; ii lte arraylen(cols); ii = ii + 1){
        sReturn[cols[ii]] = query[cols[ii]][row];
    }        
    //return the struct
    return sReturn;
}
</cfscript>

</cfcomponent>