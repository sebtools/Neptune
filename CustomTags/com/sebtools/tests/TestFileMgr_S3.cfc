<cfcomponent displayname="FileMgr: S3" extends="TestFileMgr" output="no">

<cffunction name="beforeTests" access="public" returntype="void" output="no">
	
	<cfset var CurrentFolder = getDirectoryFromPath(getCurrentTemplatePath())>
	<cfset var dirdelim = Right(CurrentFolder,1)>

	<cfset Variables.UploadFormURL = "http://localhost/TestFileMgr.cfm">
	
	<cfif FileExists( getDirectoryFromPath(getCurrentTemplatePath()) & "AmazonCredentials.cfc")>
		<cfset Variables.Credentials = CreateObject("component","AmazonCredentials").init()>
	<cfelse>
		<cfthrow message="To test FileMgr:S3, you need a AmazonCredentials.cfc that extends com.sebtools.Beany and has the following variables: AccessKey,SecretKey,CanonicalUserID,DefaultBucket,UploadURL.">	
	</cfif>

	<cfset Variables.UploadPath = "">
	<cfset Variables.UploadURL = Variables.Credentials.get("UploadURL")>

	<cfset Variables.FileMgr = CreateObject("component","com.sebtools.FileMgr_S3").init(
		UploadPath=Variables.UploadPath,
		UploadURL=Variables.UploadURL,
		Bucket=Variables.Credentials.get("DefaultBucket"),
		Credentials=Variables.Credentials
	)>
	
	<cfset Variables.UploadPath = Variables.FileMgr.getUploadPath()>
	<cfset Variables.DirDelim = Variables.FileMgr.getDirDelim()>

	<cfset Variables.ExampleFileLength = 68>

	<cfset Variables.FileMgrType = "S3">

</cffunction>

<cffunction name="shouldCopyFile" access="public" returntype="void" output="no"
	hint="FileMgr should be able to make a copy of a file."
>

	<cfset Super.shouldCopyFile()>
	
</cffunction>

<cffunction name="shouldCopyFolder" access="public" returntype="void" output="no"
	hint="FileMgr should be able to copy all files from one folder to another."
>
	
	<cfset Super.shouldCopyFolder()>
	
</cffunction>

<cffunction name="shouldDeleteFile" access="public" returntype="void" output="no"
	hint="FileMgr should be able to delete a file."
>
	
	<cfset Super.shouldDeleteFile()>
	
</cffunction>

<cffunction name="shouldGetFileLength" access="public" returntype="void" output="no"
	hint="FileMgr should be able to get the length of a file."
>

	<cfset Super.shouldGetFileLength()>
	
</cffunction>

<cffunction name="shouldGetFilePath" access="public" returntype="void" output="no"
	hint="FileMgr should be able to get the full file path of a file in a folder."
>
	
	<cfset Super.shouldGetFilePath()>
	
</cffunction>

<cffunction name="shouldGetFileURL" access="public" returntype="void" output="no"
	hint="FileMgr should be able to get the full URL to a file in a folder."
>

	<cfset Super.shouldGetFileURL()>

</cffunction>


<cffunction name="shouldGetFolderPath" access="public" returntype="void" output="no"
	hint="FileMgr should be able to get the full file path of a folder."
>
	
	<cfset Super.shouldGetFolderPath()>
	
</cffunction>

<cffunction name="shouldMakeFolder" access="public" returntype="void" output="no"
	hint="FileMgr should be able to make a folder."
>
	
	<cfset var qDir = 0>

	<!--- Action: Make a new "test" folder. --->
	<cfset Variables.FileMgr.makeFolder('testfolder')>
	<cfset Variables.FileMgr.writeFile(FileName="example.txt",Contents="This is just a test.",Folder='testfolder')>

	<!--- Assert: The "test" folder exists where it should. --->
	<cfset AssertTrue(FileExists('#Variables.UploadPath#testfolder#Variables.DirDelim#example.txt'),'Directory does not exist at expected location: #Variables.UploadPath#testfolder#Variables.DirDelim#')>

	<!--- Assert: The "test" folder is readable and writable. --->
	<cfdirectory name="qDir" directory="#Variables.UploadPath#" action = "list" filter="testfolder" listInfo="all" type="dir">
	<cfif Len(qDir.mode)>
		<cfset fail("Permissions on created folder were restricted.")>
	</cfif>

	<cfif FileExists('#Variables.UploadPath#testfolder#Variables.DirDelim#example.txt')>
		<cfset FileDelete('#Variables.UploadPath#testfolder#Variables.DirDelim#example.txt')>
	</cfif>

	<!--- Clean up: Remove the "test" folder. --->
	<cfif DirectoryExists('#Variables.UploadPath#testfolder')>
		<cfset DirectoryDelete('#Variables.UploadPath#testfolder')>
	</cfif>
	
</cffunction>

<cffunction name="shouldReadFile" access="public" returntype="void" output="no"
	hint="FileMgr should be able to read the text of a file in a folder."
>
	
	<cfset Super.shouldReadFile()>
	
</cffunction>

<cffunction name="shouldUploadFile" access="public" returntype="void" output="no"
	hint="FileMgr should be able to upload a file to a folder."
>
	
	<cfset Super.shouldUploadFile()>
	
</cffunction>

<cffunction name="shouldWriteFile" access="public" returntype="void" output="no"
	hint="FileMgr should be able to write a file to a folder."
>
	
	<cfset Super.shouldWriteFile()>
	
</cffunction>

</cfcomponent>