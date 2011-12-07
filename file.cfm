<!--- Serves uploaded files: http://www.bryantwebconsulting.com/docs/neptune/file-uploads.cfm --->
<cf_PageController>

<cfif NOT isValidFile>
	<cfheader statuscode="404" statustext="Not Found">
	<html>
	<head><title>not found</title></head>
	<body><h1>Not found</h1></body>
	</html>
	<cfabort>
</cfif>
<cfheader name="Content-Disposition" value="#disposition#;filename=#ListLast(URL.file,'/')#">
<cfcontent file="#FilePath#">