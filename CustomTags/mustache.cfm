<cfsilent>
<!---
cf_mustache

The cf_mustache tag allows you to create content that is dynamic to both ColdFusion and JavaScript.

It must have a "name" attribute to indicate which mustache template you are using.

<cf_mustache name="sample_name">
<p>Hello {{FName}} {{LName}}</p>
</cf_mustache>

Attributes:
-name (required): The name of the template
-id: The id of the element (defaults to use name)
-action
---set: To define a template without showing it.
---head: To output the template in the html head (can also define it if it hasn't been defined already)
---show: To show the template (can define and create the template if not done already)
-uri: The URI from which to retrieve new data for the template
-data: A structure of data for the template

Elements ("target") can be updated by use of the "data-mustacheaction" attribute on another element (the "trigger" element).
Possible values for ""data-mustacheaction":
-args: Uses the data of the trigger (defined below) to directly update the target
-data: Uses the data of the trigger (defined blow) to pass to the uri to get data to update the target
-form-args: Uses the form of which the trigger is a part to update the target from the uri
-form-data: Uses the form of which the trigger is a part to update the target directly

Data is retrieved from a target either by getting it from the "data-data" attribute (in a query string format) or by using the querystring of the href attribute.

The target is determined from the "data-element" attribute of the trigger (which should match the "id" of the target).
Or it will update the element it is in if that is a template element.

JavaScript methods available to cf_mustache:
-cf_mustache.renderArgs(id,arg): Updates the indicated element with the data retrieved from the URI using the args provided
-cf_mustache.renderData(id,data): Updates the indicated element with the data provided
-cf_mustache.renderFormArgs(id,form): Updates the indicated element with the data retrieved from the URI using the indicated form.
-cf_mustache.renderFormData(id,form): Updates the indicated element with the data from the indicated form

Use https://github.com/rip747/Mustache.cfc for ColdFusion implementation.
Use https://github.com/janl/mustache.js for JavaScript implementation.

--->

<cffunction name="addToHead" access="private" returntype="any" output="false" hint="I compress the given string.">
	<cfargument name="array" type="array" required="true" hint="I am the output array.">
	<cfargument name="str" type="string" required="true" hint="I am the string to add to the head.">

	<cftry>
			<cfhtmlhead text="#Arguments.str#">
		<cfcatch>
			<cfset ArrayAppend(Arguments.array,Arguments.str)>
		</cfcatch>
	</cftry>

</cffunction>

<cffunction name="compress" access="private" returntype="any" output="false" hint="I compress the given string.">
	<cfargument name="str" type="string" required="true" hint="I am the string to be compressed.">
	<cfargument name="type" type="string" required="true" hint="I am the type of compression (js or css).">

	<cfscript>
	var result = Arguments.str;
	var compr = 0;

	if ( Attributes.compress EQ true ) {
		switch(Arguments.type) {
			case "css":
			break;
			case "htm":
			break;
			case "js":
				//result	= ReReplaceNoCase(result,"\*((.|\n)(?!/))+\*","","ALL");
				result	= ReReplaceNoCase(result,"//.*?(\r\n)","","ALL");
			break;
		}
		result = reReplaceNoCase(result, "\s{2,}", " ","ALL");
	}
	</cfscript>

	<cfreturn result>
</cffunction>

<cffunction name="getArguments" access="private" returntype="struct">
	<cfscript>
	var sArgs = StructCopy(Attributes.args);
	var att = "";
	var name = "";

	for ( att in Attributes ) {
		if ( ListLen(att,"_") GT 1 AND ListFirst(att,"_") EQ "arg" ) {
			name = ListRest(att,"_");
			sArgs[name] = Attributes[att];
		}
	}

	//Get arguments from URL, if requested (lowest priority except defaults)
	if ( Attributes["urlargs"] IS true ) {
		for ( att in URL ) {
			//This is basically getting the rest of a underscore-delimited list, except that the id itself may have an underscore in it.
			if (
				ListLen(att,"_") GT 1
				AND
				Len(att) GT ( Len(Attributes.id) + 1)
				AND
				Left(att,Len(Attributes.id)+1) EQ "#Attributes.id#_"
			) {
				name = ReplaceNoCase(att,"#Attributes.id#_","");
				if ( NOT StructKeyExists(sArgs,name) ) {
					sArgs[name] = URL[att];
				}
			}
		}
	}

	//Argument defaults are lowest priority
	StructAppend(sArgs,Attributes.defaultargs,"no");
	for ( att in Attributes ) {
		if ( ListLen(att,"_") GT 1 AND ListFirst(att,"_") EQ "defaultarg" ) {
			name = ListRest(att,"_");
			if ( NOT StructKeyExists(sArgs,name) ) {
				sArgs[name] = URL[att];
			}
		}
	}

	return sArgs;
	</cfscript>

</cffunction>

<cffunction name="getComponentData" access="private" returntype="struct">

	<cfset var sLocal = {}>

	<cfif
		StructKeyExists(Attributes,"component")
		AND
		isObject(Attributes.component)
		AND
		Len(Attributes.method)
	>
		<cfinvoke
			returnvariable="sLocal.SCompData"
			component="#Attributes.component#"
			method="#Attributes.method#"
			argumentCollection="#Variables.sArguments#"
		>
		</cfinvoke>
	</cfif>

	<cfif NOT ( StructKeyExists(sLocal,"SCompData") AND isStruct(sLocal.SCompData) )>
		<cfset sLocal.SCompData = {}>
	</cfif>

	<cfreturn sLocal.SCompData>
</cffunction>

<cffunction name="getTemplateFromURI" access="private" returntype="string">
	<cfargument name="uri" type="string" required="true">

	<cfscript>
	var FullURL = "";
	var sHTTP = 0;

	FullURL = Arguments.uri;
	if ( NOT ( REFindNoCase("(http(s)?:)?//", FullURL) ) ) {
		if ( Left(FullURL,1) NEQ "/" ) {
			FullURL = "/#FullURL#";
		}
		FullURL = "#CGI.SERVER_NAME##FullURL#";
		if ( CGI.HTTPS EQ "on" ) {
			FullURL = "https:/" & "/#FullURL#";
		} else {
			FullURL = "http:/" & "/#FullURL#";
		}
	}
	</cfscript>
	<cfhttp url="#FullURL#" result="sHTTP">

	<cfreturn sHTTP["FileContent"]>
</cffunction>

<cfscript>
function getTagData(tag) {
	var sResult = {};
	var str = Arguments.tag;
	var xTag = 0;
	var att = "";
	var name = "";
	var action = "default";

	//Convert to valid XML
	str = REReplaceNoCase(str, "^{{{{?", "");
	str = REReplaceNoCase(str, "}}}}?$", "");
	name = ListFirst(str," ");//Get the name, so we can switch it to "name", since the provided name will be invalid.
	str = replaceNoCase(str, "#name#", "name");

	//Parse the XML. Not in a try/catch for now since the user will need to know if this didn't work.
	xTag = XmlParse("<#str#/>");

	for ( att in xTag["name"].XmlAttributes ) {
		sResult[att] = xTag["name"].XmlAttributes[att];
	}
	switch(name) {
		case "~":
			action = "transform";
		break;
		case "->":
			action = "point";
		break;
	}

	return {"action":action,"attributes":sResult};
}
</cfscript>

<cffunction name="QueryStringToStruct" access="private" returntype="any" output="false" hint="I accept a URL query string and return it as a structure.">
	<cfargument name="querystring" type="string" required="true" hint="I am the query string for which to parse.">

	<cfscript>
	var aList = ListToArray(Arguments.querystring,"&");
	return aList.reduce(function(result,item,index){
		result[ListFirst(item,"=")] = ListRest(item,"=");
		return result;
	},{});
	</cfscript>
</cffunction>

<cffunction name="AsQueryString" access="private" returntype="string" output="false" hint="I return the given data as a querystring.">
	<cfargument name="data" type="any" required="true">

	<cfscript>
	if ( isStruct(Arguments.data) ) {
		return Struct2QueryString(Arguments.data);
	}
	return Arguments.data;
	</cfscript>
</cffunction>

<cffunction name="Struct2QueryString" access="private" returntype="string" output="false" hint="I accept a structure and return it as a URL query string.">
	<cfargument name="struct" type="struct" required="true" hint="I am the struct to turn into a query string.">

	<cfscript>
	return Arguments.struct.reduce(function(result, key, value) {
			result = result?:"";
			return ListAppend(result,"#LCase(key)#=#value#","&");
	});
	</cfscript>
</cffunction>

<!--- https://www.bennadel.com/blog/124-ask-ben-converting-a-query-to-an-array.htm --->
<cffunction name="QueryToArray" access="public" returntype="array" output="false" hint="I turn a query into an array of structures.">
	<cfargument name="data" type="query" required="yes">

	<cfscript>
	// Define the local scope.
	var LOCAL = StructNew();

	// Get the column names as an array.
	LOCAL.Columns = ListToArray( ARGUMENTS.Data.ColumnList );

	// Create an array that will hold the query equivalent.
	LOCAL.QueryArray = ArrayNew( 1 );

	// Loop over the query.
	for (LOCAL.RowIndex = 1 ; LOCAL.RowIndex LTE ARGUMENTS.Data.RecordCount ; LOCAL.RowIndex = (LOCAL.RowIndex + 1)){

		// Create a row structure.
		LOCAL.Row = StructNew();

		// Loop over the columns in this row.
		for (LOCAL.ColumnIndex = 1 ; LOCAL.ColumnIndex LTE ArrayLen( LOCAL.Columns ) ; LOCAL.ColumnIndex = (LOCAL.ColumnIndex + 1)){

			// Get a reference to the query column.
			LOCAL.ColumnName = LOCAL.Columns[ LOCAL.ColumnIndex ];

			// Store the query cell value into the struct by key.
			LOCAL.Row[ LOCAL.ColumnName ] = ARGUMENTS.Data[ LOCAL.ColumnName ][ LOCAL.RowIndex ];

		}

		// Add the structure to the query array.
		ArrayAppend( LOCAL.QueryArray, LOCAL.Row );

	}

	// Return the array equivalent.
	return( LOCAL.QueryArray );
	</cfscript>
</cffunction>

<cffunction name="makeLink" access="public" returntype="string" output="no">
	<cfargument name="Path" type="string" required="true">
	<cfargument name="Args" type="struct" required="false">

	<cfset var result = Arguments.Path>

	<cfif StructCount(Arguments.Args)>
		<cfset result = "#result#?#Struct2QueryString(Arguments.Args)#">
	</cfif>

	<!--- Add anchor to links to go to div if it is in use. --->
	<cfif Attributes.useDiv IS true>
		<cfset result &= "###Attributes.id#">
	</cfif>

	<cfreturn result>
</cffunction>

<cffunction name="self" access="public" returntype="string" output="no">

	<cfset var sURL = QueryStringToStruct(CGI.QUERY_STRING)>
	<cfset var sArgs = StructCopy(Arguments)>

	<cfscript>
	var arg = "";

	StructAppend(sArgs,Variables.sArguments,false);

	for ( arg in sArgs ) {
		sUrl["#Attributes.urlprefix##arg#"] = sArgs[arg];
	}
	</cfscript>

	<cfreturn makeLink("",sURL)>
</cffunction>

<cffunction name="runPreTag">
	<cfargument name="str" type="string" required="true">
	<cfargument name="data" type="struct" required="true">

	<cfset var sTag = getTagData(Arguments.str)>
	<cfset var replacement = "">

	<cfinvoke
		returnvariable="replacement"
		method="runPreTag_#sTag.action#"
		argumentCollection="#sTag.attributes#"
		data="#Arguments.data#"
	>

	<cfreturn replacement>
</cffunction>
<cffunction name="runPreTag_default">
	<cfreturn "">
</cffunction>
<cffunction name="runPreTag_point">
	<cfargument name="Label" type="string" default="Click Here">
	<cfargument name="args" type="string" default="">
	<cfargument name="element" type="string" default="a">
	<cfargument name="activeclass" type="string" default="">

	<cfscript>
	var result = '';
	var useOuterElement = ( Len(Arguments.element) AND Arguments.element NEQ "a" );
	var class = '';
	var sArgs = QueryStringToStruct(Arguments.args);
	var href = self(ArgumentCollection=sArgs);
	var isActive = true;
	var arg = "";

	if ( Len(Arguments.activeclass) ) {
		for ( arg in sArgs ) {
			if (
				NOT (
					( StructKeyExists(Variables.sArguments,arg) AND sArgs[arg] EQ Variables.sArguments[arg] )
					OR
					NOT ( StructKeyExists(Variables.sArguments,arg) OR Len(sArgs[arg]) )
				)
			) {
				isActive = false;
			}
		}
		if ( isActive ) {
			class = Arguments.activeclass;
		}
	}

	if ( useOuterElement ) {
		result &= '<#Arguments.element#';
		if ( Len(class) ) {
			result &= ' class="#class#"';
		}
		result &= '><a';
	} else {
		result &= '<a';
		if ( Len(class) ) {
			result &= ' class="#class#"';
		}
	}

	result &= ' href="#href#"';
	if ( Attributes.script IS true ) {
		result &= ' data-mustacheaction="args" data-data="#Struct2QueryString(sArgs)#"';
	}
	result &= '>';
	result &= Arguments.label;
	result &= '</a>';
	if ( useOuterElement ) {
		result &= '</#Arguments.element#>';
	}
	</cfscript>

	<cfreturn result>
</cffunction>
<cffunction name="runPreTag_transform">
	<cfargument name="data" type="struct" default="">
	<cfargument name="key" type="string" default="">
	<cfargument name="value" type="string" default="">
	<cfargument name="output" type="string" default="">

	<cfscript>
	result = "";
	if ( StructKeyExists(Arguments.data,Arguments.key) AND Arguments.data[key] EQ Arguments.value ) {
		result = output;
	}
	</cfscript>

	<cfreturn result>
</cffunction>

<cfscript>
function QueryRowToStruct(query) {
	var row = 1; //by default, do this to the first row of the query
	var ii = 1; //a var for looping
	var cols = ListToArray(query.columnList);//the cols to loop over
	var sReturn = StructNew();//the struct to return

	//if there is a second argument, use that for the row number
	if( ArrayLen(arguments) GT 1 ) {
		row = arguments[2];
	}
	//loop over the cols and build the struct from the query row
	for(ii = 1; ii LTE ArrayLen(cols); ii = ii + 1){
		sReturn[cols[ii]] = query[cols[ii]][row];
	}

	return sReturn;
}

//Make sure request variable used by cf_mustache exists.
if ( NOT StructKeyExists(request,"cf_mustache") ) {
	request["cf_mustache"] = {
		"templates":{},
		"instances":{},
		"external_files":{}
	};
}

//Make sure that the default name for the template is unique.
default_name = "template";
if ( StructKeyExists(request.cf_mustache.templates,default_name) ) {
	ii = 1;
	while ( StructKeyExists(request.cf_mustache.templates,default_name) ) {
		ii++;
		default_name = "template#ii#";
	}
}

//Create Attribute Defaults
sAttributes = {
	action="show",
	name=default_name,
	method="",
	data={},
	id="",
	uri=Reverse("cfc." & ListRest(Reverse(CGI.SCRIPT_NAME),".")),
	template_uri="",
	returnvariable="",
	script=false,
	counter="num",
	args={},
	defaultargs={},
	urlargs=false,
	compress=true,
	require_css="",
	require_js="",
	useDiv=false
};

//Set Attribute Defaults
for ( att in sAttributes ) {
	if ( NOT StructKeyExists(Attributes,att) ) {
		Attributes[att] = sAttributes[att];
	}
}
//"id" attribute default to the value of the "name" attribute
if ( NOT Len(Attributes.id) ) {
	Attributes.id = Attributes.name;
}

//Make sure that the id for the template is unique.
Variables.id_orig = Attributes.id;
if ( StructKeyExists(request.cf_mustache.instances,Attributes.id) ) {
	ii = 1;
	while ( StructKeyExists(request.cf_mustache.templates,Attributes.id) ) {
		ii++;
		Attributes.id = "#Variables.id_orig##ii#";
	}
}
request.cf_mustache.instances[Attributes.id] = {};

//Use the id of the tag as the prefix by default
if ( NOT Len(Attributes.urlargs) ) {
	Attributes.urlargs = false;
}
if ( NOT StructKeyExists(Attributes,"urlprefix") ) {
	if ( Attributes.urlargs IS true ) {
		Attributes.urlprefix = Attributes.id;
	} else if ( Attributes.urlargs IS false ) {
		Attributes.urlprefix = "";
	} else {
		Attributes.urlprefix = Attributes.urlargs;
	}
}
//Make sure urlprefix uses an underscore if it exists.
if ( Len(Attributes.urlprefix) AND NOT Right(Attributes.urlprefix,1) EQ "_" ) {
	Attributes.urlprefix = "#Attributes.urlprefix#_";
}

sAttributes["urlprefix"] = "";//So it won't get included in data. Not in the original struct so that it can manually be set to an empty string.

//Parse args if provided as string.
if ( isSimpleValue(Attributes.args) ) {
	if ( isJSON(Attributes.args) ) {
		Attributes.args = DeserializeJSON(Attributes.args);
	} else {
		Attributes.args = QueryStringToStruct(Attributes.args);
	}
}

//Parse defaultargs if provided as string.
if ( isSimpleValue(Attributes.defaultargs) ) {
	if ( isJSON(Attributes.defaultargs) ) {
		Attributes.defaultargs = DeserializeJSON(Attributes.defaultargs);
	} else {
		Attributes.defaultargs = QueryStringToStruct(Attributes.defaultargs);
	}
}

//Parse data if provided as string.
if ( isSimpleValue(Attributes.data) ) {
	if ( isJSON(Attributes.data) ) {
		Attributes.data = DeserializeJSON(Attributes.data);
	} else {
		Attributes.data = QueryStringToStruct(Attributes.data);
	}
}

if ( Attributes.script ) {
	Attributes.useDiv = true;
}

//Operations to run at end of tag, if available. Otherwise run at the start.
function isGoTime() {
	return ( ThisTag.ExecutionMode EQ "End" OR NOT ThisTag.HasEndTag  );
}
//Get data from the data attribute of the tag or from attributes other than those used by the tag itself.
function getData() {
	var sResult = {};
	var att = "";
	var sCompData = getComponentData();

	if ( isQuery(Attributes.data) ) {
		sResult = QueryRowToStruct(Attributes.data);
	} else {
		sResult = Attributes.data;
	}

	for ( att in Attributes ) {
		if ( NOT StructKeyExists(sAttributes,att) ) {
			if ( ListLen(att,"_") GT 1 AND ListFirst(att,"_") EQ "arg" ) {
			} else if ( ListLen(att,"_") GT 1 AND ListFirst(att,"_") EQ "data" ) {
				sResult[ListRest(att,"_")] = Attributes[att];
			} else {
				sResult[att] = Attributes[att];
			}
		}
	}

	for ( att in sResult ) {
		if ( isQuery(sResult[att]) ) {
			sResult[att] = QueryToArray(sResult[att]);
		}
	}

	//Data attributes take priority over data returned from method.
	StructAppend(sResult,sCompData,"no");

	return sResult;
}
function preprocess(str,data) {
	var key = "";
	var str_matched = "";
	var str_replace = "";
	var aMatches = 0;

	//If we have any preprocess markers, loop through and apply them
	if ( FindNoCase("{{{{", str) ) {
		aMatches = REMatchNoCase("\{{4}.*?\}{4}", str);
		//Replace the matched value with the indicated string
		for ( str_matched in aMatches ) {
			str = ReplaceNoCase(
				str,
				str_matched,
				runPreTag(str_matched,data)
			);
		}
		str = reReplaceNoCase(str, "\{{4}.*?\}{4}", "", "ALL");
	}
	return str;
}
//Uppercase Mustache tags to make them case insensitive in the same way that ColdFusion is.
function ucase_tags(string) {
	var aMatches = REMatch("\{\{.*?\}\}", string);
	var tag = 0;
	var markerloc = 0;

	for ( tag in aMatches ) {
		if ( NOT Left(tag,4) EQ "{{{{" ) {
			//Capitalize everything in every other tag
			string = ReplaceNoCase(string, tag, UCase(tag),"ALL");
		}

	}
	return string;
}
</cfscript>

<cfscript>
if ( isGoTime() ) {
	//Define the data from the first use of the template (if more than one, suggested to use action of "set" or "head" to define a reference).
	if ( NOT StructKeyExists(request["cf_mustache"]["templates"],Attributes.name) ) {
		request["cf_mustache"]["templates"][Attributes.name] = {};
		request["cf_mustache"]["templates"][Attributes.name]["Attributes"] = Attributes;
		request["cf_mustache"]["templates"][Attributes.name]["Attributes"]["GeneratedContent"] = ThisTag.GeneratedContent;
		request["cf_mustache"]["templates"][Attributes.name]["Attributes"]["id_template"] = "#Attributes.id#-template";
		request["cf_mustache"]["templates"][Attributes.name]["Counter"] = 0;
	}
	ThisTag.GeneratedContent = "";
}
//The reference attributes for this cf_mustache name
sBaseAttributes = {};
if ( StructKeyExists(request["cf_mustache"]["templates"],Attributes.name) ) {
	sBaseAttributes = request["cf_mustache"]["templates"][Attributes.name]["Attributes"];
}
aOutputs = [];
ThisOutput = "";
</cfscript>

<cfif Attributes.action NEQ "set" AND isGoTime()>
	<cfset Variables.sArguments = getArguments()>
	<!--- Require files. Use cf_require, if available --->
	<cfif Len(Attributes.require_css) OR Len(Attributes.require_js)>
		<cfif FileExists('#GetDirectoryFromPath(GetCurrentTemplatePath())#require.cfm')>
			<cfsavecontent variable="ThisOutput"><cf_require files_css="#Attributes.require_css#" files_js="#Attributes.require_js#" display="true"></cfsavecontent>
			<cfset ArrayAppend(aOutputs,ThisOutput)>
		<cfelse>
			<!--- Include required files that haven't already been put on the page --->
			<cfif Len(Attributes.require_css)>
				<cfloop list="#Attributes.require_css#" index="path">
					<cfif NOT StructKeyExists(request.cf_mustache.external_files,path)>
						<cfsavecontent variable="ThisOutput"><cfoutput><link rel="stylesheet" href="#path#"></cfoutput></cfsavecontent>
						<cfset ArrayAppend(aOutputs,ThisOutput)>
						<cfset request.cf_mustache.external_files[path] = now()>
					</cfif>
				</cfloop>
			</cfif>
			<cfif Len(Attributes.require_js)>
				<cfloop list="#Attributes.require_js#" index="path">
					<cfif NOT StructKeyExists(request.cf_mustache.external_files,path)>
						<cfsavecontent variable="ThisOutput"><cfoutput><script src="#path#"></script></cfoutput></cfsavecontent>
						<cfset addToHead(aOutputs,ThisOutput)>
						<cfset request.cf_mustache.external_files[path] = now()>
					</cfif>
				</cfloop>
			</cfif>
		</cfif>
	</cfif>
</cfif>

<cfif Attributes.action NEQ "set" AND isGoTime() AND Attributes.script IS true>
	<!--- Output the head the first chance we get unless this is in action="set". Preferably using action="head". --->
	<cfif NOT StructKeyExists(request.cf_mustache,"head")>
		<cfsavecontent variable="ThisOutput">
		<script src="https://unpkg.com/mustache@latest"></script>
		</cfsavecontent>
		<cfset addToHead(aOutputs,ThisOutput)>
		<cfsavecontent variable="ThisOutput">
		<script>
		cf_mustache = {};
		//Make sure we can respond to window.onload without external dependencies or harming other JavaScript code.
		cf_mustache.addWindowLoadEvent = function(functionName) {
			if ( window.attachEvent ) {
				window.attachEvent('onload', functionName);
			} else {
				if ( window.onload ) {
					var curronload = window.onload;
					var newonload = function(evt) {
						curronload(evt);
						functionName(evt);
					};
					window.onload = newonload;
				} else {
					window.onload = functionName;
				}
			}
		};
		cf_mustache.getAttributes = function(str) {
			var sResult = {};
			if ( window.DOMParser ) {
				parser = new DOMParser();
				xmlDoc = parser.parseFromString(str, "text/xml");
			}
			else // Internet Explorer
			{
				xmlDoc = new ActiveXObject("Microsoft.XMLDOM");
				xmlDoc.async = false;
				xmlDoc.loadXML(str);
			}
			for ( var i=0; i < xmlDoc.getElementsByTagName('name')[0].attributes.length; i++ ) {
				var attrib = xmlDoc.getElementsByTagName('name')[0].attributes[i];
				sResult[attrib.name] = attrib.value;
			}
			return sResult;
		};
		cf_mustache.getTagData = function(str) {
			var action = 'default';
			str = str.replace(/^\{+/,'');
			str = str.replace(/\}+$/,'');
			aParts = str.split(' ');
			str = str.replace(aParts[0],'name');
			str = '<' + str + '/>';

			switch(aParts[0]) {
				case "~":
					action = "transform";
				break;
				case "-&gt;":
					action = "point";
				break;
				case "->":
					action = "point";
				break;
			}

			return {"action":action,"attributes":cf_mustache.getAttributes(str)};
		};
		cf_mustache.getURLParams = function() {
			var match,
				pl     = /\+/g,  // Regex for replacing addition symbol with a space
				search = /([^&=]+)=?([^&]*)/g,
				decode = function (s) { return decodeURIComponent(s.replace(pl, " ")); },
				query  = window.location.search.substring(1);

			urlParams = {};
			while (match = search.exec(query)) {
				urlParams[decode(match[1]).toLowerCase()] = decode(match[2]);
			}
			return urlParams;
		};
		cf_mustache.makeLink = function(path,args) {
			var result = path;
			var querystring =  cf_mustache.queryStringFromJSON(args);

			if ( querystring.length ) {
				result = result + '?' + querystring;
			}

			return result;
		};
		cf_mustache.runPreTag = function(id,str,data) {
			var sTag = cf_mustache.getTagData(str);
			var methodName = 'runPreTag_' + sTag['action'];
			var sArgs = sTag['attributes'];
			sArgs['id'] = id;
			sArgs['data'] = data;

			return cf_mustache[methodName].call(null,sArgs);
		};
		cf_mustache.runPreTag_default = function(id,str,data) {
			return '';
		};
		cf_mustache.runPreTag_point = function(id,str,data) {
			var result = '';
			var useOuterElement = (
				typeof arguments[0]['element'] == 'string'
				&&
				arguments[0]['element'].length
				&&
				arguments[0]['element'] != 'a'
			);
			var className = '';
			var sArgs = {};
			var href = '';
			var isActive = true;
			var arg = "";
			var idname = arguments[0]['id'];

			//Convert args to object if provided
			if (
				typeof arguments[0]['args'] == 'string'
				&&
				arguments[0]['args'].length
			) {
				sArgs = cf_mustache.queryStringToJSON(arguments[0]['args']);
			}
			href = cf_mustache.self(sArgs);

			if (
				typeof arguments[0]['activeclass'] == 'string'
				&&
				arguments[0]['activeclass'].length
			) {
				for ( arg in sArgs ) {
					if (
						!(
							(
								typeof cf_mustache.sInstances[idname].sArgs[arg.toLowerCase()] == 'string'
								&&
								sArgs[arg].toLowerCase() == cf_mustache.sInstances[idname].sArgs[arg.toLowerCase()].toLowerCase()
							)
							||
							!( typeof cf_mustache.sInstances[idname].sArgs[arg.toLowerCase()] == 'string' || sArgs[arg].length > 0 )
						)
					) {
						isActive = false;
					}
				}
				if ( isActive ) {
					className = arguments[0]['activeclass'];
				}
			}

			if ( useOuterElement ) {
				result = result + '<' + arguments[0]['element'];
				if ( className.length ) {
					result = result + ' class="' + className + '"';
				}
				result += '><' + 'a';//Weird formatting on code here just to keep from messing up the colorizing in my editor
			} else {
				result += '<' + 'a';//Weird formatting on code here just to keep from messing up the colorizing in my editor
				if ( className.length > 0 ) {
					result = result + ' class="' + className + '"';
				}
			}
			result = result + ' href="' + href + '"';
			result = result + ' data-mustacheaction="args" data-data="' + cf_mustache.queryStringFromJSON(sArgs) + '"';
			result += '>';
			result += arguments[0]['label'];
			result += '</a>';
			if ( useOuterElement ) {
				result = result + '</' + arguments[0]['element'] + '>';
			}

			return result;
		};
		cf_mustache.runPreTag_transform = function(str,data) {
			if (
				typeof arguments[0]['key'] == 'string'
				&&
				typeof arguments[0]['value'] == 'string'
				&&
				typeof arguments[0]['output'] == 'string'
				&&
				typeof arguments[0]['data'][arguments[0]['key']] == 'string'
				&&
				arguments[0]['data'][arguments[0]['key']] == arguments[0]['value']

			) {
				return arguments[0]['output'];
			} else {
				return '';
			}
		};
		cf_mustache.self = function(sArgs) {
			var sURL = cf_mustache.sURLParams;
			var arg = '';
			for ( arg in sArgs ) {
				sURL[arg.toLowerCase()] = sArgs[arg];
			}

			return cf_mustache.makeLink(window.location.pathname,sURL);
		};
		cf_mustache.preprocess = function(id,str,data) {
			var regex_re = new RegExp('\{{4}.*?\}{4}', 'g' );
			var str_matched = '';

			if ( typeof id != 'string' ) {
				id = id.getAttribute('id');
			}

			//If we have any preprocess markers, loop through and apply them
			if ( str.indexOf('{{{{') > -1 ) {
				str = str.replace(
					regex_re,
					function(str_matched) {
				  		return cf_mustache.runPreTag(id,str_matched,data);
					}
				);
				str.replace('\{{4}.*?\}{4}','');
			}
			return str;
		};
		cf_mustache.queryStringFromJSON = function(data) {
			var result = '';
			for ( var key in data ) {
				if ( typeof data[key] == 'string' ) {
					if ( result.length ) {
						result += '&';
					}
					result += key + '=' + data[key];
				}
			}
			return result;
		};
		//Ability to convert q querystring to JSON
		cf_mustache.queryStringToJSON = function(qs) {
			qs = qs || location.search.slice(1);

			var pairs = qs.split('&');
			var result = {};
			pairs.forEach(function(p) {
				var pair = p.split('=');
				var key = pair[0];
				var value = decodeURIComponent(pair[1] || '');

				if( result[key] ) {
					if( Object.prototype.toString.call( result[key] ) === '[object Array]' ) {
						result[key].push( value );
					} else {
						result[key] = [ result[key], value ];
					}
				} else {
					result[key] = value;
				}
			});

			return JSON.parse(JSON.stringify(result));
		};
		//Get data from a form. Should work if given the form element or an id to it or given any child of a form (or an id to that).
		cf_mustache.getFormData = function(form) {
			if ( typeof form != "object" ) {
				form = document.getElementById(form);
			}
			while ( form.nodeName != 'FORM' ) {
				form = form.parentNode;
			}
			aData = (Array.apply(0, form.elements).map(x =>((obj => ( x.type == "radio" || x.type == "checkbox" ) ? x.checked ? obj:null:obj)({[x.name]:x.value}))).filter(x => x));
			data = {};
			for( var i=0; i < aData.length; i++ ) {
				data = Object.assign(data, aData[i]);
			};
			return data;
		};
		//Load Mustache trigger events to the document
		cf_mustache.loadMustacheTriggersDocument = function() {
			cf_mustache.loadMustacheTriggers(document);
		};
		//Load mustache trigger events to any given object
		cf_mustache.loadMustacheTriggers = function(object) {
			aTriggers = object.querySelectorAll('[data-mustacheaction]');
			for (let i = 0; i < aTriggers.length; i++) {
				aTriggers[i].addEventListener('click', (event) => {
					var obj = event.target;
					var action = obj.dataset["mustacheaction"];
					var sArgs = {};
					var aActionSplit = action.split("-");
					var obj2 = obj;

					event.preventDefault();//Make sure to stop default action of element

					//Find the target element
					if ( obj.dataset["element"] != undefined ) {
						sArgs["element"] = obj.dataset["element"];
					} else {
						const limit = 32;
						var iterations = 0;
						while ( obj2.dataset["template"] == undefined && typeof obj2.parentElement == "object" && iterations < limit ) {
							obj2 = obj2.parentElement;
							iterations++;
						}
						sArgs["element"] = obj2["id"];
					}

					if ( aActionSplit[0] == 'form' ) {
						//Form actions don't need to get data from the element
						action = aActionSplit[1];
						if ( action == 'args' ) {
							cf_mustache.renderFormArgs(sArgs["element"],obj);
						}
						if ( action == 'data' ) {
							cf_mustache.renderFormData(sArgs["element"],obj);
						}
					} else {
						//Get the data for non-form actions
						if ( obj.dataset["data"] == undefined && obj["href"] != undefined ) {
							var qs = (obj["href"].split("?").length)? obj["href"].split("?")[1]: '';
							obj.dataset["data"] = qs;
						}
						sArgs["data"] = obj.dataset["data"];

						if ( action == 'args' ) {
							cf_mustache.renderArgs(sArgs["element"],sArgs["data"]);
						}
						if ( action == 'data' ) {
							cf_mustache.renderData(sArgs["element"],sArgs["data"]);
						}
					}

				});
			}
		};
		cf_mustache.htmlToElem = function(html) {
			let temp = document.createElement('template');
			html = html.trim(); // Never return a space text node as a result
			temp.innerHTML = html;
			return temp.content.firstChild;
	  	};
		cf_mustache.add = function(type,elem,name,data) {
			var aTypes = type.split('-');
			var action = aTypes[0];
			var fetch = aTypes[1] || 'data';
			var id = name + '-template';
			var num = document.querySelectorAll('[data-template="' + id + '"]').length + 1;;//One for the next element
			var id_new = id + '-' + num;
			var obj = cf_mustache.htmlToElem(document.getElementById(id).innerHTML);

			//The elem argument should either be an object or we should get the object for that id.
			if ( typeof elem == "string" ) {
				var elem = document.getElementById(elem);
			}
			//Default data to an empty structure (object)
			data = data || {};

			//Add the counter to the data
			data[cf_mustache.sCounters[id]] = num;

			//Make sure that the id and data-template attributes are correct.
			obj.setAttribute('data-template',id);
			obj.setAttribute('id',id_new);

			//Add data to the element in the requested manner.
			switch(fetch) {
				case 'data':
					cf_mustache.renderData(obj,data);
				break;
				case 'args':
					cf_mustache.renderArgs(obj,data);
				// code block
				break;
				case 'formdata':
					cf_mustache.renderFormData(obj,data);
				break;
				case 'formargs':
					cf_mustache.renderFormArgs(obj,data);
				// code block
				break;
				default:
				// code block
			}

			//Take the requested action in adding the element to the DOM.
			switch(action) {
				case 'insertBefore':
					elem.parentNode.insertBefore(obj,elem);
				break;
				case 'appendChild':
					elem.appendChild(obj);
				// code block
				break;
				default:
				// code block
			}

		};
		cf_mustache.processResponse = function(str) {
			//Handle ColdFusion errors
			if ( str.indexOf('cfdump') > 0 ) {
				var re_begin = 'Message(.*?)<\/td>(.*?)<td>';
				var re_end = '<\/td>';
				var regex_msg = new RegExp(re_begin + '(.*?)' + re_end, 'g' );
				var str_msg = str.replace(/(?:\r\n|\r|\n)/g, '');
				str_msg = str_msg.match(regex_msg)[0];
				str_msg = str_msg.replace(RegExp(re_begin),'');
				str_msg = str_msg.replace(RegExp(re_end + '$'),'');
				str_msg = str_msg.trim();

				console.log('cf_mustache ERROR: ' + str_msg);
				str = '{"Message":"' + str_msg + '"}';
			}
			return str;
		};
		cf_mustache.post = function(uri,args,returncall) {
			var request = new XMLHttpRequest();
			if ( typeof args != 'string' ) {
				args = cf_mustache.queryStringFromJSON(args);
			}

			request.open('POST', uri, true);
			request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');

			request.onreadystatechange = function() {
				if (this.readyState === 4) {
					if (this.status >= 200 && this.status < 400) {
						// Success!
						returncall(cf_mustache.processResponse(this.responseText));
					} else {
						// Error :(
					}
				}
			};

			console.log('cf_mustache.post() to url: ' + uri + ' with args: ' + args);
			request.send(args);
			request = null;
		};
		//Fetch the data from the URI and render it
		cf_mustache.renderArgs = function(id,args) {
			var arg = '';
			//The elem argument should either be an object or we should get the object for that id.
			if ( typeof id == "string" ) {
				var obj = document.getElementById(id);
			} else {
				var obj = id;
				id = obj.getAttribute('id');
			}
			var id_template = obj.getAttribute('data-template');
			var uri = cf_mustache.sTemplates[id_template]['uri'];
			var sArgs = {};
			var request = new XMLHttpRequest();

			if ( !obj.style.opacity.length ) {
				obj.style.opacity = "1";
			}
			obj.style.opacity = obj.style.opacity * 0.3;

			//We need the args as a struct so we can add data to them.
			if ( typeof args == 'string' ) {
				args = cf_mustache.queryStringToJSON(args);
			}

			//Set arguments (needed both to get data and because other code compares against the current argument state).
			if ( typeof cf_mustache.sInstances[id] == 'undefined' ) {
				cf_mustache.sInstances[id] = {'sArgs':{}};
			}
			for ( arg in args ) {
				cf_mustache.sInstances[id].sArgs[arg] = args[arg];
			}
			sArgs = cf_mustache.sInstances[id].sArgs;//Just the local copy of the arguments.

			cf_mustache.post(
				uri,
				cf_mustache.sInstances[id].sArgs,
				function(data) { cf_mustache.renderData(id,JSON.parse(data)) }
			);

		};
		//Use the form to fetch the data from the uri and render it
		cf_mustache.renderFormArgs = function(id,form) {
			cf_mustache.renderArgs(id,cf_mustache.getFormData(form));
		};
		//Use the form to render the data
		cf_mustache.renderFormData = function(id,form) {
			cf_mustache.renderData(id,cf_mustache.getFormData(form));
		};
		//Just to make keys case-insensitive
		cf_mustache.ucase_keys = function(data) {
			for (var key in data) {
				if ( typeof data[key] == 'string' ) {
					//Simple replacement for strings
					data[key.toUpperCase()] = data[key];
				} else {
					//Dive down replacement for non-strings
					data[key.toUpperCase()] = cf_mustache.ucase_keys(data[key]);
				}
				//Ditch original key if case doesn't match.
				if ( key !== key.toUpperCase() ) {
					delete data[key];
				}
			}
			return data;
		};
		//Uppercase Mustache tags to make them case insensitive in the same way that ColdFusion is.
		cf_mustache.ucase_tags = function(str) {
			var regex_re = new RegExp('\{{2}.*?\}{2}', 'g' );
			var str_matched = '';

			str = str.replace(
				regex_re,
				function(str_matched) {
					if ( str_matched.indexOf('{{{{') == 0 ) {
						return str_matched;
					} else {
						return str_matched.toUpperCase();
					}
				}
			);
			return str;
		};
		//The base rendering method
		cf_mustache.renderData = function(id,data) {
			if ( typeof data == "string" ) {
				try {
					data = JSON.parse(data);
				} catch (e) {
					data = cf_mustache.queryStringToJSON(data);
				}
			}

			//The id argument should either be an object or we should get the object for that id.
			if ( typeof id == "string" ) {
				var obj = document.getElementById(id);
			} else {
				var obj = id;
			}

			cf_mustache.renderDataA(obj,data);

			obj.style.opacity = obj.style.opacity / 0.3;
			
		};
		cf_mustache.renderDataA = function(obj,data) {
			var id = obj.getAttribute('id');
			var id_template = obj.getAttribute('data-template');
			//Make sure that a key exists for the template
			if ( typeof cf_mustache.sTemplates[id_template] == 'undefined' ) {
				cf_mustache.sTemplates[id_template] = {};
			}
			if ( typeof cf_mustache.sTemplates[id_template]['html'] != 'string' ) {
				cf_mustache.sTemplates[id_template]['html'] = '';
			}
			if ( typeof cf_mustache.sTemplates[id_template]['html'] == 'string' && cf_mustache.sTemplates[id_template]['html'].length ) {
				//If the string already exists, just use that.
				cf_mustache.renderDataB(obj,id_template,data);
			} else if ( !!document.getElementById(id_template) ) {
				//If the object exists in the DOM, use that.
				cf_mustache.sTemplates[id_template]['html'] = document.getElementById(id_template).innerHTML;
				cf_mustache.renderDataB(obj,id_template,data);
			} else if ( typeof cf_mustache.sTemplates[id_template]['template_uri'] == 'string' ) {
				//If we have a template_uri, get the HTML from that.
				cf_mustache.post(
					cf_mustache.sTemplates[id_template]['template_uri'],
					cf_mustache.sInstances[id].sArgs,
					function(str) {
						cf_mustache.processTemplateHTML(id_template,str);
						cf_mustache.renderDataB(obj,id_template,data)
					}
				);
			} else {
				//Otherwise log the failure.
				console.log('No template found for ' + obj.getAttribute('id') + '.');
			}
		};
		cf_mustache.processTemplateHTML = function(id_template,html) {
			cf_mustache.sTemplates[id_template]['html'] = cf_mustache.ucase_tags(html);
		};
		cf_mustache.renderDataB = function(obj,id_template,data) {
			delete data.GeneratedContent;
			var template = cf_mustache.preprocess(obj.getAttribute('id'),cf_mustache.sTemplates[id_template]['html'],data);
			var evt = new CustomEvent(
				'cf_mustache.render',
				{
					detail: {
						'id': obj.getAttribute('id'),
						'data': data
					}
				}
			);
			document.getElementById( obj.getAttribute('id') + '-data' ).innerHTML = JSON.stringify(data);
			obj.innerHTML = Mustache.render(template, cf_mustache.ucase_keys(data));
			cf_mustache.loadMustacheTriggers(obj);//Make sure that triggers in the element still work.

			// dispatch the events
			window.dispatchEvent(evt);
		};
		cf_mustache.sURLParams = cf_mustache.getURLParams();
		cf_mustache.sTemplates = {};//A place to store URIs for each template
		cf_mustache.sInstances = {};//A place to store instance data
		cf_mustache.sCounters = {};
		//Load up the triggers
		cf_mustache.addWindowLoadEvent(cf_mustache.loadMustacheTriggersDocument);
		</script>
		</cfsavecontent>
		<cfset addToHead(aOutputs,compress(ThisOutput,"js"))>
		<cfset request["cf_mustache"]["head"] = {}>
	</cfif>
	<!--- Store URIs for each template. --->
	<cfif NOT StructKeyExists(request["cf_mustache"]["head"],Attributes.name)>
		<cfsavecontent variable="ThisOutput"><cfoutput>
		<cfif NOT Len(sBaseAttributes.template_uri)>
			<script id="#sBaseAttributes.id_template#" type="text/html">
			#Trim(ucase_tags(sBaseAttributes["GeneratedContent"]))#
			</script>
		</cfif>
		<script>
		cf_mustache.sTemplates['#sBaseAttributes.id_template#'] = {
			'uri':'#sBaseAttributes.uri#<cfif Len(sBaseAttributes.method)>?method=#sBaseAttributes.method#</cfif>'<cfif Len(sBaseAttributes.template_uri)>,
			'template_uri':'#sBaseAttributes.template_uri#'</cfif>
		};
		cf_mustache.sCounters['#sBaseAttributes.id_template#'] = '#Attributes.Counter#'
		</script></cfoutput></cfsavecontent>
		<cfset addToHead(aOutputs,compress(ThisOutput,"htm"))>
		<cfset request["cf_mustache"]["head"][Attributes.name] = true>
	</cfif>
	<cfsavecontent variable="ThisOutput"><cfoutput>
	<script>
	cf_mustache.sInstances['#Attributes.id#'] = {
		'sArgs':cf_mustache.queryStringToJSON('#AsQueryString(Variables.sArguments)#')
	};
	</script>
	</cfoutput></cfsavecontent>
	<cfset addToHead(aOutputs,compress(ThisOutput,"htm"))>
</cfif>

<!--- Actually show the element, with data. --->
<cfif Attributes.action EQ "show" AND isGoTime()>
	<cfscript>
	//Use template_uri for GeneratedContent if it is provided and no GeneratedContent
	if ( Len(sBaseAttributes.template_uri) AND NOT Len(Trim(sBaseAttributes["GeneratedContent"])) ) {
		sBaseAttributes["GeneratedContent"] = getTemplateFromURI(sBaseAttributes.template_uri);
	}

	oMustache = CreateObject("component","Mustache").init();
	TemplateHTML = sBaseAttributes["GeneratedContent"];
	TemplateID = sBaseAttributes["id_template"];
	request["cf_mustache"]["templates"][Attributes.name]["Counter"]++;
	sData = getData();
	//Added Counter to the data
	sData[request["cf_mustache"]["templates"][Attributes.name]["Attributes"]["Counter"]] = request["cf_mustache"]["templates"][Attributes.name]["Counter"];
	TemplateHTML = preprocess(TemplateHTML,sData);
	</cfscript>
	<cfif Attributes.script>
		<cfset sCopyData = StructCopy(sData)>
		<cfset StructDelete(sCopyData,"GeneratedContent")>
		<cfsavecontent variable="ThisOutput"><cfoutput><script id="#Attributes.id#-data" class="cc-mustache-data" type="text/data">#SerializeJSON(sCopyData)#</script></cfoutput></cfsavecontent>
		<cfset addToHead(aOutputs,ThisOutput)>
	</cfif>
	<cfif Attributes.useDiv>
		<cfsavecontent variable="ThisOutput"><cfoutput><div id="#Attributes.id#" class="cc-mustache cc-mustache-#TemplateID#"<cfif Attributes.script IS true> data-template="#TemplateID#"</cfif>>#oMustache.render(template=TemplateHTML,context=sData)#</div></cfoutput></cfsavecontent>
	<cfelse>
		<cfsavecontent variable="ThisOutput"><cfoutput>#oMustache.render(template=TemplateHTML,context=sData)#</cfoutput></cfsavecontent>
	</cfif>
	<cfset ArrayAppend(aOutputs,ThisOutput)>
</cfif>

<cfscript>
output = "";
for ( ii in aOutputs ) {
	output = "#output##ii#";
}
if ( Len(Attributes.returnvariable) ) {
	Caller[Attributes.returnvariable] = output;
}
</cfscript>
</cfsilent><cfif NOT Len(Attributes.returnvariable)><cfoutput>#output#</cfoutput></cfif>
