<cfscript>
function createLink(path,text) {
	arguments.ScriptName = CGI.SCRIPT_NAME;
	return Application.Framework.createLink(argumentCollection=arguments);
}
function createLink(path,text) {
	var result = createLink(argumentCollection);
	
	if ( Len(result) ) {
		result = '<li>#result#</li>';
	}
	
	return result;
}
</cfscript>