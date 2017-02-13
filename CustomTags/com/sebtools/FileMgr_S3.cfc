<cfcomponent displayname="File Manager" extends="FileMgr" output="no">

<cffunction name="init" access="public" returntype="FileMgr" output="no" hint="I instantiate and return this object.">
	<cfargument name="UploadPath" type="string" default="" hint="The file path for uploads.">
	<cfargument name="UploadURL" type="string" default="http://s3.amazonaws.com/" hint="The URL path for uploads.">
	<cfargument name="Bucket" type="string" required="true" hint="AWS S3 Bucket name.">
	<cfargument name="Credentials" type="any" required="true" hint="AWS Credentials.">

	<cfset setUpVariables(ArgumentCollection=Arguments)>
	<cfset Variables.StorageMechanism = "S3">

	<!--- Make sure needed S3 credentials exist. --->
	<cfif NOT ( Variables.Credentials.has("AccessKey") AND Variables.Credentials.has("SecretKey") AND Variables.Credentials.has("CanonicalUserID")  )>
		<cfthrow message="S3 FileMgr requires AWS credentials (AccessKey,SecretKey,CanonicalUserID)." type="FileMgr">
	</cfif>

	<cfif NOT Len(Trim(Variables.UploadPath))>
		<cfset Variables.UploadPath = 's3://' & Variables.Credentials.get("AccessKey") & ':' & Variables.Credentials.get("SecretKey") & '@' & Variables.Bucket & '/'>
	</cfif>

	<cfif Variables.UploadURL CONTAINS "s3.amazonaws.com" AND NOT Variables.UploadURL CONTAINS Arguments.Bucket>
		<cfset Variables.UploadURL = UploadURL & Arguments.Bucket & "/">
	</cfif>

	<cfreturn This>
</cffunction>

<cffunction name="convertFolder" access="public" returntype="string" output="no">
	<cfargument name="Folder" type="string" required="yes">
	<cfargument name="delimiter" type="string" default="/">

	<cfreturn LCase(Super.convertFolder(ArgumentCollection=Arguments))>
</cffunction>

<cffunction name="getDirDelim" acess="public" returntype="string" output="no">

	<cfif NOT StructKeyExists(variables,"dirdelim")>
		<cfset variables.dirdelim = "/">
	</cfif>

	<cfreturn variables.dirdelim>
</cffunction>

<cffunction name="makedir" access="public" returntype="any" output="no" hint="I make a directory (if it doesn't exist already).">
	<cfargument name="Directory" type="string" required="yes">

	<cfset Super.makedir(ArgumentCollection=Arguments)>

</cffunction>

<cffunction name="makedir_private" access="private" returntype="any" output="no" hint="I make a directory.">
	<cfargument name="Directory" type="string" required="yes">

	<cfdirectory action="CREATE" directory="#Arguments.Directory#">

</cffunction>

<cffunction name="uploadFile" access="public" returntype="any" output="no">
	<cfargument name="FieldName" type="string" required="yes">
	<cfargument name="Folder" type="string" required="no">
	<cfargument name="NameConflict" type="string" default="Error">
	<cfargument name="TempDirectory" default="#variables.TempDir#">

	<cfset var destination = getDirectory(argumentCollection=arguments)>
	<cfset var CFFILE = StructNew()>
	<cfset var sOrigFile = 0>
	<cfset var tempPath = "">
	<cfset var serverPath = "">
	<cfset var skip = false>
	<cfset var dirdelim = '/' />
	<cfset var result = "">

	<!--- Make sure the destination exists. --->
	<cfif StructKeyExists(arguments,"Folder")>
		<cfset makeFolder(arguments.Folder)>
	</cfif>

	<!--- Set default extensions --->
	<cfif NOT StructKeyExists(arguments,"extensions")>
		<cfset arguments.extensions = variables.DefaultExtensions>
	</cfif>

	<!--- Upload to temp directory. --->
	<cfif StructKeyExists(Form,Arguments.FieldName)>
		<cfif StructKeyExists(arguments,"accept")>
			<cffile action="UPLOAD" filefield="#Arguments.FieldName#" destination="#destination##cleanFileName(getClientFileName(Arguments.FieldName))#" nameconflict="#Arguments.NameConflict#" result="CFFILE" accept="#arguments.accept#">
		<cfelse>
			<cffile action="UPLOAD" filefield="#Arguments.FieldName#" destination="#destination##cleanFileName(getClientFileName(Arguments.FieldName))#" nameconflict="#Arguments.NameConflict#" result="CFFILE">
		</cfif>
		<cfset serverPath = ListAppend(CFFILE.ServerDirectory, CFFILE.ServerFile, getDirDelim())>
	<cfelse>
		<cffile destination="#Arguments.TempDirectory#" source="#Arguments.FieldName#" action="copy" result="CFFILE">
		<cfset serverPath = ListAppend(CFFILE.ServerDirectory, CFFILE.ServerFile, getDirDelim())>
	</cfif>

	<!--- Check file extension --->
	<cfif
			Len(arguments.extensions)
		AND	NOT ListFindNoCase(arguments.extensions,ListLast(serverPath,"."))
	>
		<!--- Bad file extension.  Delete file. --->
		<cffile action="DELETE" file="#serverPath#">
		<cfreturn StructNew()>
	</cfif>

	<cfset StoreSetMetadata("#serverPath#",convertS3MetaFromCFFILE(CFFILE))>

	<!--- set permissions on the newly created file on S3 --->
	<cfset StoreSetACL("#serverPath#",getStandardS3Permissions())>

	<cfset CFFILE.ServerDirectory = getDirectoryFromPath(serverPath)>
	<cfset CFFILE.ServerFile = getFileFromPath(serverPath)>
	<cfset CFFILE.ServerFileName = ReReplaceNoCase(CFFILE.ServerFile,"\.#CFFILE.SERVERFILEEXT#$","")>

	<cfif StructKeyExists(arguments,"return") AND isSimpleValue(arguments.return)>
		<cfif arguments.return EQ "name">
			<cfset arguments.return = "ServerFile">
		</cfif>
		<cfif StructKeyExists(CFFILE,arguments.return)>
			<cfset result = CFFILE[arguments.return]>
			<cfif isSimpleValue(result) AND isSimpleValue(variables.dirdelim)>
				<cfset result = ListLast(result,variables.dirdelim)>
			</cfif>
		</cfif>
	<cfelse>
		<cfset result = CFFILE>
	</cfif>

	<cfreturn result>
</cffunction>

<cffunction name="writeFile" access="public" returntype="string" output="no" hint="I save a file.">
	<cfargument name="FileName" type="string" required="yes">
	<cfargument name="Contents" type="string" required="yes">
	<cfargument name="Folder" type="string" required="no">

	<cfset var destination = Super.writeFile(ArgumentCollection=Arguments)>

	<!--- set permissions on the newly created file on S3 --->
	<cfset StoreSetACL("#destination#",getStandardS3Permissions())>

	<cfreturn destination>
</cffunction>

<cffunction name="writeBinaryFile" access="public" returntype="string" output="no" hint="I save a file.">
	<cfargument name="FileName" type="string" required="yes">
	<cfargument name="Contents" type="binary" required="yes">
	<cfargument name="Folder" type="string" required="no">

	<cfset var destination = Super.writeBinaryFile(ArgumentCollection=Arguments)>

	<!--- set permissions on the newly created file on S3 --->
	<cfset StoreSetACL("#destination#",getStandardS3Permissions())>

	<cfreturn destination>
</cffunction>

<cffunction name="getStandardS3Permissions" access="private" returntype="array" output="no">
	<cfset var perms = [{group="all", permission="read"},{id="#Variables.Credentials.get('CanonicalUserID')#", permission="full_control"}]>
	<cfreturn perms>
</cffunction>

<cffunction name="convertS3MetaFromCFFILE" access="private" returntype="struct" output="no">
	<cfargument name="CFFILE" type="struct" required="yes">

	<cfset var sResult = {
		last_modified=GetHTTPTimeString(Arguments.CFFILE.TIMELASTMODIFIED),
		date=GetHTTPTimeString(Arguments.CFFILE.TIMECREATED),
		content_length=JavaCast("String",Arguments.CFFILE.FILESIZE),
		content_type=Arguments.CFFILE.CONTENTTYPE
	}>

	<!--- 	OTHER KEYS:
			owner=
			etag=
			content_encoding=
			content_disposition=
			content_language=
			content_md5=
			md5_hash=
	 --->

	<cfreturn sResult>
</cffunction>

<cffunction name="getClientFileName" returntype="string" output="false" hint="">
    <cfargument name="fieldName" required="true" type="string" hint="Name of the Form field" />

    <cfset var tmpPartsArray = Form.getPartsArray() />

    <cfif IsDefined("tmpPartsArray")>
        <cfloop array="#tmpPartsArray#" index="local.tmpPart">
            <cfif local.tmpPart.isFile() AND local.tmpPart.getName() EQ arguments.fieldName> <!---   --->
                <cfreturn local.tmpPart.getFileName() />
            </cfif>
        </cfloop>
    </cfif>

    <cfreturn "" />
</cffunction>
</cfcomponent>
