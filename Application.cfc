<cfcomponent extends="_framework.SuperApplication" output="no">

<!--- Any application name that is unique to this site will work --->
<cfscript>
This.Name = Hash(getDirectoryFromPath(getCurrentTemplatePath()));
request.SessionTimeout = 90;
this.sessionTimeout = CreateTimeSpan( 0, 0, request.sessionTimeout, 0 );
</cfscript>

</cfcomponent>