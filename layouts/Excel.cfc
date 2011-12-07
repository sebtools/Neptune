<cfcomponent displayname="MS Excel" extends="layout">
<cffunction name="head" access="public" output="yes"><cfargument name="title" type="string" required="yes">
<cfheader name="Content-Disposition" value="attachment;filename=#ReplaceNoCase(variables.FileName, ".cfm", ".xls")#">
<cfcontent type="application/msexcel" reset="Yes">
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<title>#xmlFormat(arguments.title)#</title>
	<base href="#variables.me.DomainName#/" /><!--- Make sure images show up correctly --->
</cffunction>
<cffunction name="body" access="public" output="yes">
</head>
<body>
<!--- <p>#DateFormat(now(),"mm/d/yyyy")#</p> --->
</cffunction>
<cffunction name="end" access="public" output="yes">
</body>
</html>
</cffunction>
<cffunction name="switchLayout" access="public" returntype="layout" output="no" hint="I prevent the layout to be switched once Excel is chosen as the layout.">
	<cfargument name="layout" type="string" required="yes">
	<cfreturn this>
</cffunction>
</cfcomponent>