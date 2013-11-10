<!---
1.0 RC9 (Build 121)
Last Updated: 2011-10-11
Created by Steve Bryant 2004-06-01
Information: http://www.bryantwebconsulting.com/docs/sebtags/?version=1.0
Documentation:
http://www.bryantwebconsulting.com/docs/sebtags/sebfield-general-attributes.cfm?version=1.0
---><cfsetting enablecfoutputonly="Yes">
<cfset TagName = "cf_sebField"><cfset ParentTag = "cf_sebForm"><cfset ParentTag2 = "cf_sebSubForm"><cfset ParentTag3 = "cf_sebGroup"><cfif NOT isDefined("ThisTag.ExecutionMode")><cfthrow message="&lt;#TagName#&gt; must be called as a custom tag" type="cftag"></cfif>
<cfif ThisTag.ExecutionMode EQ "End" OR (ThisTag.ExecutionMode EQ "Start" AND NOT ThisTag.HasEndTag)><cfsilent>
<cfif ListFindNoCase(GetBaseTagList(), ParentTag2)>
	<cfassociate basetag="#ParentTag2#" datacollection="qfields">
<cfelseif ListFindNoCase(GetBaseTagList(), ParentTag)>
	<cfassociate basetag="#ParentTag#" datacollection="qfields">
<cfelse>
	<cfthrow message="&lt;#TagName#&gt; must be called as a custom tag between &lt;#ParentTag#&gt; and &lt;/#ParentTag#&gt;" type="cftag">
</cfif>
<cfif ListFindNoCase(GetBaseTagList(), ParentTag3)>
	<cfassociate basetag="#ParentTag3#" datacollection="aFields">
</cfif>
	<cfscript>
	ParentData = getBaseTagData("cf_sebForm");
	ParentAtts = ParentData.attributes;
	if ( ListFindNoCase(GetBaseTagList(), ParentTag2) ) {
		sSubForm = getBaseTagData(ParentTag2);
		sSubFormAtts = sSubForm.attributes;
	}
	if ( ListFindNoCase(GetBaseTagList(), ParentTag3) ) {
		sGroup = getBaseTagData(ParentTag3);
		sGroupAtts = sGroup.attributes;
	}
	
	sForm = ParentData.sForm;
	ThisTag.config = ParentAtts.config;
	LiErrFields = ParentData.TagInfo.LiErrFields;
	
	liHtmlAtts = "class,style,title,size,tabindex,onFocus,onBlur,onSelect,onChange,onClick,onDblClick,onMouseDown,onMouseUp,onMouseOver,onMouseMove,onMouseOut,onKeyPress,onKeyDown,onKeyUp,autocomplete";
	liNoNameNeeded	= "button,cancel,reset,submit,delete,subdelete,submit/cancel,submit/cancel/delete,plaintext,custom1";
	liButtonTypes	= "button,cancel,reset,submit,delete,subdelete,submit/cancel,submit/cancel/delete";
	liSubFieldTypes = "select,checkbox,radio,options";
	//liValidTypes = "hidden,cancel,checkbox,date,jtdate,datestamp,delete,file,password,radio,reset,select,submit,text,textarea,paragraph,memo,yesno,yes/no,YES/NO RADIO,custom2";
	request.liButtonTypes = liButtonTypes;
	
	ThisTag.atts = StructNew();
	ThisTag.atts.fieldname = "";
	ThisTag.atts.type = "";
	ThisTag.atts.id = "";
	ThisTag.atts.length = "";
	ThisTag.atts.multiple = false;
	ThisTag.atts.dbfield = "";
	ThisTag.atts.dbdatatype = "";
	ThisTag.atts.cfdatatype = "";
	ThisTag.atts.label = "";
	ThisTag.atts.help = "";
	ThisTag.atts.required = false;
	ThisTag.atts.isnullable = true;
	ThisTag.atts.isunique = false;
	ThisTag.atts.locked = false;
	ThisTag.atts.accept = "";
	ThisTag.atts.destination = "";
	ThisTag.atts.nameconflict = "ERROR";
	ThisTag.atts.mode = "644";
	ThisTag.atts.showFile = true;
	ThisTag.atts.showImage = true;
	ThisTag.atts.cols = 40;
	ThisTag.atts.rows = 8;
	ThisTag.atts.wrap = "";
	ThisTag.atts.qformmethods = "";
	ThisTag.atts.extensions = "";
	ThisTag.atts.urlpath = "";
	ThisTag.atts.defaultvalue = "";
	ThisTag.atts.value = "";
	ThisTag.atts.dbvalue = "";
	ThisTag.atts.setvalue = "";
	ThisTag.atts.isInSubFormCT = false;
	ThisTag.atts.urlvar = "";
	
	ThisTag.atts.subquery = "";
	ThisTag.atts.subtable = "";
	ThisTag.atts.subarray = "";
	ThisTag.atts.subvalues = "";
	ThisTag.atts.subdisplays = "";
	ThisTag.atts.subtitles = "";
	ThisTag.atts.subothers = "";
	ThisTag.atts.subselections = "";
	ThisTag.atts.defaultChecked = false;
	ThisTag.atts.fieldlist = "";
	ThisTag.atts.reltable = "";
	ThisTag.atts.relquery = "";
	ThisTag.atts.fktype = "";
	ThisTag.atts.fkdatatype = "";
	ThisTag.atts.topopt = "";
	ThisTag.atts.topoptvalue = "";
	ThisTag.atts.addlink = "";
	ThisTag.atts.link = "";
	ThisTag.atts.linktext = "";
	ThisTag.atts.deletable = "";
	ThisTag.atts.folder = "";
	ThisTag.atts.input_prefix = "";
	ThisTag.atts.input_suffix = "";
	ThisTag.atts.other = false;
	ThisTag.atts.requireother = false;
	ThisTag.atts.otherlabel = "Other";
	ThisTag.atts.otherfieldlabel = "Other";
	ThisTag.atts.DefaultValueOther = "";
	ThisTag.atts.isEditable = ParentAtts.isEditable;
	ThisTag.atts.minimize = ParentAtts.minimize;
	
	//Use "name" for fieldname
	if ( StructKeyExists(attributes,"name") AND Len(attributes.name) AND NOT StructKeyExists(attributes,"fieldname") ) {
		attributes.fieldname = attributes.name;
	}
	if ( StructKeyExists(attributes,"fieldname") AND Len(attributes.fieldname) AND NOT (StructKeyExists(attributes,"dbfield") AND Len(Trim(attributes.dbfield)) ) ) {
		attributes.dbfield = attributes.fieldname;
	}
	
	/* Default attributes from parent */
	if ( StructKeyExists(attributes,"dbfield") AND StructKeyExists(ParentAtts,"sFields") AND isStruct(ParentAtts.sFields) AND StructKeyExists(ParentAtts.sFields,attributes.dbfield) AND isStruct(ParentAtts.sFields[attributes.dbfield]) ) {
		for (att in ParentAtts.sFields[attributes.dbfield]) {
			if ( StructKeyExists(ParentAtts.sFields[attributes.dbfield],att) AND NOT ( StructKeyExists(attributes,"type") AND attributes.type EQ "select" AND att EQ "size" ) ) {
				ThisTag.atts[att] = ParentAtts.sFields[attributes.dbfield][att];
			}
		}
	}
	if ( isDefined("sSubFormAtts") ) {
		if ( StructKeyExists(attributes,"dbfield") AND StructKeyExists(sSubFormAtts,"sFields") AND isStruct(sSubFormAtts.sFields) AND StructKeyExists(sSubFormAtts.sFields,attributes.dbfield) AND isStruct(sSubFormAtts.sFields[attributes.dbfield]) ) {
			for (att in sSubFormAtts.sFields[attributes.dbfield]) {
				if ( NOT ( StructKeyExists(attributes,"type") AND attributes.type EQ "select" AND att EQ "size" ) ) {
					ThisTag.atts[att] = sSubFormAtts.sFields[attributes.dbfield][att];
				}
			}
		}	
	}
	
	if ( StructKeyExists(attributes,"dbfield") AND StructKeyExists(ParentData.Caller, "sebFields") AND StructKeyExists(ParentData.Caller.sebFields,attributes.dbfield) ) {
		StructAppend(attributes, ParentData.Caller.sebFields[attributes.dbfield], "no");
	}
	if ( StructKeyExists(attributes,"fieldname") AND StructKeyExists(ParentData.Caller, "sebFields") AND StructKeyExists(ParentData.Caller.sebFields,attributes.fieldname) ) {
		StructAppend(attributes, ParentData.Caller.sebFields[attributes.fieldname], "no");
	}
	if ( StructKeyExists(attributes,"id") AND StructKeyExists(ParentData.Caller, "sebFields") AND StructKeyExists(ParentData.Caller.sebFields,attributes.id) ) {
		StructAppend(attributes, ParentData.Caller.sebFields[attributes.id], "no");
	}
	if ( StructKeyExists(ParentData.Caller, "sebFieldAttributess") ) {
		StructAppend(attributes, ParentData.Caller.sebFieldAttributess, "no");
	}
	if ( StructKeyExists(attributes,"defaultAttributes")  ) {
		StructAppend(attributes, attributes.defaultAttributes, "no");
	}
	if ( StructKeyExists(attributes,"dbfield") AND StructKeyExists(request, "cftags") AND StructKeyExists(request.cftags, TagName) AND StructKeyExists(request.cftags[TagName],attributes.dbfield) ) {
		StructAppend(attributes, request.cftags[TagName][attributes.dbfield], "no");
	}
	if ( StructKeyExists(attributes,"fieldname") AND StructKeyExists(request, "cftags") AND StructKeyExists(request.cftags, TagName) AND StructKeyExists(request.cftags[TagName],attributes.fieldname) ) {
		StructAppend(attributes, request.cftags[TagName][attributes.fieldname], "no");
	}
	if ( StructKeyExists(request, "cftags") AND StructKeyExists(request.cftags, TagName) ) {
		StructAppend(attributes, request.cftags[TagName], "no");
	}
	if ( StructKeyExists(request, "cftags") AND StructKeyExists(request.cftags, "sebtags") ) {
		StructAppend(attributes, request.cftags["sebtags"], "no");
	}
	
	for (i=1; i lte ListLen(liHtmlAtts); i=i+1 ) {
		if ( NOT StructKeyExists(ThisTag.atts,ListGetAt(liHtmlAtts, i)) ) {
			ThisTag.atts[ListGetAt(liHtmlAtts, i)] = "";
		}
	}

	if ( NOT StructKeyExists(attributes,"type") ) {
		attributes.type = ThisTag.atts["type"];
	}
	
	//If no type is provided, attempt to determine one
	if ( NOT ( StructKeyExists(attributes,"type") AND Len(Trim(attributes.type)) ) ) {
		if ( StructKeyExists(attributes,"subvalues") AND Len(Trim(attributes.subvalues)) ) {
			attributes.type = "options";
		} else if (
				( StructKeyExists(ThisTag,"GeneratedContent") AND Len(ThisTag.GeneratedContent) )
			OR	( StructKeyExists(attributes,"GeneratedContent") AND Len(attributes.GeneratedContent) )
		) {
			attributes.type = "custom";
		} else {
			attributes.type = "text";
		}
	}
	if ( isDefined("attributes.type") AND ListFindNoCase(liNoNameNeeded, attributes.type) ) {
		liReqAtts = "";
	} else {
		liReqAtts = "fieldname";
	}
	
	if ( StructKeyExists(attributes,"type") AND StructKeyExists(ParentData.Caller, "sebFieldTypes") AND StructKeyExists(ParentData.Caller.sebFieldTypes,attributes.type) ) {
		StructAppend(attributes, ParentData.Caller.sebFieldTypes[attributes.type], "no");
	}
	if ( StructKeyExists(attributes,"type") AND StructKeyExists(request, "cftags") AND StructKeyExists(request.cftags, TagName) AND StructKeyExists(request.cftags[TagName],attributes.type) ) {
		StructAppend(attributes, request.cftags[TagName][attributes.type], "no");
	}
	
	//Copy atts back to standard attributes scope
	StructAppend(attributes, ThisTag.atts, "no");
	
	//Use "name" for fieldname
	if ( StructKeyExists(attributes,"name") AND Len(attributes.name) AND NOT Len(attributes.fieldname) ) {
		attributes.fieldname = attributes.name;
	}
	
	if ( StructKeyExists(attributes,"type") ) {
		if ( attributes.type EQ "integer" AND NOT ( StructKeyExists(attributes,"Length") AND isNumeric(attributes.Length) AND attributes.Length GT 0 AND attributes.Length LT 10 ) ) {
			attributes.Length = 9;
		}
		
		if ( ( attributes.type EQ "decimal" OR attributes.type EQ "money" ) AND NOT ( StructKeyExists(attributes,"Length") AND isNumeric(attributes.Length) AND attributes.Length GT 0 AND attributes.Length LT 10 ) ) {
			attributes.Length = 9;
		}
		
		if ( attributes.type EQ "image" ) {
			attributes.type = "file";
			attributes.accept = "image/png,image/x-png,image/gif,image/jpg,image/jpeg,image/pjpeg";
			attributes.extensions = "jpg,gif,png";
		}
		
		if ( attributes.type EQ "money" ) {
			attributes.type = "text";
			attributes.stripregex = "[^\-\d\.]";
			if ( NOT Len(attributes.input_prefix) ) {
				attributes.input_prefix = "$";
			}
			/*
			function fMask_Money(str) {
				result = arguments.str;
				if ( isNumeric(result) ) {
					result = "$#DecimalFormat(str)#"; 
				}
				return result;
			}
			attributes.fMask = fMask_Money;
			*/
		}
		
		if ( attributes.type EQ "date" AND StructKeyExists(sForm,attributes.fieldname) ) {
			// Fix in case user enters date as only numbers (ex 01192011 for "January 19, 2011")
			if ( Len(sForm[attributes.fieldname]) EQ 8 AND Right(sForm[attributes.fieldname],4) GT 1900 AND Right(sForm[attributes.fieldname],4) LT Year(now()) + 1000 ) {
				sForm[attributes.fieldname] = "#Left(sForm[attributes.fieldname],2)#/#Mid(sForm[attributes.fieldname],3,2)#/#Right(sForm[attributes.fieldname],4)#";
			}
		}
		
		if ( attributes.type EQ "email" ) {
			attributes.stripregex = " ";
		}
		
		if ( attributes.type EQ "integer" OR attributes.type EQ "decimal" ) {
			attributes.stripregex = "[ ,]+";
		}
		
		if ( isDefined("attributes.type") AND ListFindNoCase(StructKeyList(ParentAtts.validations),attributes.type) ) {
			attributes.validationtype = attributes.type;
			attributes.regex = ParentAtts.validations[attributes.type];
			attributes.type = "text";
		}
	}
	
	if ( ( StructKeyExists(attributes,"folder") AND Len(attributes.folder) ) OR ( isDefined("attributes.type") AND attributes.type eq "file" ) ) {
		liReqAtts = ListAppend(liReqAtts, "destination");
		liReqAtts = ListAppend(liReqAtts, "nameconflict");
		DirDelim = CreateObject("java", "java.io.File").separator;
		/* If thumbfield is passed, get thumbfolder */
		if ( StructKeyExists(attributes,"thumbfield") AND Len(attributes.thumbfield) ) {
			if ( NOT ( StructKeyExists(attributes,"thumbfolder") AND Len(attributes.thumbfolder) ) ) {
				if ( StructKeyExists(ParentAtts.sFields,attributes.thumbfield) AND StructKeyExists(ParentAtts.sFields[attributes.thumbfield],"folder") ) {
					attributes.thumbfolder = ParentAtts.sFields[attributes.thumbfield]["folder"];
				}
			}
		}
		if ( Len(ParentAtts.UploadFilePath) AND Len(ParentAtts.UploadBrowserPath) ) {
			if ( StructKeyExists(attributes,"folder") AND Len(attributes.folder) ) {
				attributes.folder = ListChangeDelims(attributes.folder,",","/");
				attributes.folder = ListChangeDelims(attributes.folder,",","\");
				/* Set destination and url path from folder and form settings */
				if ( Right(ParentAtts.UploadFilePath,1) NEQ DirDelim ) {
					ParentAtts.UploadFilePath = "#ParentAtts.UploadFilePath##DirDelim#";
				}
				if ( Right(ParentAtts.UploadBrowserPath,1) NEQ "/" ) {
					ParentAtts.UploadBrowserPath = "#ParentAtts.UploadBrowserPath#/";
				}
				if ( NOT ( StructKeyExists(attributes,"destination") AND Len(attributes.destination) ) ) {
					attributes.destination = "#ParentAtts.UploadFilePath##ListChangeDelims(attributes.folder,DirDelim,',')#";
				}
				if ( NOT ( StructKeyExists(attributes,"urlpath") AND Len(attributes.urlpath) ) ) {
					attributes.urlpath = "#ParentAtts.UploadBrowserPath##ListChangeDelims(attributes.folder,'/',',')#";
				}
			}
			if ( StructKeyExists(attributes,"thumbfolder") AND Len(attributes.thumbfolder) ) {
				attributes.thumbfolder = ListChangeDelims(attributes.thumbfolder,",","\");
				attributes.thumbfolder = ListChangeDelims(attributes.thumbfolder,"/",",");
				attributes.thumbpath = "#ParentAtts.UploadBrowserPath##attributes.thumbfolder#/";
			}
		}
		if ( StructKeyExists(attributes,"destination") AND Len(attributes.destination) AND Right(attributes.destination,1) NEQ DirDelim ) {
			attributes.destination = attributes.destination & DirDelim;
		}
		if ( StructKeyExists(attributes,"urlpath") AND Len(attributes.urlpath) AND Right(attributes.urlpath,1) NEQ "/" ) {
			attributes.urlpath = attributes.urlpath & "/";
		}
	}
	
	/* Get data from component */
	if ( StructKeyExists(attributes,"subcomp") AND StructKeyExists(ParentAtts,"CFC_Component") AND NOT StructKeyExists(attributes,"CFC_Component") ) {
		if ( StructKeyExists(ParentAtts.CFC_Component,attributes.subcomp) AND isObject(ParentAtts.CFC_Component[attributes.subcomp]) ) {
			attributes.CFC_Component = ParentAtts.CFC_Component[attributes.subcomp];
		} else if ( StructKeyExists(ParentAtts.CFC_Component,"getParentComponent") AND isObject(ParentAtts.CFC_Component.getParentComponent()) ) {
			oParent = ParentAtts.CFC_Component.getParentComponent();
			if ( isDefined("oParent") AND StructKeyExists(oParent,attributes.subcomp) AND isObject(oParent[attributes.subcomp]) ) {
				attributes.CFC_Component = oParent[attributes.subcomp];
			}
		} 
	}
	</cfscript>
	<cfif
			isDefined("attributes.CFC_Component")
		AND (
					StructKeyExists(attributes.CFC_Component,"getMetaStruct")
				OR	getMetaData(attributes.CFC_Component).extends.name CONTAINS "_framework.PageController"
				OR	getMetaData(attributes.CFC_Component).extends.name CONTAINS "Master"
			)
	>
		<cftry>
			<cfset sCompMeta = attributes.CFC_Component.getMetaStruct()>
		<cfcatch>
		</cfcatch>
		</cftry>
		<cfscript>
		if ( isDefined("sCompMeta") AND isStruct(sCompMeta) ) {
			if ( StructKeyExists(sCompMeta,"method_gets") AND NOT StructKeyExists(attributes,"CFC_Method") ) {
				attributes.CFC_Method = sCompMeta.method_gets;
			} 
			if ( StructKeyExists(sCompMeta,"arg_pk") AND NOT Len(attributes.subvalues) ) {
				attributes.subvalues = sCompMeta.arg_pk;
			} 
			if ( StructKeyExists(sCompMeta,"field_label") AND NOT Len(attributes.subdisplays) ) {
				attributes.subdisplays = sCompMeta.field_label;
			} 
		}
		</cfscript>
	</cfif>
	<!---<cfif StructKeyExists(attributes,"subcomp")><cfdump var="#attributes#" ><cfdump var="#ParentAtts#" ><cfabort></cfif>--->
	<!--- Check for required attributes ---><cfif Len(liReqAtts)><cfloop index="thisReqAtt" list="#liReqAtts#"><cfif NOT Len(attributes[thisReqAtt])><cfthrow message="#thisReqAtt# is a required attribute for #TagName#" type="cftag"></cfif></cfloop></cfif>
	<cfscript>
	if ( Len(attributes.id) eq 0 ) {
		attributes.id = attributes.fieldname;
	}
	
	if ( (attributes.type eq "text" OR attributes.type eq "password") AND NOT Len(attributes.length) ) {
		attributes.length = 50;
	}
	
	if ( (attributes.type neq "select") AND Len(attributes.length) AND NOT Len(attributes.size) ) {
		attributes.size = attributes.length;
	}
	
	if ( Len(attributes.dbfield) eq 0 ) {
		attributes.dbfield = attributes.fieldname;
	}
	
	if ( Len(attributes.label) eq 0 ) {
		attributes.label = attributes.fieldname;
	}
	
	if ( Len(attributes.title) eq 0 ) {
		attributes.title = attributes.label;
	}
	
	if ( NOT isBoolean(attributes.required) ) {
		attributes.required = false;
	}
	
	if ( NOT isBoolean(attributes.isnullable) ) {
		attributes.isnullable = true;
	}
	if ( Len(attributes.subvalues) AND NOT Len(attributes.subdisplays) ) {
		attributes.subdisplays = attributes.subvalues;
	}
	attributes.hasOtherOption = false;
	attributes.numOtherOptions = 0;
	
	//Fix fieldname to be valid for HTML/JS
	attributes.fieldname = ReplaceNoCase(attributes.fieldname,"-","_","ALL");
	if ( isNumeric(Left(attributes.fieldname,1)) ) {
		attributes.fieldname = "A#attributes.fieldname#";
	}
	
	if ( Len(attributes.urlvar) AND StructKeyExists(URL,attributes.urlvar) AND NOT Len(attributes.defaultValue) ) {
		attributes.defaultValue = URL[attributes.urlvar];
	}
	
	if ( Len(attributes.setvalue) ) {
		attributes.value = Trim(attributes.setvalue);
	} else {
		if ( Len(attributes.fieldname) ) {
			if ( ParentAtts.qFormData.RecordCount ) {
				if ( ListFindNoCase(ParentAtts.qFormData.ColumnList, attributes.dbfield) AND isSimpleValue(ParentAtts.qFormData[attributes.dbfield][1]) ) {
					attributes.value = ParentAtts.qFormData[attributes.dbfield][1];
				} else {
					attributes.value = attributes.defaultvalue;
				}
			} else {
				attributes.value = attributes.defaultvalue;
			}
			attributes.dbvalue = attributes.value;
			if ( StructKeyExists(sForm,attributes.fieldname) AND Len(sForm[attributes.fieldname]) AND attributes.type neq "file" ) {
				attributes.value = sForm[attributes.fieldname];
			}
		}
	}
	
	attributes.ValueOther = "";
	if ( NOT StructKeyExists(attributes,"OtherField") ) {
		attributes.OtherField = "#attributes.fieldname#_other";
	}
	if ( StructKeyExists(attributes,"setValueOther") AND Len(attributes.setvalueother) ) {
		attributes.ValueOther = Trim(attributes.setValueOther);
	} else {
		if ( Len(attributes.fieldname) AND StructKeyExists(attributes,"OtherField") AND Len(attributes.OtherField) ) {
			if ( ParentAtts.qFormData.RecordCount ) {
				if ( ListFindNoCase(ParentAtts.qFormData.ColumnList, attributes.OtherField) AND isSimpleValue(ParentAtts.qFormData[attributes.OtherField][1]) ) {
					attributes.ValueOther = ParentAtts.qFormData[attributes.OtherField][1];
				} else {
					attributes.ValueOther = attributes.defaultValueOther;
				}
			} else {
				attributes.ValueOther = attributes.defaultValueOther;
			}
			attributes.dbvalue = attributes.value;
			if ( StructKeyExists(sForm,attributes.OtherField) AND Len(sForm[attributes.OtherField]) AND attributes.type NEQ "file" ) {
				attributes.ValueOther = sForm[attributes.OtherField];
			}
		}
	}
	/*
	if ( Len(attributes.dbvalue) AND attributes.type eq "password" AND Len(attributes.value) ) {
		if ( Trim(attributes.value) neq Left(Hash(attributes.dbvalue), Len(attributes.dbvalue)) ) {
			attributes.value = Left(Hash(attributes.value), Len(attributes.value));
		}		
	}
	*/
	//For related table, set datatype for foreign key field (default to pktype for table)
	if ( Len(attributes.reltable) OR Len(attributes.relquery) ) {
		//foreign key type defaults to same as primary key type
		if ( NOT Len(attributes.fktype) ) {
			attributes.fktype = ParentAtts.pktype;
		}
		//If cfdatatype is specified, use that for foreign key datatype
		if ( Len(attributes.cfdatatype) AND NOT Len(attributes.fkdatatype) ) {
			attributes.fkdatatype = attributes.cfdatatype;
		}
		//If still not foreign key datatype, determine from foreign key type.
		if ( NOT Len(attributes.fkdatatype) ) {
			if ( attributes.fktype eq "GUID"  ) {
				attributes.fkdatatype = "CF_SQL_IDSTAMP";
			} else {
				attributes.fkdatatype = "CF_SQL_INTEGER";
			}
		}
	}
	
	//If no deletable attribute is set here, then check the form tag
	if ( attributes.type eq "submit/cancel/delete" AND StructKeyExists(ParentAtts,"isDeletable") AND NOT Len(attributes.deletable) ) {
		attributes.deletable = ParentAtts.isDeletable;
	}
	
	//If this is a component-driven form with no delete method, then just use submit/cancel
	if ( attributes.type eq "submit/cancel/delete" ) {
		if (
					StructKeyExists(ParentAtts,"CFC_Component")
				AND	StructKeyExists(ParentAtts,"CFC_Method")
				AND	Len(ParentAtts.CFC_Method)
				AND	NOT (
							StructKeyExists(ParentAtts,"CFC_DeleteMethod")
						AND	Len(ParentAtts.CFC_DeleteMethod)
					)
		) {
			attributes.deletable = false;
		}
	}
	
	//If this is a non-deletable record, just use submit/cancel
	if ( attributes.type EQ "submit/cancel/delete" AND Len(attributes.deletable) AND NOT isBoolean(attributes.deletable) ) {
		attributes.deletable = ParentData.doShow(ParentAtts.qFormData,attributes.deletable,1);
		/*
		if ( Left(attributes.deletable,1) eq "!" ) {
			attributes.deletable = ReplaceNoCase(attributes.deletable,"!","","ONE");
			if ( ParentAtts.qFormData.RecordCount AND ListFindNoCase(ParentAtts.qFormData.ColumnList, attributes.deletable) ) {
				attributes.deletable = NOT ParentAtts.qFormData[attributes.deletable][1];
			}
		} else {
			if ( ParentAtts.qFormData.RecordCount AND ListFindNoCase(ParentAtts.qFormData.ColumnList, attributes.deletable) ) {
				attributes.deletable = ParentAtts.qFormData[attributes.deletable][1];
			}
		}
		*/
	}
	if ( attributes.type EQ "submit/cancel/delete" AND isBoolean(attributes.deletable) AND NOT attributes.deletable ) {
		attributes.type = "submit/cancel";
	}
	
	if ( attributes.type EQ "submit/cancel/delete" OR attributes.type EQ "submit/cancel" OR attributes.type EQ "submit" ) {
		if ( ListLen(attributes.label) lt 1 ) {
			attributes.label = ListAppend(attributes.label,ListGetAt(ParentAtts.SubmitBarLabels,1));
		}
		if ( attributes.type CONTAINS "cancel" AND ListLen(attributes.label) lt 2 ) {
			attributes.label = ListAppend(attributes.label,ListGetAt(ParentAtts.SubmitBarLabels,2));
		}
		if ( attributes.type CONTAINS "delete" AND ListLen(attributes.label) lt 3 ) {
			attributes.label = ListAppend(attributes.label,ListGetAt(ParentAtts.SubmitBarLabels,3));
		}
	}
	
	if ( StructKeyExists(attributes,"class") AND Len(attributes.class) ) {
		attributes.class = "#attributes.class# #attributes.type#";
	} else {
		attributes.class = "#attributes.type#";
	}
	if ( ListFindNoCase(LiErrFields,attributes.fieldname) ) {
		attributes.class = "#attributes.class# err";
	}
	attributes.value = ParentData.masky(attributes.value);

	attributes.display = attributes.value;
	//attributes.GeneratedContent = "";
	
	if ( NOT StructKeyExists(attributes,"isRequiredOnServer") ) {
		attributes.isRequiredOnServer = attributes.required;
	}
	
	attributes.isRequiredOnServerForGroup = attributes.required;
	if ( attributes.isRequiredOnServer ) {
		//File isn't required if locked or has value already
		if ( attributes.type EQ "file" AND (attributes.locked OR Len(attributes.value)) ) {
			attributes.isRequiredOnServer = false;
			attributes.isRequiredOnServerForGroup = false;
		}
		//Don't require fields in group if it is tied to a field that is being passed
		if ( isDefined("sGroupAtts") AND sGroupAtts.isFKField ) {// AND StructKeyExists(sForm,sGroupAtts.fkfield) AND Len(Trim(sForm[sGroupAtts.fkfield]))
			attributes.isRequiredOnServer = false;
		}
		if ( StructKeyExists(ParentData,"sEffectiveHasDataFields") AND isStruct(ParentData.sEffectiveHasDataFields) AND StructKeyExists(ParentData.sEffectiveHasDataFields,attributes.fieldname) ) {
			attributes.isRequiredOnServer = false;
		}
	}
	
	if ( NOT (StructKeyExists(attributes,"showtopopt") AND isBoolean(attributes.showtopopt) ) ) {
		if ( attributes.multiple IS true ) {
			attributes.showtopopt = false;
		} else {
			attributes.showtopopt = true;
		}
	}
	
	ParentData["fieldlist"] = ListAppend(ParentData["fieldlist"],attributes.fieldname);
	</cfscript>
	<!--- Make sure not to update a password field if is unchanged (based on Hash) --->
	
	<cfif ListFindNoCase(liSubFieldTypes, attributes.type) AND NOT isDefined("ThisTag.qSubFields")>
		<cfif Len(attributes.reltable)>
			<cftry>
				<cfquery name="qreltable" datasource="#ParentAtts.datasource#">SELECT #attributes.subvalues# AS fkfield FROM #attributes.reltable# WHERE #ParentAtts.pkfield# = <cfqueryparam value="#ParentAtts.recordid#" cfsqltype="#ParentAtts.datatype#"></cfquery>
				<cfcatch><cfset qreltable = QueryNew('fkfield')></cfcatch>
			</cftry>
			<cfif NOT Len(attributes.value)><cfset attributes.value = ValueList(qreltable.fkfield)></cfif>
		</cfif>
		<cfif Len(attributes.relquery) AND isDefined("ParentData.Caller.#attributes.relquery#") AND isQuery(ParentData.Caller[attributes.relquery])>
			<cfset qreltable = ParentData.Caller[attributes.relquery]>
			<cfif ListFindNoCase(qreltable.ColumnList,attributes.subvalues) AND NOT ListFindNoCase(qreltable.ColumnList,"fkfield")>
				<cfquery name="qreltable" dbtype="query">
				SELECT	#attributes.subvalues# AS fkfield
				FROM	qreltable
				</cfquery>
			</cfif>
			<cfif NOT Len(attributes.value)><cfset attributes.value = ValueList(qreltable.fkfield)></cfif>
		</cfif>
		<cfscript>
		attributes.hasOtherOption = false;
		attributes.numOtherOptions = 0;
		ThisTag.qSubFields = ArrayNew(1);
		/*
		if ( attributes.type eq "select" AND attributes.size lte 1 ) {
			ArrayAppend(ThisTag.qSubFields,StructNew());
			ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].value = "";
			ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].display = "";
			ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].checked = false;
		}
		*/
		</cfscript>
		<cfif StructKeyExists(attributes,"CFC_Component") AND isObject(attributes.CFC_Component) AND StructKeyExists(attributes,"CFC_Method") AND Len(attributes.CFC_Method) AND NOT Len(attributes.subquery)>
			<cfif NOT StructKeyExists(attributes,"CFC_GetArgs")>
				<cfset attributes.CFC_GetArgs = StructNew()>
			</cfif>
			<cfif NOT ListFindNoCase(attributes.fieldlist,attributes.subvalues)>
				<cfset attributes.fieldlist = ListAppend(attributes.fieldlist,attributes.subvalues)>
			</cfif>
			<cfif NOT ListFindNoCase(attributes.fieldlist,attributes.subdisplays)>
				<cfset attributes.fieldlist = ListAppend(attributes.fieldlist,attributes.subdisplays)>
			</cfif>
			<cfif NOT ListFindNoCase(attributes.fieldlist,attributes.subdisplays)>
				<cfset attributes.fieldlist = ListAppend(attributes.fieldlist,attributes.subdisplays)>
			</cfif>
			<cfif Len(attributes.subtitles) AND NOT ListFindNoCase(attributes.fieldlist,attributes.subtitles)>
				<cfset attributes.fieldlist = ListAppend(attributes.fieldlist,attributes.subtitles)>
			</cfif>
			<cfif Len(attributes.subselections) AND NOT ListFindNoCase(attributes.fieldlist,attributes.subselections)>
				<cfset attributes.fieldlist = ListAppend(attributes.fieldlist,attributes.subselections)>
			</cfif>
			<cfif NOT StructKeyExists(attributes.CFC_GetArgs,"fieldlist")>
				<cfset attributes.CFC_GetArgs.fieldlist = attributes.fieldlist>
			</cfif>
			<cfinvoke returnvariable="qSubQuery" component="#attributes.CFC_Component#" method="#attributes.CFC_Method#" argumentcollection="#attributes.CFC_GetArgs#">
		</cfif>
		<cfif isQuery(attributes.subquery)>
			<cfset qSubQuery = attributes.subquery>
			<cfset attributes.subquery = "">
		</cfif>
		<cfif Len(attributes.subquery) OR ( isDefined("qSubQuery") AND isQuery(qSubQuery) )>
			<cfif NOT Len(attributes.subvalues)><cfthrow message="&lt;#TagName#&gt; The subvalues attribute must be a valid column name in the #attributes.subquery# query" type="cftag"></cfif>
			<cfif NOT ( isDefined("qSubQuery") AND isQuery(qSubQuery) )>
				<cfset qSubQuery = Evaluate("ParentData.Caller.#attributes.subquery#")>
			</cfif>
			<cfloop query="qSubQuery">
				<cfscript>
				ArrayAppend(ThisTag.qSubFields,StructNew());
				ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].value = qSubQuery[attributes.subvalues][CurrentRow];
				if ( isDate(qSubQuery[attributes.subdisplays][CurrentRow]) AND qSubQuery[attributes.subdisplays][CurrentRow] GT "January 1, 1980" AND qSubQuery[attributes.subdisplays][CurrentRow] GT 1 ) {
					ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].display = DateFormat(qSubQuery[attributes.subdisplays][CurrentRow],"m/dd/yyyy");
				} else {
					ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].display = qSubQuery[attributes.subdisplays][CurrentRow];
				}
				if ( Len(attributes.subtitles) ) {
					ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].title = qSubQuery[attributes.subtitles][CurrentRow];
				}
				if ( Len(attributes.subothers) ) {
					ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].other = qSubQuery[attributes.subothers][CurrentRow];
				} else {
					ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].other = false;
				}
				//ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].checked = false;
				if ( Len(attributes.subselections) AND Len(attributes.value) EQ 0 AND ListFindNoCase(qSubQuery.ColumnList,attributes.subselections) AND isBoolean(qSubQuery[attributes.subselections][CurrentRow]) ) {
					ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].checked = qSubQuery[attributes.subselections][CurrentRow];
				} else {
					ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].checked = attributes.defaultChecked;
				}
				/*
				if ( ListFindNoCase(attributes.value, qSubQuery[attributes.subvalues][CurrentRow]) ) {
					ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].checked = true;
					attributes.display = ListAppend(attributes.display,ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].value);
				} else {
					ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].checked = attributes.defaultChecked;
				}
				*/
				</cfscript>
			</cfloop>
		<cfelseif Len(attributes.subtable) AND Len(ParentAtts.datasource)>
			<cfquery name="qsubtable" datasource="#ParentAtts.datasource#">
			SELECT		#attributes.subvalues# AS subvalue
						<cfif attributes.subvalues NEQ attributes.subdisplays>, #attributes.subdisplays# AS subdisplay</cfif>
						<cfif Len(Trim(attributes.subtitles))>, #attributes.subtitles# AS subtitle</cfif>
						<cfif Len(Trim(attributes.subothers))>, #attributes.subothers# AS subother</cfif>
						<cfif Len(Trim(attributes.subselections))>, #attributes.subselections# AS subselections</cfif>
			FROM		#attributes.subtable#
			ORDER BY	#attributes.subdisplays#
			</cfquery>
			<cfloop query="qsubtable">
			<cfscript>
			ArrayAppend(ThisTag.qSubFields,StructNew());
			ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].value = qsubtable["subvalue"][CurrentRow];
			if ( attributes.subvalues EQ attributes.subdisplays ) {
				ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].display = qsubtable["subvalue"][CurrentRow];
			} else {
				ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].display = qsubtable["subdisplay"][CurrentRow];
			}
			if ( Len(attributes.subtitles) ) {
				ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].title = qsubtable["subtitle"][CurrentRow];
			}
			if ( Len(attributes.subothers) ) {
				ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].other = qsubtable["subother"][CurrentRow];
			} else {
				ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].other = false;
			}
			ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].checked = attributes.defaultChecked;
			if ( Len(attributes.subselections) AND Len(attributes.value) EQ 0 AND ListFindNoCase(qsubtable.ColumnList,attributes.subselections) AND isBoolean(qsubtable[attributes.subselections][CurrentRow]) ) {
				ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].checked = qsubtable[attributes.subselections][CurrentRow];
			} else {
				ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].checked = attributes.defaultChecked;
			}
			/*
			if ( ListFindNoCase(attributes.value, qsubtable["subvalue"][CurrentRow]) ) {
				ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].checked = true;
				attributes.display = ListAppend(attributes.display,ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].value);
			} else {
				ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].checked = attributes.defaultChecked;
			}
			*/
			</cfscript>
			</cfloop>
		<cfelseif structKeyExists(attributes, "subarray") and ((isSimpleValue(attributes.subarray) and len(attributes.subarray) gt 0) or (isArray(attributes.subarray) and arrayLen(attributes.subarray) gt 0))>
			<cfif isSimpleValue(attributes.subarray)>
				<cfif not isDefined("ParentData.caller." & attributes.subarray)>
					<cfthrow message="&lt;#TagName#&gt; The specified subarray (#attributes.subarray#) was not found in the caller's variable scope." type="cftag">
				</cfif>
				<cfset attributes.subarray = evaluate("ParentData.caller." & attributes.subarray) />
			</cfif>
			<cfif arrayLen(attributes.subarray) eq 0>
				<cfthrow message="&lt;#TagName#&gt; The specified subarray was empty." type="cftag">
			</cfif>
			<cfif not structKeyExists(attributes, "subvalues")>
				<cfthrow message="&lt;#TagName#&gt; The subvalues attribute must be defined when using a subarray." type="cftag">
			</cfif>
			<cfif len(attributes.subvalues) eq 0>
				<cfthrow message="&lt;#TagName#&gt; The subvalues attribute must identify the key name within the array of structures." type="cftag">
			</cfif>
			<cfif len(attributes.subdisplays) eq 0>
				<cfset attributes.subdisplays = attributes.subvalues />
			</cfif>
			<cfloop from="1" to="#arrayLen(attributes.subarray)#" index="i">
				<cfset arrayAppend(ThisTag.qSubFields, structNew()) />
				<cfset ThisTag.qSubFields[arrayLen(ThisTag.qSubFields)].value = attributes.subarray[i][attributes.subvalues] />
				<cfset ThisTag.qSubFields[arrayLen(ThisTag.qSubFields)].display = attributes.subarray[i][attributes.subdisplays] />
				<cfif Len(attributes.subtitles)>
					<cfset ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].title = attributes.subarray[i][attributes.subtitles]>
				</cfif>
				<cfif Len(attributes.subothers)>
					<cfset ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].other = attributes.subarray[i][attributes.subothers]>
				<cfelse>
					<cfset ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].other = false>
				</cfif>
				<cfset ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].checked = attributes.defaultChecked />
				<cfif Len(attributes.subselections) AND Len(attributes.value) EQ 0 AND StructKeyExists(attributes.subarray[i],attributes.subselections) AND isBoolean(attributes.subarray[i][attributes.subselections])>
					<cfset ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].checked = attributes.subarray[i][attributes.subselections]>
				<cfelse>
					<cfset ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].checked = attributes.defaultChecked>
				</cfif>
			</cfloop>
		<cfelseif Len(attributes.subvalues)>
			<cfif ListLen(attributes.subvalues) neq ListLen(attributes.subdisplays)>
				<cfthrow message="&lt;#TagName#&gt; You must have the same number of subvalues and subdisplays." type="cftag">
			</cfif>
			<cfscript>
			for (i=1; i lte ListLen(attributes.subvalues); i=i+1) {
				ArrayAppend(ThisTag.qSubFields,StructNew());
				ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].value = ListGetAt(attributes.subvalues,i);
				ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].display = ListGetAt(attributes.subdisplays,i);
				if ( Len(attributes.subtitles) ) {
					ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].title = ListGetAt(attributes.subtitles,i);
				}
				if ( Len(attributes.subothers) ) {
					ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].other = ListGetAt(attributes.subothers,i);
				} else {
					ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].other = false;
				}
				ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].checked = attributes.defaultChecked;
				if ( Len(attributes.subselections) AND Len(attributes.value) EQ 0 AND ListFindNoCase(attributes.subselections,ListGetAt(attributes.subvalues,i)) ) {
					ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].checked = true;
				} else {
					ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].checked = attributes.defaultChecked;
				}
				/*
				if ( ListFindNoCase(attributes.value, ListGetAt(attributes.subvalues,i))  ) {
					ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].checked = true;
					attributes.display = ListAppend(attributes.display,ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].value);
				} else {
					ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].checked = attributes.defaultChecked;
				}
				*/
			}
			</cfscript>
		<!--- <cfelse>
			<cfthrow message="&lt;#TagName#&gt; must include cf_sebSubfield tags or a subquery or subtable or subvalues attribute." type="cftag"> --->
		</cfif>
	</cfif>
	<cfif ListFindNoCase(liSubFieldTypes, attributes.type)>
		<!--- Add "other" option --->
		<cfif StructKeyExists(ThisTag,"qSubFields") AND attributes.other IS true>
			<cfscript>
			ArrayAppend(ThisTag.qSubFields,StructNew());
			ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].value = "SebFormOtherValue";
			ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].display = attributes.otherlabel;
			ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].title = attributes.otherlabel;
			ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].checked = false;
			ThisTag.qSubFields[ArrayLen(ThisTag.qSubFields)].other = true;
			</cfscript>
		</cfif>
		<cfif attributes.type EQ "options">
			<cfif ArrayLen(ThisTag.qSubFields) GT 5>
				<cfset attributes.type = "select">
			<cfelseif ArrayLen(ThisTag.qSubFields) EQ 1 AND ( attributes.required EQ true OR attributes.defaultValue EQ ThisTag.qSubFields[1].value )>
				<cfset attributes.type = "hidden">
				<cfset attributes.setValue = ThisTag.qSubFields[1].value>
				<cfset attributes.value = ThisTag.qSubFields[1].value>
			<cfelseif StructKeyExists(attributes,"multiple") AND attributes.multiple IS true>
				<cfset attributes.type = "checkbox">
			<cfelse>
				<cfset attributes.type = "radio">
			</cfif>
		</cfif>
		<cfscript>
		hasSubOtherChecked = false;
		for (i=1; i lte ArrayLen(ThisTag.qSubFields); i=i+1) {
			if ( ListFindNoCase(attributes.value, ThisTag.qSubFields[i].value)  ) {
				ThisTag.qSubFields[i].checked = true;
				if ( StructKeyExists(ThisTag.qSubFields[i],"other") AND ThisTag.qSubFields[i].other IS true ) {
					hasSubOtherChecked = true;
				}
			}
			if ( StructKeyExists(ThisTag.qSubFields[i],"other") AND ThisTag.qSubFields[i].other IS true ) {
				attributes.hasOtherOption = true;
				attributes.numOtherOptions = attributes.numOtherOptions + 1;
				ParentAtts.hasOtherFields = true;
			}
		}
		//If field has "other" field and "other" data is provided, added "other" field must be the one checked
		i = ArrayLen(ThisTag.qSubFields);
		if (
				attributes.other IS true
			AND	StructKeyExists(ThisTag.qSubFields[i],"other")
			AND	ThisTag.qSubFields[i].other IS true
			AND	Len(attributes.ValueOther) GT 0
			AND	NOT hasSubOtherChecked
		) {
			ThisTag.qSubFields[i].checked = true;
		}
		</cfscript>
		<cfif attributes.minimize IS true AND NOT Len(attributes.addlink)>
			<cfif NOT ArrayLen(ThisTag.qSubFields)>
				<cfset attributes.type = "none">
			<cfelseif attributes.required AND ArrayLen(ThisTag.qSubFields) EQ 1 AND ThisTag.qSubFields[1].other NEQ true>
				<cfset attributes.type = "hidden">
				<cfset attributes.defaultValue = ThisTag.qSubFields[1].value>
				<cfset attributes.setValue = ThisTag.qSubFields[1].value>
				<cfset attributes.value = ThisTag.qSubFields[1].value>
			</cfif>
		</cfif>
	</cfif>
	
	<cfif StructKeyExists(ThisTag,"qSubFields")>
		<cfset attributes.qSubFields = ThisTag.qSubFields>
	</cfif>
	
	<cfif NOT StructKeyExists(ThisTag.config.Fields,"all")>
		<cfsavecontent variable="ThisTag.config.fields.all"><cfoutput>[Input]</cfoutput></cfsavecontent>
	</cfif>

	<cfif ParentAtts.altertable AND NOT Len(attributes.dbdatatype) AND NOT ListFindNoCase(liNoNameNeeded, attributes.type)>
		<cfthrow message="&lt;#TagName#&gt;: dbdatatype is required if altertable attribute of &lt;#ParentTag#&gt; is true." type="cftag">
	</cfif>
	<cfif ParentAtts.altertable AND NOT isNumeric(attributes.length) AND ListFindNoCase("text,memo,varchar,longcarchar", attributes.dbdatatype)>
		<cfthrow message="&lt;#TagName#&gt;: length is required for text datatypes if altertable attribute of &lt;#ParentTag#&gt; is true." type="cftag">
	</cfif>
	
	</cfsilent><cfoutput><cfsilent>
	
	<cfset thisInput = "">
	
	<!--- <cfif attributes.type eq "hidden">
		<cfsavecontent variable="input"><input type="hidden" name="#attributes.fieldname#"<cfif Len(attributes.id)> id="#attributes.id#"</cfif> value="#attributes.value#"/></cfsavecontent>
		<cfset thisInput = input>
		<cfset thisInput = "">
	<cfelse> --->
	
	<cfset input = "">
	<cfswitch expression="#attributes.type#">
	
	<cfcase value="hidden"><cfset input = ""><cfset thisInput = ""></cfcase>
	<cfcase value="none"><cfset input = ""><cfset thisInput = ""></cfcase>

	<cfcase value="text">
		<cfsavecontent variable="input"><cfif attributes.isEditable IS false>#HTMLEditFormat(attributes.value)#<cfelse><input type="text" name="#attributes.fieldname#"<cfif Len(attributes.id)> id="#attributes.id#"</cfif> value="#HTMLEditFormat(attributes.value)#"<cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt])> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop><cfif Len(attributes.length)> maxlength="#attributes.length#"</cfif>/></cfif></cfsavecontent>
	</cfcase>
	
	<cfcase value="button">
		<cfsavecontent variable="input"><cfif attributes.isEditable IS false><input type="button" value="#attributes.label#"<cfif Len(attributes.fieldname)> name="#attributes.fieldname#"</cfif><cfif Len(attributes.id)> id="#attributes.id#"</cfif><cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt])> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop>/></cfif></cfsavecontent>
	</cfcase>
	
	<cfcase value="plaintext">
		<cfset attributes.help = "">
		<cfsavecontent variable="input"><div id="#attributes.id#-div" class="sebPlainText"<cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt])> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop>><span id="#attributes.id#-val">#HTMLEditFormat(attributes.value)#</span><input type="hidden" id="#attributes.id#" name="#attributes.fieldname#" value="#HTMLEditFormat(attributes.value)#"/></div></cfsavecontent>
	</cfcase>
	
	<cfcase value="file">
		<cfif
				StructKeyExists(attributes,"thumbfield")
			AND	Len(attributes.thumbfield)
			AND	ListFindNoCase(ParentAtts.qFormData.ColumnList,attributes.thumbfield)
			AND Len(ParentAtts.qFormData[attributes.thumbfield][1])
		>
			<cfset imgPath = "#attributes.thumbpath##ParentAtts.qFormData[attributes.thumbfield][1]#">
		<cfelse>
			<cfset imgPath = "#attributes.urlpath##GetFileFromPath(attributes.value)#">
		</cfif>
		
		<cfif attributes.locked OR attributes.isEditable IS false>
			<cfif Len(attributes.value) AND FileExists("#attributes.destination##attributes.value#")>
				<cfif ListFindNoCase("gif,jpg,png", ListLast(attributes.value, ".")) AND attributes.showImage>
					<cfsavecontent variable="input"><input type="hidden" name="#attributes.fieldname#" value=""/><cfif attributes.showFile><img src="#imgPath#" alt="#attributes.label#" class="sebField-image"></cfif></cfsavecontent>
				<cfelse>
					<cfsavecontent variable="input"><input type="hidden" name="#attributes.fieldname#" value=""/><cfif attributes.showFile><a href="#attributes.urlpath##URLEncodedFormat(GetFileFromPath(attributes.value))#" target="_new" title="#attributes.label#">#HTMLEditFormat(GetFileFromPath(attributes.value))#</a></cfif></cfsavecontent>
				</cfif>					
			<cfelse>
				<cfsavecontent variable="input"><input type="hidden" name="#attributes.fieldname#" value=""/><cfif attributes.showFile>(none)</cfif></cfsavecontent>
			</cfif>
		<cfelse>
			<cfif NOT Len(attributes.style)><cfset attributes.style = "padding:0px;margin:0px;"></cfif>
			<cfsavecontent variable="input">
			<cfif Len(attributes.value) AND FileExists("#attributes.destination##attributes.value#")><cfif attributes.showFile><div><cfif ListFindNoCase("gif,jpg,png", ListLast(attributes.value, ".")) AND attributes.showImage><img src="#imgPath#" alt="#attributes.label#" class="sebField-image"> </cfif><strong><a href="#attributes.URLPath##URLEncodedFormat(GetFileFromPath(attributes.value))#">#HTMLEditFormat(GetFileFromPath(attributes.value))#</a></strong></div></cfif><cfif NOT attributes.required><div title="Remove #HTMLEditFormat(GetFileFromPath(attributes.value))#"><input type="checkbox" name="delete#attributes.fieldname#" id="delete#attributes.fieldname#" value="1" title="clear #attributes.label#"><label id="lbl-delete#attributes.fieldname#" for="delete#attributes.fieldname#">remove #HTMLEditFormat(GetFileFromPath(attributes.value))#</label></div><cfelse><div>replace with:</div></cfif></cfif>
			<input type="file" name="#attributes.fieldname#"<cfif Len(attributes.id)> id="#attributes.id#"</cfif><cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt])> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop>/></cfsavecontent>
		</cfif>
	</cfcase>
	
	<cfcase value="cancel">
		<cfsavecontent variable="input"><cfif attributes.isEditable NEQ false><input type="button"<cfif Len(attributes.fieldname)> name="#attributes.fieldname#"</cfif><cfif Len(attributes.id)> id="#attributes.id#"</cfif><cfif Len(attributes.label)> value="#attributes.label#"</cfif><cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt])> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop><cfif StructKeyExists(attributes,"CancelURL") AND Len(attributes.CancelURL)> onclick="location.replace('#attributes.CancelURL#');"<cfelse> onclick="history.back();"</cfif>/></cfif></cfsavecontent>
	</cfcase>

	<cfcase value="checkbox">
		<cfif attributes.isEditable IS false>
			<cfsavecontent variable="input"><ul><cfloop index="thisSubField" from="1" to="#ArrayLen(ThisTag.qsubfields)#" step="1"><cfif ThisTag.qsubfields[thisSubField].checked>
				<li>#ThisTag.qsubfields[thisSubField].display#<cfif StructKeyExists(ThisTag.qsubfields[thisSubField],"other") AND ThisTag.qsubfields[thisSubField].other IS true>(#attributes.ValueOther#)</cfif></li>
			</cfif></cfloop></ul></cfsavecontent>
		<cfelse>
			<cfsavecontent variable="input"><fieldset class="checkbox<cfif StructKeyExists(attributes,"class") AND Len(attributes.class)> #attributes.class#</cfif>" id="#attributes.id#_set"<cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt]) AND thisHtmlAtt neq "size" AND thisHtmlAtt neq "class"> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop>><cfloop index="thisSubField" from="1" to="#ArrayLen(ThisTag.qsubfields)#" step="1">
			<cfset thisID = "#attributes.id#_#thisSubField#"><input type="checkbox" id="#thisID#" name="#attributes.fieldname#" value="#HTMLEditFormat(ThisTag.qsubfields[thisSubField].value)#"<cfif ThisTag.qsubfields[thisSubField].checked> checked="checked"</cfif><cfif StructKeyExists(ThisTag.qsubfields[thisSubField],"other") AND ThisTag.qsubfields[thisSubField].other IS true> class="sebform-option-other"</cfif>/> <label id="lbl-#thisID#" for="#thisID#"<cfif StructKeyExists(ThisTag.qsubfields[thisSubField],"title")> title="#HTMLEditFormat(ThisTag.qsubfields[thisSubField].title)#"</cfif>>#ThisTag.qsubfields[thisSubField].display#</label><cfif StructKeyExists(ThisTag.qsubfields[thisSubField],"other") AND ThisTag.qsubfields[thisSubField].other IS true AND attributes.numOtherOptions EQ 1> <input name="#attributes.OtherField#" id="#attributes.id#-other" value="#attributes.ValueOther#" size="10" onclick="document.getElementById('#thisID#').checked = true;" /></cfif><br/></cfloop><cfif attributes.numOtherOptions GT 1><div id="#attributes.id#-otherdiv"><label for="#attributes.id#-other">#attributes.OtherFieldLabel#:</label> <input name="#attributes.OtherField#" id="#attributes.id#-other" value="#attributes.ValueOther#" size="10" /><br /></div></cfif></fieldset></cfsavecontent>
		</cfif>
	</cfcase>
	
	<cfcase value="date,jtdate">
		<cfif attributes.isEditable IS false>
			<cfsavecontent variable="input"><cfif isDate(attributes.value)>#DateFormat(attributes.value,"mm/dd/yyyy")#</cfif></cfsavecontent>
		<cfelse>
			<cfsavecontent variable="input">
			<cfset formattedValue = "" ><cfset DateCodebase = "/images/">
			<cfset formattedValue = Attributes.value>
			<cfif Len(Attributes.value) AND isDate(Attributes.value) AND Year(Attributes.value) GTE 1900 AND Year(Attributes.value) LTE (Year(now()) + 100)>
				<!---<cftry>--->
					<cfset formattedValue = DateFormat(Attributes.value, 'mm/dd/yyyy') >
					<!---<cfcatch><cfset formattedValue = ""></cfcatch>
				</cftry>--->
			</cfif>
			<input type="text" name="#attributes.fieldname#"<cfif Len(attributes.id)> id="#attributes.id#"</cfif> value="#formattedValue#"<cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt])> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop><cfif StructKeyExists(attributes,"length") AND Len(attributes.length) AND NOT StructKeyExists(attributes,"maxlength")> maxlength="#attributes.length#"</cfif>/>
			<cfif attributes.type eq "jtdate">
			<cfif NOT IsDefined("ParentData.caller.EzCalendarScript") >
				<cfset ParentData.caller.EzCalendarScript = 1 >
	
				<cfset EzHEADTxt = CHR(13) & '<!-- Code added by EzINPUT DATE: -->' & CHR(13) >
				<cfhtmlhead text="#EzHEADTxt#" >
				<cfset EzHEADTxt = '<link rel="STYLESHEET" type="text/css" href="#DateCodebase#calendar.css">' & CHR(13)  >
				<cfhtmlhead text="#EzHEADTxt#" >
				<cfset EzHEADTxt = '<script src="#DateCodebase#calendar.js" type="text/javascript"></script>' & CHR(13) & CHR(13) >
				<cfhtmlhead text="#EzHEADTxt#" >
			</cfif>
			<a href="javascript: void(0);" onmouseover="if (timeoutId) clearTimeout(timeoutId);window.status='Show Calendar';return true;" onmouseout="if (timeoutDelay) calendarTimeout();window.status='';" onclick="g_Calendar.show(event,'#ParentAtts.formname#.#attributes.fieldname#',false,'mm/dd/yyyy'); return false;"><img src="#DateCodebase#calendar.gif" name="imgCalendar" width="34" height="21" border="0" alt=""></a>
			</cfif>
			<font size="1">(mm/dd/yyyy)</font>
			</cfsavecontent>
		</cfif>
	</cfcase>

	<cfcase value="date2">
		<cfif attributes.isEditable IS false>
			<cfsavecontent variable="input"><cfif isDate(attributes.value)>#DateFormat(attributes.value,"mm/dd/yyyy")#</cfif></cfsavecontent>
		<cfelse>
			<cfsavecontent variable="input">
			<cfset formattedValue = "" ><cfset DateCodebase = "/images/">
			<cfset formattedValue = Attributes.value>
			<cfif Len(Attributes.value) AND isDate(Attributes.value) AND Year(Attributes.value) GTE 1900 AND Year(Attributes.value) LTE (Year(now()) + 100)>
				<!---<cftry>--->
					<cfset formattedValue = DateFormat(Attributes.value, 'mm/dd/yyyy') >
					<!---<cfcatch><cfset formattedValue = ""></cfcatch>
				</cftry>--->
			</cfif>
			<input type="text" name="#attributes.fieldname#"<cfif Len(attributes.id)> id="#attributes.id#"</cfif> value="#formattedValue#"<cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt])> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop><cfif StructKeyExists(attributes,"length") AND Len(attributes.length) AND NOT StructKeyExists(attributes,"maxlength")> maxlength="#attributes.length#"</cfif> datepicker="true" datepicker_format="MM/DD/YYYY"/>
			<cfif NOT IsDefined("request.sebField_Date2") >
				<cfset request.sebField_Date2 = 1 >
				<cfset date2Head = '<script type="text/javascript" src="#ParentAtts.librarypath#date2/datepickercontrol.js"></script>'>
				<cfhtmlhead text="#date2Head#" >
				<cfset date2Head = '<link type="text/css" rel="stylesheet" href="#ParentAtts.librarypath#date2/datepickercontrol_bluegray.css">'>
				<cfhtmlhead text="#date2Head#" >
				<cfset date2Head = '<link type="text/css" rel="stylesheet" href="#ParentAtts.librarypath#date2/content.css">'>
				<cfhtmlhead text="#date2Head#" >
			</cfif>
			<cfif NOT StructKeyExists(request,"sebField_#ParentAtts.formname#_Date2") >
				<cfset request["sebField_#ParentAtts.formname#_Date2"] = 1 >
				<input type="hidden" id="DPC_TODAY_TEXT" value="today"/>
				<input type="hidden" id="DPC_BUTTON_TITLE" value="Open calendar..."/>
				<input type="hidden" id="DPC_MONTH_NAMES" value="['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']"/>
				<input type="hidden" id="DPC_DAY_NAMES" value="['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']"/>
			</cfif>
			</cfsavecontent>
		</cfif>
	</cfcase>

	<cfcase value="datestamp"></cfcase>

	<cfcase value="delete"><cfif Len(attributes.fieldname) eq 0><cfset attributes.fieldname = "sebformDelete"></cfif>
		<cfsavecontent variable="input"><cfif attributes.isEditable NEQ false><input type="submit" name="#attributes.fieldname#"<cfif Len(attributes.id)> id="#attributes.id#"</cfif><cfif Len(attributes.label)> value="#attributes.label#"</cfif><cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt])> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop> onclick="return confirm('Are you sure you want to permanantly delete this item?');"/></cfif></cfsavecontent>
		<cfif NOT Len(ParentAtts.datasource) OR NOT isNumeric(ParentAtts.recordid)><cfset input = "<!-- Delete button only displays when editing a record -->"></cfif>
	</cfcase>

	<cfcase value="password">
		<cfif attributes.isEditable IS false>
			<cfsavecontent variable="input">********</cfsavecontent>
		<cfelse>
			<cfsavecontent variable="input"><input type="password" name="#attributes.fieldname#"<cfif Len(attributes.id)> id="#attributes.id#"</cfif> value="#HTMLEditFormat(attributes.value)#"<cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt])> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop><cfif Len(attributes.length)> maxlength="#attributes.length#"</cfif>/></cfsavecontent>
		</cfif>
	</cfcase>

	<cfcase value="radio">
		<cfif attributes.isEditable IS false>
			<cfsavecontent variable="input"><ul><cfloop index="thisSubField" from="1" to="#ArrayLen(ThisTag.qsubfields)#" step="1"><cfif ThisTag.qsubfields[thisSubField].checked>
				<li>#ThisTag.qsubfields[thisSubField].display#<cfif StructKeyExists(ThisTag.qsubfields[thisSubField],"other") AND ThisTag.qsubfields[thisSubField].other IS true>(#attributes.ValueOther#)</cfif></li>
			</cfif></cfloop></ul></cfsavecontent>
		<cfelse>
			<cfsavecontent variable="input"><!-- #HTMLEditFormat(attributes.value)# --><fieldset class="radio" id="#attributes.id#_set"<cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt]) AND thisHtmlAtt neq "size"> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop>><cfloop index="thisSubField" from="1" to="#ArrayLen(ThisTag.qsubfields)#" step="1">
			<cfset thisID = "#attributes.id#_#thisSubField#"><input type="radio" id="#thisID#" name="#attributes.fieldname#" value="#HTMLEditFormat(ThisTag.qsubfields[thisSubField].value)#"<cfif ThisTag.qsubfields[thisSubField].checked> checked="checked"</cfif><cfif ThisTag.qsubfields[thisSubField].other IS true> class="sebform-option-other"</cfif>/> <label id="lbl-#thisID#" for="#thisID#"<cfif StructKeyExists(ThisTag.qsubfields[thisSubField],"title")> title="#HTMLEditFormat(ThisTag.qsubfields[thisSubField].title)#"</cfif>>#ThisTag.qsubfields[thisSubField].display#</label><cfif StructKeyExists(ThisTag.qsubfields[thisSubField],"other") AND ThisTag.qsubfields[thisSubField].other IS true AND attributes.numOtherOptions EQ 1> <input name="#attributes.OtherField#" id="#attributes.id#-other" value="#attributes.ValueOther#" size="10" onclick="document.getElementById('#thisID#').checked = true;" /></cfif><br/></cfloop><cfif attributes.numOtherOptions GT 1><div id="#attributes.id#-otherdiv"><label for="#attributes.id#-other">#attributes.OtherFieldLabel#:</label> <input name="#attributes.OtherField#" id="#attributes.id#-other" value="#attributes.ValueOther#" size="10" /></div><br/></cfif></fieldset></cfsavecontent>
		</cfif>
	</cfcase>
	
	<cfcase value="reset">
		<cfsavecontent variable="input"><cfif attributes.isEditable NEQ false><input type="reset"<cfif Len(attributes.fieldname)> name="#attributes.fieldname#"</cfif><cfif Len(attributes.id)> id="#attributes.id#"</cfif><cfif Len(attributes.label)> value="#attributes.label#"</cfif><cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt])> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop>/></cfif></cfsavecontent>
	</cfcase>

	<cfcase value="select">
		<cfif attributes.isEditable NEQ false>
		<cfsavecontent variable="input">
<select name="#attributes.fieldname#"<cfif StructKeyExists(attributes,"multiple") AND attributes.multiple IS true> multiple</cfif><cfif Len(attributes.id)> id="#attributes.id#"</cfif><cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt])> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop>><cfif attributes.showtopopt><option value="#attributes.topoptvalue#"><cfif Len(Trim(attributes.topopt))>#attributes.topopt#<cfelse>&nbsp;</cfif></option></cfif><cfloop index="thisSubField" from="1" to="#ArrayLen(ThisTag.qsubfields)#" step="1">
	<option value="#HTMLEditFormat(ThisTag.qsubfields[thisSubField].value)#"<cfif ThisTag.qsubfields[thisSubField].checked> selected="selected"</cfif><cfif ThisTag.qsubfields[thisSubField].other IS true> class="sebform-option-other"</cfif>><cfif Len(Trim(ThisTag.qsubfields[thisSubField].display))>#ThisTag.qsubfields[thisSubField].display#<cfelse>&nbsp;</cfif></option></cfloop>
</select><cfif attributes.hasOtherOption> <input name="#attributes.OtherField#" id="#attributes.id#-other" class="sebfield-select-other" value="#attributes.ValueOther#" size="10" /></cfif><cfif Len(attributes.addlink)> <a href="#attributes.addlink#" id="#attributes.id#-addlink">add new #LCase(attributes.label)#</a></cfif><cfif Len(attributes.link)> <a href="#attributes.link#" id="#attributes.id#-link"><cfif Len(attributes.linktext)>#attributes.linktext#<cfelse>#attributes.link#</cfif></a></cfif>
</cfsavecontent>
		<cfelse>
			<cfsavecontent variable="input">
			<cfif StructKeyExists(attributes,"multiple") AND attributes.multiple IS true>
				<ul><cfloop index="thisSubField" from="1" to="#ArrayLen(ThisTag.qsubfields)#" step="1"><cfif ThisTag.qsubfields[thisSubField].checked>
					<li>#ThisTag.qsubfields[thisSubField].display#</li></cfif></cfloop>
				</ul>
			<cfelse>
				<cfloop index="thisSubField" from="1" to="#ArrayLen(ThisTag.qsubfields)#" step="1"><cfif ThisTag.qsubfields[thisSubField].checked>
					<div>#ThisTag.qsubfields[thisSubField].display#</div>
				</cfif></cfloop>
			</cfif>
			</cfsavecontent>
		</cfif>
	</cfcase>
	
	<cfcase value="subdelete">
		<cfif attributes.isEditable NEQ false>
		<cfsavecontent variable="input"><input type="checkbox" id="#attributes.id#" name="#attributes.fieldname#" value="1"/> <label id="lbl-#attributes.id#" for="#attributes.id#">#attributes.label#</label><br/></cfsavecontent>
		</cfif>
	</cfcase>

	<cfcase value="submit">
		<cfif attributes.isEditable NEQ false>
		<cfsavecontent variable="input"><div class="sebSubmitBar"><input type="submit" value="#attributes.label#"<cfif Len(attributes.fieldname)> name="#attributes.fieldname#"</cfif><cfif Len(attributes.id)> id="#attributes.id#"</cfif><cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt])> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop>/></div></cfsavecontent>
		</cfif>
	</cfcase>
	
	<cfcase value="submit/cancel">
		<cfif attributes.isEditable NEQ false>
		<cfsavecontent variable="input"><div class="sebSubmitBar"><cfset attributes.Title = "">
		<input type="submit" value="#ListFirst(attributes.label)#"<cfif Len(attributes.fieldname)> name="#attributes.fieldname#"</cfif><cfif Len(attributes.id)> id="#attributes.id#"</cfif><cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt])> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop>/>
		&nbsp;
		<input type="button"<cfif Len(attributes.fieldname)> name="#attributes.fieldname#"</cfif><cfif Len(attributes.id)> id="#attributes.id#2"</cfif><cfif ListLen(attributes.label) gt 1> value="#ListGetAt(attributes.label,2)#"</cfif><cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt])> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop><cfif StructKeyExists(attributes,"CancelURL") AND Len(attributes.CancelURL)> onclick="location.replace('#attributes.CancelURL#');"<cfelse> onclick="history.back();"</cfif>/>
		</div></cfsavecontent>
		</cfif>
	</cfcase>
	
	<cfcase value="submit/cancel/delete">
		<cfif attributes.isEditable NEQ false>
		<cfsavecontent variable="input"><div class="sebSubmitBar"><cfset attributes.Title = "">
		<input type="submit" value="#ListFirst(attributes.label)#"<cfif Len(attributes.fieldname)> name="#attributes.fieldname#"</cfif><cfif Len(attributes.id)> id="#attributes.id#"</cfif><cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt])> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop>/>
		&nbsp;
		<input type="button"<cfif Len(attributes.fieldname)> name="#attributes.fieldname#"</cfif><cfif Len(attributes.id)> id="#attributes.id#2"</cfif><cfif ListLen(attributes.label) gt 1> value="#ListGetAt(attributes.label,2)#"<cfelse> value="Cancel"</cfif><cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt])> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop><cfif StructKeyExists(attributes,"CancelURL") AND Len(attributes.CancelURL)> onclick="location.replace('#attributes.CancelURL#');"<cfelse> onclick="history.back();"</cfif>/>
		&nbsp;
		<cfif Len(attributes.fieldname) eq 0><cfset attributes.fieldname = "sebformDelete"></cfif>
		<cfif (Len(ParentAtts.datasource) OR StructKeyExists(ParentAtts,"CFC_DeleteMethod")) AND Len(ParentAtts.recordid) AND ParentAtts.recordid neq 0>
		<input type="submit" name="#attributes.fieldname#"<cfif Len(attributes.id)> id="#attributes.id#3"</cfif><cfif ListLen(attributes.label) gt 2> value="#ListLast(attributes.label)#"<cfelse> value="Delete"</cfif><cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt])> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop> onclick="return confirm('Are you sure you want to permanantly DELETE this item?');"/>
		</cfif>
		</div></cfsavecontent>
		</cfif>
	</cfcase>

	<cfcase value="textarea,paragraph,memo">
		<cfif attributes.isEditable NEQ false>
			<cfset attributes.type = "textarea"><!---<cfset attributes.value = ReplaceNoCase(attributes.value, "</textarea>", "&lt;/textarea&gt;", "ALL")>--->
			<cfsavecontent variable="input"><textarea name="#attributes.fieldname#"<cfif Len(attributes.id)> id="#attributes.id#"</cfif> cols="#attributes.cols#" rows="#attributes.rows#"<cfif Len(attributes.wrap)> wrap="#attributes.wrap#"</cfif><cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt]) AND thisHtmlAtt neq "size"> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop>>#HTMLEditFormat(attributes.value)#</textarea><cfif isNumeric(attributes.length) AND attributes.length gt 0><div class="sebTextareaMaxLength" id="#attributes.id#-maxlength">(Maximum characters: #attributes.length#)</div><div id="#attributes.id#-countdiv" style="display:none;">You have <input readonly="readonly" type="text" name="#attributes.id#_countdown" id="#attributes.id#-countdown" size="3" value="#attributes.length-Len(attributes.value)#"> characters left.</div></cfif></cfsavecontent>
		<cfelse>
			<cfsavecontent variable="input">#HTMLEditFormat(attributes.value)#</cfsavecontent>
		</cfif>
	</cfcase>

	<cfcase value="time"><cfif isDate(attributes.value)><cfset attributes.value = TimeFormat(attributes.value)></cfif>
		<cfsavecontent variable="input"><input type="text" name="#attributes.fieldname#"<cfif Len(attributes.id)> id="#attributes.id#"</cfif> value="#HTMLEditFormat(attributes.value)#"<cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt])> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop><cfif Len(attributes.length)> maxlength="#attributes.length#"</cfif>/></cfsavecontent>
	</cfcase>
	
	<cfcase value="yesno,yes/no,YES/NO RADIO">
		<cfif attributes.locked OR attributes.isEditable IS false>
			<cfsavecontent variable="input">#YesNoFormat(attributes.value)#<input type="hidden" id="#attributes.id#" name="#attributes.fieldname#" value="#HTMLEditFormat(attributes.value)#" /></cfsavecontent>
		<cfelse>
			<cfif NOT Len(attributes.style)><cfset attributes.style = "border: 0px solid white;"></cfif>
			<cfsavecontent variable="input"><fieldset class="yesno" id="#attributes.id#_set"<cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt]) AND thisHtmlAtt neq "size"> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop>>
		<cfset thisID = "#attributes.id#_1"><input type="radio" id="#thisID#" name="#attributes.fieldname#" value="1"<cfif isBoolean(attributes.value) AND attributes.value> checked="checked"<cfset attributes.display = "Yes"></cfif>/>&nbsp;<label id="lbl-#thisID#" for="#thisID#">Yes</label> &nbsp;
		<cfset thisID = "#attributes.id#_0"><input type="radio" id="#thisID#" name="#attributes.fieldname#" value="0"<cfif isBoolean(attributes.value) AND NOT attributes.value> checked="checked"<cfset attributes.display = "No"></cfif>/>&nbsp;<label id="lbl-#thisID#" for="#thisID#">No</label><br/>
		</fieldset></cfsavecontent><!--- <fieldset></fieldset> --->
		</cfif>
	</cfcase>

	<cfcase value="custom,custom1,custom2">
		<cfif NOT StructKeyExists(attributes,"GeneratedContent")><cfset attributes.GeneratedContent = ThisTag.GeneratedContent></cfif>
		<cfsavecontent variable="input">#attributes.GeneratedContent#</cfsavecontent>
	</cfcase>
	
	<cfcase value="xdate">
		<cfif isDate(attributes.value)><cfset attributes.value = DateFormat(attributes.value,"mm/dd/yyyy")><cfelse><cfset attributes.value = ""></cfif>
		<cfsavecontent variable="input"><!---
		<input type="text" name="#attributes.fieldname#"<cfif Len(attributes.id)> id="#attributes.id#"</cfif> value="#DateFormat(attributes.value)#"<cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt])> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop>/>
<button id="trigger">...</button>
<script type="text/javascript">
  Calendar.setup(
    {
      inputField  : "#attributes.id#",         // ID of the input field
      ifFormat    : "%Y-%m-%d",    // the date format
      button      : "trigger"       // ID of the button
    }
  );
</script>
---><!--- <input type="hidden" name="#attributes.fieldname#"<cfif Len(attributes.id)> id="#attributes.id#"</cfif> value="#attributes.value#"/> --->
<table border="0" cellspacing="0" cellpadding="0"><tr><td>
<div id="calendar-#attributes.id#" style="margin-bottom:0;"></div><input style="margin-top:0;" type="text" name="#attributes.fieldname#"<cfif Len(attributes.id)> id="#attributes.id#"</cfif> value="#attributes.value#" size="12" maxlength="10"/><cfif NOT attributes.required><input type="button" name="clr#attributes.id#" value="clr" onclick="#attributes.id#.value=''"></cfif>
</td></tr></table>

<script type="text/javascript">
function dateSelect#attributes.id#(calendar, date) {if (calendar.dateClicked) {document.getElementById("#attributes.id#").value = date;}};
if ( document.getElementById('#attributes.id#').value.length > 0 ) {myDate = new Date(document.getElementById('#attributes.id#').value);} else {myDate = new Date();}
var calendar#attributes.id# = new Calendar(0, myDate, dateSelect#attributes.id#);
//calendar#attributes.id#.inputField = "#attributes.id#";
calendar#attributes.id#.setDateFormat("%m/%d/%Y");
calendar#attributes.id#.create(document.getElementById('calendar-#attributes.id#'));
calendar#attributes.id#.show();
</script></cfsavecontent>
	</cfcase>
			
	<cfcase value="xwysiwyg,htmlarea,xstandard">
<cfif attributes.type eq "xstandard">
<cfsavecontent variable="input">
	<cfif CGI.HTTPS eq "on"><cfset protocal = "https"><cfelse><cfset protocal = "http"></cfif>
	<input type="hidden" name="#attributes.fieldname#"<cfif Len(attributes.id)> id="#attributes.id#"</cfif> value="" />
	<object type="application/x-xstandard" id="#attributes.id#-edit" width="420" height="400" codebase="http://#CGI.HTTP_HOST#/lib/xstandard/XStandard.cab##Version=1,5,0,0">
		<param name="Value" value="#HTMLEditFormat(attributes.value)#" />
		<param name="Toolbar" value="strong,em,indent,numbering,bullets,image,hyperlink,undo,source" /><!--- data-table --->
		<param name="CSS" value="http://#CGI.HTTP_HOST#/i/d/1/all.css" />
		<param name="Base" value="http://#CGI.HTTP_HOST#/" />
		<param name="EnablePasteMarkup" value="yes" />
		<param name="ClassImageFloatLeft" value="left" />
		<param name="ClassImageFloatRight" value="right" />
		<cfif StructKeyExists(attributes,"Styles")><param name="Styles" value="#attributes.Styles#" /><cfelse><param name="Styles" value="http://#CGI.HTTP_HOST#/lib/xstandard/styles.xml" /></cfif>
	</object>
</cfsavecontent>
<cfelse>
<cfsavecontent variable="input">
<br/><textarea name="#attributes.fieldname#"<cfif Len(attributes.id)> id="#attributes.id#"</cfif> cols="#attributes.cols#" rows="#attributes.rows#"<cfif Len(attributes.wrap)> wrap="#attributes.wrap#"</cfif><cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt]) AND thisHtmlAtt neq "size"> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop>>#HTMLEditFormat(attributes.value)#</textarea>
<script type="text/javascript">_editor_url = "#ParentAtts.librarypath#htmlarea/";_editor_lang = "en";</script>
<script type="text/javascript" src="#ParentAtts.librarypath#htmlarea/htmlarea-c.js"></script>
<script type="text/javascript" defer="1">
var config = new HTMLArea.Config();
config.killWordOnPaste = true;
config.toolbar = [ [ /*"fontstyles", "fontname", "space", "fontsize", "space", */ "formatblock", "space", "bold", "italic", "underline", "separator", "strikethrough", "subscript", "superscript", "separator", "copy", "cut", "paste", "space", "undo", "redo" ], [ "justifyleft", "justifycenter", "justifyright", "justifyfull", "separator", "insertorderedlist", "insertunorderedlist", "outdent", "indent", "separator", "textindicator", "separator", "inserthorizontalrule", "createlink", "insertimage", "inserttable", "htmlmode", "separator", "about" ] ];
var myID = HTMLArea.getElementById("textarea", '#attributes.id#');
ha#attributes.id# = new HTMLArea(myID,config);
ha#attributes.id#.generate();
//HTMLArea.replace("#attributes.id#",ha#attributes.id#);
</script></cfsavecontent>
</cfif>
	</cfcase>

	<cfdefaultcase>
		<cfif StructKeyExists(ThisTag,"GeneratedContent") AND Len(ThisTag.GeneratedContent)>
			<cfsavecontent variable="input">#ThisTag.GeneratedContent#</cfsavecontent>
		<cfelse>
			<cfsavecontent variable="input"></cfsavecontent>
			<cftry>
				<cfif attributes.type EQ "fckeditor" AND StructKeyExists(attributes,"ckeditor")>
					<cfset attributes.type = "CKeditor">
				</cfif>
				<cfinclude template="sebField_#attributes.type#.cfm">
				<cfcatch>
					<cfif CFCATCH.Message CONTAINS "Could not find the included template sebField_#attributes.type#.cfm">
						<cfthrow message="The type ""#attributes.type#"" is not a valid type for cf_sebField" type="sebField" detail="If you are trying to create a custom field type, make sure to put the sebField_#attributes.type# file in the same directory as sebField.cfm." errorcode="NoSuchFieldType">
					<cfelse>
						<cfrethrow>
					</cfif>
				</cfcatch>
			</cftry>
		</cfif>
		
	</cfdefaultcase>
		
	</cfswitch>
		
	<cfscript>
	if ( NOT StructKeyExists(attributes,"GeneratedContent") ) {
		attributes.GeneratedContent = Trim(ThisTag.GeneratedContent);
	}
	
	
	if ( StructKeyExists(ThisTag.config.fields, attributes.type) ) {
		thisInput = ThisTag.config.fields[attributes.type];
	} else if ( ListFindNoCase(liButtonTypes, attributes.type) AND StructKeyExists(ThisTag.config["fields"], "buttons") ) {
		thisInput = ThisTag.config.fields["buttons"];
	} else {
		thisInput = ThisTag.config.fields.all;
	}
	if ( Len(Trim(attributes.GeneratedContent)) AND attributes.type neq "custom1" ) {// AND ListFindNoCase(liValidTypes, attributes.type)
		thisInput = attributes.GeneratedContent;
		ThisTag.GeneratedContent = "";
	}
	thisInput = ReplaceNoCase(thisInput,  "[id]", '#attributes.id#',"ALL");
	if ( Len(Trim(attributes.Label)) AND NOT ListFindNoCase(liButtonTypes, attributes.type) ) {
		thisInput = ReplaceNoCase(thisInput,  "[Label]", '#attributes.Label#');
		if ( attributes.required ) {
			thisInput = ReplaceNoCase(thisInput,  "[ReqMark]", ThisTag.config.ReqMark);
		} else {
			thisInput = ReplaceNoCase(thisInput,  "[ReqMark]", "");
		}
		thisInput = ReplaceNoCase(thisInput,  "[Colon]", ThisTag.config.Colon, "All");
		thisInput = ReplaceNoCase(thisInput,  '{', '<label id="lbl-#attributes.id#" for="#attributes.id#" class="sebform">');
		thisInput = ReplaceNoCase(thisInput,  '}', '</label>');
		if ( Len(attributes.help) AND NOT FindNoCase(chr(34),attributes.help) ) {
			thisInput = ReplaceNoCase(thisInput,  '#chr(60)#label', '#chr(60)#label title="#attributes.help#"', 'ALL');
		}
	} else {
		thisInput = ReplaceNoCase(thisInput,  "[Label]", "");
		thisInput = ReplaceNoCase(thisInput,  "[Colon]", "", "All");
		thisInput = ReplaceNoCase(thisInput,  "[ReqMark]", "");
		thisInput = REReplaceNoCase(thisInput,"{[^}]*}","","ALL");
	}
	if ( Len(attributes.input_prefix) ) {
		input = "#attributes.input_prefix##input#";
	}
	if ( Len(attributes.input_suffix) ) {
		input = "#input##attributes.input_suffix#";
	}
	thisInput = ReplaceNoCase(thisInput,  "[Input]", input);
	thisInput = ReplaceNoCase(thisInput,  "[Help]", attributes.help);
	thisInput = ReplaceNoCase(thisInput,  "[value]", attributes.value);
	
	if ( Len(Trim(attributes.GeneratedContent)) AND attributes.type eq "custom2") {
		thisInput = input;
	}
	/*
	if ( Len(attributes.GeneratedContent) AND attributes.type eq "custom2") {
		thisInput = input;
	}
	*/
	</cfscript>
	<cfset attributes.output = Trim(thisInput)>
</cfsilent>
<cfif ListFindNoCase(GetBaseTagList(), ParentTag2) AND NOT attributes.isInSubFormCT><cfset request.cftags.cf_sebSubForm.fieldsnum = request.cftags.cf_sebSubForm.fieldsnum + 1>[Field:#request.cftags.cf_sebSubForm.fieldsnum#]<cfelseif attributes.type neq "hidden" AND attributes.type neq "none">#attributes.output#</cfif></cfoutput></cfif><cfsilent>
<cfscript>
if ( ThisTag.ExecutionMode eq "End" ) {
	if ( StructKeyExists(ThisTag, "qsubfields") ) {
		attributes.qsubfields = ThisTag.qsubfields;
	}
	ThisTag.GeneratedContent = "";
}
if ( StructKeyExists(attributes,"type") AND attributes.type EQ "none" ) {
	thisInput = "";
	ThisTag.GeneratedContent = "";
	attributes.GeneratedContent = "";
	ArrayDeleteAt(ParentData.ThisTag.qfields,ArrayLen(ParentData.ThisTag.qfields));
}
</cfscript>
<!--- </cfsilent> --->
</cfsilent><cfsetting enablecfoutputonly="No">