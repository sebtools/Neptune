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
if ( NOT StructKeyExists(request,"cf_mustache_templates") ) {
	request["cf_mustache_templates"] = {};
}

//Make sure that the default name for the template is unique.
default_name = "template";
if ( StructKeyExists(request.cf_mustache_templates,default_name) ) {
	ii = 1;
	while ( StructKeyExists(request.cf_mustache_templates,default_name) ) {
		ii++;
		default_name = "template_#ii#";
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
	returnvariable="",
	script=false,
	counter="num"
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
//Parse data if provided as string.
if ( isSimpleValue(Attributes.data) ) {
	if ( isJSON(Attributes.data) ) {
		Attributes.data = DeserializeJSON(Attributes.data);
	} else {
		Attributes.data = QueryStringToStruct(Attributes.data);
	}
}

//Operations to run at end of tag, if available. Otherwise run at the start.
function isGoTime() {
	return ( ThisTag.ExecutionMode EQ "End" OR NOT ThisTag.HasEndTag  );
}
//Get data from the data attribute of the tag or from attributes other than those used by the tag itself.
function getData() {
	var sResult = {};

	if ( isQuery(Attributes.data) ) {
		sResult = QueryRowToStruct(Attributes.data);
	} else {
		sResult = Attributes.data;
	}

	for ( att in Attributes ) {
		if ( NOT StructKeyExists(sAttributes,att) ) {
			if ( ListLen(att,"_") GT 1 AND ListFirst(att,"_") EQ "data" ) {
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

	return sResult;
}
function reFetch(regex,string) {
	var sFind = reFindNoCase(Arguments.regex, Arguments.string, 1, true);
	if ( StructCount(sFind) AND ArrayLen(sFind.len) AND Val(sFind.len[1]) ) {
		return Mid(Arguments.string,sFind.pos[1],sFind.len[1]);
	} else {
		return "";
	}
}
function preprocess(str,data) {
	var key = "";
	var str_matched = "";
	var str_replace = "";
	var aMatches = 0;
	//If we have any transform markers, loop through the data keys to do the transformation
	if ( FindNoCase("{{~", str) ) {
		for ( key in data ) {
			//Can't replace non-string values
			if ( isSimpleValue(data[key]) ) {
				aMatches = REMatchNoCase("\{\{\~#key#:=:#data[key]#==>.*?\}\}", str);
				//Replace the matched value with the indicated string
				for ( str_matched in aMatches ) {
					str_replace = ReReplaceNoCase(
						ReReplaceNoCase(str_matched, "\{\{\~#key#:=:#data[key]#==>", ""),
						"\}\}$",
						""
					);
					//Perform the replacement
					str = ReplaceNoCase(str, str_matched, str_replace);
				}
			}
		}
		str = reReplaceNoCase(str, "\{\{\~.*?\}\}", "", "ALL");
	}
	return str;
}
//Uppercase Mustache tags to make them case insensitive in the same way that ColdFusion is.
function ucase_tags(string) {
	var aMatches = REMatch("\{\{.*?\}\}", string);
	var tag = 0;
	var markerloc = 0;

	for ( tag in aMatches ) {
		if ( Left(tag,3) EQ "{{~" ) {
			//Capitalize everything but the replacement value for transformation tags
			markerloc = findNoCase("==>", tag);
			string = ReplaceNoCase(
				string,
				tag,
				UCase( Left(tag,markerloc) ) & Right(tag,Len(tag)-markerloc),
				"ALL"
			);
		} else {
			//Capitalize everything in every other tag
			string = ReplaceNoCase(string, tag, UCase(tag),"ALL");
		}

	}
	return string;
}
</cfscript>

<cfscript>
if ( ThisTag.ExecutionMode EQ "End" AND Len(Trim(ThisTag.GeneratedContent)) ) {
	//Define the data from the first use of the template (if more than one, suggested to use action of "set" or "head" to define a reference).
	if ( NOT StructKeyExists(request["cf_mustache_templates"],Attributes.name) ) {
		request["cf_mustache_templates"][Attributes.name] = {};
		request["cf_mustache_templates"][Attributes.name]["Attributes"] = Attributes;
		request["cf_mustache_templates"][Attributes.name]["Attributes"]["GeneratedContent"] = ThisTag.GeneratedContent;
		request["cf_mustache_templates"][Attributes.name]["Attributes"]["id_template"] = "#Attributes.id#-template";
		request["cf_mustache_templates"][Attributes.name]["Counter"] = 0;
	}
	ThisTag.GeneratedContent = "";
}
//The reference attributes for this cf_mustache name
sBaseAttributes = {};
if ( StructKeyExists(request["cf_mustache_templates"],Attributes.name) ) {
	sBaseAttributes = request["cf_mustache_templates"][Attributes.name]["Attributes"];
}
aOutputs = [];
ThisOutput = "";
</cfscript>

<cfif Attributes.action NEQ "set" AND isGoTime() AND  Attributes.script IS true>
	<!--- Output the head the first chance we get unless this is in action="set". Preferably using action="head". --->
	<cfif NOT StructKeyExists(request,"cf_mustache_head")>
		<cfsavecontent variable="ThisOutput">
		<script src="https://unpkg.com/mustache@latest"></script>
		<script>
		var cf_mustache = {};
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
		}
		cf_mustache.preprocess = function(str,data) {
			var key = "";
			var aMatches = [];
			var regex_str_1 = '';
			var regex_str_2 = '';
			var regex_re = 0;
			var str_matched = '';
			var str_replace = '';
			//If we have any transform markers, loop through the data keys to do the transformation
			if ( str.indexOf('{{~') > -1 ) {
				for ( key in data ) {
					//alert(key);
					//Can't replace non-string values
					if ( typeof data[key] == 'string' ) {
						regex_str_1 = '\{\{\~' + key.toUpperCase() + ':=:' + data[key].toUpperCase() + '==>';
						regex_str_2 = '\}\}';
						regex_re = new RegExp( regex_str_1 + '.*?' + regex_str_2, 'i' );
						if ( false && regex_re.test(str) ) {
							aMatches = str.match(regex_re);// + key.toUpperCase() + ':=:' + data[key].toUpperCase() + '==>.*?\}\}'
							//alert(aMatches.length);
							//Replace the matched value with the indicated string
							for ( str_matched in aMatches ) {
								alert(str_matched);
								str_replace = str_matched;
								str_replace.replace(regex_str_1,'');
								str_replace.replace(regex_str_2,'');
								//Perform the replacement
								str.replace(str_matched,str_replace);
							}
						}
					}
				}
				str.replace('\{\{\~.*?\}\}','');
			}
			return str;
		}
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
		}
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
		}
		//Load Mustache trigger events to the document
		cf_mustache.loadMustacheTriggersDocument = function() {
			cf_mustache.loadMustacheTriggers(document);
		}
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
		}
		//Load up the triggers
		cf_mustache.addWindowLoadEvent(cf_mustache.loadMustacheTriggersDocument);
		cf_mustache.htmlToElem = function(html) {
		  let temp = document.createElement('template');
		  html = html.trim(); // Never return a space text node as a result
		  temp.innerHTML = html;
		  return temp.content.firstChild;
		}
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
			data[sCounters[id]] = num;

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

		}
		//Fetch the data from the URI and render it
		cf_mustache.renderArgs = function(id,args) {
			//The elem argument should either be an object or we should get the object for that id.
			if ( typeof id == "string" ) {
				var obj = document.getElementById(id);
			} else {
				var obj = id;
			}
			var id_template = obj.getAttribute('data-template');
			var uri = sURIs[id_template];
			var request = new XMLHttpRequest();

			request.open('POST', uri, true);
			request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');

			request.onreadystatechange = function() {
				if (this.readyState === 4) {
					if (this.status >= 200 && this.status < 400) {
						// Success!
						data = JSON.parse(this.responseText);

						cf_mustache.renderData(id,data);
					} else {
						// Error :(
					}
				}
			};
			if ( typeof args != 'string' ) {
				args = cf_mustache.queryStringFromJSON(args);
			}

			request.send(args);
			request = null;
		}
		//Use the form to fetch the data from the uri and render it
		cf_mustache.renderFormArgs = function(id,form) {
			cf_mustache.renderArgs(id,cf_mustache.getFormData(form));
		}
		//Use the form to render the data
		cf_mustache.renderFormData = function(id,form) {
			cf_mustache.renderData(id,cf_mustache.getFormData(form));
		}
		//Just to make keys case-insensitive
		cf_mustache.ucase_keys = function(data) {
			for (var key in data) {
				if ( key != key.toUpperCase() ) {
					data[key.toUpperCase()] = data[key];
					delete data[key];
				}
			}
			return data;
		}
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

			var id_template = obj.getAttribute('data-template');
			var template = cf_mustache.preprocess(document.getElementById(id_template).innerHTML,data);
			var rendered = Mustache.render(template, cf_mustache.ucase_keys(data));
			obj.innerHTML = rendered;
			cf_mustache.loadMustacheTriggers(obj);//Make sure that triggers in the element still work.
		}
		sURIs = {};//A place to store URIs for each template
		sCounters = {};
		</script>
		</cfsavecontent>
		<cfset ArrayAppend(aOutputs,ThisOutput)>
		<cfset request.cf_mustache_head = {}>
	</cfif>
	<!--- Store URIs for each template. --->
	<cfif NOT StructKeyExists(request.cf_mustache_head,Attributes.name)>
		<cfsavecontent variable="ThisOutput"><cfoutput><script id="#sBaseAttributes.id_template#" type="text/html">#Trim(ucase_tags(sBaseAttributes["GeneratedContent"]))#</script><script>sURIs['#sBaseAttributes.id_template#'] = '#sBaseAttributes.uri#<cfif Len(sBaseAttributes.method)>?method=#sBaseAttributes.method#</cfif>';sCounters['#sBaseAttributes.id_template#'] = '#Attributes.Counter#'</script></cfoutput></cfsavecontent>
		<cfset ArrayAppend(aOutputs,ThisOutput)>
		<cfset request.cf_mustache_head[Attributes.name] = true>
	</cfif>
</cfif>

<!--- Actually show the element, with data. --->
<cfif Attributes.action EQ "show" AND isGoTime()>
	<cfscript>
	oMustache = CreateObject("component","Mustache").init();
	TemplateHTML = sBaseAttributes["GeneratedContent"];
	TemplateID = sBaseAttributes["id_template"];
	request["cf_mustache_templates"][Attributes.name]["Counter"]++;
	sData = getData();
	//Added Counter to the data
	sData[request["cf_mustache_templates"][Attributes.name]["Attributes"]["Counter"]] = request["cf_mustache_templates"][Attributes.name]["Counter"];
	TemplateHTML = preprocess(TemplateHTML,sData);
	</cfscript>
	<cfif Attributes.script>
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
