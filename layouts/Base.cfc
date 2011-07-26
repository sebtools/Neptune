<cfcomponent displayname="Base Layout" extends="layout">
<cffunction name="head" access="public" output="yes">
<cfargument name="title" type="string" required="yes"><cfset variables.me.title = arguments.title>
<cfcontent reset="Yes"><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
	<title>#arguments.title#</title>
</cffunction>
<cffunction name="body" access="public" output="yes">
</head>
<body>
</cffunction>
<cffunction name="end" access="public" output="yes">
</body>
</html>
</cffunction>
</cfcomponent>