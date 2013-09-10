<!--- 1.0 Beta 3 (Build 36) --->
<!--- Last Updated: 2012-01-31 --->
<!--- Information: http://www.bryantwebconsulting.com/docs/com-sebtools/manager.cfm?version=Build%2012 ---><cfcomponent output="false">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="DataMgr" type="any" required="no">
	<cfargument name="FileMgr" type="any" required="no">
	<cfargument name="CFIMAGE" type="any" required="no">
	<cfargument name="wysiwyg" type="string" default="FCKeditor">
	<cfargument name="RootURL" type="string" default="">
	<cfargument name="RootPath" type="string" default="">
	
	<cfset var arg = "">
	<cfset var sTemp = StructNew()>
	
	<!--- Set variables from arguments --->
	<cfloop collection="#arguments#" item="arg">
		<cfif Len(Trim(arg)) AND StructKeyExists(arguments,arg)>
			<cfif NOT StructKeyExists(variables,arg)>
				<cfset variables[arg] = arguments[arg]>
			</cfif>
			<cfif isObject(arguments[arg]) AND NOT StructKeyExists(this,arg)>
				<cfset this[arg] = arguments[arg]>
			</cfif>
		</cfif>
	</cfloop>
	
	<cfif NOT StructKeyExists(variables,"DataMgr")>
		<cfif FileExists("#getDirectoryFromPath(getCurrentTemplatePath())#DataMgr.cfc")>
			<cfset variables.DataMgr = CreateObject("component","DataMgr").init(argumentCollection=arguments)>
			<cfset This.DataMgr = variables.DataMgr>
		<cfelse>
			<cfthrow message="Manager.cfc init() requires DataMgr." type="Manager">
		</cfif>
	</cfif>
	<cfif NOT StructKeyExists(variables,"FileMgr")>
		<cfif FileExists("#getDirectoryFromPath(getCurrentTemplatePath())#FileMgr.cfc")>
			<cfif NOT StructKeyExists(arguments,"UploadURL")>
				<cfset arguments.UploadURL = "/f/">
			</cfif>
			<cfif NOT StructKeyExists(arguments,"UploadPath")>
				<cfset arguments.UploadPath = ExpandPath(arguments.UploadURL)>
			</cfif>
			<cfset variables.FileMgr = CreateObject("component","FileMgr").init(argumentCollection=arguments)>
			<cfset This.FileMgr = variables.FileMgr>
		<cfelse>
			<cfthrow message="Manager.cfc init() requires FileMgr." type="Manager">
		</cfif>
	</cfif>
	<cfif NOT StructKeyExists(variables,"CFIMAGE") AND FileExists("#getDirectoryFromPath(getCurrentTemplatePath())#cfimagecfc.cfc")>
		<cfset variables.CFIMAGE = CreateObject("component","cfimagecfc").init()>
		<cfset This.CFIMAGE = variables.CFIMAGE>
	</cfif>
	<cfif NOT StructKeyExists(variables,"Pluralizer") AND FileExists("#getDirectoryFromPath(getCurrentTemplatePath())#Pluralizer.cfc")>
		<cfset variables.Pluralizer = CreateObject("component","Pluralizer").init()>
		<cfset This.Pluralizer = variables.Pluralizer>
	</cfif>
	
	<cfset variables.datasource = this.DataMgr.getDatasource()>
	<cfset variables.cachedata = StructNew()>
	<cfset variables.sMetaData = StructNew()>
	<cfset variables.UUID = CreateUUID()>
	
	<cfset getTypesXml()>
	
	<cfset variables.FileTypes = ArrayToList(GetValueArray(variables.xTypes,"//type[@lcase_isfiletype='true']/@name"))>
	<cfset variables.TypeNames = ArrayToList(GetValueArray(variables.xTypes,"//type/@name"))>
	
	<cfset variables.sSecurityPermissions = StructNew()>
	
	<cfreturn this>
</cffunction>

<cffunction name="getRootPath" access="public" returntype="string" output="no">
	<cfreturn variables.RootPath>
</cffunction>

<cffunction name="getRootURL" access="public" returntype="string" output="no">
	<cfreturn variables.RootURL>
</cffunction>

<cffunction name="getTypesXml" access="public" returntype="any" output="no">
	
	<cfset var xRawTypes = 0>
	<cfset var xAllTypes = 0>
	<cfset var ii = 0>
	<cfset var key = 0>
	
	<cfif NOT StructKeyExists(variables,"xTypes")>
		<cfset xRawTypes = XmlParse(types())>
		<cfset xAllTypes = XmlSearch(xRawTypes,"//*")>
		<cfloop index="ii" from="1" to="#ArrayLen(xAllTypes)#" step="1">
			<cfloop item="key" collection="#xAllTypes[ii].XmlAttributes#">
				<cfset xAllTypes[ii].XmlAttributes["lcase_#LCase(key)#"] = LCase(xAllTypes[ii].XmlAttributes[key])>
			</cfloop>
		</cfloop>
		<cfset variables.xTypes = xRawTypes>
	</cfif>
	
	<cfreturn variables.xTypes>
</cffunction>

<cffunction name="adjustImage" access="public" returntype="any" output="no">
	<cfargument name="tablename" type="string" required="true">
	<cfargument name="fieldname" type="string" required="true">
	<cfargument name="filename" type="string" required="true">
	
	<cfset var sFields = getFieldsStruct(arguments.tablename)>
	<cfset var sField = sFields[arguments.fieldname]>
	<cfset var path = variables.FileMgr.getFilePath(arguments.filename,sField.Folder)>
	
	<cfset var myImage = 0>
	<cfset var width = 0>
	<cfset var height = 0>
	
	<cfif FileExists(path) AND StructKeyExists(variables,"CFIMAGE")>
		<!--- Resize if a size limitation exists --->
		<cfif
				( StructKeyExists(sField,"MaxWidth") AND isNumeric(sField.MaxWidth) AND sField.MaxWidth GT 0 )
			OR	( StructKeyExists(sField,"MaxHeight") AND isNumeric(sField.MaxHeight) AND sField.MaxHeight GT 0 )
			OR	( StructKeyExists(sField,"MaxSmallSide") AND isNumeric(sField.MaxSmallSide) AND sField.MaxSmallSide GT 0 )
		>
			<!--- Get image --->
			<cfset myImage = variables.CFIMAGE.read(source=path)>
			
			<!--- Get height and width for scale to fit --->
			<cfset width = getWidth(sField,myImage)>
			<cfset height = getHeight(sField,myImage)>
			
			<cfif width LT myImage.width OR height LT myImage.height>
				<!--- Scale image to fit --->
				<cfinvoke component="#variables.CFIMAGE#" method="scaleToFit">
					<cfinvokeargument name="source" value="#path#">
					<cfinvokeargument name="quality" value="#sField.quality#">
					<cfinvokeargument name="width" value="#width#">
					<cfinvokeargument name="height" value="#height#">
				</cfinvoke>
			</cfif>
		</cfif>
	</cfif>
	
</cffunction>

<cffunction name="adjustImages" access="private" returntype="struct" output="no">
	<cfargument name="tablename" type="string" required="true">
	<cfargument name="data" type="struct" required="true">
	
	<cfset var aFields = getFileFields(tablename=arguments.tablename,data=arguments.data)>
	<cfset var sFields = getFieldsStruct(tablename=arguments.tablename)>
	<cfset var ii = 0>
	<cfset var in = Duplicate(arguments.data)>
	
	<!--- If cfimage is available and image is passed in, fit any images into box --->
	<cfif StructKeyExists(variables,"CFIMAGE") AND ArrayLen(aFields)>
		<cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
			<!--- Make sure images are big enough --->
			<cfif
					StructKeyExists(in,aFields[ii].name)
				AND	( StructKeyExists(aFields[ii],"type") AND aFields[ii].type EQ "image")
				AND	( StructKeyExists(aFields[ii],"Folder") AND Len(aFields[ii].Folder) )
				AND (
							( StructKeyExists(aFields[ii],"MinBox") AND isNumeric(aFields[ii].MinBox) AND aFields[ii].MinBox GT 0 )
					)	
				AND	FileExists(variables.FileMgr.getFilePath(in[aFields[ii].name],aFields[ii].Folder))
			>
				<!--- Get image --->
				<cfset myImage = variables.CFIMAGE.read(source=variables.FileMgr.getFilePath(in[aFields[ii].name],aFields[ii].Folder))>
				
				<cfif (myImage.width LT aFields[ii].MinBox) OR (myImage.height LT aFields[ii].MinBox)>
					<cfthrow message="Width and height of #aFields[ii].label# must both be at least #aFields[ii].MinBox#." type="Manager">
				</cfif>
			</cfif>
		</cfloop>
		<!--- Copy/Resize thumbnail images --->
		<cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
			<!--- If this is a thumb with a folder --->
			<cfif
					isThumbField(arguments.tablename,aFields[ii].name)
				AND	StructKeyExists(in,aFields[ii].original)
				AND	isSimpleValue(in[aFields[ii].original])
				AND	Len(in[aFields[ii].original])
			>
				<cfset makeThumb(arguments.tablename,aFields[ii].name,in[aFields[ii].original])>
				
				<!--- Add to in/data --->
				<cfset in[aFields[ii].name] = in[aFields[ii].original]>
			</cfif>
		</cfloop>
		<!--- Fit any images into box --->
		<cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
			<!--- If: image is in args and has folder and size limitation and file exists --->
			<cfif
					( StructKeyExists(in,aFields[ii].name) AND isSimpleValue(in[aFields[ii].name]) AND Len(in[aFields[ii].name]) )
				AND	( StructKeyExists(aFields[ii],"type") AND aFields[ii].type EQ "image")
				AND	( StructKeyExists(aFields[ii],"Folder") AND Len(aFields[ii].Folder) )
			>
				<cfset adjustImage(arguments.tablename,aFields[ii].name,in[aFields[ii].name])>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfreturn in>
</cffunction>

<cffunction name="getDataMgr" access="public" returntype="any" output="no">
	<cfreturn this.DataMgr>
</cffunction>

<cffunction name="getDataMgrGetRecordsArgs" access="private" returntype="string" output="no">
	
	<cfif NOT StructKeyExists(variables,"DataMgrGetRecordsArgs")>
		<cfset variables.DataMgrGetRecordsArgs = getArgumentsList(variables.DataMgr.getRecords)>
	</cfif>
	
	<cfreturn variables.DataMgrGetRecordsArgs>
</cffunction>

<cffunction name="getDataMgrSaveRecordArgs" access="private" returntype="string" output="no">
	
	<cfif NOT StructKeyExists(variables,"DataMgrSaveRecordArgs")>
		<cfset variables.DataMgrSaveRecordArgs = getArgumentsList(variables.DataMgr.saveRecord)>
	</cfif>
	
	<cfreturn variables.DataMgrSaveRecordArgs>
</cffunction>

<cffunction name="getFileMgr" access="public" returntype="any" output="no">
	<cfreturn this.FileMgr>
</cffunction>

<cffunction name="getMetaStruct" access="public" returntype="any" output="false" hint="">
	<cfargument name="tablename" type="string" required="no">
	
	<cfset var result = 0>
	
	<cfif StructKeyExists(arguments,"tablename") AND StructKeyExists(variables.sMetaData,arguments.tablename)>
		<cfset result = variables.sMetaData[arguments.tablename]>
	<cfelse>
		<cfset result = variables.sMetaData>
	</cfif>
	
	<cfreturn result>
</cffunction>

<!---<cffunction name="getMetaXML" access="public" returntype="any" output="false" hint="">
	<cfreturn variables.xMetaData>
</cffunction>--->

<cffunction name="getPrimaryKeyFields" access="public" returntype="string" output="no">
	<cfargument name="tablename" type="string" required="true">
	<cfargument name="xDef" type="any" required="false">
	
	<cfset var aPKFields = 0>
	<cfset var ii = 0>
	<cfset var result = "">
	
	<cfif StructKeyExists(arguments,"xDef")>
		<cfset aPKFields = XmlSearch(arguments.xDef,"//table[@name='#arguments.tablename#']/field[starts-with(@type,'pk:')]")>
		<cfloop index="ii" from="1" to="#ArrayLen(aPKFields)#" step="1">
			<cfset result = ListAppend(result,aPKFields[ii].XmlAttributes.name)>
		</cfloop>
	</cfif>
	
	<cfif NOT Len(result)>
		<cfset aPKFields = variables.DataMgr.getPKFields(arguments.tablename)>
		<cfloop index="ii" from="1" to="#ArrayLen(aPKFields)#" step="1">
			<cfset result = ListAppend(result,aPKFields[ii].ColumnName)>
		</cfloop>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getPrimaryKeyType" access="public" returntype="string" output="no">
	<cfargument name="tablename" type="string" required="true">
	<cfargument name="xDef" type="any" required="false">
	
	<cfset var result = "">
	<cfset var sTableMeta = sMetaData[arguments.tablename]>
	<cfset var sFields = getFieldsstruct(arguments.tablename)>
	<cfset var sField = 0>
	<cfset var pkfield = "">
	<cfset var ii = 0>
	
	<cfif StructKeyExists(sTableMeta,"pkfield")>
		<cfset pkfield = sTableMeta.pkfield>
	<cfelse>
		<cfloop index="ii" from="1" to="#ArrayLen(sTableMeta.fields)#" step="1">
			<cfif StructKeyExists(sTableMeta.fields[ii],"type") AND ListFirst(sTableMeta.fields[ii].type,":") EQ "pk">
				<cfset pkfield = ListAppend(pkfield,sTableMeta.fields[ii].name)>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfif NOT Len(pkfield)> 
		<cfset result = "complex">
	<cfelseif ListLen(pkfield) EQ 1>
		<cfset sField = sFields[pkfield]>
		<cfset result = ListLast(sField.type,":")>
	<cfelse>
		<cfset result = "complex">
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getUniversalTableName" access="private" returntype="string" output="no">
	<cfargument name="entity" type="string" required="yes">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfset var qRecords = 0>
	<cfset var result = "">
	
	<!---
	Make sure we have a table to store this in.
	This is essential that this has permanent storage.
	Currently this is the only scenario under which Manager creates a table or stores its own data in the database
	--->
	<cfif NOT Variables.DataMgr.hasTable("mgrUniversals")>
		<cfset Variables.DataMgr.loadXml(
			'
				<tables>
					<table name="mgrUniversals">
						<field ColumnName="entity" CF_DataType="CF_SQL_VARCHAR" Length="250" PrimaryKey="true" />
						<field ColumnName="tablename" CF_DataType="CF_SQL_VARCHAR" Length="250" />
					</table>
				</tables>
			',
			true,
			true
		)>
	</cfif>
	
	<!---
	Load data from the database the first time this is used
	--->
	<cfif NOT StructKeyExists(Variables,"sUniversals")>
		<cfset Variables.sUniversals = StructNew()>
		<cfset qRecords = Variables.DataMgr.getRecords(tablename="mgrUniversals")>
		<cfoutput query="qRecords">
			<cfset Variables.sUniversals[qRecords["entity"][CurrentRow]] = qRecords["tablename"][CurrentRow]>
		</cfoutput>
	</cfif>
	<cfif NOT StructKeyExists(Variables.sUniversals,Arguments.entity)>
		<cfset Variables.DataMgr.saveRecord("mgrUniversals",Arguments)>
		<cfset Variables.sUniversals[Arguments["entity"]] = Arguments["tablename"]>
	</cfif>
	
	<cfreturn Variables.sUniversals[Arguments.entity]>
</cffunction>

<cffunction name="isThumbField" access="public" returntype="string" output="no">
	<cfargument name="tablename" type="string" required="true">
	<cfargument name="fieldname" type="string" required="true">
	
	<cfset var sFields = getFieldsStruct(arguments.tablename)>
	<cfset var sField = sFields[arguments.fieldname]>
	<cfset var result = false>
	
	<cfif
			( StructKeyExists(sField,"type") AND sField.type EQ "thumb")
		AND	( StructKeyExists(sField,"Folder") AND Len(sField.Folder) )
		AND	(
					StructKeyExists(sField,"original")
				AND	StructKeyExists(sFields,sField.original)
			)

	>
		<cfset result = true>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="makeThumb" access="public" returntype="any" output="no">
	<cfargument name="tablename" type="string" required="true">
	<cfargument name="fieldname" type="string" required="true">
	<cfargument name="filename" type="string" required="true">
	
	<cfset var sFields = getFieldsStruct(arguments.tablename)>
	<cfset var sField = sFields[arguments.fieldname]>
	
	<cfset var myImage = 0>
	<cfset var width = 0>
	<cfset var height = 0>
	
	<!--- Copy file if original file exists --->
	<cfset var file_original = variables.FileMgr.getFilePath(arguments.filename,sFields[sField.original].Folder)>
	<cfset var file_thumb = variables.FileMgr.getFilePath(arguments.filename,sField.Folder)>
	
	<cfif FileExists(file_original)>
		<!--- Copy original image to thumb --->
		<cffile action="copy" source="#file_original#" destination="#file_thumb#">
		
		<!--- Resize if a size limitation exists --->
		<cfset adjustImage(arguments.tablename,arguments.fieldname,arguments.filename)>
	</cfif>

</cffunction>

<cffunction name="makeThumbs" access="public" returntype="void" output="no">
	<cfargument name="tablename" type="string" required="true">
	<cfargument name="fieldname" type="string" required="false">
	
	<cfset var aFields = 0>
	<cfset var ii = 0>
	
	<cfif StructKeyExists(arguments,"fieldname")>
		<cfset makeThumbsInternal(argumentCollection=arguments)>
	<cfelse>
		<cfset aFields = getFileFields(tablename=arguments.tablename)>
		<cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
			<cfif isThumbField(arguments.tablename,aFields[ii].name)>
				<cfset makeThumbsInternal(arguments.tablename,aFields[ii].name)>
			</cfif>
		</cfloop>
	</cfif>
	
</cffunction>

<cffunction name="makeThumbsInternal" access="private" returntype="void" output="no">
	<cfargument name="tablename" type="string" required="true">
	<cfargument name="fieldname" type="string" required="true">
	
	<cfset var sFields = 0>
	<cfset var sField = 0>
	<cfset var qRecords = 0>
	<cfset var aFilters = 0>
	<cfset var sData = 0>
	<cfset var pkfield = "">
	
	<!--- Only take action if the given field is a valid thumb field --->
	<cfif isThumbField(arguments.tablename,arguments.fieldname)>
		
		<cfset sFields = getFieldsStruct(arguments.tablename)>
		<cfset sField = sFields[arguments.fieldname]>
		<cfset aFilters = ArrayNew(1)>
	
		<!--- Only take action if table has some records with originals and no thumbnails --->
		<cfset ArrayAppend(aFilters,StructFromArgs(field=arguments.fieldname,operator="=",value=""))>
		<cfset ArrayAppend(aFilters,StructFromArgs(field=sField.original,operator="<>",value=""))>
		<cfinvoke returnvariable="qRecords" component="#variables.DataMgr#" method="getRecords">
			<cfinvokeargument name="tablename" value="#arguments.tablename#">
			<cfinvokeargument name="fieldlist" value="#getPrimaryKeyFields(arguments.tablename)#,#arguments.fieldname#,#sField.original#">
			<cfinvokeargument name="filters" value="#aFilters#">
		</cfinvoke>
		
		<cfloop query="qRecords">
			<!--- Make thumbnail of original --->
			<cfset makeThumb(arguments.tablename,arguments.fieldname,qRecords[sField.original][CurrentRow])>
			<!--- Save data --->
			<cfset sData = StructNew()>
			<cfset sData[arguments.fieldname] = qRecords[sField.original][CurrentRow]>
			<cfloop list="#getPrimaryKeyFields(arguments.tablename)#" index="pkfield">
				<cfset sData[pkfield] = qRecords[pkfield][CurrentRow]>
			</cfloop>
			<cfset variables.DataMgr.updateRecord(arguments.tablename,sData)>
		</cfloop>
		
	</cfif>
	
</cffunction>

<cffunction name="pluralize" access="public" returntype="string" output="false" hint="">
	<cfargument name="string" type="string" required="yes">
	
	<cfset var result = arguments.string>
	
	<cfif Len(Trim(result))>
		<cfif StructKeyExists(variables,"Pluralizer")>
			<cfset result = variables.Pluralizer.pluralize(arguments.string)>
		</cfif>
		
		<cfif result EQ arguments.string>
			<cfif Right(arguments.string,1) EQ "s">
				<cfset result = "#arguments.string#es">
			<cfelse>
				<cfset result = "#arguments.string#s">
			</cfif>
		</cfif>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="transformField" access="public" returntype="any" output="false" hint="">
	<cfargument name="field" type="struct" required="yes">
	<cfargument name="transformer" type="string" default="">
	
	<cfset var sField = arguments.field>
	<cfset var xTypes = variables.xTypes>
	<cfset var aType = 0>
	<cfset var att = "">
	<cfset var isListField = false>
	
	<!--- If a transformer is present, adjust accordingly. --->
	<cfif Len(arguments.transformer) AND StructKeyExists(sField,"type")>
		<cfset aType = XmlSearch(xTypes,"//type[@lcase_name='#LCase(sField.type)#']/transform[@lcase_name='#LCase(arguments.transformer)#']")>
		<cfif ArrayLen(aType)>
			<!--- Set all attributes --->
			<cfloop collection="#aType[1].XmlAttributes#" item="att">
				<cfif
						att NEQ "name"
					AND	NOT ( Len(att) GT Len("lcase_") AND Left(att,Len("lcase_")) EQ "lcase_" )
					AND	NOT ( StructKeyExists(sField,att) AND Len(sField[att]) AND att NEQ "type" )
				>
					<cfset sField[att] = aType[1].XmlAttributes[att]>
				</cfif>
			</cfloop>
			<cfset aType = XmlSearch(xTypes,"//type[@lcase_name='#LCase(sField.type)#']")>
			<!--- Set all attributes --->
			<cfif ArrayLen(aType)>
				<cfloop collection="#aType[1].XmlAttributes#" item="att">
					<cfif
							att NEQ "name"
						AND	NOT ( Len(att) GT Len("lcase_") AND Left(att,Len("lcase_")) EQ "lcase_" )
						AND	NOT ( StructKeyExists(sField,att) AND Len(sField[att]) )
					>
						<cfset sField[att] = aType[1].XmlAttributes[att]>
					</cfif>
				</cfloop>
			</cfif>
		<cfelse>
			<cfset sField = StructNew()>
		</cfif>
	<cfelse>
		<cfif StructKeyExists(sField,"type")>
			<cfset aType = XmlSearch(xTypes,"//type[@lcase_name='#LCase(sField.type)#']")>
			<!--- Set all attributes --->
			<cfif ArrayLen(aType)>
				<cfloop collection="#aType[1].XmlAttributes#" item="att">
					<cfif
							att NEQ "name"
						AND	NOT ( Len(att) GT Len("lcase_") AND Left(att,Len("lcase_")) EQ "lcase_" )
						AND	NOT ( StructKeyExists(sField,att) AND Len(sField[att]) )
					>
						<cfset sField[att] = aType[1].XmlAttributes[att]>
					</cfif>
				</cfloop>
			</cfif>
		</cfif>
	</cfif>
	<!--- Default size shouldn't exceed 50 --->
	<cfif
			StructKeyExists(sField,"Length")
		AND	isNumeric(sField.Length)
		AND	sField.Length GT 50
		AND	NOT StructKeyExists(sField,"size")>
		<cfset sField["size"] = 50>
	</cfif>
	<cfif StructKeyExists(sField,"Default") AND arguments.transformer EQ "sebField">
		<cfset sField["defaultValue"] = sField["Default"]>
	</cfif>
	
	<!--- Set values from attributes scoped for this transformer --->
	<cfif Len(arguments.transformer)>
		<cfloop collection="#sField#" item="att">
			<cfif
					ListLen(att,"_") EQ 2
				AND	ListFirst(att,"_") EQ arguments.transformer
			>
				<cfset sField[ListLast(att,"_")] = sField[att]>
			</cfif>
		</cfloop>
	</cfif>
	
	<!---<cfif arguments.transformer EQ "sebColumn">
		<cfset sField["dbfield"] = sField["name"]>
		<cfif NOT StructKeyExists(sField,"label")>
			<cfset sField["label"] = sField["name"]>
		</cfif>
		<cfif NOT StructKeyExists(sField,"header")>
			<cfset sField["header"] = sField["label"]>
		</cfif>
	</cfif>--->
	
	<cfset isListField = ( StructKeyExists(sField,"relation") AND StructKeyExists(sField.relation,"type") AND isSimpleValue(sField.relation.type) AND sField.relation.type EQ "list" )>
	
	<cfif
			StructKeyExists(arguments,"transformer")
		AND	arguments.transformer EQ "sebField"
	>
		<cfif isListField>
			<cfset sField.type="checkbox">
		<!---<cfelseif StructKeyExists(sField,"relation")>
			<cfset sField = StructNew()>--->
		</cfif>
	</cfif>
	
	<!--- If field has attribute name matching transformer value with a value of "false", ditch field --->
	<cfif Len(arguments.transformer) AND StructKeyExists(sField,arguments.transformer) AND sField[arguments.transformer] IS false>
		<cfset sField = StructNew()>
	</cfif>
	
	<cfreturn sField>
</cffunction>

<cffunction name="getFieldsArray" access="public" returntype="array" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="transformer" type="string" default="">
	
	<cfset var aFields = getFieldsArrayInternal(transformer=arguments.transformer,tablename=arguments.tablename)>
	<cfset var ii = 0>
	<cfset var sField = 0>
	
	<cfloop index="ii" from="#ArrayLen(aFields)#" to="1" step="-1">
		<cfif
			(
					(
							arguments.transformer EQ "sebField"
						OR	arguments.transformer EQ "sebColumn"
					)
				AND	StructKeyExists(aFields[ii],"relation")
				AND	NOT (
							StructKeyExists(aFields[ii].relation,"type")
						AND	aFields[ii].relation.type EQ "list"
					)
			)
		><!--- ( StructKeyExists(aFields[ii],"type") AND aFields[ii].type NEQ "relation" ) --->
			<cfset ArrayDeleteAt(aFields,ii)>
		<cfelseif
				(
						arguments.transformer EQ "sebField"
					OR	arguments.transformer EQ "sebColumn"
				)
			AND	(
						( StructKeyExists(aFields[ii],"type") AND ListFirst(aFields[ii].type,":") EQ "pk" )
					OR	( StructKeyExists(aFields[ii],"PrimaryKey") AND aFields[ii].PrimaryKey IS true )
				)
		>
			<cfset ArrayDeleteAt(aFields,ii)>
		<cfelseif arguments.transformer EQ "sebField" AND StructKeyExists(aFields[ii],"type") AND aFields[ii].type EQ "thumb">
			<cfset ArrayDeleteAt(aFields,ii)>
		<cfelseif arguments.transformer EQ "sebColumn" AND StructKeyExists(aFields[ii],"type")>
			<!--- Sorter must always come first --->
			<!---<cfif aFields[ii].type EQ "Sorter" AND ii GT 1>
				<cfset sField = Duplicate(aFields[ii])>
				<cfset ArrayDeleteAt(aFields,ii)>
				<cfset ArrayPrepend(aFields,sField)>
				<cfset ii = ArrayLen(aFields)>--->
			<cfif aFields[ii].type EQ "delete">
				<cfset ArrayDeleteAt(aFields,ii)>
			</cfif>
		</cfif>
	</cfloop>
	
	<cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
		<cfif arguments.transformer EQ "sebColumn" AND StructKeyExists(aFields[ii],"type")>
			<cfset sField = Duplicate(aFields[ii])>
			<cfset ArrayDeleteAt(aFields,ii)>
			<cfset ArrayPrepend(aFields,sField)>
		</cfif>
	</cfloop>
	
	<cfreturn aFields>
</cffunction>

<cffunction name="getFieldsArrayInternal" access="public" returntype="array" output="no">
	<cfargument name="transformer" type="string" default="">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfset var aRawFields = Duplicate(variables.sMetaData[arguments.tablename].fields)>
	<cfset var aFields = ArrayNew(1)>
	<cfset var ii = 0>
	<cfset var sField = 0>
	
	<cfloop index="ii" from="1" to="#ArrayLen(aRawFields)#" step="1">
		<cfset sField = transformField(aRawFields[ii],arguments.transformer)>
		<cfif StructCount(sField)>
			<cfset ArrayAppend(aFields,sField)>
		</cfif>
	</cfloop>
	
	<!--- For DataMgr, if a table has multiple pk:identity, none should increment --->
	<cfif StructKeyExists(arguments,"transformer") AND arguments.transformer EQ "DataMgr">
		<cfset aFields = alterDataMgrIncrements(aFields)>
	</cfif>
	
	<cfreturn aFields>
</cffunction>

<cffunction name="getPKRecord" access="public" returntype="query" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="data" type="struct" required="yes">
	<cfargument name="fieldlist" type="string" default="" hint="A list of fields to return. If left blank, all fields will be returned.">
	
	<cfset var in = Duplicate(arguments.data)>
	<cfset var pkfields = variables.DataMgr.getPKFields(arguments.tablename)>
	<cfset var ii = 0>
	<cfset var qRecord = QueryNew("none")>
	<cfset var pklist = "">
	<cfset var isOrdinal = true>
	
	<cfif NOT ArrayLen(pkfields)>
		<cfthrow message="getRecord can only be used against tables with at least one primary key field." type="Manager">
	</cfif>
	
	<!--- Make a list of pkfields --->
	<cfloop index="ii" from="1" to="#ArrayLen(pkfields)#" step="1">
		<cfset pklist = ListAppend(pklist,pkfields[ii].ColumnName)>
	</cfloop>
	
	<cfloop item="ii" collection="#in#">
		<cfif NOT isNumeric(ii)>
			<cfset isOrdinal = false>
		</cfif>
	</cfloop>
	
	<!--- Set argument names if not given by names --->
	<cfif
			isOrdinal
		AND	ArrayLen(in) GTE ArrayLen(pkfields)
		AND NOT StructKeyExists(in,pkfields[1].ColumnName)
	>
		<cfloop index="ii" from="1" to="#ArrayLen(pkfields)#" step="1">
			<cfset in[pkfields[ii].ColumnName] = in[ii]>
		</cfloop>
	</cfif>
	
	<!--- Delete any arguments that aren't simple and primary keys --->
	<cfloop collection="#in#" item="ii">
		<cfif
				NOT (
							StructKeyExists(in,ii)
						AND	isSimpleValue(in[ii])
						AND	ListFindNoCase(pklist,ii)
						AND	Len(in[ii])
					)
		>
			<cfset StructDelete(in,ii)>
		</cfif>
	</cfloop>
	
	<!--- If all pks are passed in, retrieve record --->
	<cfif ArrayLen(pkfields) GT 0 AND StructCount(in) GT 0 AND ArrayLen(pkfields) EQ StructCount(in)>
		<cfinvoke returnvariable="qRecord" component="#variables.DataMgr#" method="getRecord">
			<cfinvokeargument name="tablename" value="#arguments.tablename#">
			<cfinvokeargument name="data" value="#in#">
			<cfinvokeargument name="fieldlist" value="#arguments.fieldlist#">
		</cfinvoke>
	</cfif>
	
	<cfreturn qRecord>
</cffunction>

<cffunction name="getRecord" access="public" returntype="query" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="data" type="struct" required="yes">
	
	<cfset var qRecord = 0>
	
	<cfset arguments.isGetRecord = true>
	
	<cfset arguments = alterArgs(argumentCollection=arguments)>
	<cfset arguments.data = makeNamedPKArgs(tablename=arguments.tablename,data=arguments.data)>
	
	<cfif NOT StructKeyExists(arguments,"fieldlist")>
		<cfset arguments.fieldlist = "">
	</cfif>
	
	<cfset qRecord = variables.DataMgr.getRecord(argumentCollection=arguments)>
	
	<cfreturn alterRecords(arguments.tablename,qRecord)>
</cffunction>

<cffunction name="getRecords" access="public" returntype="query" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="data" type="struct" default="#StructNew()#">
	
	<cfreturn alterRecords(arguments.tablename,variables.DataMgr.getRecords(argumentCollection=alterArgs(argumentCollection=arguments)))>
</cffunction>

<cffunction name="isRecordDeletable" access="public" returntype="boolean" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="data" type="struct" default="#StructNew()#">
	<cfargument name="query" type="query" required="false">
	
	<cfset var result = true>
	<cfset var qRecord = 0>
	<cfset var sMetaData = getMetaStruct()>
	<cfset var sTableData = sMetaData[arguments.tablename]>
	<cfset var col = "">
	<cfset var negate = false>
	
	<cfif StructKeyExists(arguments,"query")>
		<cfset qRecord = arguments.query>
	<cfelse>
		<cfset qRecord = getRecord(tablename=arguments.tablename,data=arguments.data)>
	</cfif>
	
	<!--- Check "deletable" attribute/property of table --->
	<cfif result IS true AND StructKeyExists(sTableData,"deletable") AND Len(sTableData.deletable)>
		<cfif isBoolean(sTableData.deletable)>
			<cfset result = sTableData.deletable>
		<cfelse>
			<cfset col = sTableData.deletable>
			<cfif Left(sTableData.deletable,1) EQ "!">
				<cfset col = ReplaceNoCase(col,"!",1)>
				<cfset negate = true>
			</cfif>
			<cfif ListFindNoCase(qRecord.ColumnList,col)>
				<cfif isBoolean(qRecord[col][1])>
					<cfset result = qRecord[col][1]>
					<cfif negate>
						<cfset result = NOT result>
					</cfif>
				</cfif>
			</cfif>
		</cfif>
	</cfif>
	
	<!--- Check for no deletes for related records --->
	<cfif result IS true>
		<cfset result = variables.DataMgr.isDeletable(tablename=arguments.tablename,data=arguments.data,qRecord=qRecord)>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="removeRecord" access="public" returntype="void" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="data" type="struct" default="#StructNew()#">
	
	<cfset var in = makeNamedPKArgs(arguments.tablename,arguments.data,"removeRecord")>
	<cfset var aFileFields = getFileFields(tablename=arguments.tablename)>
	<cfset var ii = 0>
	<cfset var qRecord = getRecord(tablename=arguments.tablename,data=in)>
	<cfset var conflicttables = variables.DataMgr.getDeletionConflicts(tablename=arguments.tablename,data=in,qRecord=qRecord)>
	<cfset var sCascadeDeletions = variables.DataMgr.getCascadeDeletions(tablename=arguments.tablename,data=in,qRecord=qRecord)>
	<cfset var qRecords = 0>
	<cfset var isLogicalDelete = variables.DataMgr.isLogicalDeletion(arguments.tablename)>
	
	<cfif qRecord.RecordCount EQ 1>
		
		<!--- ToDo: Handle conflicts from cascade --->
		<cfif Len(conflicttables)>
			<cfthrow message="You cannot delete a record in #arguments.tablename# when associated records exist in #conflicttables#." type="Manager" errorcode="NoDeletesWithRelated">
		</cfif>
		
		<!--- Delete any files --->
		<cfloop index="ii" from="1" to="#ArrayLen(aFileFields)#" step="1">
			<cfif
					Len(qRecord[aFileFields[ii].name][1])
				AND	(
							(
									isLogicalDelete IS true
								AND	(
											StructKeyExists(aFileFields[ii],"onRecordDelete")
										AND	aFileFields[ii].onRecordDelete EQ "Delete"
									)
							)
						OR	(
									isLogicalDelete IS false
								AND	NOT (
											StructKeyExists(aFileFields[ii],"onRecordDelete")
										AND	aFileFields[ii].onRecordDelete EQ "Ignore"
									)
							)
					)
			>
				<cfset variables.FileMgr.deleteFile(qRecord[aFileFields[ii].name][1],aFileFields[ii].Folder)>
			</cfif>
		</cfloop>
		
		<cfset variables.DataMgr.deleteRecord(arguments.tablename,in)>
		
		<!--- Perform cascade deletes --->
		<cfloop item="ii" collection="#sCascadeDeletions#">
			<cfset qRecords = variables.DataMgr.getRecords(tablename=ii,data=sCascadeDeletions[ii],fieldlist=getPrimaryKeyFields(ii))>
			<cfloop query="qRecords">
				<cfset removeRecord(tablename=ii,data=QueryRowToStruct(qRecords,CurrentRow))>
			</cfloop>
		</cfloop>
		
	</cfif>
	
</cffunction>

<cffunction name="copyRecord" access="public" returntype="string" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="data" type="struct" default="#StructNew()#">
	<cfargument name="CopyChildren" type="boolean" required="no">
	<cfargument name="CopyFiles" type="boolean" default="true">
	
	<cfset var in = Duplicate(arguments.data)>
	<cfset var aFileFields = getFileFields(tablename=arguments.tablename)>
	<cfset var qRecord = 0>
	<cfset var sRecord = 0>
	<cfset var ii = 0>
	<cfset var result = "">
	<cfset var path = "">
	<cfset var pkfields = getPrimaryKeyFields(arguments.tablename)>
	<cfset var table = "">
	<cfset var sChildren = 0>
	<cfset var qChildren = 0>
	<cfset var childpkfields = 0>
	<cfset var sFTables = 0>
	
	<cfset arguments.OnExists = "insert">
	
	<cfset StructDelete(arguments,"data")>
	
	<cfset qRecord = getPKRecord(tablename=arguments.tablename,data=in,fieldlist=getFieldListFromArray(getFieldsArray(arguments.tablename)))>
	<cfset sRecord = QueryRowToStruct(qRecord)>
	
	<cfset StructAppend(in,sRecord,"no")>
	
	<!--- Copy any associated files --->
	<cfif ArrayLen(aFileFields) AND arguments.CopyFiles>
		<cfloop index="ii" from="1" to="#ArrayLen(aFileFields)#" step="1">
			<!--- If the file name is passed in (with a new value) then action has already been taken against it --->
			<cfif
					Len(sRecord[aFileFields[ii].name])
				AND	NOT (
								StructKeyExists(in,aFileFields[ii].name)
							AND	in[aFileFields[ii].name] NEQ sRecord[aFileFields[ii].name]
						)
			>
				<cfset in[aFileFields[ii].name] = variables.FileMgr.makeFileCopy(sRecord[aFileFields[ii].name],aFileFields[ii].folder)>
			</cfif>
		</cfloop>
	</cfif>
	
	<!--- Ditch primary keys --->
	<cfloop list="#pkfields#" index="ii">
		<cfset StructDelete(in,ii)>
	</cfloop>
	
	<cfset arguments.data = in>
	
	<cfset result = saveRecord(argumentCollection=arguments)>
	
	<cfif
			( StructKeyExists(Arguments,"CopyChildren") AND Arguments.CopyChildren IS true )
		AND	qRecord.RecordCount
		AND	(
					StructKeyExists(variables.sMetaData[arguments.tablename],"childtables")
				AND	Len(variables.sMetaData[arguments.tablename]["childtables"])
			)
		AND	ListLen(pkfields) EQ 1
	>
		<cfloop index="table" list="#variables.sMetaData[arguments.tablename].childtables#">
			<cfset sChildren = StructNew()>
			<cfset sFTables = Variables.DataMgr.getFTableFields(table)>
			<cfif StructKeyExists(sFTables,arguments.tablename)>
				<cfset sChildren[sFTables[arguments.tablename]] = qRecord[pkfields][1]>
				<cfset childpkfields = getPrimaryKeyFields(table)>
				<cfset qChildren = getRecords(tablename=table,data=sChildren,fieldlist=childpkfields)>
				<cfoutput query="qChildren">
					<cfset sRecord = StructNew()>
					<cfset sRecord[sFTables[arguments.tablename]] = result>
					<cfloop index="ii" list="#childpkfields#">
						<cfset sRecord[ii] = qChildren[ii][CurrentRow]>
					</cfloop>
					<cfset copyRecord(tablename=table,data=sRecord,CopyChildren=true)>
				</cfoutput>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="copyRecordChildren" access="public" returntype="void" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="data" type="struct" default="#StructNew()#">
</cffunction>

<cffunction name="saveRecord" access="public" returntype="string" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="data" type="struct" default="#StructNew()#">
	<cfargument name="OnExists" type="string" required="no" hint="defaults to update.">
	
	<cfset var in = Duplicate(arguments.data)>
	<cfset var aFileFields = getFileFields(tablename=arguments.tablename,data=arguments.data)>
	<cfset var ii = 0>
	<cfset var qRecord = 0>
	<cfset var result = "">
	<cfset var FormField = "">
	<cfset var FileResult = "">
	<cfset var isUpload = false>
	<cfset var isFormUpload = false>
	
	<!--- Default OnExists to update, but use key from data if it exists --->
	<cfif NOT StructKeyExists(arguments,"OnExists")>
		<cfif StructKeyExists(in,"OnExists")>
			<cfset arguments.OnExists = in.OnExists>
		<cfelse>
			<cfset arguments.OnExists = "update">
		</cfif>
	</cfif>
	
	<!--- Take actions on any file fields --->
	<cfif ArrayLen(aFileFields) AND StructCount(in)>
		
		<cfloop index="ii" from="1" to="#ArrayLen(aFileFields)#">
			<cfset FormField = aFileFields[ii].name>
			<cfif
					StructKeyExists(in,"#aFileFields[ii].name#_FormField")
				AND	StructKeyExists(Form,"#in['#aFileFields[ii].name#_FormField']#")
			>
				<cfset FormField = in['#aFileFields[ii].name#_FormField']>
			</cfif>
			<cfset isUpload = false>
			<cfset isFormUpload = isUpload>
			<cfif StructKeyExists(in,aFileFields[ii].name)>
				<cftry>
					<cfset isUpload = FileExists(Form[FormField])>
					<cfset isFormUpload = isUpload>
				<cfcatch>
				</cfcatch>
				</cftry>
				<cfif NOT isUpload>
					<cftry>
						<cfset isUpload = FileExists(in[aFileFields[ii].name])>
					<cfcatch>
					</cfcatch>
					</cftry>
				</cfif>
			</cfif>
			<cfif isUpload>
				<cfif isFormUpload>
					<cfinvoke returnvariable="FileResult" component="#variables.FileMgr#" method="uploadFile">
						<cfif isFormUpload>
							<cfinvokeargument name="FieldName" value="#FormField#">
						<cfelse>
							<cfinvokeargument name="FieldName" value="#in[aFileFields[ii].name]#">
						</cfif>
						<cfinvokeargument name="Folder" value="#aFileFields[ii].Folder#">
						<cfif StructKeyExists(aFileFields[ii],"NameConflict")>
							<cfinvokeargument name="NameConflict" value="#aFileFields[ii].NameConflict#">
						</cfif>
						<cfif StructKeyExists(aFileFields[ii],"accept")>
							<cfinvokeargument name="accept" value="#aFileFields[ii].accept#">
						</cfif>
						<cfif StructKeyExists(aFileFields[ii],"extensions")>
							<cfinvokeargument name="extensions" value="#aFileFields[ii].extensions#">
						</cfif>
						<cfinvokeargument name="return" value="name">
					</cfinvoke>
					<cfif isStruct(FileResult) AND StructKeyExists(FileResult,"ServerFile")>
						<cfset in[aFileFields[ii].name] = FileResult["ServerFile"]>
					</cfif>
					<cfif isSimpleValue(FileResult)>
						<cfset in[aFileFields[ii].name] = FileResult>
					</cfif>
					<cfif StructKeyExists(in,aFileFields[ii].name) AND isSimpleValue(in[aFileFields[ii].name])>
						<cfif NOT StructKeyExists(aFileFields[ii],"Length")>
							<cfset aFileFields[ii].Length = 50>
						</cfif>
						<cfset in[aFileFields[ii].name] = fixFileName(in[aFileFields[ii].name],variables.FileMgr.getDirectory(aFileFields[ii].Folder),aFileFields[ii].Length)>
					</cfif>
				<cfelse>
					<cffile destination="#Variables.FileMgr.getDirectory(aFileFields[ii].Folder)#" source="#in[aFileFields[ii].name]#" action="copy">
					<cfset in[aFileFields[ii].name] = getFileFromPath(in[aFileFields[ii].name])>
				</cfif>
			</cfif>
		</cfloop>
		
		<!--- fit any images into box (if possible) --->
		<cfset in = adjustImages(tablename=arguments.tablename,data=in)>
		
		<!--- Delete any files that are cleared out --->
		<cfset qRecord = getPKRecord(tablename=arguments.tablename,data=in,fieldlist=getFieldListFromArray(aFileFields))>
		<cfif qRecord.RecordCount>
			<cfloop index="ii" from="1" to="#ArrayLen(aFileFields)#" step="1">
				<cfif Len(qRecord[aFileFields[ii].name][1]) AND StructKeyExists(in,aFileFields[ii].name) AND NOT Len(Trim(in[aFileFields[ii].name]))>
					<cfset variables.FileMgr.deleteFile(qRecord[aFileFields[ii].name][1],aFileFields[ii].Folder)>
				</cfif>
			</cfloop>
		</cfif>
		
	</cfif>
	
	<cfset arguments.data = Duplicate(in)>
	<cfset arguments.alterargs_for = "save">
	<cfset result = variables.DataMgr.insertRecord(argumentCollection=alterArgs(argumentCollection=arguments))>
	
	<cfreturn result>
</cffunction>

<cffunction name="getFieldListFromArray" access="private" returntype="string" output="false">
	<cfargument name="aFields" type="array" required="yes">
	
	<cfset var result = "">
	<cfset var ii = 0>
	
	<cfloop index="ii" from="1" to="#ArrayLen(arguments.aFields)#" step="1">
		<cfset result = ListAppend(result,arguments.aFields[ii].name)>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<cffunction name="getFileFields" access="public" returntype="array" output="false">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="data" type="struct" default="#StructNew()#">
	
	<cfset var aResults = ArrayNew(1)>
	<cfset var in = Duplicate(arguments.data)>
	<cfset var aFields = getFieldsArray(tablename=arguments.tablename)>
	<cfset var ii = 0>
	
	<cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
		<cfif
				( StructKeyExists(aFields[ii],"Folder") AND	Len(aFields[ii].Folder) )
			AND	(
						(
								StructCount(in) EQ 0
							OR	StructKeyExists(in,aFields[ii].name)
						)
					OR	(
								StructKeyExists(aFields[ii],"original")
							AND	StructKeyExists(in,aFields[ii].original)
						)
				)
		>
			<cfset ArrayAppend(aResults,aFields[ii])>
		</cfif>
	</cfloop>
	
	<cfreturn aResults>
</cffunction>

<cffunction name="alterRecords" access="public" returntype="query" output="false" hint="">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="query" type="query" required="yes">
	
	<!---<cfset var sTable = variables.sMetaData[arguments.tablename]>--->
	<cfset var aFields = getFieldsArray(arguments.tablename)>
	<cfset var sFields = getFieldsStruct(arguments.tablename)>
	<cfset var ii = 0>
	<cfset var FolderFields = "">
	<cfset var field = "">
	<cfset var aPaths = ArrayNew(1)>
	<cfset var aURLs = ArrayNew(1)>
	
	<cfif Len(Trim(variables.FileMgr.getUploadPath())) OR Len(Trim(variables.FileMgr.getUploadURL()))>
		<cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
			<cfif StructKeyExists(aFields[ii],"Folder") AND Len(Trim(aFields[ii].Folder))>
				<cfset FolderFields = ListAppend(FolderFields,aFields[ii].name)>
			</cfif>
		</cfloop>
		
		<cfif Len(FolderFields)>
			<cfloop index="field" list="#FolderFields#">
				<cfif Len(Trim(variables.FileMgr.getUploadPath())) AND ListFindNoCase(arguments.query.ColumnList,field) AND NOT ListFindNoCase(arguments.query.ColumnList,"#field#URL")>
					<cfset aPaths = ArrayNew(1)>
					<cfloop query="arguments.query">
						<cfif Len(Trim(arguments.query[field][CurrentRow]))>
							<cfset ArrayAppend(aPaths,"#variables.FileMgr.getFilePath(arguments.query[field][CurrentRow],sFields[field].Folder)#")>
						<cfelse>
							<cfset ArrayAppend(aPaths,"")>
						</cfif>
					</cfloop>
					<cfset QueryAddColumn(arguments.query,"#field#Path",aPaths)>
				</cfif>
				<cfif Len(Trim(variables.FileMgr.getUploadURL())) AND ListFindNoCase(arguments.query.ColumnList,field) AND NOT ListFindNoCase(arguments.query.ColumnList,"#field#URL")>
					<cfset aURLs = ArrayNew(1)>
					<cfloop query="arguments.query">
						<cfif Len(Trim(arguments.query[field][CurrentRow]))>
							<cfset ArrayAppend(aURLs,"#variables.FileMgr.getFileURL(arguments.query[field][CurrentRow],sFields[field].Folder)#")>
						<cfelse>
							<cfset ArrayAppend(aURLs,"")>
						</cfif>
					</cfloop>
					<cfset QueryAddColumn(arguments.query,"#field#URL",aURLs)>
				</cfif>
			</cfloop>
		</cfif>
	</cfif>
	
	<cfreturn arguments.query>
</cffunction>

<cffunction name="alterArgs" access="public" returntype="struct" output="false" hint="">
	<cfargument name="alterargs_for" type="string" default="get">
	
	<cfset var sMetaData = getMetaStruct()>
	<cfset var sArgs = StructFromArgs(arguments)>
	<cfset var sTableData = sMetaData[sArgs.tablename]>
	<cfset var sFields = getFieldsStruct(sArgs.tablename)>
	<cfset var sSort = 0>
	<cfset var dmargs = 0>
	<cfset var dmarg = "">
	
	<cfif arguments.alterargs_for EQ "save">
		<cfset dmargs = getDataMgrSaveRecordArgs()>
	<cfelse>
		<cfset dmargs = getDataMgrGetRecordsArgs()>
	</cfif>
	
	<!--- Any data args that match DataMgr args should be copied there --->
	<cfif StructKeyExists(arguments,"data")>
		<cfif StructKeyExists(arguments.data,"data")>
			<cfset StructAppend(arguments.data,arguments.data.data,"no")>
		</cfif>
		<cfloop list="#dmargs#" index="dmarg">
			<cfif StructKeyExists(sArgs.data,dmarg) AND NOT StructKeyExists(sArgs,dmarg)>
				<cfset sArgs[dmarg] = sArgs.data[dmarg]>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfif arguments.alterargs_for EQ "get">
		<!--- Default list to fields marked "isOnList=true" for multi-record queries (if none are marked, empty string will retrieve all fields) --->
		<cfif NOT StructKeyExists(sArgs,"fieldlist")>
			<cfif StructKeyExists(arguments,"isGetRecord")>
				<cfset sArgs.fieldlist = "">
			<cfelse>
				<cfset sArgs.fieldlist = sTableData["listfields"]>
			</cfif>
		</cfif>
		
		<cfif NOT ( StructKeyExists(sArgs,"sortfield") )>
			<cfif StructKeyExists(sTableData,"orderby") AND NOT ( StructKeyExists(sArgs,"orderby") )>
				<cfset sArgs["orderby"] = sTableData["orderby"]>
			<cfelse>
				<cfset sSort = getTableSort(sArgs.tablename,sArgs.fieldlist)>
				<cfif StructKeyExists(sSort,"field")>
					<cfset sArgs["sortfield"] = sSort.field>
					<cfset sArgs["sortdir"] = sSort.dir>
				</cfif>
			</cfif>
		</cfif>
	</cfif>
	
	<cfset StructDelete(arguments,"alterargs_for")>
	
	<cfreturn sArgs>
</cffunction>

<cffunction name="alterDataMgrIncrements" access="private" returntype="array" output="no" hint="I make sure DataMgr isn't given multiple increments.">
	<cfargument name="aFields" type="array" required="true">
	
	<cfset var ii = 0>
	<cfset var incCount = 0>
	
	<cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
		<cfif
				( StructKeyExists(aFields[ii],"Increment") AND aFields[ii].Increment IS true )
			OR	( StructKeyExists(aFields[ii],"PrimaryKey") AND aFields[ii].PrimaryKey IS true )
		>
			<cfset incCount = incCount + 1>
		</cfif>
	</cfloop>
	<cfif incCount GT 1>
		<cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
			<cfif StructKeyExists(aFields[ii],"Increment") AND aFields[ii].Increment EQ 1>
				<cfset aFields[ii]["Increment"] = false>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfreturn aFields>
</cffunction>

<cffunction name="getWidth" access="private" returntype="string" output="no">
	<cfargument name="struct" type="struct" required = "yes">
	<cfargument name="imagedata" type="any" required="yes">
	
	<cfset var data = arguments.struct>
	<cfset var result = imagedata.width>
	
	<cfif
			( StructKeyExists(data,"MaxWidth") AND isNumeric(data.MaxWidth) AND data.MaxWidth GT 0 )
		AND	imagedata.width GT data.MaxWidth
	>
		<cfset result = Int(data.MaxWidth)>
	<cfelseif
			( StructKeyExists(data,"MaxSmallSide") AND isNumeric(data.MaxSmallSide) AND data.MaxSmallSide GT 0 )
		AND	imagedata.height GTE imagedata.width
	>
		<cfset result = Int(data.MaxSmallSide)>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getHeight" access="private" returntype="string" output="no">
	<cfargument name="struct" type="struct" required="yes">
	<cfargument name="imagedata" type="any" required="yes">
	
	<cfset var data = arguments.struct>
	<cfset var result = imagedata.height>
	
	<cfif
			( StructKeyExists(data,"MaxHeight") AND isNumeric(data.MaxHeight) AND data.MaxHeight GT 0 )
		AND	imagedata.height GT data.MaxHeight
	>
		<cfset result = Int(data.MaxHeight)>
	<cfelseif
			( StructKeyExists(data,"MaxSmallSide") AND isNumeric(data.MaxSmallSide) AND data.MaxSmallSide GT 0 )
		AND	imagedata.width GTE imagedata.height
	>
		<cfset result = Int(data.MaxSmallSide)>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="makeNamedPKArgs" access="public" returntype="struct" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="data" type="struct" required="yes">
	<cfargument name="method" type="string" default="getRecord">
	
	<cfset var pkfields = variables.DataMgr.getPKFields(arguments.tablename)>
	<cfset var ii = 0>
	
	<cfif NOT ArrayLen(pkfields)>
		<cfthrow message="#arguments.method# can only be used against tables with at least one primary key field." type="Manager">
	</cfif>
	
	<!--- Set argument names if not given by names --->
	<cfif
			StructCount(arguments.data) GTE ArrayLen(pkfields)
		AND	NOT StructKeyExists(arguments.data,pkfields[1].ColumnName)
	>
		<cfloop index="ii" from="1" to="#ArrayLen(pkfields)#" step="1">
			<cfif
					StructKeyExists(arguments.data,ii)
				AND	NOT StructKeyExists(arguments.data,pkfields[ii].ColumnName)
			>
				<cfset arguments.data[pkfields[ii].ColumnName] = arguments.data[ii]>
				<cfset StructDelete(arguments.data,ii)>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfreturn StructCopy(arguments.data)>
</cffunction>

<cffunction name="setTable" access="private" returntype="void" output="false" hint="">
	<cfargument name="tablename" type="string" required="yes">
	
	<cflock name="Manager_#arguments.tablename#" timeout="30">
		<cfif NOT StructKeyExists(variables.sMetaData,arguments.tablename)>
			<cfset variables.sMetaData[arguments.tablename] = StructNew()>
			<cfset variables.sMetaData[arguments.tablename]["fieldlist"] = "">
			<cfset variables.sMetaData[arguments.tablename]["fields"] = ArrayNew(1)>
			<cfset variables.sMetaData[arguments.tablename]["listfields"] = "">
			<cfset variables.sMetaData[arguments.tablename]["fields"] = ArrayNew(1)>
			<cfset variables.sMetaData[arguments.tablename]["sFields"] = StructNew()>
			<cfset variables.sMetaData[arguments.tablename]["_sortfield"] = "">
			<cfset variables.sMetaData[arguments.tablename]["_sortdir"] = "">
			<cfset variables.sMetaData[arguments.tablename]["hasFileFields"] = false>
			<cfset variables.sMetaData[arguments.tablename]["sAttributes"] = StructNew()>
		</cfif>
	</cflock>
	
</cffunction>

<cffunction name="getTableSort" access="private" returntype="struct" output="false" hint="">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="fieldlist" type="string" required="no">
	
	<cfset var table = arguments.tablename>
	<cfset var sTable = variables.sMetaData[table]>
	<cfset var aFields = sTable["fields"]>
	<cfset var sField = 0>
	<cfset var ii = 0>
	
	<cfset var aSortDefaults = ArrayNew(1)>
	<cfset var aSorters = ArrayNew(1)>
	
	<cfset var sResult = StructNew()>
	
	<cfif NOT (StructKeyExists(arguments,"fieldlist") AND Len(arguments.fieldlist) )>
		<cfset arguments.fieldlist = variables.sMetaData[arguments.tablename]["fieldlist"]>
	</cfif>
	
	<!--- Set internal sort field and direction --->
	<cfif StructKeyExists(sTable,"sortfield") AND ListFindNoCase(arguments.fieldlist,sTable["sortfield"])>
		<cfset sResult["field"] = sTable["sortfield"]>
		<cfif StructKeyExists(sTable,"sortdir")>
			<cfset sResult["dir"] = sTable["sortdir"]>
		</cfif>
	<cfelse>
		<cfloop index="ii" from="1" to="#ArrayLen(aFields)#">
			<cfset sField = aFields[ii]>
			
			<cfif ListFindNoCase(arguments.fieldlist,sField.name)>
				<!--- Check for sort (apply to table if none exists) --->
				<cfif StructKeyExists(sField,"defaultSort") AND ListFindNoCase("ASC,DESC",sField.defaultSort)>
					<cfset ArrayAppend(aSortDefaults,StructFromArgs(field=sField.name,dir=sField.defaultSort))>
				</cfif>
				<cfif
						(StructKeyExists(sField,"Special") AND sField.Special EQ "Sorter")
					OR	(StructKeyExists(sField,"type") AND sField.type EQ "Sorter")
				>
					<cfset ArrayAppend(aSorters,StructFromArgs(field=sField.name,dir="ASC"))>
				</cfif>
			</cfif>
		</cfloop>
		
		<cfif ArrayLen(aSorters)>
			<cfloop index="ii" from="1" to="#ArrayLen(aSorters)#" step="1">
				<cfif ListFindNoCase(arguments.fieldlist,aSorters[ii]["field"])>
					<cfset sResult = aSorters[ii]>
					<cfbreak>
				</cfif>
			</cfloop>
		<cfelseif ArrayLen(aSortDefaults)>
			<cfloop index="ii" from="1" to="#ArrayLen(aSortDefaults)#" step="1">
				<cfif ListFindNoCase(arguments.fieldlist,aSortDefaults[ii]["field"])>
					<cfset sResult = aSortDefaults[ii]>
					<cfbreak>
				</cfif>
			</cfloop>
		<cfelseif StructKeyExists(sTable,"labelField")>
			<cfset sResult["field"] = sTable["labelField"]>
		</cfif>
	</cfif>
	
	<cfif StructKeyExists(sResult,"field") AND NOT StructKeyExists(sResult,"dir")>
		<cfset sResult["dir"] = "ASC">
	</cfif>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="setField" access="public" returntype="any" output="false" hint="">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="fieldname" type="string" required="yes">
	<cfargument name="type" type="string" required="no">
	
	<cfset var sField = Duplicate(arguments)>
	<cfset var ii = 0>
	<cfset var sDataMgrField = 0>
	
	<cfset StructDelete(sField,"tablename")>
	<cfset StructDelete(sField,"fieldname")>
	<cfset sField["name"] = arguments.fieldname>
	
	<!--- Expand folder --->
	<cfif
			StructKeyExists(sField,"Folder")
		AND	StructKeyExists(variables.sMetaData[arguments.tablename],"folder")
		AND	NOT (
					StructKeyExists(sField,"ExpandFolder")
				AND	sField.ExpandFolder IS false
			)
	>
		<cfset sField["Folder"] = ListPrepend(sField["Folder"],variables.sMetaData[arguments.tablename].folder)>
	</cfif>
	
	<!--- Default URLvar for foreign keys --->
	<cfif NOT StructKeyExists(sField,"urlvar")>
		<cfif
				StructKeyExists(arguments,"type")
			AND	ListFirst(arguments.type,":") EQ "fk"
		>
			<cfset sField["urlvar"] = LCase(sField["name"])>
			<cfif Right(sField["urlvar"],2) EQ "id">
				<cfset sField["urlvar"] = Left(sField["urlvar"],Len(sField["urlvar"])-2)>
				<cfif Right(sField["urlvar"],1) EQ "_">
					<cfset sField["urlvar"] = Left(sField["urlvar"],Len(sField["urlvar"])-1)>
				</cfif>
			</cfif>
		<cfelseif
				StructKeyExists(arguments,"fentity")
			AND	Len(arguments.fentity)
		>
			<cfset sField["urlvar"] = LCase(makeCompName(arguments.fentity))>
		</cfif>
	</cfif>
	
	<!--- Only set fields with a type or a relation --->
	<cfif StructKeyExists(arguments,"type") OR StructKeyExists(arguments,"relation")>
		<!--- Make sure a table exists for this field --->
		<cfset setTable(arguments.tablename)>
		<cfif ListFindNoCase(sMetaData[arguments.tablename]["fieldlist"],arguments.fieldname)>
			<!--- Update field --->
			<cfloop index="ii" from="1" to="#ArrayLen(sMetaData[arguments.tablename].fields)#">
				<cfif sMetaData[arguments.tablename].fields[ii].name EQ arguments.fieldname>
					<cfset sMetaData[arguments.tablename].fields[ii] = sField>
				</cfif>
			</cfloop>
		<cfelse>
			<!--- Add field --->
			<cfset ArrayAppend(sMetaData[arguments.tablename]["fields"],sField)>
			<cfset sMetaData[arguments.tablename]["fieldlist"] = ListAppend(sMetaData[arguments.tablename]["fieldlist"],arguments.fieldname)>
			<cfif StructKeyExists(arguments,"isOnList") AND isBoolean(arguments.isOnList) AND arguments.isOnList>
				<cfset sMetaData[arguments.tablename]["listfields"] = ListAppend(sMetaData[arguments.tablename]["listfields"],arguments.fieldname)>
			</cfif>
		</cfif>
		<cfset sMetaData[arguments.tablename]["sFields"][arguments.fieldname] = sField>
		<cfset StructDelete(sMetaData[arguments.tablename]["sFields"][arguments.fieldname],"isInTableCreation")>
		
		<cfif NOT ( StructKeyExists(arguments,"isInTableCreation") AND isBoolean(arguments.isInTableCreation) AND arguments.isInTableCreation )>
			<cfset sDataMgrField = transformField(Duplicate(sField),"DataMgr")>
			<cfset sDataMgrField["tablename"] = arguments.tablename>
			<cfset sDataMgrField["ColumnName"] = arguments.fieldname>
			<cfset variables.DataMgr.setColumn(argumentCollection=sDataMgrField)>
			
			<!--- Make any thumbnails for new thumbnail field --->
			<cfif isThumbField(arguments.tablename,arguments.fieldname)>
				<cfset makeThumbs(arguments.tablename,arguments.fieldname)>
			</cfif>
		</cfif>
		
		
		<cfif StructKeyExists(sField,"Folder")>
			<cfset variables.FileMgr.makeFolder(sField.Folder)>
			<cfset variables.sMetaData[arguments.tablename]["hasFileFields"] = true>
		</cfif>
		
	</cfif>
	
</cffunction>

<cffunction name="loadXml" access="public" returntype="any" output="false" hint="">
	<cfargument name="xml" type="any" required="yes">
	
	<cfset var xIn = XmlParse(arguments.xml)>
	<cfset var table = "">
	<cfset var aInTables = 0>
	<cfset var tt = 0>
	
	<cflock name="Manager_loadXml#variables.UUID#" timeout="1800" throwontimeout="yes">
		<cfset adjustXml(xIn)>
		
		<cfset loadXmlStruct(xIn)>
		<cfset loadDataMgrXml(xIn)>
		
		<cfset aInTables = XmlSearch(xIn,"//table[string-length(@name)>0]")>
		
		<!--- Make thumbnails --->
		<cfloop index="tt" from="1" to="#ArrayLen(aInTables)#">
			<cfset table = aInTables[tt].XmlAttributes["name"]>
			<cfif variables.sMetaData[table]["hasFileFields"] IS true>
				<cfset makeThumbs(table)>
			</cfif>
		</cfloop>
	</cflock>
	
	<cfreturn xIn>
</cffunction>

<cffunction name="adjustXml" access="public" returntype="any" output="false" hint="">
	<cfargument name="xml" type="any" required="yes">
	
	<cfset var xDef = 0>
	<cfset var aTables = 0>
	<cfset var aFTables = 0>
	<cfset var table = "">
	<cfset var ftable = "">
	<cfset var aFields = 0>
	<cfset var tt = 0>
	<cfset var ff = 0>
	<cfset var ll = 0>
	<cfset var sField = "">
	<cfset var special = "">
	<cfset var xType = 0>
	<cfset var insertAt = 0>
	
	<cfif isSimpleValue(arguments.xml)>
		<cfset xDef = XmlParse(arguments.xml)>
	<cfelseif isXMLDoc(arguments.xml)>
		<cfset xDef = arguments.xml>
	<cfelse>
		<cfthrow message="XML argument of loadXmlStruct must be XML." type="Manager">
	</cfif>
	
	<cfset xDef = applyTableDefaults(xDef)>
	<cfset xDef = applyEntities(xDef)>
	<cfset xDef = applySecurityPermissions(xDef)>
	
	<cfset aTables = XmlSearch(xDef,"//table[string-length(@name)>0]")>
	
	<!--- Table/Field pre-processing --->
	<cfloop index="tt" from="1" to="#ArrayLen(aTables)#">
		<cfset table = aTables[tt].XmlAttributes["name"]>
		<!--- Create entry for table if not already in memory --->
		<cfset setTable(table)>
		
		<cfif NOT StructKeyExists(aTables[tt].XmlAttributes,"deletable")>
			<cfset aTables[tt].XmlAttributes["deletable"] = "isDeletable">
		</cfif>
		
		<!--- Update table properties --->
		<cfset StructAppend(variables.sMetaData[table]["sAttributes"],aTables[tt].XmlAttributes,"yes")>
		<cfset StructAppend(variables.sMetaData[table],aTables[tt].XmlAttributes,"yes")>
		<cfset StructDelete(variables.sMetaData[table],"name")>
		
		<cfif NOT StructKeyExists(aTables[tt].XmlAttributes,"methodSingular")>
			<cfif StructKeyExists(variables.sMetaData[table],"methodSingular")>
				<cfset aTables[tt].XmlAttributes["methodSingular"] = variables.sMetaData[table]["methodSingular"]>
			<cfelseif StructKeyExists(aTables[tt].XmlAttributes,"labelSingular")>
				<cfset aTables[tt].XmlAttributes["methodSingular"] = makeCompName(aTables[tt].XmlAttributes["labelSingular"])>
				<cfset variables.sMetaData[table]["methodSingular"] = aTables[tt].XmlAttributes["methodSingular"]>
			</cfif>
		</cfif>
		<cfif NOT StructKeyExists(aTables[tt].XmlAttributes,"methodPlural")>
			<cfif StructKeyExists(variables.sMetaData[table],"methodPlural")>
				<cfset aTables[tt].XmlAttributes["methodPlural"] = variables.sMetaData[table]["methodPlural"]>
			<cfelseif StructKeyExists(aTables[tt].XmlAttributes,"labelPlural")>
				<cfset aTables[tt].XmlAttributes["methodPlural"] = makeCompName(aTables[tt].XmlAttributes["labelPlural"])>
				<cfset variables.sMetaData[table]["methodPlural"] = aTables[tt].XmlAttributes["methodPlural"]>
			</cfif>
		</cfif>
		
		<cfset aFields = XmlSearch(xDef,"//table[@name='#table#']//field[string-length(@name)>0]")>
		
		<!--- Create primary key field from pkfield attribute --->
		<cfif
				StructKeyExists(aTables[tt].XmlAttributes,"pkfield")
			AND	Len(Trim(aTables[tt].XmlAttributes.pkfield))
			AND	NOT StructKeyExists(variables.sMetaData[table].sFields,variables.sMetaData[table].pkfield)
			AND	NOT ArrayLen(XmlSearch(xDef,"//table[@name='#table#']//field[@name='#variables.sMetaData[table].pkfield#']"))
		>
			<!--- Look for existing pkfield --->
			<cfloop index="ff" from="1" to="#ArrayLen(aFields)#">
				<cfif StructKeyExists(aFields[ff],"type") AND Len(aFields[ff].type) AND ListFirst(aFields[ff].type,":") EQ "pk">
					<cfthrow message="Primary key for #table# defined in pkfield attribute (#variables.sMetaData[table].pkfield#) does not match a field defined as a primary key." type="Manager">
				</cfif>
			</cfloop>
			
			<!--- No errors? Then create the field --->
			<cfset xField = XmlElemNew(xDef,"field")>
			<cfset xField.XmlAttributes["name"] = variables.sMetaData[table].pkfield>
			<cfset xField.XmlAttributes["type"] = "pk:integer">
			
			<cfset ArrayPrepend(aTables[tt].XmlChildren,Duplicate(xField))>
		</cfif>
		
		<!--- Create label field from labelField attribute --->
		<cfif
				StructKeyExists(aTables[tt].XmlAttributes,"labelField")
			AND	Len(Trim(aTables[tt].XmlAttributes.labelField))
			AND	NOT ListFindNoCase(variables.sMetaData[table].fieldlist,variables.sMetaData[table].labelField)
			AND	NOT StructKeyExists(variables.sMetaData[table].sFields,variables.sMetaData[table].labelField)
			AND	NOT ArrayLen(XmlSearch(xDef,"//table[@name='#table#']//field[@name='#variables.sMetaData[table].labelField#']"))
		>
		
			<cfset xField = XmlElemNew(xDef,"field")>
			<cfset xField.XmlAttributes["name"] = variables.sMetaData[table].labelField>
			<cfset xField.XmlAttributes["label"] = variables.sMetaData[table]["labelSingular"]>
			<cfset xField.XmlAttributes["type"] = "text">
			<cfset xField.XmlAttributes["required"] = "true">
			
			<cfif
					StructKeyExists(variables.sMetaData[table],"labelLength")
				AND	isNumeric(variables.sMetaData[table].labelLength)
				AND	variables.sMetaData[table].labelLength GT 0
			>
				<cfset xField.XmlAttributes["Length"] = Int(variables.sMetaData[table].labelLength)>
			<cfelse>
				<cfset xField.XmlAttributes["Length"] = 120>
			</cfif>
			
			<cfset insertAt = Min(
				ArrayLen(
					XmlSearch(
						xDef,
						"//table[@name='#table#']//field"
					)
				) + 1,
				ArrayLen(
					XmlSearch(
						xDef,
						"//table[@name='#table#']//field[starts-with(@type,'pk:')]"
					)
				) + 1
			)>
			
			<cfif insertAt GTE ArrayLen(aTables[tt].XmlChildren)>
				<cfset ArrayAppend(aTables[tt].XmlChildren,xField)>
			<cfelse>
				<cfset ArrayInsertAt(aTables[tt].XmlChildren,insertAt,xField)>
			</cfif>
			
		</cfif>
		
		<!--- Add Special fields --->
		<cfif
				StructKeyExists(variables.sMetaData[table],"Specials")
			AND	Len(Trim(variables.sMetaData[table].Specials))
		>
			<cfloop list="#variables.sMetaData[table].Specials#" index="special">
				<cfif
						ListFindNoCase(variables.TypeNames,special)
					AND	NOT ArrayLen(XmlSearch(aTables[tt],"/field[@type='#special#']"))
				>
					<cfset xField = XmlElemNew(xDef,"field")>
					<cfset xField.XmlAttributes["type"] = special>
					<cfif special EQ "CreationDate" OR special EQ "LastUpdatedDate">
						<cfset xField.XmlAttributes["sebcolumn"] = false>
					</cfif>
					<cfset ArrayAppend(aTables[tt].XmlChildren,xField)>
				</cfif>
			</cfloop>
		</cfif>
		
		<!--- Add help for image sizes --->
		<cfloop index="ff" from="1" to="#ArrayLen(aFields)#">
			<cfset xField = aFields[ff]>
			<cfif
					StructKeyExists(xField.XmlAttributes,"type")
				AND	xField.XmlAttributes["type"] EQ "image"
				AND	( StructKeyExists(xField.XmlAttributes,"MaxWidth") AND Val(xField.XmlAttributes["MaxWidth"]) )
				AND	( StructKeyExists(xField.XmlAttributes,"MaxHeight") AND Val(xField.XmlAttributes["MaxHeight"]) )
				AND	NOT ( StructKeyExists(xField.XmlAttributes,"help") AND Len(xField.XmlAttributes["help"]) )
			>
				<cfset xField.XmlAttributes["help"] = '( At least #xField.XmlAttributes["MaxWidth"]#px X #xField.XmlAttributes["MaxHeight"]#px )'>
			</cfif>
		</cfloop>
		
		<!--- Add "IN" filter for pk field --->
		<cfif
				StructKeyExists(aTables[tt].XmlAttributes,"pkfield")
			AND	StructKeyExists(aTables[tt].XmlAttributes,"methodPlural")
			AND	ArrayLen(
					XmlSearch(
						xDef,
						"//table[@name='#table#']//field[starts-with(@type,'pk:')]"
					)
				) EQ 1
			AND NOT (
					ArrayLen(
						XmlSearch(
							xDef,
							"//table[@name='#table#']//filter[@name='#LCase(aTables[tt].XmlAttributes.methodPlural)#']"
						)
					)
				)	
		>
			<cfset xField = XmlElemNew(xDef,"filter")>
			<cfset xField.XmlAttributes["name"] = LCase(aTables[tt].XmlAttributes.methodPlural)>
			<cfset xField.XmlAttributes["field"] = aTables[tt].XmlAttributes.pkfield>
			<cfset xField.XmlAttributes["operator"] = "IN">
			<cfset ArrayAppend(aTables[tt].XmlChildren,Duplicate(xField))>
			
			<cfset xField = XmlElemNew(xDef,"filter")>
			<cfset xField.XmlAttributes["name"] = "exclude">
			<cfset xField.XmlAttributes["field"] = aTables[tt].XmlAttributes.pkfield>
			<cfset xField.XmlAttributes["operator"] = "NOT IN">
			<cfset ArrayAppend(aTables[tt].XmlChildren,Duplicate(xField))>
		</cfif>
		
	</cfloop>
	
	
	<!--- Handle Fields with ftable attributes --->
	<cfset adjustXmlFTableFields(xDef)>
	
	<!--- Add names to fields with only types --->
	<cfset adjustXmlAddNamesToTypes(xDef)>
	
	<cfreturn xDef>
</cffunction>

<cffunction name="adjustXmlFTableFields" access="private" returntype="any" output="false" hint="">
	<cfargument name="xDef" type="any" required="true">
	
	<cfset var axFields = XmlSearch(xDef,"//field[string-length(@ftable)>0]")>
	<cfset var xField = 0>
	<cfset var xTable = 0>
	<cfset var ff = 0>
	<cfset var table = "">
	<cfset var ftable = "">
	<cfset var axFTables = 0>
	<cfset var xFTable = 0>
	<cfset var xLabelField = 0>
	<cfset var NumField = "">
	<cfset var xNumField = 0>
	<cfset var HasField = "">
	<cfset var xHasField = 0>
	<cfset var xListField = 0>
	<cfset var xListNamesField = 0>
	<cfset var isMany2Many = 0>
	
	<cfloop index="ff" from="1" to="#ArrayLen(axFields)#" step="1">
		<cfset xField = axFields[ff]>
		<cfset xTable = xField.XmlParent>
		<cfset table = xTable.XmlAttributes["name"]>
		<cfset ftable = xField.XmlAttributes["ftable"]>
		<cfset axFTables = XmlSearch(xDef,"//table[@name='#ftable#']")>
		<cfif ArrayLen(axFTables)>
			
			<cfset xFTable = axFTables[1]>
			
			<cfif NOT StructKeyExists(xField.XmlAttributes,"subcomp")>
				<cfif StructKeyExists(variables.sMetaData, ftable) AND StructKeyExists(variables.sMetaData[ftable],"methodPlural")>
					<cfset xField.XmlAttributes["subcomp"] = makeCompName(variables.sMetaData[ftable]["methodPlural"])>
				<cfelseif StructKeyExists(xFTable.XmlAttributes,"methodPlural")>
					<cfset xField.XmlAttributes["subcomp"] = makeCompName(xFTable.XmlAttributes["methodPlural"])>
				</cfif>
			</cfif>
			
			<cfif
					StructKeyExists(xField.XmlAttributes,"jointype")
				AND	(
							xField.XmlAttributes["jointype"] EQ "many"
						OR	xField.XmlAttributes["jointype"] EQ "list"
						OR	xField.XmlAttributes["jointype"] EQ "many2many"
					)
			>
				<cfset isMany2Many = ( xField.XmlAttributes["jointype"] EQ "many2many" OR ArrayLen(XmlSearch(xDef,"//table[@name='#ftable#']/field[@ftable='#table#'][@jointype='many' or @jointype='list' or @jointype='many2many']")) )>
				<cfif NOT StructKeyExists(xField.XmlAttributes,"type")>
					<cfset xField.XmlAttributes["type"] = "Relation">
				</cfif>
				<cfif NOT StructKeyExists(xField.XmlAttributes,"name")>
					<cfif StructKeyExists(xField.XmlAttributes,"fentity")>
						<cfset xField.XmlAttributes["name"] = Pluralize(makeCompName(xField.XmlAttributes["fentity"]))>
					<cfelseif StructKeyExists(variables.sMetaData,ftable)>
						<cfset xField.XmlAttributes["name"] = makeCompName(variables.sMetaData[ftable]["methodPlural"])>
					</cfif>
					<cfif table EQ ftable>
						<cfset xField.XmlAttributes.name = "Related#xField.XmlAttributes.name#">
					</cfif>
				</cfif>
				<cfif NOT StructKeyExists(xField.XmlAttributes,"Label")>
					<cfif StructKeyExists(variables.sMetaData, ftable) AND StructKeyExists(variables.sMetaData[ftable],"labelPlural")>
						<cfset xField.XmlAttributes["Label"] = variables.sMetaData[ftable]["labelPlural"]>
						<cfif table EQ ftable>
							<cfset xField.XmlAttributes.Label = "Related #xField.XmlAttributes.Label#">
						</cfif>
					</cfif>
				</cfif>
				<cfif NOT StructKeyExists(xField.XmlAttributes,"OldField")>
					<cfset xField.XmlAttributes["OldField"] = getPrimaryKeyFields(ftable,xDef)>
					<cfif ListLen(xField.XmlAttributes["OldField"]) NEQ 1>
						<!---<cfthrow message="You must provide a field name for joins with #ftable# as no single primary key field could be found." type="Manager">--->
						<cfset StructDelete(xField.XmlAttributes,"OldField")>
					</cfif>
				</cfif>
				<cfif NOT StructKeyExists(xField.XmlAttributes,"jointable")>
					<cfset xField.XmlAttributes["jointable"] = getJoinTableName(xDef,table,ftable)>
				</cfif>
				<cfset ArrayAppend(xField.XmlChildren,XmlElemNew(xDef,"relation"))>
				<cfset xField.XmlChildren[1].XmlAttributes["type"] = "list">
				<cfset xField.XmlChildren[1].XmlAttributes["table"] = ftable>
				<cfset xField.XmlChildren[1].XmlAttributes["field"] = getPrimaryKeyFields(ftable,xDef)>
				<cfset xField.XmlChildren[1].XmlAttributes["join-table"] = xField.XmlAttributes["jointable"]>
				<cfset xField.XmlChildren[1].XmlAttributes["local-table-join-field"] = getPrimaryKeyFields(table,xDef)>
				<cfset xField.XmlChildren[1].XmlAttributes["join-table-field-local"] = getPrimaryKeyFields(table,xDef)>
				<cfset xField.XmlChildren[1].XmlAttributes["join-table-field-remote"] = getPrimaryKeyFields(ftable,xDef)>
				<cfset xField.XmlChildren[1].XmlAttributes["remote-table-join-field"] = getPrimaryKeyFields(ftable,xDef)>
				<cfif table EQ ftable>
					<cfset xField.XmlChildren[1].XmlAttributes["join-table-field-remote"] = "Related#getPrimaryKeyFields(ftable,xDef)#">
					<cfif StructKeyExists(xField.XmlAttributes,"bidirectional") AND isBoolean(xField.XmlAttributes["bidirectional"])>
						<cfset xField.XmlChildren[1].XmlAttributes["bidirectional"] = xField.XmlAttributes["bidirectional"]>
					<cfelse>
						<cfset xField.XmlChildren[1].XmlAttributes["bidirectional"] = true>
					</cfif>
				</cfif>
				<cfif NOT StructKeyExists(xField.XmlAttributes,"listshowfield")>
					<cfif StructKeyExists(variables.sMetaData, ftable) AND StructKeyExists(variables.sMetaData[ftable],"methodSingular")>
						<cfset xField.XmlAttributes["listshowfield"] = makeCompName(variables.sMetaData[ftable]["methodSingular"] & "Names")>
						<cfif table EQ ftable>
							<cfset xField.XmlAttributes.listshowfield = "Related#xField.XmlAttributes.listshowfield#">
						</cfif>
					</cfif>
				</cfif>
				<cfif StructKeyExists(xField.XmlAttributes,"listshowfield")>
					<!--- Add label and has relation fields (if they don't exists) --->
					<cfif NOT ArrayLen( XmlSearch(xDef,"//table[@name='#table#']/field[@name='#xField.XmlAttributes.listshowfield#']") )>
						<cfset xLabelField = XmlElemNew(xDef,"field")>
						<cfset xLabelField.XmlAttributes["name"] = xField.XmlAttributes.listshowfield>
						<cfset xLabelField.XmlAttributes["label"] = xField.XmlAttributes.label>
						<cfset ArrayAppend(xLabelField.XmlChildren,XmlElemNew(xDef,"relation"))>
						<cfset xLabelField.XmlChildren[1].XmlAttributes["type"] = "list">
						<cfset xLabelField.XmlChildren[1].XmlAttributes["table"] = ftable>
						<cfset xLabelField.XmlChildren[1].XmlAttributes["field"] = variables.sMetaData[ftable]["labelField"]>
						<cfset xLabelField.XmlChildren[1].XmlAttributes["join-table"] = xField.XmlAttributes["jointable"]>
						<cfset xLabelField.XmlChildren[1].XmlAttributes["local-table-join-field"] = getPrimaryKeyFields(table,xDef)>
						<cfset xLabelField.XmlChildren[1].XmlAttributes["join-table-field-local"] = getPrimaryKeyFields(table,xDef)>
						<cfset xLabelField.XmlChildren[1].XmlAttributes["join-table-field-remote"] = getPrimaryKeyFields(ftable,xDef)>
						<cfset xLabelField.XmlChildren[1].XmlAttributes["remote-table-join-field"] = getPrimaryKeyFields(ftable,xDef)>
						<cfset ArrayAppend(xTable.XmlChildren,xLabelField)>
					</cfif>
				</cfif>
				<!--- Add Num and Has relation fields (if they don't exist) --->
				<cfif table EQ ftable>
					<cfset NumField = "NumRelated#xTable.XmlAttributes.methodPlural#">
					<cfset HasField = "hasRelated#xTable.XmlAttributes.methodPlural#">
				<cfelse>
					<cfset NumField = "Num#xTable.XmlAttributes.methodPlural#">
					<cfset HasField = "has#xTable.XmlAttributes.methodPlural#">
				</cfif>
				<cfif NOT ArrayLen(XmlSearch(xFTable,"/field[@name='#NumField#']"))>
					<cfset xNumField = XmlElemNew(xDef,"field")>
					<cfset xNumField.XmlAttributes["name"] = NumField>
					<cfset xNumField.XmlAttributes["label"] = xTable.XmlAttributes.labelPlural>
					<cfif table EQ ftable>
						<cfset xNumField.XmlAttributes.label = "Related #xNumField.XmlAttributes.label#">
					</cfif>
					<cfset xNumField.XmlAttributes["sebcolumn_type"] = "numeric">
					<cfset ArrayAppend(xNumField.XmlChildren,XmlElemNew(xDef,"relation"))>
					<cfset xNumField.XmlChildren[1].XmlAttributes["type"] = "count">
					<cfset xNumField.XmlChildren[1].XmlAttributes["table"] = xField.XmlAttributes["jointable"]>
					<cfset xNumField.XmlChildren[1].XmlAttributes["field"] = getPrimaryKeyFields(table,xDef)>
					<cfset xNumField.XmlChildren[1].XmlAttributes["join-field-local"] = getPrimaryKeyFields(ftable,xDef)>
					<cfset xNumField.XmlChildren[1].XmlAttributes["join-field-remote"] = getPrimaryKeyFields(ftable,xDef)>
					<cfif StructKeyExists(xField.XmlAttributes,"onRemoteDelete")>
						<cfset xNumField.XmlChildren[1].XmlAttributes["onDelete"] = xField.XmlAttributes["onRemoteDelete"]>
					</cfif>
					<cfif ListLen(xNumField.XmlChildren[1].XmlAttributes["join-field-local"]) EQ 1>
						<cfset ArrayAppend(xFTable.XmlChildren,xNumField)>
					</cfif>
				</cfif>
				<cfif NOT ArrayLen(XmlSearch(xFTable,"/field[@name='#HasField#']"))>
					<cfset xHasField = XmlElemNew(xDef,"field")>
					<cfset xHasField.XmlAttributes["name"] = HasField>
					<cfset xHasField.XmlAttributes["label"] = "Has #xTable.XmlAttributes.labelPlural#?">
					<cfif table EQ ftable>
						<cfset xHasField.XmlAttributes.label = "Has Child #xNumField.XmlAttributes.label#s?">
					</cfif>
					<cfset xHasField.XmlAttributes["sebcolumn_type"] = "yesno">
					<cfset ArrayAppend(xHasField.XmlChildren,XmlElemNew(xDef,"relation"))>
					<cfset xHasField.XmlChildren[1].XmlAttributes["type"] = "has">
					<cfset xHasField.XmlChildren[1].XmlAttributes["field"] = NumField>
					<cfset ArrayAppend(xFTable.XmlChildren,xHasField)>
				</cfif>
			<cfelse>
				<cfif NOT StructKeyExists(xField.XmlAttributes,"type")>
					<cfset xField.XmlAttributes["type"] = "fk:integer">
				</cfif>
				<cfif NOT StructKeyExists(xField.XmlAttributes,"name")>
					<cfset xField.XmlAttributes["name"] = getPrimaryKeyFields(ftable,xDef)>
					<cfif ListLen(xField.XmlAttributes["name"]) NEQ 1>
						<cfthrow message="You must provide a field name for joins with #ftable# as no single primary key field could be found." type="Manager">
					</cfif>
					<cfif table EQ ftable>
						<cfset xField.XmlAttributes.name = "Parent#xField.XmlAttributes.name#">
					</cfif>
				</cfif>
				<cfif NOT StructKeyExists(xField.XmlAttributes,"Label")>
					<cfif StructKeyExists(variables.sMetaData, ftable) AND StructKeyExists(variables.sMetaData[ftable],"labelSingular")>
						<cfset xField.XmlAttributes["Label"] = variables.sMetaData[ftable]["labelSingular"]>
						<cfif table EQ ftable>
							<cfset xField.XmlAttributes.Label = "Parent #xField.XmlAttributes.Label#">
						</cfif>
					</cfif>
				</cfif>
				<cfif NOT StructKeyExists(xField.XmlAttributes,"listshowfield")>
					<cfif StructKeyExists(variables.sMetaData, ftable) AND StructKeyExists(variables.sMetaData[ftable],"methodSingular")>
						<cfset xField.XmlAttributes["listshowfield"] = makeCompName(variables.sMetaData[ftable]["methodSingular"])>
						<cfif table EQ ftable>
							<cfset xField.XmlAttributes.listshowfield = "Parent#xField.XmlAttributes.listshowfield#">
						</cfif>
					</cfif>
				</cfif>
				<cfif table EQ ftable AND NOT StructKeyExists(xField.XmlAttributes,"urlvar")>
					<cfset xField.XmlAttributes["urlvar"] = LCase(makeCompName(variables.sMetaData[ftable]["methodSingular"]))>
				</cfif>
				
				<cfif StructKeyExists(xField.XmlAttributes,"listshowfield")>
					<!--- Add label and has relation fields (if they don't exists) --->
					<cfif NOT ArrayLen( XmlSearch(xDef,"//table[@name='#table#']/field[@name='#xField.XmlAttributes.listshowfield#']") )>
						<cfset xLabelField = XmlElemNew(xDef,"field")>
						<cfset xLabelField.XmlAttributes["name"] = xField.XmlAttributes.listshowfield>
						<cfset xLabelField.XmlAttributes["label"] = xField.XmlAttributes.label>
						<cfset ArrayAppend(xLabelField.XmlChildren,XmlElemNew(xDef,"relation"))>
						<cfset xLabelField.XmlChildren[1].XmlAttributes["type"] = "label">
						<cfset xLabelField.XmlChildren[1].XmlAttributes["table"] = ftable>
						<cfset xLabelField.XmlChildren[1].XmlAttributes["field"] = variables.sMetaData[ftable]["labelField"]>
						<cfset xLabelField.XmlChildren[1].XmlAttributes["join-field-local"] = xField.XmlAttributes["name"]>
						<cfset xLabelField.XmlChildren[1].XmlAttributes["join-field-remote"] = getPrimaryKeyFields(ftable,xDef)>
						<cfif StructKeyExists(xField.XmlAttributes,"onMissing")>
							<cfset xLabelField.XmlChildren[1].XmlAttributes["onMissing"] = xField.XmlAttributes["onMissing"]>
						</cfif>
						<cfif ListLen(xLabelField.XmlChildren[1].XmlAttributes["join-field-remote"]) EQ 1>
							<cfset ArrayAppend(xTable.XmlChildren,xLabelField)>
						</cfif>
					</cfif>
					<cfif NOT ArrayLen( XmlSearch(xDef,"//table[@name='#table#']/field[@name='Has#xField.XmlAttributes.listshowfield#']") )>
						<cfset xHasField = XmlElemNew(xDef,"field")>
						<cfset xHasField.XmlAttributes["name"] = "Has#xField.XmlAttributes.listshowfield#">
						<cfset xHasField.XmlAttributes["label"] = "Has #xField.XmlAttributes.label#?">
						<cfset ArrayAppend(xHasField.XmlChildren,XmlElemNew(xDef,"relation"))>
						<cfset xHasField.XmlChildren[1].XmlAttributes["type"] = "has">
						<cfset xHasField.XmlChildren[1].XmlAttributes["field"] = xField.XmlAttributes.listshowfield>
						<cfset ArrayAppend(xTable.XmlChildren,xHasField)>
					</cfif>
				</cfif>
				
				<!--- Add Num and Has relation field to ftable (if they don't exist) --->
				<cfif table EQ ftable>
					<cfset NumField = "NumChild#xTable.XmlAttributes.methodPlural#">
					<cfset HasField = "hasChild#xTable.XmlAttributes.methodPlural#">
				<cfelse>
					<cfset NumField = "Num#xTable.XmlAttributes.methodPlural#">
					<cfset HasField = "has#xTable.XmlAttributes.methodPlural#">
				</cfif>
				<cfif NOT ArrayLen(XmlSearch(xFTable,"/field[@name='#NumField#']"))>
					<cfset xNumField = XmlElemNew(xDef,"field")>
					<cfset xNumField.XmlAttributes["name"] = NumField>
					<cfset xNumField.XmlAttributes["label"] = xTable.XmlAttributes.labelPlural>
					<cfif table EQ ftable>
						<cfset xNumField.XmlAttributes.label = "Child #xNumField.XmlAttributes.label#">
					</cfif>
					<cfset xNumField.XmlAttributes["sebcolumn_type"] = "numeric">
					<cfset ArrayAppend(xNumField.XmlChildren,XmlElemNew(xDef,"relation"))>
					<cfset xNumField.XmlChildren[1].XmlAttributes["type"] = "count">
					<cfset xNumField.XmlChildren[1].XmlAttributes["table"] = table>
					<cfset xNumField.XmlChildren[1].XmlAttributes["field"] = getPrimaryKeyFields(ftable,xDef)>
					<cfset xNumField.XmlChildren[1].XmlAttributes["join-field-local"] = getPrimaryKeyFields(ftable,xDef)>
					<cfset xNumField.XmlChildren[1].XmlAttributes["join-field-remote"] = xField.XmlAttributes["name"]>
					<cfif StructKeyExists(xField.XmlAttributes,"onRemoteDelete")>
						<cfset xNumField.XmlChildren[1].XmlAttributes["onDelete"] = xField.XmlAttributes["onRemoteDelete"]>
					</cfif>
					<cfif ListLen(xNumField.XmlChildren[1].XmlAttributes["join-field-local"]) EQ 1>
						<cfset ArrayAppend(xFTable.XmlChildren,xNumField)>
					</cfif>
				</cfif>
				<cfif NOT ArrayLen(XmlSearch(xFTable,"/field[@name='#HasField#']"))>
					<cfset xHasField = XmlElemNew(xDef,"field")>
					<cfset xHasField.XmlAttributes["name"] = HasField>
					<cfset xHasField.XmlAttributes["label"] = "Has #xTable.XmlAttributes.labelPlural#?">
					<cfif table EQ ftable>
						<cfset xHasField.XmlAttributes.label = "Has Child #xNumField.XmlAttributes.label#s?">
					</cfif>
					<cfset xHasField.XmlAttributes["sebcolumn_type"] = "yesno">
					<cfset ArrayAppend(xHasField.XmlChildren,XmlElemNew(xDef,"relation"))>
					<cfset xHasField.XmlChildren[1].XmlAttributes["type"] = "has">
					<cfset xHasField.XmlChildren[1].XmlAttributes["field"] = NumField>
					<cfset ArrayAppend(xFTable.XmlChildren,xHasField)>
				</cfif>
			</cfif>
			
			<cfif StructKeyExists(variables.sMetaData, ftable)>
				<cfif NOT StructKeyExists(variables.sMetaData[ftable],"childtables")>
					<cfset variables.sMetaData[ftable]["childtables"] = "">
				</cfif>
				<cfif NOT ListFindNoCase(variables.sMetaData[ftable]["childtables"],table)>
					<cfset variables.sMetaData[ftable]["childtables"] = ListAppend(variables.sMetaData[ftable]["childtables"],table)>
				</cfif>
			</cfif>
			
			<!--- Add list fields if indicated --->
			<!---<cfif StructKeyExists(xField.XmlAttributes,"withListFields") AND xField.XmlAttributes["withListFields"] IS true>
				<cfset ListValueFieldName = xTable.XmlAttributes.methodPlural>
				<cfset ListNamesFieldName = "#xTable.XmlAttributes.SingularPlural#Names">
				<cfif table EQ ftable>
					<cfset ListValueFieldName = "Child#ListValueFieldName#">
					<cfset ListNamesFieldName = "Child#ListNamesFieldName#">
				</cfif>
				<cfif NOT ArrayLen(XmlSearch(xFTable,"//field[@name='#ListValueFieldName#']"))>
					<cfset xListField = XmlElemNew(xDef,"field")>
					<cfset xListField.XmlAttributes["name"] = ListValueFieldName>
					<cfset xListField.XmlAttributes["label"] = xListField.XmlAttributes.labelPlural>
					<cfif table EQ ftable>
						<cfset xListField.XmlAttributes.label = "Child #xListField.XmlAttributes.label#">
					</cfif>
					<cfset ArrayAppend(xListField.XmlChildren,XmlElemNew(xDef,"relation"))>
					<cfset xListField.XmlChildren[1].XmlAttributes["type"] = "list">
					<cfset xListField.XmlChildren[1].XmlAttributes["table"] = ftable>
					<cfset xListField.XmlChildren[1].XmlAttributes["field"] = getPrimaryKeyFields(ftable,xDef)>
					<cfset xListField.XmlChildren[1].XmlAttributes["join-field-local"] = getPrimaryKeyFields(ftable,xDef)>
					<cfset xListField.XmlChildren[1].XmlAttributes["join-field-remote"] = xField.XmlAttributes["name"]>
					<cfset ArrayAppend(xFTable.XmlChildren,xListField)>
				</cfif>
				<cfif NOT ArrayLen(XmlSearch(xFTable,"//field[@name='#ListNamesFieldName#']"))>
					<cfset xListNamesField = XmlElemNew(xDef,"field")>
					<cfset xListField.XmlAttributes["name"] = ListNamesFieldName>
					<cfset xListNamesField.XmlAttributes["label"] = xListField.XmlAttributes.labelPlural>
					<cfif table EQ ftable>
						<cfset xListNamesField.XmlAttributes.label = "Child #xListNamesField.XmlAttributes.label#">
					</cfif>
					<cfset ArrayAppend(xListNamesField.XmlChildren,XmlElemNew(xDef,"relation"))>
					<cfset xListNamesField.XmlChildren[1].XmlAttributes["type"] = "list">
					<cfset xListNamesField.XmlChildren[1].XmlAttributes["field"] = variables.sMetaData[ftable]["labelField"]>
					<cfset xListNamesField.XmlChildren[1].XmlAttributes["join-field-local"] = getPrimaryKeyFields(ftable,xDef)>
					<cfset xListNamesField.XmlChildren[1].XmlAttributes["join-field-remote"] = xField.XmlAttributes["name"]>
					<cfset ArrayAppend(xFTable.XmlChildren,xListNamesField)>
				</cfif>
			</cfif>--->
		</cfif>
	</cfloop>
	
	<cfreturn xDef>
</cffunction>

<cffunction name="getEntityTableName" access="private" returntype="string" output="false" hint="">
	<cfargument name="entity" type="string" required="true">
	<cfargument name="prefix" type="string" required="false">
	<cfargument name="xDef" type="any" required="false">
	<cfargument name="ErrorOnFail" type="boolean" default="true">
	
	<cfset var result = "">
	<cfset var axTables = 0>
	<cfset var xpath = "">
	
	<!--- TODO: find without prefix --->
	
	<cfif StructKeyExists(arguments,"xDef")>
		<cfset applyTableDefaults(arguments.xDef)>
		<cfset xpath = "//table">
		<cfif StructKeyExists(arguments,"prefix")>
			<cfset xpath = "#xpath#[@prefix='#arguments.prefix#']">
		</cfif>
		<cfset xpath = "#xpath#[@entity='#arguments.entity#'][string-length(@name)>0]">
		
		<cfset axTables = XmlSearch(xDef,xpath)>
		<cfif ArrayLen(axTables) EQ 1>
			<cfset result = axTables[1].XmlAttributes["name"]>
		</cfif>
	</cfif>
	
	<cfif NOT Len(result)>
		<cfloop collection="#variables.sMetaData#" item="table">
			<cfif
					StructKeyExists(variables.sMetaData[table],"entity")
				AND	variables.sMetaData[table]["entity"] EQ arguments.entity
				AND	(
							NOT StructKeyExists(arguments,"prefix")
						OR	(
									StructKeyExists(variables.sMetaData[table],"prefix")
								AND	variables.sMetaData[table]["prefix"] EQ arguments.prefix
							)
							
					)
			>
				<cfset result = ListAppend(result,table)>
				<cfbreak>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfif ListLen(result) GT 1>
		<cfset result = "">
	</cfif>
	
	<cfif arguments.ErrorOnFail AND NOT Len(result)>
		<cfif StructKeyExists(arguments,"prefix")>
			<cfthrow message="Unable to determine table for entity #arguments.entity# with prefix #arguments.prefix#." type="Manager">
		<cfelse>
			<cfthrow message="Unable to determine table for entity #arguments.entity#." type="Manager">
		</cfif>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getJoinTableName" access="private" returntype="string" output="false" hint="">
	<cfargument name="xDef" type="any" required="true">
	<cfargument name="Table1" type="string" required="true">
	<cfargument name="Table2" type="string" required="true">
	
	<cfset var result = "">
	<cfset var axTable1 = 0>
	<cfset var axTable2 = 0>
	<cfset var axFind = 0>
	<cfset var sTables = StructNew()>
	<cfset var table = "">
	<cfset var OrderedTableNames = "">
	
	<cfset applyTableDefaults(Arguments.xDef)>
	
	<cfset axTable1 = XmlSearch(Arguments.xDef,"//table[@name='#Arguments.Table1#']")>
	<cfset axTable2 = XmlSearch(Arguments.xDef,"//table[@name='#Arguments.Table2#']")>
	<cfset sTables[Arguments.Table1] = StructNew()>
	<cfset sTables[Arguments.Table2] = StructNew()>
	
	<cfif ArrayLen(axTable1) EQ 1 AND ArrayLen(axTable2) EQ 1>
		<cfset sTables[Arguments.Table1]["xTable"] = axTable1[1]>
		<cfset sTables[Arguments.Table2]["xTable"] = axTable2[1]>
	<cfelse>
		<cfthrow message="Unable to find both tables: #Arguments.Table1# and #Arguments.Table2# needed for a join relation." type="Manager">
	</cfif>
	
	<cfset sTables[Arguments.Table1]["name"] = Arguments.Table1>
	<cfset sTables[Arguments.Table2]["name"] = Arguments.Table2>
	<cfloop collection="#sTables#" item="table">
		<cfif StructKeyExists(sTables[table]["xTable"].XmlAttributes,"prefix")>
			<cfset sTables[table]["prefix"] = sTables[table]["xTable"].XmlAttributes["prefix"]>
		<cfelse>
			<cfset sTables[Arguments.Table2]["prefix"] = "">
		</cfif>
		<cfset sTables[table]["Root"] = sTables[table]["name"]>
		<cfif Len(sTables[table]["prefix"]) AND Left(sTables[table]["name"],Len(sTables[table]["prefix"])) EQ sTables[table]["prefix"]>
			<cfset sTables[table]["Root"] = ReplaceNoCase(sTables[table]["name"],sTables[table]["prefix"],"","ONE")>
		</cfif>
	</cfloop>
	
	<cfset OrderedTableNames = ListSort(StructKeyList(sTables),"text")>
	<cfif sTables[Arguments.Table1]["prefix"] EQ sTables[Arguments.Table2]["prefix"]>
		<cfloop index="table" list="#OrderedTableNames#">
			<cfset result = ListAppend(result,sTables[table]["Root"],"2")>
		</cfloop>
		<cfset result = sTables[Arguments.Table1]["prefix"] & result>
	<cfelse>
		<cfloop index="table" list="#OrderedTableNames#">
			<cfset result = ListAppend(result,sTables[table]["name"],"2")>
		</cfloop>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="Security_getPermissions" access="public" returntype="string" output="false">
	<cfargument name="tablename" type="string" required="true">
	
	<cfset var result = "">
	
	<cfif StructKeyExists(Variables.sSecurityPermissions,Arguments.tablename)>
		<cfset result = Variables.sSecurityPermissions[Arguments.tablename]>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="Security_AddPermissions" access="private" returntype="any" output="false">
	<cfargument name="Permissions" type="string" required="yes">
	
	<cfif Len(Arguments.Permissions)>
		<cfif StructKeyExists(Variables,"Security")>
			<cfinvoke component="#Variables.Security#" method="addPermissions" permissions="#Arguments.Permissions#" OnExists="update">
			</cfinvoke>
		<cfelse>
			<cfif NOT StructKeyExists(Variables,"Security_Permissions")>
				<cfset Variables.Security_Permissions = "">
			</cfif>
			<cfset Variables.Security_Permissions = ListAppend(Variables.Security_Permissions,Arguments.Permissions)> 
		</cfif>
	</cfif>
	
</cffunction>

<cffunction name="Security_Register" access="public" returntype="any" output="false">
	<cfargument name="Component" type="any" required="yes">
	
	<cfset Variables.Security = Arguments.Component>
	
	<cfif StructKeyExists(Variables,"Security_Permissions")>
		<cfset Security_AddPermissions(Variables.Security_Permissions)>
		<cfset StructDelete(Variables,"Security_Permissions")>
	</cfif>
	
</cffunction>


<cffunction name="adjustXmlAddNamesToTypes" access="private" returntype="any" output="false" hint="">
	<cfargument name="xDef" type="any" required="true">
	
	<cfset var axFields = XmlSearch(xDef,"//field[string-length(@type)>0][not(@name)]")>
	<cfset var xField = 0>
	<cfset var xTable = 0>
	<cfset var ff = 0>
	<cfset var table = "">
	<cfset var axTypes = 0>
	<cfset var xType = 0>
	
	<cfloop index="ff" from="1" to="#ArrayLen(axFields)#">
		<cfset xField = axFields[ff]>
		<cfset xTable = xField.XmlParent>
		<cfset table = xTable.XmlAttributes["name"]>
		<cfset axTypes = XmlSearch(variables.xTypes,"//type[@lcase_name='#LCase(xField.XmlAttributes.type)#']")>
		<cfif ArrayLen(axTypes) EQ 1>
			<cfset xType = axTypes[1]>
			<cfif StructKeyExists(xType.XmlAttributes,"defaultFieldName")>
				<cfset xField.XmlAttributes["name"] = xType.XmlAttributes["defaultFieldName"]>
			<cfelse>
				<cfif StructKeyExists(xTable.XmlAttributes,"entity")>
					<cfset xField.XmlAttributes["name"] = makeCompName(xTable.XmlAttributes["entity"]) & xField.XmlAttributes["type"]>
				<cfelseif StructKeyExists(xTable.XmlAttributes,"methodSingular")>
					<cfset xField.XmlAttributes["name"] = makeCompName(xTable.XmlAttributes["methodSingular"]) & xField.XmlAttributes["type"]>
				<cfelseif StructKeyExists(xTable.XmlAttributes,"labelSingular")>
					<cfset xField.XmlAttributes["name"] = makeCompName(xTable.XmlAttributes["labelSingular"]) & xField.XmlAttributes["type"]>
				<cfelse>
					<cfset xField.XmlAttributes["name"] = xField.XmlAttributes["type"]>
				</cfif>
			</cfif>
			<cfif StructKeyExists(xType.XmlAttributes,"defaultFieldLabel") AND NOT StructKeyExists(xField.XmlAttributes,"label")>
				<cfset xField.XmlAttributes["label"] = xType.XmlAttributes["defaultFieldLabel"]>
			</cfif>
		</cfif>
	</cfloop>
	 
	 <cfreturn arguments.xDef>
</cffunction>

<cffunction name="applyTableDefaults" access="private" returntype="any" output="false" hint="">
	<cfargument name="xDef" type="any" required="yes">
	
	<cfset var axTablesRoot = XmlSearch(xDef,"/tables")>
	<cfset var axTables = 0>
	<cfset var ii = 0>
	<cfset var key = 0>
	
	<cfif StructCount(axTablesRoot[1].XmlAttributes)>
		<cfset axTables = XmlSearch(xDef,"/tables/table")>
		<cfloop index="ii" from="1" to="#ArrayLen(axTables)#" step="1">
			<cfloop collection="#axTablesRoot[1].XmlAttributes#" item="key">
				<cfif NOT StructKeyExists(axTables[ii].XmlAttributes,key)>
					<cfset axTables[ii].XmlAttributes[key] = axTablesRoot[1].XmlAttributes[key]>
				</cfif>
			</cfloop>
		</cfloop>
	</cfif>
	
	<cfreturn arguments.xDef>
</cffunction>

<cffunction name="applySecurityPermissions" access="private" returntype="any" output="false" hint="">
	<cfargument name="xDef" type="any" required="yes">
	
	<cfset var axPermissions = XmlSearch(xDef,"//table[string-length(@permissions)>0]")>
	<cfset var ii = 0>
	<cfset var key = "">
	
	<cfloop index="ii" from="1" to="#ArrayLen(axPermissions)#" step="1">
		<cfset Security_AddPermissions(axPermissions[ii].XmlAttributes["permissions"])>
		<cfif StructKeyExists(axPermissions[ii].XmlAttributes,"name")>
			<cfif StructKeyExists(variables.sSecurityPermissions,axPermissions[ii].XmlAttributes["name"])>
				<cfloop list="#axPermissions[ii].XmlAttributes.permissions#" index="key">
					<cfif NOT ListFindNoCase(variables.sSecurityPermissions[axPermissions[ii].XmlAttributes["name"]],key)>
						<cfset variables.sSecurityPermissions[axPermissions[ii].XmlAttributes["name"]] = ListAppend(variables.sSecurityPermissions[axPermissions[ii].XmlAttributes["name"]],key)>
					</cfif>
				</cfloop>
			<cfelse>
				<cfset variables.sSecurityPermissions[axPermissions[ii].XmlAttributes["name"]] = axPermissions[ii].XmlAttributes.permissions>
			</cfif>
		<!---<cfelse>
			<cfdump var="#axPermissions[ii]#">
			<cfabort>--->
		</cfif>
	</cfloop>
	
	<cfreturn arguments.xDef>
</cffunction>

<cffunction name="applyEntities" access="private" returntype="any" output="false" hint="">
	<cfargument name="xDef" type="any" required="yes">
	
	<cfset var xEntities = XmlSearch(xDef,"//table[string-length(@entity)>0]")>
	<cfset var ee = 0>
	<cfset var prefix = "">
	<cfset var base = "">
	<cfset var root = "">
	<cfset var sEntityTables = StructNew()>
	<cfset var axFields = 0>
	<cfset var ff = 0>
	<cfset var axRelations = 0>
	<cfset var rr = 0>
	<cfset var prefixes = "">
	<cfset var permissions = "">
	<cfset var table = "">
	
	<cfloop index="ee" from="1" to="#ArrayLen(xEntities)#">
		<cfset root = makeCompName(xEntities[ee].XmlAttributes.entity)>
		<cfif StructKeyExists(xEntities[ee].XmlAttributes,"prefix")>
			<cfset prefix = xEntities[ee].XmlAttributes.prefix>
		<cfelse>
			<cfset prefix = "">
		</cfif>
		<cfif Len(prefix)>
			<cfset prefixes = ListAppend(prefixes,prefix)>
		</cfif>
		<cfif StructKeyExists(xEntities[ee].XmlAttributes,"base")>
			<cfset base = makeCompName(xEntities[ee].XmlAttributes.base)>
		<cfelse>
			<cfset base = makeCompName(pluralize(xEntities[ee].XmlAttributes.entity))>
		</cfif>
		<cfif NOT StructKeyExists(xEntities[ee].XmlAttributes,"name")>
			<cfset xEntities[ee].XmlAttributes["name"] = "#prefix##base#">
		</cfif>
		<cfif StructKeyExists(xEntities[ee].XmlAttributes,"universal") AND xEntities[ee].XmlAttributes.universal IS true>
			<cfset xEntities[ee].XmlAttributes["name"] = getUniversalTableName(entity=xEntities[ee].XmlAttributes.entity,tablename=xEntities[ee].XmlAttributes.name)>
		</cfif>
		<cfif StructKeyExists(variables.sMetaData,xEntities[ee].XmlAttributes["name"]) AND StructKeyExists(variables.sMetaData[xEntities[ee].XmlAttributes["name"]],"sAttributes")>
			<cfset StructAppend(xEntities[ee].XmlAttributes,variables.sMetaData[xEntities[ee].XmlAttributes["name"]]["sAttributes"],"no")>
		</cfif>
		<cfif NOT StructKeyExists(xEntities[ee].XmlAttributes,"labelSingular")>
			<cfset xEntities[ee].XmlAttributes["labelSingular"] = xEntities[ee].XmlAttributes.entity>
		</cfif>
		<cfif NOT StructKeyExists(xEntities[ee].XmlAttributes,"labelPlural")>
			<cfset xEntities[ee].XmlAttributes["labelPlural"] = pluralize(xEntities[ee].XmlAttributes.labelSingular)>
		</cfif>
		<cfif NOT StructKeyExists(xEntities[ee].XmlAttributes,"methodSingular")>
			<cfset xEntities[ee].XmlAttributes["methodSingular"] = makeCompName(xEntities[ee].XmlAttributes.entity)>
		</cfif>
		<cfif NOT StructKeyExists(xEntities[ee].XmlAttributes,"methodPlural")>
			<cfset xEntities[ee].XmlAttributes["methodPlural"] = makeCompName(pluralize(xEntities[ee].XmlAttributes.entity))>
		</cfif>
		<cfif NOT ( StructKeyExists(xEntities[ee].XmlAttributes,"pkfield") OR ArrayLen(XmlSearch(xEntities[ee],"//field[starts-with(@lcase_type,'pk:')]")) )>
			<cfset xEntities[ee].XmlAttributes["pkfield"] = "#root#ID">
		</cfif>
		<cfif NOT StructKeyExists(xEntities[ee].XmlAttributes,"labelField")>
			<cfset xEntities[ee].XmlAttributes["labelField"] = "#root#Name">
		</cfif>
		<cfif NOT StructKeyExists(xEntities[ee].XmlAttributes,"folder")>
			<cfset xEntities[ee].XmlAttributes["folder"] = "#variables.FileMgr.PathNameFromString(base)#">
			<cfif Len(prefix)>
				<cfset xEntities[ee].XmlAttributes["folder"] = ListPrepend(xEntities[ee].XmlAttributes["folder"],variables.FileMgr.PathNameFromString(prefix))>
			</cfif>
		</cfif>
		<cfset sEntityTables[xEntities[ee].XmlAttributes.entity] = xEntities[ee].XmlAttributes.name>
	</cfloop>
	
	<!--- Convert fentity fields to ftable fields --->
	<cfset axFields = XmlSearch(xDef,"//field[string-length(@fentity)>0][not(@ftable)]")>
	<cfloop index="ff" from="1" to="#ArrayLen(axFields)#">
		<cfif StructKeyExists(sEntityTables,axFields[ff].XmlAttributes["fentity"])>
			<cfset axFields[ff].XmlAttributes["ftable"] = sEntityTables[axFields[ff].XmlAttributes["fentity"]]>
		<cfelse>
			<!--- TODO: Find elsewhere or throw exception --->
		</cfif>
	</cfloop>
	
	<cfset axRelations = XmlSearch(xDef,"//relation[string-length(@entity)>0][not(@table)]")>
	<cfloop index="rr" from="1" to="#ArrayLen(axRelations)#">
		<cfif StructKeyExists(sEntityTables,axRelations[rr].XmlAttributes["entity"])>
			<cfset axRelations[rr].XmlAttributes["table"] = sEntityTables[axRelations[rr].XmlAttributes["entity"]]>
		<cfelse>
			<!--- TODO: Find elsewhere or throw exception --->
		</cfif>
	</cfloop>
	
	<cfset xEntities = XmlSearch(xDef,"//data[string-length(@entity)>0]")>
	<cfloop index="ee" from="1" to="#ArrayLen(xEntities)#">
		<cfinvoke method="getEntityTableName" returnvariable="table">
			<cfinvokeargument name="Entity" value="#xEntities[ee].XmlAttributes['entity']#">
			<cfinvokeargument name="xDef" value="#Arguments.xDef#">
			<cfif StructKeyExists(xEntities[ee].XmlAttributes,"prefix")>
				<cfinvokeargument name="prefix" value="#xEntities[ee].XmlAttributes['prefix']#">
			</cfif>
		</cfinvoke>
		<cfset xEntities[ee].XmlAttributes['table'] = table>
	</cfloop>
	
	<cfreturn arguments.xDef>
</cffunction>

<cffunction name="loadDataMgrXml" access="private" returntype="any" output="false" hint="">
	<cfargument name="xml" type="any" required="yes">
	
	<cfset var xDef = arguments.xml>
	<cfset var tables = 0>
	<cfset var table = "">
	<cfset var sTables = StructNew()>
	<cfset var xFields = 0>
	<cfset var ii = 0>
	<cfset var xField = 0>
	<cfset var fieldname = "">
	<cfset var sField = 0>
	<cfset var att = 0>
	
	<cfset tables = ArrayToList(GetValueArray(xDef,"//tables/table[string-length(@name)>0]/@name"))>
	
	<cfloop list="#tables#" index="table">
		<cfset sTables[table] = getFieldsStructInternal(transformer="DataMgr",tablename=table)>
	</cfloop>
	
	<cfset xFields = XmlSearch(xDef,"//tables/table[string-length(@name)>0]/field[string-length(@name)>0]")>
	
	<!--- Process fields to alter attributes for DataMgr needs --->
	<cfloop index="ii" from="1" to="#ArrayLen(xFields)#" step="1">
		<cfset xField = xFields[ii]>
		<cfset table = xField.XmlParent.XmlAttributes["name"]>
		<cfset fieldname = xField.XmlAttributes["name"]>
		<cfif StructKeyExists(sTables[table],fieldname)>
			<!--- Alter attributes for DataMgr --->
			<cfset sField = sTables[table][fieldname]>
			<cfset StructClear(xField.XmlAttributes)>
			<cfloop collection="#sField#" item="att">
				<cfif StructKeyExists(sField,att) AND isSimpleValue(sField[att])>
					<cfset xField.XmlAttributes[att] = sField[att]>
				</cfif>
			</cfloop>
			<cfset xField.XmlAttributes["ColumnName"] = sField["name"]>
			<cfset StructDelete(xField.XmlAttributes,"name")>
			<cfset StructDelete(xField.XmlAttributes,"type")>
		</cfif>
	</cfloop>
	
	<cfset variables.DataMgr.loadXml(xDef,true,true)>
	
</cffunction>

<cffunction name="loadXmlStruct" access="public" returntype="void" output="false" hint="">
	<cfargument name="xml" type="any" required="yes">
	
	<cfset var xDef = 0>
	<cfset var aTables = 0>
	<cfset var table = "">
	<cfset var aFields = 0>
	<cfset var tt = 0>
	<cfset var ff = 0>
	<cfset var ll = 0>
	<cfset var sField = "">
	<cfset var key = "">
	
	<cfif isSimpleValue(arguments.xml)>
		<cfset xDef = XmlParse(arguments.xml)>
	<cfelseif isXMLDoc(arguments.xml)>
		<cfset xDef = arguments.xml>
	<cfelse>
		<cfthrow message="XML argument of loadXmlStruct must be XML." type="Manager">
	</cfif>
	<cfset aTables = XmlSearch(xDef,"//table[string-length(@name)>0]")>
	
	<!--- Actually add the tables and fields --->
	<cfloop index="tt" from="1" to="#ArrayLen(aTables)#">
		<cfset table = aTables[tt].XmlAttributes["name"]>
		<cfset variables.sMetaData[table]["sFields"] = StructNew()>
		<cfset aFields = XmlSearch(xDef,"//table[@name='#table#']//field[string-length(@name)>0]")>
		<cfloop index="ff" from="1" to="#ArrayLen(aFields)#">
			<cfset sField = Duplicate(aFields[ff].XmlAttributes)>
			<cfset sField["tablename"] = table>
			<cfset sField["fieldname"] = aFields[ff].XmlAttributes.name>
			<!--- If a relation element is included, make a key for the element --->
			<cfif StructKeyExists(aFields[ff],"relation")>
				<cfset sField["relation"] = StructNew()>
				<cfset sField["relation"] = Duplicate(aFields[ff].relation.XmlAttributes)>
				<cfif StructKeyExists(aFields[ff].relation,"filter")>
					<cfset sField["relation"]["filters"] = ArrayNew(1)>
					<cfloop index="ll" from="1" to="#ArrayLen(aFields[ff].relation.filter)#" step="1">
						<cfset ArrayAppend(sField["relation"]["filters"],aFields[ff].relation.filter[ll].XmlAttributes)>
					</cfloop>
				</cfif>
			</cfif>
			
			<!--- Default folder for file types --->
			<cfif
					StructKeyExists(sField,"type")
				AND	ListFindNoCase(variables.FileTypes,sField.type)
				AND	NOT StructKeyExists(sField,"folder")
			>
				<cfset sField["folder"] = variables.FileMgr.PathNameFromString(sField["fieldname"])>
			</cfif>
			
			<cfset sField["isInTableCreation"] = true>
			<cfset setField(argumentCollection=sField)>
		</cfloop>
	</cfloop>
	
</cffunction>

<cffunction name="fixFileName" access="private" returntype="string" output="false">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="dir" type="string" required="yes">
	<cfargument name="maxlength" type="numeric" default="0">
	
	<cfset var dirdelim = variables.FileMgr.getDirDelim()>
	<cfset var result = ReReplaceNoCase(arguments.name,"[^a-zA-Z0-9_\-\.]","_","ALL")><!--- Remove special characters from file name --->
	<cfset var path = "">
	
	<cfset result = variables.FileMgr.LimitFileNameLength(arguments.maxlength,result)>
	
	<cfset path = "#dir##dirdelim##result#">
	
	<!--- If corrected file name doesn't match original, rename it --->
	<cfif arguments.name NEQ result AND FileExists("#arguments.dir##dirdelim##arguments.name#")>
		<cfset path = variables.FileMgr.createUniqueFileName(path,arguments.maxlength)>
		<cfset result = ListLast(path,dirdelim)>
		<cffile action="rename" source="#arguments.dir##dirdelim##arguments.name#" destination="#result#">
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="types" access="public" returntype="string" output="no">
	
	<cfset var result = "">
	
	<cfsavecontent variable="result"><cfoutput>
	<types>
		<type name="pk:integer" datatype="number">
			<transform name="sebField" type="numeric" PrimaryKey="true" />
			<transform name="sebColumn" type="numeric" PrimaryKey="true" />
			<transform name="DataMgr" CF_DataType="CF_SQL_INTEGER" PrimaryKey="true" Increment="true" />
		</type>
		<type name="pk:uuid" datatype="text">
			<transform name="sebField" type="text" PrimaryKey="true" />
			<transform name="sebColumn" type="text" PrimaryKey="true" />
			<transform name="DataMgr" CF_DataType="CF_SQL_VARCHAR" PrimaryKey="true" Special="UUID" />
		</type>
		<type name="fk:integer" datatype="number">
			<transform name="sebField" type="select" more="..." />
			<transform name="sebColumn" type="text" />
			<transform name="DataMgr" CF_DataType="CF_SQL_INTEGER" />
		</type>
		<type name="pk:text" datatype="text">
			<transform name="sebField" type="text" />
			<transform name="sebColumn" type="text" />
			<transform name="DataMgr" CF_DataType="CF_SQL_VARCHAR" PrimaryKey="true" />
		</type>
		<type name="fk:text" datatype="text">
			<transform name="sebField" type="select" more="..." />
			<transform name="sebColumn" type="select" more="..." />
			<transform name="DataMgr" CF_DataType="CF_SQL_VARCHAR" />
		</type>
		<type name="text" datatype="text">
			<transform name="sebField" type="text" />
			<transform name="sebColumn" type="text" />
			<transform name="DataMgr" CF_DataType="CF_SQL_VARCHAR" />
		</type>
		<type name="pk:idstamp" datatype="text">
			<transform name="sebField" type="pkfield" />
			<transform name="sebColumn" type="pkfield" />
			<transform name="DataMgr" CF_DataType="CF_SQL_IDSTAMP" PrimaryKey="true" />
		</type>
		<type name="fk:idstamp" datatype="text">
			<transform name="sebField" type="select" more="..." />
			<transform name="sebColumn" type="select" more="..." />
			<transform name="DataMgr" CF_DataType="CF_SQL_IDSTAMP" />
		</type>
		<type name="idstamp" datatype="text">
			<transform name="sebField" type="text" />
			<transform name="sebColumn" type="text" />
			<transform name="DataMgr" CF_DataType="CF_SQL_IDSTAMP" />
		</type>
		<type name="string" datatype="text">
			<transform name="sebField" type="text" />
			<transform name="sebColumn" type="text" />
			<transform name="DataMgr" CF_DataType="CF_SQL_VARCHAR" />
		</type>
		<type name="boolean" datatype="boolean">
			<transform name="sebField" type="yesno" />
			<transform name="sebColumn" type="yesno" />
			<transform name="DataMgr" CF_DataType="CF_SQL_BIT" />
		</type>
		<type name="integer" datatype="number">
			<transform name="sebField" type="integer" size="4" />
			<transform name="sebColumn" type="text" />
			<transform name="DataMgr" CF_DataType="CF_SQL_INTEGER" />
		</type>
		<type name="decimal" datatype="decimal">
			<transform name="sebField" type="decimal" size="4" />
			<transform name="sebColumn" type="numeric" />
			<transform name="DataMgr" CF_DataType="CF_SQL_DECIMAL" precision="18" scale="2" />
		</type>
		<type name="money" datatype="number">
			<transform name="sebField" type="money" size="6" />
			<transform name="sebColumn" type="money" />
			<transform name="DataMgr" CF_DataType="CF_SQL_DECIMAL" precision="18" scale="2" />
		</type>
		<type name="float" datatype="number">
			<transform name="sebField" type="text" size="6" />
			<transform name="sebColumn" type="text" />
			<transform name="DataMgr" CF_DataType="CF_SQL_FLOAT" />
		</type>
		<type name="CreationDate" datatype="date" defaultFieldName="DateCreated" defaultFieldLabel="Date Created">
			<transform name="DataMgr" CF_DataType="CF_SQL_DATE" Special="CreationDate" />
			<transform name="sebColumn" type="date" />
		</type>
		<type name="LastUpdatedDate" datatype="date" defaultFieldName="DateUpdated" defaultFieldLabel="Date Updated">
			<transform name="DataMgr" CF_DataType="CF_SQL_DATE" Special="LastUpdatedDate" />
			<transform name="sebColumn" type="date" />
		</type>
		<type name="date" datatype="date">
			<transform name="sebField" type="date2" />
			<transform name="sebColumn" type="date" />
			<transform name="DataMgr" CF_DataType="CF_SQL_DATE" />
		</type>
		<type name="time" datatype="time">
			<transform name="sebField" type="time" />
			<transform name="sebColumn" type="time" />
			<transform name="DataMgr" CF_DataType="CF_SQL_DATE" />
		</type>
		<type name="file" datatype="text" isFileType="true" Length="120" NameConflict="makeunique">
			<transform name="sebField" type="file" />
			<transform name="sebColumn" type="text" />
			<transform name="DataMgr" CF_DataType="CF_SQL_VARCHAR" />
		</type>
		<type name="image" datatype="text" quality="1.0" isFileType="true" Length="120" NameConflict="makeunique">
			<transform name="sebField" type="image" />
			<transform name="sebColumn" type="image" />
			<transform name="DataMgr" CF_DataType="CF_SQL_VARCHAR" />
		</type>
		<type name="thumb" datatype="text" quality="1.0" isFileType="true" Length="120" NameConflict="makeunique">
			<transform name="sebField" type="thumb" />
			<transform name="sebColumn" type="image" />
			<transform name="DataMgr" CF_DataType="CF_SQL_VARCHAR" />
		</type>
		<type name="memo" datatype="text">
			<transform name="sebField" type="textarea" />
			<transform name="sebColumn" type="text" />
			<transform name="DataMgr" CF_DataType="CF_SQL_LONGVARCHAR" />
		</type>
		<type name="html" datatype="text">
			<transform name="sebField" type="#variables.wysiwyg#" />
			<transform name="sebColumn" type="html" />
			<transform name="DataMgr" CF_DataType="CF_SQL_LONGVARCHAR" />
		</type>
		<type name="HTML" datatype="text">
			<transform name="sebField" type="#variables.wysiwyg#" />
			<transform name="sebColumn" type="html" />
			<transform name="DataMgr" CF_DataType="CF_SQL_LONGVARCHAR" />
		</type>
		<type name="email" datatype="text" Length="120">
			<transform name="sebField" type="email" />
			<transform name="sebColumn" type="text" />
			<transform name="DataMgr" CF_DataType="CF_SQL_VARCHAR" />
		</type>
		<type name="password" datatype="text" Length="120">
			<transform name="sebField" type="password" />
			<transform name="DataMgr" CF_DataType="CF_SQL_VARCHAR" />
		</type>
		<type name="Sorter" defaultFieldName="ordernum">
			<transform name="sebColumn" type="Sorter" />
			<transform name="DataMgr" CF_DataType="CF_SQL_INTEGER" Special="Sorter" />
		</type>
		<type name="DeletionDate" datatype="date" defaultFieldName="WhenDeleted">
			<transform name="DataMgr" CF_DataType="CF_SQL_DATE" Special="DeletionMark" />
			<transform name="sebColumn" type="delete" />
		</type>
		<type name="DeletionMark" datatype="boolean" defaultFieldName="isDeleted">
			<transform name="DataMgr" CF_DataType="CF_SQL_BIT" Special="DeletionMark" />
			<transform name="sebColumn" type="delete" />
		</type>
		<type name="URL" datatype="text" Length="250">
			<transform name="DataMgr" CF_DataType="CF_SQL_VARCHAR" />
			<transform name="sebColumn" type="text" />
			<transform name="sebField" type="url" />
		</type>
		<type name="UUID" datatype="text">
			<transform name="DataMgr" CF_DataType="CF_SQL_VARCHAR" Special="UUID" />
		</type>
		<type name="relation">
			<transform name="sebColumn" type="text" />
			<transform name="sebField" type="text" />
			<transform name="DataMgr" />
		</type>
	</types>
	</cfoutput></cfsavecontent>
	
	<cfreturn result>
</cffunction>

<cffunction name="XmlAsString" access="public" returntype="any" output="false" hint="">
	<cfargument name="XmlElem" type="any" required="yes">
	
	<cfset var result = ToString(arguments.XmlElem)>
	
	<!--- Remove XML encoding (so that this can be embedded in another document) --->
	<cfset result = ReReplaceNoCase(result,"<\?xml[^>]*>","","ALL")>
	
	<cfreturn result>
</cffunction>

<cffunction name="getFieldsStruct" access="public" returntype="struct" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="transformer" type="string" required="no">
	
	<cfif StructCount(arguments) EQ 1>
		<cfif NOT (
				StructKeyExists(variables,"cachedata")
			AND	StructKeyExists(variables.cachedata,arguments.tablename)
			AND	StructKeyExists(variables.cachedata[arguments.tablename],"FieldsStruct")
			AND	isStruct(variables.cachedata[arguments.tablename]["FieldsStruct"])
		)>
			<cfset variables.cachedata[arguments.tablename]["FieldsStruct"] = getFieldsStructInternal(argumentCollection=arguments)>
		</cfif>
		<cfreturn variables.cachedata[arguments.tablename]["FieldsStruct"]>
	<cfelse>
		<cfreturn getFieldsStructInternal(argumentCollection=arguments)>
	</cfif>
</cffunction>

<cffunction name="getVariables" access="public" returntype="any" output="false" hint="">
	<cfreturn variables>
</cffunction>

<cffunction name="getArgumentsList" access="private" returntype="string" output="false">
	<cfargument name="func" type="any">
	
	<cfset var result = "">
	<cfset var sMethod = getMetaData(arguments.func)>
	<cfset var aa = 0>
	
	<cfif ArrayLen(sMethod.Parameters)>
		<cfloop index="aa" from="1" to="#ArrayLen(sMethod.Parameters)#">
			<cfset result = ListAppend(result,sMethod.Parameters[aa].name)>
		</cfloop>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getFieldsStructInternal" access="private" returntype="struct" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="transformer" type="string" required="no">
	
	<cfset var sFields = StructNew()>
	<cfset var aFields = 0>
	<cfset var ii = 0>
	
	<cfset aFields = getFieldsArrayInternal(argumentCollection=arguments)>
	
	<cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
		<cfif StructKeyExists(aFields[ii],"name")>
			<cfset sFields[aFields[ii]["name"]] = aFields[ii]>
		</cfif>
	</cfloop>
	
	<cfreturn sFields>
</cffunction>

<cffunction name="manageTableFieldSorts" access="private" returntype="any" output="false" hint="">
	<cfargument name="tablename" type="string" required="yes">
	
</cffunction>

<cffunction name="StructFromArgs" access="public" returntype="struct" output="false" hint="">
	
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

<cffunction
	name="GetValueArray"
	access="public"
	returntype="array"
	output="false"
	hint="Returns an array of of either attribute values or node text values.">

	<!--- Define arguments. --->
	<cfargument
		name="XML"
		type="any"
		required="true"
		hint="The ColdFusion XML document we are searching."
		/>

	<cfargument
		name="XPath"
		type="string"
		required="true"
		hint="The XPAth that will return the XML nodes from which we will be getting the values for our array."
		/>

	<cfargument
		name="NumericOnly"
		type="boolean"
		required="false"
		default="false"
		hint="Flags whether only numeric values will be selected."
		/>

	<!--- Define the local scope. --->
	<cfset var LOCAL = StructNew() />

	<!---
		Get the matching XML nodes based on the
		given XPath.
	--->
	<cfset LOCAL.Nodes = XmlSearch(
		ARGUMENTS.XML,
		ARGUMENTS.XPath
		) />


	<!--- Set up an array to hold the returned values. --->
	<cfset LOCAL.Return = ArrayNew( 1 ) />

	<!--- Loop over the matched nodes. --->
	<cfloop
		index="LOCAL.NodeIndex"
		from="1"
		to="#ArrayLen( LOCAL.Nodes )#"
		step="1">

		<!--- Get a short hand to the current node. --->
		<cfset LOCAL.Node = LOCAL.Nodes[ LOCAL.NodeIndex ] />

		<!---
			Check to see what kind of value we are getting -
			different nodes will have different values. When
			getting the value, we must also check to see if
			only numeric values are being returned.
		--->
		<cfif (
			StructKeyExists( LOCAL.Node, "XmlText" ) AND
			(
				(NOT ARGUMENTS.NumericOnly) OR
				IsNumeric( LOCAL.Node.XmlText )
			))>

			<!--- Add the element node text. --->
			<cfset ArrayAppend(
				LOCAL.Return,
				LOCAL.Node.XmlText
				) />

		<cfelseif (
			StructKeyExists( LOCAL.Node, "XmlValue" ) AND
			(
				(NOT ARGUMENTS.NumericOnly) OR
				IsNumeric( LOCAL.Node.XmlValue )
			))>

			<!--- Add the attribute node value. --->
			<cfset ArrayAppend(
				LOCAL.Return,
				LOCAL.Node.XmlValue
				) />

		</cfif>

	</cfloop>


	<!--- Return value array. --->
	<cfreturn LOCAL.Return />
</cffunction>
<cffunction
	name="XmlAppend"
	access="public"
	returntype="any"
	output="false"
	hint="Copies the children of one node to the node of another document.">
 
	<!--- Define arguments. --->
	<cfargument
		name="NodeA"
		type="any"
		required="true"
		hint="The node whose children will be added to."
		/>
 
	<cfargument
		name="NodeB"
		type="any"
		required="true"
		hint="The node whose children will be copied to another document."
		/>
 
 
	<!--- Set up local scope. --->
	<cfset var LOCAL = StructNew() />
 
	<!---
		Get the child nodes of the originating XML node.
		This will return both tag nodes and text nodes.
		We only want the tag nodes.
	--->
	<cfset LOCAL.ChildNodes = ARGUMENTS.NodeB.GetChildNodes() />
 
 
	<!--- Loop over child nodes. --->
	<cfloop
		index="LOCAL.ChildIndex"
		from="1"
		to="#LOCAL.ChildNodes.GetLength()#"
		step="1">
 
 
		<!---
			Get a short hand to the current node. Remember
			that the child nodes NodeList starts with
			index zero. Therefore, we must subtract one
			from out child node index.
		--->
		<cfset LOCAL.ChildNode = LOCAL.ChildNodes.Item(
			JavaCast(
				"int",
				(LOCAL.ChildIndex - 1)
				)
			) />
 
		<!---
			Import this noded into the target XML doc. If we
			do not do this first, then COldFusion will throw
			an error about us using nodes that are owned by
			another document. Importing will return a reference
			to the newly created xml node. The TRUE argument
			defines this import as DEEP copy.
		--->
		<cfset LOCAL.ChildNode = ARGUMENTS.NodeA.GetOwnerDocument().ImportNode(
			LOCAL.ChildNode,
			JavaCast( "boolean", true )
			) />
 
		<!---
			Append the imported xml node to the child nodes
			of the target node.
		--->
		<cfset ARGUMENTS.NodeA.AppendChild(
				LOCAL.ChildNode
			) />
 
	</cfloop>
 
 
	<!--- Return the target node. --->
	<cfreturn ARGUMENTS.NodeA />
</cffunction>
<cfscript>
function makeCompName(str) {
	var result = "";
	var find = FindNoCase(" ",result);
	var word = "";
	var ii = 0;
	
	if ( find ) {
		/* Turn all special characters into spaces */
		str = ReReplaceNoCase(str,"[^a-z0-9]"," ","ALL");
		
		/* Remove duplicate spaces */
		while ( find GT 0 ) {
			str = ReplaceNoCase(str,"  "," ","ALL");
			find = FindNoCase("  ",str);
		}
		
		/* Proper case words and remove spaces */
		for ( ii=1; ii LTE ListLen(str," "); ii=ii+1 ) {
			word = ListGetAt(str,ii," ");
			word = UCase(Left(word,1)) & LCase(Mid(word,2,Len(word)-1));
			result = "#result##word#";
		}
	} else {
		result = ReReplaceNoCase(str,"[^a-z0-9]","","ALL");
	}
	
	return result;
}
/**
 * Tests passed value to see if it is a properly formatted U.S. zip code.
 * 
 * @param str 	 String to be checked. (Required)
 * @return Returns a boolean. 
 * @author Jeff Guillaume (jeff@kazoomis.com) 
 * @version 1, May 8, 2002 
 */
function IsZipUS(str) {
	return REFind('^[[:digit:]]{5}(( |-)?[[:digit:]]{4})?$', str); 
}
/**
 * Makes a row of a query into a structure.
 * 
 * @param query 	 The query to work with. 
 * @param row 	 Row number to check. Defaults to row 1. 
 * @return Returns a structure. 
 * @author Nathan Dintenfass (nathan@changemedia.com) 
 * @version 1, December 11, 2001 
 */
function QueryRowToStruct(query){
	var row = 1;//by default, do this to the first row of the query
	var ii = 1;//a var for looping
	var cols = listToArray(query.columnList);//the cols to loop over
	var stReturn = structnew();//the struct to return
	
	if(arrayLen(arguments) GT 1) row = arguments[2];//if there is a second argument, use that for the row number
	
	//loop over the cols and build the struct from the query row
	for(ii = 1; ii lte arraylen(cols); ii = ii + 1){
		stReturn[cols[ii]] = query[cols[ii]][row];
	}		
	
	return stReturn;//return the struct
}
</cfscript>

</cfcomponent>