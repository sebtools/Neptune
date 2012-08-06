<cfcomponent displayname="Imports" extends="com.sebtools.Records" output="no">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="Manager" type="any" required="yes">
	<cfargument name="POIUtility" type="any" required="no">
	
	<cfset initInternal(argumentCollection=arguments)>
	
	<cfreturn This>
</cffunction>

<cffunction name="initInternal" access="public" returntype="any" output="no">
	<cfargument name="Manager" type="any" required="yes">
	<cfargument name="POIUtility" type="any" required="no">
	
	<cfset Super.initInternal(argumentCollection=arguments)>
	
	<cfif
			NOT StructKeyExists(variables,"POIUtility")
		AND	StructKeyExists(variables,"Parent")
		AND	isObject(variables.Parent)
		AND	StructKeyExists(variables.Parent,"getVariable")
	>
		<cftry>
			<cfset variables.POIUtility = variables.Parent.getVariable("POIUtility")>
		<cfcatch>
		</cfcatch>
		</cftry>
	</cfif>
	
	<cfif
			NOT StructKeyExists(variables,"POIUtility")
		AND	StructKeyExists(variables.Manager,"POIUtility")
	>
		<cfset variables.POIUtility = variables.Manager.POIUtility>
	</cfif>
	
	<cfif NOT StructKeyExists(variables,"POIUtility")>
		<cfthrow message="Importer required POIUtility to work.">
	</cfif>
	
	<cfset Variables.oSpreadsheet = CreateObject("component","Spreadsheet").init(variables.POIUtility)>
	
	<cfset getImportee()>
	
	<cfreturn This>
</cffunction>

<cffunction name="getFieldsStruct" access="public" returntype="struct" output="no">
	
	<cfset var sResult = Super.getFieldsStruct(argumentCollection=arguments)>
	
	<cfif StructKeyExists(variables,"Importee")>
		<cfset StructAppend(sResult,variables.Importee.getFieldsStruct(argumentCollection=arguments))>
	</cfif>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="getMetaStruct" access="public" returntype="struct" output="no">
	
	<cfset var sResult = Super.getMetaStruct(argumentCollection=arguments)>
	
	<cfset sResult["method_save"] = "importRecords">
	
	<cfif StructKeyExists(variables,"Importee")>
		<cftry>
			<cfset sImporteeStruct = variables.Importee.getMetaStruct(argumentCollection=arguments)>
			<cfset sResult["label_Singular"] = sImporteeStruct.label_Singular>
			<cfset sResult["label_Plural"] = sImporteeStruct.label_Plural>
			<cfset sResult["method_save"] = "import#sImporteeStruct.method_Plural#">
			<cfset sResult["message_save"] = "#sResult.label_Plural# Imported.">
		<cfcatch>
		</cfcatch>
		</cftry>
	</cfif>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="getImportee" access="public" returntype="any" output="no">
	
	<cfset var result = 0>
	<cfset var sThis = 0>
	<cfset var name = 0>
	
	<cfif StructKeyExists(variables,"Importee") AND isObject(variables.Importee)>
		<cfset result = variables.Importee>
	<cfelse>
		<cfif StructKeyExists(variables,"Parent") AND isObject(variables.Parent)>
			<cfif NOT ( StructKeyExists(variables,"Importee") AND isSimpleValue(variables.Importee) AND Len(Trim(variables.Importee)) )>
				<cfset sThis = getMetaData(This)>
				<cfset name = ReplaceNoCase(ListLast(sThis.name,"."),"Importer","","ALL")>
				<cfif StructKeyExists(variables.Parent,name) AND isObject(variables.Parent[name])>
					<cfset variables.Importee = variables.Parent[name]>
				<cfelse>
					<cfset name = variables.Manager.pluralize(name)>
					<cfif StructKeyExists(variables.Parent,name) AND isObject(variables.Parent[name])>
						<cfset variables.Importee = variables.Parent[name]>
					</cfif>
				</cfif>
			</cfif>
			<cfif
					StructKeyExists(variables,"Importee")
				AND	isSimpleValue(variables.Importee)
				AND	Len(Trim(variables.Importee))
				AND	StructKeyExists(variable.Parent,variables.Importee)
				AND	isObject(variable.Parent[variables.Importee])
			>
				<cfset variables.Importee = variable.Parent[variables.Importee]>
			</cfif>
		</cfif>
	</cfif>
	
	<cfif StructKeyExists(variables,"Importee") AND NOT isObject(variables.Importee)>
		<cfset StructDelete(variables,"Importee")>
	</cfif>
	
	<cfif StructKeyExists(variables,"Importee")>
		<cfset variables.sImporteeMeta = variables.Importee.getMetaStruct()>
		<cfset result = variables.Importee>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getParentComponent" access="public" returntype="any" output="no">
	
	<cfif StructKeyExists(variables,"Parent")>
		<cfreturn variables.Parent>
	<cfelse>
		<cfreturn Super.getParentComponent()>
	</cfif>
</cffunction>

<cffunction name="importRecord" access="public" returntype="void" output="no">
	
	<cfif StructKeyExists(variables,"Importee")>
		<cfinvoke component="#variables.Importee#" method="#variables.sImporteeMeta.method_save#" argumentCollection="#arguments#">
	</cfif>
	
</cffunction>

<cffunction name="importRecords" access="public" returntype="void" output="no">
	
	<cfset var success = false>
	<cfset var ErrorMessage = "">
	<cfset var sArgs = Duplicate(arguments)>
	
	<cfif StructKeyExists(variables,"Importee")>
		<cfset sArgs["Component"] = This>
		<cfset sArgs["Method"] = "import#variables.sImporteeMeta.method_Singular#">
		<cfset sArgs["ExcelFile"] = Arguments.FileImport>
		<cfset sArgs["CatchErrTypes"] = variables.sImporteeMeta.catch_types>
		
		<cfset StructDelete(sArgs,"FileImport")>
	</cfif>
	
	<cfset success = importSpreadsheet(argumentCollection=sArgs)>
	
	<cfif NOT success>
		<cfset ErrorMessage = 'Some records failed to upload. <a href="/f/#variables.Importer.getFolder('FileErrors')#/#arguments.FileImport#">Download Remaing Data</a>.'>
		<cfthrow message="#ErrorMessage#" type="Importer">
	</cfif>
	
</cffunction>

<cffunction name="importSpreadsheet" access="public" returntype="boolean" output="no" hint="I return all of the Imports.">
	<cfargument name="component" type="any" required="yes">
	<cfargument name="method" type="string" required="yes">
	<cfargument name="ExcelFile" type="string" required="yes">
	<cfargument name="RequiredColumns" type="string" required="no">
	<cfargument name="CatchErrTypes" type="string" default="">
	<cfargument name="CompactionDelim" type="string" default="">
	
	<cfset var qRecords = 0>
	<cfset var FilePath = variables.FileMgr.getFilePath(arguments.ExcelFile,getFolder('FileImport'))>
	<cfset var isSuccessful = true>
	<cfset var sImport = StructNew()>
	<cfset var sArgs = Duplicate(arguments)>
	<cfset var sFields = StructNew()>
	<cfset var qRejects = 0>
	<cfset var result = "">
	<cfset var results = "">
	
	<cfset StructDeleteKeys(sArgs,"component,method,ExcelFile,RequiredColumns,CatchErrTypes")>
	
	<cfif NOT StructKeyExists(arguments,"RequiredColumns")>
		<cfset arguments.RequiredColumns = getRequiredColumns(arguments.component,arguments.method)>
	</cfif>
	
	<cfset qRecords = Variables.oSpreadsheet.readExcel(src=FilePath,CompactionDelim=Arguments.CompactionDelim)>
	<cfset qRejects = QueryNew("#qRecords.ColumnList#,SpreadSheetImportError")>
	
	<cfif structKeyExists(arguments.component,"getFieldsStruct")>
		<cfset sFields = arguments.component.getFieldsStruct()>
	</cfif>
	
	<cfloop query="qRecords">
		<cfset sData = variables.DataMgr.queryRowToStruct(qRecords,CurrentRow)>
		<cfset appendArgDefaults(sData,sArgs)>
		<cfset StructFormatData(sData,sFields)>
		<cftry>
			<cfinvoke component="#arguments.component#" method="#arguments.method#" argumentCollection="#sData#" returnvariable="result"></cfinvoke>
			<cfif isDefined("result") AND isSimpleValue(result)>
				<cfset results = ListAppend(results,result)>
			</cfif>
		<cfcatch>
			<cfif Len(arguments.CatchErrTypes) EQ 0 OR ListFindNoCase(arguments.CatchErrTypes,cfcatch.type)>
				<cfset sData["SpreadSheetImportError"] = CFCATCH.Message>
				<cfset isSuccessful = false>
				<cfset QueryAddRecord(qRejects,sData)>
			<cfelse>
				<cfrethrow>
			</cfif>
		</cfcatch>
		</cftry>
	</cfloop>
	
	<cfif NOT isSuccessful>
		<!---<cfthrow message="Upload Failed for unknown reason." type="Importer">--->
		<cfset saveSpreadsheet(arguments.ExcelFile,qRejects)>
		<cfset sImport["FileErrors"] = arguments.ExcelFile>
	</cfif>
	
	<cfset sImport["FileImport"] = arguments.ExcelFile>
	<cftry>
		<cfset saveImport(argumentCollection=sImport)>
	<cfcatch>
	</cfcatch>
	</cftry>
	
	<cfreturn isSuccessful>
</cffunction>

<cffunction name="addMethods" access="private" returntype="void" output="no">
	
	<cfset var singular = 0>
	<cfset var plural = 0>
	<cfset var methods = 0>
	<cfset var rmethods = "importRecord,importRecords">
	<cfset var method = "">
	<cfset var rmethod = "">
	<cfset var ii = 0>
	<cfset var sImporteeStruct = 0>
	
	<cfset Super.addMethods()>
	
	<cfif StructKeyExists(variables,"Importee")>
		<cfset sImporteeStruct = variables.Importee.getMetaStruct()>
		<cfset singular = sImporteeStruct.method_Singular>
		<cfset plural = sImporteeStruct.method_Plural>
		<cfset methods = "import#singular#,import#plural#">
		
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
	</cfif>
	
</cffunction>

<!---<cffunction name="removeImport" access="public" returntype="void" output="no" hint="I delete the given Import.">
	<cfargument name="ImportID" type="string" required="yes">
	
	<cfset removeRecord(argumentCollection=arguments)>
	
</cffunction>--->

<cffunction name="appendArgDefaults" access="private" returntype="void" output="false" hint="I add a NamedQuery key to each sheet in the spreadsheet as a column with column headers coming from the header row.">
	<cfargument name="struct" type="struct" required="true">
	<cfargument name="args" type="struct" required="true">
	
	<cfset var key = "">
	
	<cfscript>
	for ( key in arguments.args ) {
		if (
			NOT (
						StructKeyExists(arguments.struct,key)
					AND	Len(Trim(arguments.struct[key]))
				)
		) {
			arguments.struct[key] = arguments.args[key];
		}
	}
	</cfscript>
	
</cffunction>

<cffunction name="saveSpreadsheet" access="private" returntype="void" output="no">
	<cfargument name="FileName" type="string" required="true">
	<cfargument name="query" type="query" required="true">
	
	<cfset var FilePath = variables.FileMgr.getFilePath(arguments.FileName,getFolder('FileErrors'))>
	
	<cfset variables.oSpreadsheet.WriteExcel(FileName=FilePath,query=query)>
	
</cffunction>

<cffunction name="getRequiredColumns" access="public" returntype="string" output="no">
	<cfargument name="component" type="any" required="yes">
	<cfargument name="method" type="string" required="yes">
	
	<cfset var sMethod = getMetaData(arguments.component[arguments.method])>
	<cfset var ii = 0>
	<cfset var result = "">
	
	<cfloop index="ii" from="1" to="#ArrayLen(sMethod.Parameters)#" step="1">
		<cfif StructKeyExists(sMethod.Parameters[ii],"Required") AND sMethod.Parameters[ii].Required IS true>
			<cfset result = ListAppend(result,sMethod.Parameters[ii].name)>
		</cfif>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<cffunction name="xml" access="public" output="yes">
<tables prefix="xls">
	<table entity="Import" labelField="DateImported" Specials="LastUpdatedDate">
		<field name="DateImported" Label="Date Imported" type="CreationDate" />
		<field
			name="FileImport"
			Label="Excel File"
			type="file"
			Folder="excel-imports"
			Accept="application/msexcel,application/vnd.ms-excel,application/x-msdownload"
			nameconflict="MakeUnique"
			Extensions="xls"
			required="true"
		/>
		<field
			name="FileErrors"
			Label="Errors File"
			type="file"
			Folder="excel-imports-errors"
			Accept="application/msexcel,application/vnd.ms-excel,application/x-msdownload"
			Extensions="xls"
		/>
	</table>
</tables>
</cffunction>

<cffunction name="StructDeleteKeys" access="private" returntype="struct" output="false">
	<cfargument name="struct" type="struct" required="true">
	<cfargument name="keys" type="string" required="true">
	
	<cfset key = "">
	
	<cfloop list="#arguments.keys#" index="key">
		<cfset StructDelete(arguments.struct,key)>
	</cfloop>
	
	<cfreturn arguments.struct>
</cffunction>

<cffunction name="StructFormatData" access="private" returntype="struct" output="false">
	<cfargument name="struct" type="struct" required="true">
	<cfargument name="sFields" type="struct" required="false">
	
	<cfset var key = "">
	<cfset var types = "date,time">
	
	<cfif StructKeyExists(arguments,"sFields") AND StructCount(arguments.sFields)>
		<cfloop collection="#arguments.struct#" item="key">
			<cfif
					StructKeyExists(arguments.struct,key)
				AND	StructKeyExists(sFields,key)
				AND	( isDate(arguments.struct[key]) OR isNumeric(arguments.struct[key]) )
				AND	StructKeyExists(sFields[key],"type")
				AND	ListFindNoCase(types,sFields[key].type)
			>
				<cfif sFields[key].type EQ "date">
					<cfset arguments.struct[key] = DateFormat(arguments.struct[key]) & " " & TimeFormat(arguments.struct[key])>
				<cfelseif sFields[key].type EQ "time">
					<cfset arguments.struct[key] = TimeFormat(arguments.struct[key])>
				</cfif>
			</cfif>
		</cfloop>
	<cfelse>
		<cfloop collection="#arguments.struct#" item="key">
			<cfif
					StructKeyExists(arguments.struct,key)
				AND	( isDate(arguments.struct[key]) OR isNumeric(arguments.struct[key]) )
			>
				<cfif key CONTAINS "date">
					<cfset arguments.struct[key] = DateFormat(arguments.struct[key]) & " " & TimeFormat(arguments.struct[key])>
				<cfelseif key CONTAINS "time">
					<cfset arguments.struct[key] = TimeFormat(arguments.struct[key])>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfreturn arguments.struct>
</cffunction>

<cffunction name="QueryAddRecord" access="private" returntype="void" output="false" hint="I add a row to a query with data from a structure.">
	<cfargument name="query" type="query" required="true">
	<cfargument name="struct" type="struct" required="true">
	
	<cfset var col = "">
	
	<cfset QueryAddRow(arguments.query)>
	
	<cfloop list="#arguments.query.ColumnList#" index="col">
		<cfif StructKeyExists(arguments.struct,col) AND isSimpleValue(arguments.struct[col])>
			<cftry>
				<cfset QuerySetCell(arguments.query,col,arguments.struct[col])>
			<cfcatch>
			</cfcatch>
			</cftry>
		</cfif>
	</cfloop>
	
</cffunction>

</cfcomponent>