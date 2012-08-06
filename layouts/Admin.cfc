<cfcomponent displayname="Admin Layout" extends="layout">
<cffunction name="head" access="public" output="yes"><cfargument name="title" type="string" required="yes"><cfset variables.title = arguments.title>
<cfcontent reset="yes"><!doctype html>
<html class="no-js" lang="en">
<head>
	<title>#arguments.title#</title>
	<script type="text/javascript" src="/all.js"></script>
</cffunction>
<cffunction name="body" access="public" output="yes">
</head>
<body class="admin">
		<cf_sebMenu LogoutLink="/admin/logout.cfm" data="#variables.AdminMenu#" width="100%">
			<cf_sebMenuItem label="Admin Home" link="/admin/" />
		</cf_sebMenu>
</cffunction>
<cffunction name="end" access="public" output="yes">
		<cf_sebMenu action="end">
</body>
</html>
</cffunction>

</cfcomponent>
