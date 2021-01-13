<cfparam name="attributes.name" default="">

<!--- *** GET LAYOUT *** --->
<cfif StructKeyExists(attributes,"layout") AND NOT isObject(attributes.layout)>
	<cfset StructDelete(attributes,"layout")>
</cfif>
<!--- Find layout component --->
<cfif NOT StructKeyExists(attributes,"layout")>
	<cfif StructKeyExists(Caller,"layout") AND isObject(Caller.layout)>
		<cfset attributes.layout = Caller.layout>
	<cfelseif StructKeyExists(Caller,"This") AND isObject(Caller.This)>
		<cfset attributes.layout = Caller.This>
	<cfelseif StructKeyExists(request,"layout") AND isObject(Caller.layout)>
		<cfset attributes.layout = request.layout>
	<cfelse>
		<cfif FileExists(ExpandPath("/layouts/Default.cfc"))>
			<!--- If the Default layout is where it is expected, go ahead and create the layout object --->
			<cfinvoke returnvariable="attributes.layout" component="layouts.Default" method="init">
				<cfinvokeargument name="CGI" value="#CGI#">
				<cfif StructKeyExists(Application,"Framework") AND StructKeyExists(Application.Framework,"Loader") AND isObject(Application.Framework.Loader)>
					<cfinvokeargument name="Factory" value="#Application.Framework.Loader#">
				</cfif>
			</cfinvoke>
			<cfset Caller.layout = attributes.layout>
			<cfset request.layout = attributes.layout>
		<cfelse>
			<!---<cfparam name="attributes.layout">--->
			<!--- Throwing an error because it isn't sufficient for the variable to exists. It also must be an object --->
			<cfthrow message="layout attribute is not defined" type="layout">
		</cfif>
	</cfif>
</cfif>

<cfscript>
//Operations to run at end of tag, if available. Otherwise run at the start.
function isGoTime() {
	return ( ThisTag.ExecutionMode EQ "End" OR NOT ThisTag.HasEndTag  );
}
//Get the data attributes to pass to cf_mustache
Variables.sDataAttributes = {};
if ( isGoTime() ) {
	Variables.sMustacheAtts = {};
	//Numbering to make unique names for calls to cf_mustache
	if ( NOT StructKeyExists(request,"cf_show_tags") ) {
		request["cf_show_tags"] = {};
	}
	if ( NOT StructKeyExists(request["cf_show_tags"],Attributes.name) ) {
		request["cf_show_tags"][Attributes.name] = 0;
	}
	request["cf_show_tags"][Attributes.name]++;
	if ( StructKeyExists(Attributes,"data") ) {
		Variables.sMustacheAtts = StructCopy(Attributes);
	} else {
		Variables.sDataAttributes["data"] = StructCopy(Attributes);
	}

	//Name is reserved for cf_show
	Variables.sMustacheAtts["name"] = Attributes["name"] & "_" & request["cf_show_tags"][Attributes.name];
}
</cfscript>

<cfif isGoTime()><cf_mustache attributeCollection="#Variables.sMustacheAtts#"><cfinvoke component="#attributes.layout#" method="show#attributes.name#"></cf_mustache></cfif>
