<cfcomponent displayname="MS Word Filter" output="false" hint="I strip out the junk MS Word puts into HTML.">

<cffunction name="init" access="public" returntype="any" output="no" hint="I instantiate and return this component.">
	<cfreturn This>
</cffunction>

<cffunction name="filter" access="public" returntype="struct" output="no" hint="I run the filter on the given structure and return it.">
	<cfargument name="data" type="struct" required="yes">
	<cfargument name="maxpoints" type="numeric" default="0">
	
	<cfset var field = "">

	<cfloop collection="#arguments.data#" item="field">
		<!--- This means we'll test for MS Word text twice, but that will save an extra variable assignment. --->
		<cfif isMSWordText(Arguments.data[field])>
			<cfset Arguments.data[field] = cleanWord(Arguments.data[field])>
		</cfif>
	</cfloop>
	
	<cfreturn Arguments.data>
</cffunction>

<cfscript>
function isMSWordText(string) {
	//If it isn't a string, this isn't MS Word text.
	if ( NOT isSimpleValue(Arguments.string) ) {
		return false;
	}
	//If the string isn't at least 200 characters, it isn't from MS Word.
	if ( Len(Trim(Arguments.string)) LT 200 ) {
		return false;
	}
	return ( FindNoCase('MsoNormal',string) GT 0 );
}
function cleanWord(string) {
	var result = string;//Just in case we want access to the original string later.
	
	if ( isMSWordText(string) ) {
		result = cleanWordStyleBlock(result);
		result = cleanStyleAtts(result);
		result = cleanSpans(result);
		result = cleanEmptyLines(result);
	}

	return result;
}
function cleanWordStyleBlock(string) {
	var result = string;//Just in case we want access to the original string later.
	var styleOpen = FindNoCase('<style type="text/css"><!--',result);
	var styleClose = FindNoCase('</style>',result,styleOpen+1) + Len('</style>');
	var styleBlock = '';
	//If we find an MS Word style block, ditch it.
	if ( styleOpen AND styleClose ) {
		styleClose = styleClose-5;//Not sure why this is needed. Need to figure that out.
		styleBlock = Mid(string,styleOpen,styleClose);
		result = ReplaceNoCase(result,styleBlock,'');
	}
	return result;
}
function cleanStyleAtts(string) {
	var result = string;//Just in case we want access to the original string later.
	result = REReplaceNoCase(result,' style=".*?"','','ALL');
	return result;
}
function cleanSpans(string) {
	var result = string;//Just in case we want access to the original string later.
	result = REReplaceNoCase(result,'</?span>','','ALL');
	return result;
}
function cleanEmptyLines(string) {
	var result = string;//Just in case we want access to the original string later.
	result = ReplaceNoCase(result,'&nbsp;','','ALL');//The non-breaking spaces Word adds aren't needed.
	result = REReplaceNoCase(result,'<br ?/?>\s*</p>','</p>','ALL');//No need for carriage return at end of paragraph.
	result = ReplaceNoCase(result,'<p></p>','','ALL');//Ditch now-empty paragraphs
	return result;
}
</cfscript>
</cfcomponent>