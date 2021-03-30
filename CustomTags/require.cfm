<cfsilent>

<cfparam name="Attributes.title" default="">
<cfparam name="Attributes.files" default="">
<cfparam name="Attributes.files_css" default="">
<cfparam name="Attributes.files_js" default="">
<cfparam name="Attributes.head_css" default="">
<cfparam name="Attributes.head_js" default="">
<cfparam name="Attributes.meta_tags" default="#{}#">

<cfscript>
Variables.aOutputs = [];
Variables.output = "";

Variables.sMetaTags = Attributes.meta_tags;

function isGoTime() {
	return ( ThisTag.ExecutionMode EQ "End" OR NOT ThisTag.HasEndTag  );
}
function addFile(path,type) {
	var filepath = ListFirst(path,"?");
	if ( NOT StructKeyExists(request["cf_require"]["files"],filepath) ) {
		request["cf_require"]["files"][filepath] = path;
		switch (Arguments.type) {
			case "css":
				addOutput('<link rel="stylesheet" href="#path#" type="text/css" media="all"/>');
			break;
			case "js":
				addOutput('<script type="text/javascript" src="#path#"></script>');
			break;
		}
	}
}
function addOutput(text) {
	ArrayAppend(Variables.aOutputs,Arguments.text);
}
function addText(text) {
	var hashed = Hash(text);
	if ( NOT StructKeyExists(request["cf_require"]["textblocks"],hashed) ) {
		request["cf_require"]["textblocks"][hashed] = text;
		addOutput(text);
	}
}

//Make sure request variable used by cf_mustache exists.
if ( NOT StructKeyExists(request,"cf_require") ) {
	request["cf_require"] = {
		"files":{},
		"textblocks":{},
		"title":""
	};
}

if ( isGoTime() ) {
	//Add Title (if not existing)
	if ( Len(Attributes.title) AND NOT Len(request["cf_require"]["title"]) ) {
		request["cf_require"]["title"] = Attributes.title;
		addOutput(Attributes.title);
	}

	//Meta tags go after title
	if ( isStruct(sMetaTags) AND StructCount(sMetaTags) ) {
		for ( tag in sMetaTags ) {
			addText('<meta name="#LCase(tag)#" content="#HTMLEditFormat(sMetaTags[tag])#" />');
		}
	}

	//CSS files after title and meta, but above other CSS and any JavaScript
	if ( Len(Attributes.files_css) ) {
		for ( ii=1; ii LTE ListLen(Attributes.files_css,","); ii++ ) {
			addFile(ListGetAt(Attributes.files_css,ii),"css");
		}
	}

	//CSS head after CSS files, but above any JavaScript
	if ( Len(attributes.head_css) ) {
		addText('<style type="text/css">#Attributes.head_css#</style>');
	}

	//JavaScript files after any CSS, but above in-line JavaScript
	if ( Len(Attributes.files_js) ) {
		for ( ii=1; ii LTE ListLen(Attributes.files_js,","); ii++ ) {
			addFile(ListGetAt(Attributes.files_js,ii),"js");
		}
	}

	//In-line JavaScript after JavaScript files
	if ( Len(attributes.head_js) ) {
		addText('<script type="text/javascript">#attributes.head_js#</script>');
	}

	if ( Len(Trim(ThisTag.GeneratedContent)) ) {
		addText(Trim(ThisTag.GeneratedContent));
	}

	for ( entry in Variables.aOutputs ) {
		Variables.output &= entry;
	}

}
</cfscript>
</cfsilent><cfif isGoTime()><cfoutput>#Variables.output#</cfoutput></cfif>
