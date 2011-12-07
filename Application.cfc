<cfcomponent extends="_framework.SuperApplication" output="no">

<!--- Any application name that is unique to this site will work --->
<cfset This.Name = Hash(getDirectoryFromPath(getCurrentTemplatePath()))>

</cfcomponent>