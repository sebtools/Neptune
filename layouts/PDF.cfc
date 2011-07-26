<cfcomponent displayname="MS Word" extends="layout">
<!--- This file is a quick example of an alternate layout component for WML phone --->
<cffunction name="head" access="public" output="yes"><cfargument name="title" type="string" required="yes">
<cfcontent reset="Yes">
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<title>#xmlFormat(arguments.title)#</title>
	<base href="#variables.me.DomainName#/" /><!--- Make sure images show up correctly --->
</cffunction>
<cffunction name="body" access="public" output="yes">
</head>
<body>
</cffunction>
<cffunction name="end" access="public" output="yes"><cfset var output = "">
</body>
</html><!--- ** Unfortunately, you can't use cfflush with PDF layout ** --->
<cfset output = getPageContext().getOut().getString()><!--- Thanks to kola.oyedeji --->
<cfset output = ReplaceNoCase(output, 'class="right"',  'align="right"' , 'ALL')>
<cfset output = ReplaceNoCase(output, 'class="left"',  'align="left"' , 'ALL')>
<cfheader name="Content-Disposition" value="attachment;filename=#ReplaceNoCase(variables.me.FileName, ".cfm", ".pdf")#">
<cfcontent type="application/pdf" reset="Yes">
<cfdocument format="PDF" pagetype="letter">
#output#
</cfdocument>
</cffunction>
<cffunction name="switchLayout" access="public" returntype="layout" output="no" hint="I prevent the layout to be switched once PDF is chosen as the layout.">
	<cfargument name="layout" type="string" required="yes">
	<cfreturn this>
</cffunction>
</cfcomponent>
