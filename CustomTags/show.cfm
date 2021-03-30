<cfset Variables.TagAttributes = "name,layout,args">
<cfparam name="attributes.name" default="">

<!--- *** GET LAYOUT *** --->
<cfif StructKeyExists(attributes,"layout") AND NOT isObject(attributes.layout)>
	<cfset StructDelete(attributes,"layout")>
</cfif>
<!--- Find layout component --->
<cfif NOT StructKeyExists(attributes,"layout")>
	<cfscript>
	Me = Variables;
	while ( StructKeyExists(Me,"Caller") AND NOT StructKeyExists(attributes,"layout")  ) {
		Me = Me["Caller"];
		if ( StructKeyExists(Me,"layout") AND isObject(Me["layout"]) ) {
			Attributes.layout = Me["layout"];
		} else if ( StructKeyExists(Me,"Attributes") AND StructKeyExists(Me["Attributes"],"layout") AND isObject(Me["Attributes"]["layout"]) ) {
			Attributes.layout = Me["Attributes"]["layout"];
		} else if ( StructKeyExists(Me,"This") AND StructKeyExists(Me["This"],"layout") AND isObject(Me["This"]["layout"]) ) {
			Attributes.layout = Me["This"]["layout"];
		} else if ( StructKeyExists(Me,"This") AND isObject(Me["This"]) ) {
			Attributes.layout = Me["This"];
		}
	}
	</cfscript>
</cfif>
<cfif NOT StructKeyExists(attributes,"layout")>
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
	Variables.sMustacheAtts = StructCopy(Attributes);

	//Name is reserved for cf_show
	Variables.sMustacheAtts["name"] = Attributes["name"] & "_" & request["cf_show_tags"][Attributes.name];
}
if ( isGoTime() ) {
	Variables.sArguments = {};
	if ( StructKeyExists(Attributes,"args") AND isStruct(Attributes.args) ) {
		Variables.sArguments = StructCopy(Attributes.args);
	}
	for ( attr in Attributes ) {
		if ( ListLen(attr,"_") GT 1 AND ListFirst(attr,"_") EQ "arg" ) {
			Variables.sArguments[ListRest(attr,'_')] = Attributes[attr];
		} else if ( NOT ListFindNoCase(Variables.TagAttributes,attr) ) {
			Variables.sArguments[attr] = Attributes[attr];
		}
	}
	Variables.sMustacheAtts["Component"] = Attributes.layout;
	Variables.sMustacheAtts["Method"] = "get_#attributes.name#";
	//Variables.sMustacheAtts["args"] = Variables.sArguments;
}
</cfscript>
<!---
<cfif isGoTime() AND NOT StructKeyExists(Variables.sMustacheAtts,"data")>
	<cfif StructKeyExists(Attributes.layout,"get_#attributes.name#")>
		<cfinvoke returnvariable="Variables.sMustacheAtts.data" component="#Attributes.layout#" method="get_#attributes.name#">
			<cfinvokeargument name="ArgumentCollection" value="#Variables.sArguments#">
		</cfinvoke>
	</cfif>
</cfif>
--->

<cfif isGoTime()><cf_mustache attributeCollection="#Variables.sMustacheAtts#"><cfinvoke returnvariable="result" component="#attributes.layout#" method="show_#attributes.name#" argumentCollection="#Variables.sArguments#"><cfif StructKeyExists(Variables,"result")><cfoutput>#Variables.result#</cfoutput></cfif></cf_mustache></cfif>
