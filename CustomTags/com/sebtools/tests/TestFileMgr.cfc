<cfcomponent displayname="FileMgr" extends="mxunit.framework.TestCase" output="no">
<!---
FileMgr should be able to:
-Upload a file to a folder.
-Copy all files from one folder to another.
-Make a copy of a file.
-Delete a file
-Determine the full file path of a folder.
-Get the length of a file.
-Get the full file path of a file in a folder.
-Get the full URL to a file in a folder.
-Make a folder
-Read the text of a file in a folder.
-Write a file in a folder.
--->
<cffunction name="beforeTests" access="public" returntype="void" output="no">
	
	<cfset var CurrentFolder = getDirectoryFromPath(getCurrentTemplatePath())>
	<cfset var dirdelim = Right(CurrentFolder,1)>
	
	<cfset Variables.UploadFormURL = "http://localhost/TestFileMgr.cfm">

	<cfset Variables.UploadPath = CurrentFolder & "files#dirdelim#">
	<cfset Variables.UploadURL = "http://local.example.com/files/">
	
	<cfset Variables.FileMgr = CreateObject("component","com.sebtools.FileMgr").init(UploadPath=UploadPath,UploadURL=Variables.UploadURL)>
	<cfset Variables.DirDelim = Variables.FileMgr.getDirDelim()>

	<cfset Variables.ExampleFileLength = 70>

	<cfset Variables.FileMgrType = "">

</cffunction>

<cffunction name="shouldCopyFile" access="public" returntype="void" output="no"
	hint="FileMgr should be able to make a copy of a file."
>

	<!--- Action: Copy example.txt using makeFileCopy(). --->
	<cfset var fileToCopy = 'example.txt' />
	<cfset var copiedFile = ''>
	<cfset var cleanupFileToCopy = false>

	<cfif NOT FileExists(Variables.FileMgr.getFilePath(fileToCopy))>
		<cfset Variables.FileMgr.writeFile(FileName=fileToCopy,Contents="Hello World.")>
		<cfset cleanupFileToCopy = true>
	</cfif>

	<cfset copiedFile = Variables.FileMgr.makeFileCopy(FileName="#fileToCopy#")>

	<!--- Assert: New copy of example.txt (with new name) was just created in same folder. --->
	<cfset assertTrue((fileToCopy is not copiedFile),'The file was not copied correctly.')>

	<!--- Clean up: Delete the newly created file. --->
	<cfif copiedFile NEQ fileToCopy>
		<cfset Variables.FileMgr.deleteFile(FileName="#copiedFile#")>
	</cfif>
	<cfif cleanupFileToCopy>
		<cfset Variables.FileMgr.deleteFile(FileName="#fileToCopy#")>
	</cfif>
	
</cffunction>

<cffunction name="shouldCopyFolder" access="public" returntype="void" output="no"
	hint="FileMgr should be able to copy all files from one folder to another."
>

	<cfset var qFrom = 0>
	<cfset var qTo = 0>
	<cfset var FromList = "">
	<cfset var ToList = "">
	<cfset var ii = 0>

	<!--- Action: Copy all files from the "from" folder into the "to" folder using copyFiles(). --->
	<cfset Variables.FileMgr.copyFiles(from="from",to="to")>

	<!--- Assert: All files in the "from" folder also exist in the "to" folder. --->
	<cfset qFrom = Variables.FileMgr.getMyDirectoryList('#Variables.UploadPath#/to/')>
	<cfset qTo = Variables.FileMgr.getMyDirectoryList('#Variables.UploadPath#/to/')>

	<cfset FromList = ValueList(qFrom.name)>
	<cfset ToList = ValueList(qTo.name)>

	<cfloop list="#FromList#" index="ii">
		<cfif NOT ListContainsNoCase(ToList,ii)>
			<cfset fail('The directory was not successfully copied (#ii# was not found in the folder).')>
		</cfif>
	</cfloop>

	<!--- Clean up: Delete the newly copied files from the "to" folder. --->
	<cfloop list="#FromList#" index="ii">
		<cfset Variables.FileMgr.deleteFile(FileName="#ii#",Folder="to")>
	</cfloop>
	
</cffunction>

<cffunction name="shouldDeleteFile" access="public" returntype="void" output="no"
	hint="FileMgr should be able to delete a file."
>

	<cfset var fileToDelete = 'example 2.txt'>

	<cfif NOT FileExists(Variables.FileMgr.getFilePath(fileToDelete,"from"))>
		<cfset Variables.FileMgr.writeFile(FileName=fileToDelete,Contents="Hello World.",Folder="from")>
	<cfelse>
		<cfset fileToDelete = Variables.FileMgr.makeFileCopy(FileName="#fileToDelete#",Folder="from")>
		<cfset assertTrue(FileExists('#Variables.UploadPath#/from/#fileToDelete#'),'File did not copy successfully.')>
	</cfif>

	<!--- Action: Delete the "example 2.txt" file from the "from" folder using deleteFile(). --->
	<cfset Variables.FileMgr.deleteFile(FileName="#fileToDelete#",Folder="from")>

	<!--- Assert: The "example 2.txt" copy no longer exists. --->
	<cfset assertFalse(FileExists('#Variables.UploadPath#/from/#fileToDelete#'),'File did not delete successfully.')>

	
</cffunction>

<cffunction name="shouldGetFileLength" access="public" returntype="void" output="no"
	hint="FileMgr should be able to get the length of a file."
>

	<cfset var fileToMeasure = 'example.txt'>
	<cfset var testContent = 'Hello World.'>
	<cfset var expectedFileLength = Variables.ExampleFileLength>
	<cfset var testFileLength = 0>
	<cfset var cleanupFileToMeasure = false>

	<cfif NOT FileExists(Variables.FileMgr.getFilePath(fileToMeasure))>
		<cfset Variables.FileMgr.writeFile(FileName=fileToMeasure,Contents=testContent)>
		<cfset cleanupFileToMeasure = true>
		<cfset expectedFileLength = Len(Trim(testContent))>
	</cfif>

	<!--- Action: Get the length of the "example.txt" file using getFileLen(). --->
	<cfset testFileLength = Variables.FileMgr.getFileLen(FileName="example.txt")>

	<!--- Assert: The length is correct. --->
	<cfset assertEquals(expectedFileLength,testFileLength,'The returned file length is incorrect.')>

	<!--- Clean up: Delete any created files --->
	<cfif cleanupFileToMeasure>
		<cfset Variables.FileMgr.deleteFile(FileName="#fileToMeasure#")>
	</cfif>
	
</cffunction>

<cffunction name="shouldGetFilePath" access="public" returntype="void" output="no"
	hint="FileMgr should be able to get the full file path of a file in a folder."
>

	<!--- Action: Get the path of the "example.txt" using getFilePath(). --->
	<cfset var testFilePath = Variables.FileMgr.getFilePath(FileName="example.txt")>

	<!--- Assert: The file path matches the location of that file. --->
	<cfset assertEquals('#Variables.UploadPath#example.txt',testFilePath,'File path returned is incorrect.')>
	
</cffunction>

<cffunction name="shouldGetFileURL" access="public" returntype="void" output="no"
	hint="FileMgr should be able to get the full URL to a file in a folder."
>

	<!--- Action: Get the path of the "example.txt" in the "from" folder using getFileURL(). --->
	<cfset var testURL = Variables.FileMgr.getFileURL(FileName='from/example.txt')>

	<!--- Assert: The file URL is "#Variables.UploadURL#from/example.txt". --->
	<cfset assertEquals('#Variables.UploadURL#from/example.txt',testURL,'File url returned is incorrect.')>

</cffunction>


<cffunction name="shouldGetFolderPath" access="public" returntype="void" output="no"
	hint="FileMgr should be able to get the full file path of a folder."
>
	<!--- Action: Get the path of the "from" folder using getDirectory(). --->
	<cfset var testDirectory = Variables.UploadPath & "from#Variables.DirDelim#">

	<!--- Assert: The path matches the location of that folder. --->
	<cfset assertEquals(testDirectory,Variables.FileMgr.getDirectory('from'),'Directory paths do NOT match.')>
	
</cffunction>

<cffunction name="shouldMakeFolder" access="public" returntype="void" output="no"
	hint="FileMgr should be able to make a folder."
>
	
	<cfset var qDir = 0>

	<!--- Action: Make a new "test" folder. --->
	<cfset Variables.FileMgr.makeFolder('testfolder')>

	<!--- Assert: The "test" folder exists where it should. --->
	<cfset AssertTrue(DirectoryExists('#Variables.UploadPath#testfolder#Variables.DirDelim#'),'Directory does not exist at expected location: #Variables.UploadPath#testfolder#Variables.DirDelim#')>

	<!--- Assert: The "test" folder is readable and writable. --->
	<cfdirectory name="qDir" directory="#Variables.UploadPath#" action = "list" filter="testfolder" listInfo="all" type="dir">
	<cfif Len(qDir.mode)>
		<cfset fail("Permissions on created folder were restricted.")>
	</cfif>

	<!--- Clean up: Remove the "test" folder. --->
	<cfif DirectoryExists('#Variables.UploadPath#testfolder')>
		<cfset DirectoryDelete('#Variables.UploadPath#testfolder') />
	</cfif>
	
</cffunction>

<cffunction name="shouldReadFile" access="public" returntype="void" output="no"
	hint="FileMgr should be able to read the text of a file in a folder."
>
	
	<cfset var folder = 'from'>
	<cfset var fileToRead = 'example.txt'>
	<cfset var testFileContent = ''>
	<cfset var testContent = 'Hello World.'>
	<cfset var testLength = Variables.ExampleFileLength>
	<cfset var cleanupFileToRead = false>

	<cfif NOT FileExists(Variables.FileMgr.getFilePath(fileToRead,folder))>
		<cfset Variables.FileMgr.writeFile(FileName=fileToRead,Contents=testContent,Folder=folder)>
		<cfset cleanupFileToRead = true>
		<cfset testLength = Len(Trim(testContent))>
	</cfif>
	<!--- Action: Read the "example.txt" file in the "from" folder using readFile(). --->
	<cfset testFileContent = Variables.FileMgr.readFile(FileName="example.txt",Folder=folder)>

	<!--- Assert: That the result matches the contents of the file. --->
	<cfset assertEquals(testLength,Len(Trim(testFileContent)),'File was not read correctly.')>

	<!--- Cleanup: Delete any created files --->
	<cfif cleanupFileToRead>
		<cfset Variables.FileMgr.deleteFile("#fileToRead#",folder)>
	</cfif>
	
</cffunction>

<cffunction name="shouldUploadFile" access="public" returntype="void" output="no"
	hint="FileMgr should be able to upload a file to a folder."
>
	
	<cfset var HTTP_Result = "">
	<cfset var folder = "to">
	<cfset var UploadedPath = Variables.FileMgr.getFilePath(FileName='example.txt',Folder=folder)>

	<!--- Action upload a new file to the "to" folder using uploadFile() (how to imitate an upload will be a challenge here) --->
	<cfhttp url="#Variables.UploadFormURL#" method="post" result="HTTP_Result">
		<cfhttpparam type="file" name="UploadedFile" file="#Variables.FileMgr.getFilePath(FileName='example.txt')#" mimetype="text/plain">
		<cfhttpparam type="Formfield" name="FileMgrType" value="#Variables.FileMgrType#">
	</cfhttp>

	<cfif Left(Trim(HTTP_Result.FileContent),Len("Uploaded")) NEQ "Uploaded">
		<cfoutput>#HTTP_Result.FileContent#</cfoutput><cfabort />
	</cfif>

	<!--- Assert: The upload file exists. --->
	<cfset assertTrue(FileExists(UploadedPath),'File was not uploaded. Note that you need #Variables.UploadFormURL# present for this to work.')>

	<!--- Assert: The uploaded file is readable. --->
	<cfset assertEquals(Trim(Variables.FileMgr.readFile("example.txt")),Trim(Variables.FileMgr.readFile("example.txt",folder)),"Failed to create the file as readable and with the correct contents.")>

	<!--- Clean up: Remove the newly uploaded file. --->
	<cfset FileDelete(UploadedPath)>
	
</cffunction>

<cffunction name="shouldWriteFile" access="public" returntype="void" output="no"
	hint="FileMgr should be able to write a file to a folder."
>
	
	<!--- Write a new file to the "to" folder using writeFile(). --->
	<cfset Variables.FileMgr.writeFile(FileName="test.txt",Contents="Hello World.",Folder="to")>

	<!--- Assert: The new file exists and the file name of the new file is correct. --->
	<cfset assertTrue(FileExists('#Variables.UploadPath#/to/test.txt'))>

	<!--- Assert: The contents of the new file is correct. --->
	<cfset assertEquals(Len('Hello World.'),Len(Variables.FileMgr.readFile(FileName="test.txt",Folder="to")),'File content is incorrect.')>

	<!--- Clean up: Remove the the new file. --->
	<cfset Variables.FileMgr.deleteFile(FileName="test.txt",Folder="to")>
	
</cffunction>

<cffunction name="uploadFileTest" access="public" returntype="void" output="no">
	<cfset Variables.FileMgr.uploadFile(
		FieldName="UploadedFile",
		Folder="to",
		NameConflict="overwrite"
	)>
</cffunction>

<cffunction name="stub" access="public" returntype="void" output="no">
	<cfset fail("No test written yet.")>
</cffunction>

</cfcomponent>