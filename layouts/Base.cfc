<cfcomponent displayname="Base Layout" extends="layout">
<cffunction name="head" access="public" output="yes">
<cfargument name="title" type="string" required="yes"><cfset variables.me.title = arguments.title>
<cfcontent reset="Yes"><!doctype html>
<html class="no-js" lang="en">
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