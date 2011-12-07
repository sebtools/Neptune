<!---
1.0 RC9 (Build 121)
Last Updated: 2011-10-11
Created by Steve Bryant 2004-06-01
Information: http://www.bryantwebconsulting.com/docs/sebtags/?version=1.0
Documentation:
http://www.bryantwebconsulting.com/docs/sebtags/sebform-basics.cfm?version=1.0
---><cfset TagName = "cf_sebSubForm"><cfset ParentTag = "cf_sebForm">
<cfif NOT isDefined("ThisTag.ExecutionMode") OR NOT ListFindNoCase(GetBaseTagList(), ParentTag)><cfthrow message="&lt;#TagName#&gt; must be called as a custom tag between &lt;#ParentTag#&gt; and &lt;/#ParentTag#&gt;" type="cftag"></cfif>

<cfswitch expression="#ThisTag.ExecutionMode#">

<cfcase value="Start">
	<cfassociate basetag="#ParentTag#" datacollection="subforms">
	<cfparam name="attributes.tablename" default="">
	<cfparam name="attributes.query" default="">
	<cfparam name="attributes.pkfield" default="">
	<cfparam name="attributes.pktype" default="">
	<cfparam name="attributes.fkfield" default="">
	<cfparam name="attributes.label" default="">
	<cfparam name="attributes.filter" default="">
	<cfparam name="attributes.orderBy" default="">
	<cfparam name="attributes.addrows" default="1" type="numeric">
	<cfparam name="attributes.maxrows" default="0" type="numeric">
	<cfparam name="attributes.cols" default="1" type="numeric">
	<cfparam name="attributes.useFieldset" default="true" type="boolean">
	<cfparam name="attributes.prefix" default="subform_#attributes.tablename#_">
	
	<cfset ParentData = getBaseTagData("cf_sebForm")>
	<cfset ParentAtts = ParentData.attributes>
	
	<!--- Get form defaults from component --->
	<cfif
			isDefined("attributes.CFC_Component")
		AND (
					StructKeyExists(attributes.CFC_Component,"getMetaStruct")
				OR	getMetaData(attributes.CFC_Component).extends.name CONTAINS "_framework.PageController"
				OR	getMetaData(attributes.CFC_Component).extends.name CONTAINS "Master"
				OR	getMetaData(attributes.CFC_Component).extends.name CONTAINS "Records"
			)
	>
		<cftry>
			<cfset sCompMeta = attributes.CFC_Component.getMetaStruct()>
			<cfif isDefined("sCompMeta") AND isStruct(sCompMeta)>
				<cfif StructKeyExists(sCompMeta,"arg_pk") AND Len(sCompMeta.arg_pk) AND NOT Len(attributes.pkfield)>
					<cfset attributes.pkfield = sCompMeta.arg_pk>
				</cfif>
				<cfif StructKeyExists(sCompMeta,"method_save") AND Len(sCompMeta.method_save) AND NOT isDefined("attributes.CFC_Method")>
					<cfset attributes.CFC_Method = sCompMeta.method_save>
				</cfif>
				<cfif StructKeyExists(sCompMeta,"method_gets") AND Len(sCompMeta.method_gets) AND NOT isDefined("attributes.CFC_GetMethod")>
					<cfset attributes.CFC_GetMethod = sCompMeta.method_gets>
				</cfif>
				<cfif StructKeyExists(sCompMeta,"method_delete") AND Len(sCompMeta.method_delete) AND NOT isDefined("attributes.CFC_DeleteMethod")>
					<cfset attributes.CFC_DeleteMethod = sCompMeta.method_delete>
				</cfif>
				<cfif StructKeyExists(sCompMeta,"catch_types") AND Len(sCompMeta.catch_types) AND NOT ListFindNoCase(attributes.CatchErrTypes,sCompMeta.catch_types)>
					<cfset ParentAtts.CatchErrTypes = ListAppend(ParentAtts.CatchErrTypes,sCompMeta.catch_types)>
				</cfif>
			</cfif>
		<cfcatch>
		</cfcatch>
		</cftry>
	</cfif>
	
	<!--- Get field defaults from component --->
	<cfif
			isDefined("attributes.CFC_Component")
		AND (
					StructKeyExists(attributes.CFC_Component,"getFieldsStruct")
				OR	getMetaData(attributes.CFC_Component).extends.name CONTAINS "_framework.PageController"
				OR	getMetaData(attributes.CFC_Component).extends.name CONTAINS "Master"
				OR	getMetaData(attributes.CFC_Component).extends.name CONTAINS "Records"
			)
	>
		<cftry>
			<cfset attributes.sFields = attributes.CFC_Component.getFieldsStruct(transformer="sebField")>
			<cfset StructAppend(ParentAtts.sFields,attributes.sFields,"no")>
			<!--- If component has getFieldStruct, make sure to catch "Master" errors --->
			<cfif NOT ListFindNoCase(ParentAtts.CatchErrTypes,"Master")>
				<cfset ParentAtts.CatchErrTypes = ListAppend(ParentAtts.CatchErrTypes,"Master")>
			</cfif>
		<cfcatch>
		</cfcatch>
		</cftry>
	</cfif>
	
	<cfif NOT Len(Trim(attributes.fkfield))>
		<cfset attributes.fkfield = ParentAtts.pkfield>
	</cfif>
	
	<cfif NOT ( Len(attributes.tablename) OR Len(attributes.query) OR ( isDefined("attributes.CFC_Component") AND isDefined("attributes.CFC_GetMethod") ) )>
		<cfthrow message="&lt;#TagName#&gt;: tablename, query attribute, or CFC must be provided in order to use &lt;#TagName#&gt;" type="cftag">
	</cfif>
	<cfif isDefined("attributes.CFC_Component") AND isDefined("attributes.CFC_GetMethod")>
		<cfinvoke returnvariable="qsubdata" component="#attributes.CFC_Component#" method="#attributes.CFC_GetMethod#">
			<cfinvokeargument name="#attributes.fkfield#" value="#ParentAtts.recordid#">
		</cfinvoke>
	<cfelseif Len(attributes.query)>
		<cfif StructKeyExists(Caller,attributes.query) AND isQuery(Caller[attributes.query])>
			<cfset qsubdata = Caller[attributes.query]>
		<cfelse>
			<cfthrow message="&lt;#TagName#&gt;: query attribute must be the name of a query on the page calling &lt;#TagName#&gt;" type="cftag">
		</cfif>
	<cfelse>
		<cfif NOT Len(ParentAtts.datasource)>
			<cfthrow message="&lt;#TagName#&gt;: datasource attribute for &lt;#ParentTag#&gt; must be provided in order to use &lt;#TagName#&gt; with tablename attribute" type="cftag">
		</cfif>
		<cfif NOT ( Len(attributes.pkfield) AND Len(attributes.fkfield) )>
			<cfthrow message="&lt;#TagName#&gt;: pkfield and fkfield attributes must be provided when using tablename attribute with &lt;#TagName#&gt; with tablename attribute" type="cftag">
		</cfif>
		<cfif NOT Len(attributes.pktype)>
			<cfset attributes.pktype = ParentAtts.pktype>
		</cfif>
		<cftry>
			<cfquery name="qsubdata" datasource="#ParentAtts.datasource#">SELECT * FROM #attributes.tablename# WHERE #attributes.fkfield# = <cfqueryparam value="#ParentAtts.recordid#" cfsqltype="#ParentAtts.pktype#"> <cfif Len(attributes.filter)>AND #attributes.filter# </cfif><cfif Len(attributes.orderBy)>ORDER BY #attributes.orderBy#</cfif></cfquery>
			<cfcatch><cfset qsubdata = QueryNew('sebform_none')></cfcatch>
		</cftry>
	</cfif>
	<cfscript>
	if ( attributes.pktype eq "GUID"  ) {
		attributes.datatype = "CF_SQL_IDSTAMP";
	} else {
		attributes.datatype = "CF_SQL_INTEGER";
	}
	if ( attributes.maxrows gt 0 ) {
		attributes.addrows = Min( (attributes.maxrows - qsubdata.RecordCount), attributes.addrows );
	}
	if ( NOT StructKeyExists(request, "cftags") ) {
		request.cftags = StructNew();
	}
	if ( NOT StructKeyExists(request.cftags, TagName) ) {
		request.cftags[TagName] = StructNew();
	}
	request.cftags[TagName].fieldsnum = 0;
	/*
	if ( NOT StructKeyExists(request.cftags[TagName], "attributes") ) {
		request.cftags[TagName].attributes = StructNew();
	}
	request.cftags[TagName].attributes = attributes;
	*/
	request.subfieldnum = 0;
	
	</cfscript>
</cfcase>

<cfcase value="End">
	<!--- Check to see if updates to table are needed --->
	<cfscript>
	attributes.qsubdata = qsubdata;
	attributes.qsubdata_RecordCount = qsubdata.RecordCount;
	attributes.qsubdata_ColumnList = qsubdata.ColumnList;
	attributes.qfields = ThisTag.qfields;
	attributes.GeneratedContent = Trim(ThisTag.GeneratedContent);
	attributes.hasFileField = false;

	ThisTag.GeneratedContent = "";
	RecordFields = ArrayNew(1);
	AddFields = ArrayNew(1);
	if ( isDefined("ThisTag.qfields") ) {
		aFields = Duplicate(ThisTag.qfields);
	}
	/*
	tmpOutput = "";
	tmpRecord = "";
	tmpField = "";
	*/
	arrFields = ArrayNew(1);
	doSQLDDL = false;
	for (thisField=1; thisField lte ArrayLen(ThisTag.qfields); thisField=thisField+1 ) {
		if ( Len(ThisTag.qfields[thisField].dbfield) ) {
			ArrayAppend(arrFields, ThisTag.qfields[thisField]);
			
			//If this field is not in the database, mark that a SQL DDL statement is needed
			if ( NOT ListFindNoCase(qsubdata.ColumnList, ThisTag.qfields[thisField].dbfield)  ) {
				doSQLDDL = true;
			}
			
			//Check for type=file
			if ( arrFields[thisField].type eq "file" ) {
				attributes.hasFileField = true;
			}
		}
	}
	
	numFieldsets = 0;
	</cfscript>
	<!--- Create/Alter table if it needs it (and if the altertable attribute is true) --->
	<cfif ParentAtts.altertable AND doSQLDDL>
		<cfscript>
		Tables = ArrayNew(1);
		ArrayAppend(Tables, StructNew());
		Tables[ArrayLen(Tables)].TableName = attributes.tablename;
		Tables[ArrayLen(Tables)].Fields = ArrayNew(1);
		Tables[ArrayLen(Tables)].PrimaryKey = attributes.pkfield;
		Tables[ArrayLen(Tables)].Index = "";
			ArrayAppend(Tables[ArrayLen(Tables)].Fields, StructNew());
			Tables[ArrayLen(Tables)].Fields[ArrayLen(Tables[ArrayLen(Tables)].Fields)].ColumnName = attributes.pkfield;
			Tables[ArrayLen(Tables)].Fields[ArrayLen(Tables[ArrayLen(Tables)].Fields)].DataType = "int";
			Tables[ArrayLen(Tables)].Fields[ArrayLen(Tables[ArrayLen(Tables)].Fields)].AllowNulls = False;
			Tables[ArrayLen(Tables)].Fields[ArrayLen(Tables[ArrayLen(Tables)].Fields)].Length = 4;
			Tables[ArrayLen(Tables)].Fields[ArrayLen(Tables[ArrayLen(Tables)].Fields)].Increment = True;
			Tables[ArrayLen(Tables)].Fields[ArrayLen(Tables[ArrayLen(Tables)].Fields)].DefaultValue = "";
		for (thisField=1; thisField lte ArrayLen(arrFields); thisField=thisField+1 ) {
			ArrayAppend(Tables[ArrayLen(Tables)].Fields, StructNew());
			Tables[ArrayLen(Tables)].Fields[ArrayLen(Tables[ArrayLen(Tables)].Fields)].ColumnName = arrFields[thisField].dbfield;
			Tables[ArrayLen(Tables)].Fields[ArrayLen(Tables[ArrayLen(Tables)].Fields)].DataType = arrFields[thisField].dbdatatype;
			Tables[ArrayLen(Tables)].Fields[ArrayLen(Tables[ArrayLen(Tables)].Fields)].AllowNulls = True;
			Tables[ArrayLen(Tables)].Fields[ArrayLen(Tables[ArrayLen(Tables)].Fields)].Length = arrFields[thisField].length;
			if ( arrFields[thisField].dbfield eq attributes.pkfield ) {
				Tables[ArrayLen(Tables)].Fields[ArrayLen(Tables[ArrayLen(Tables)].Fields)].Increment = True;
			} else {
				Tables[ArrayLen(Tables)].Fields[ArrayLen(Tables[ArrayLen(Tables)].Fields)].Increment = False;
			}
			Tables[ArrayLen(Tables)].Fields[ArrayLen(Tables[ArrayLen(Tables)].Fields)].DefaultValue = "";
		}
		</cfscript>
		<cftry>
			<cf_dbchanges datasource="#ParentAtts.datasource#" dbtype="#ParentAtts.dbtype#" Tables="#Tables#">
			<cfcatch><cfthrow message="&lt;#TagName#&gt;: Error running &lt;cf_dbchanges&gt;. Make sure that the tag is installed in the same directory as &lt;#TagName#&gt;" type="cftag"></cfcatch>
		</cftry>
	</cfif>
	<cfif ParentAtts.format EQ "table">
	<tr><td colspan="2">
	</cfif>
	<!---  If this subform tag has qfield tag below it --->
	<cfif isDefined("aFields") AND isArray(aFields)>
		<cfif attributes.cols gt 1><table><tr></cfif>
		<!---  Loop through existing records --->
		<cfloop index="j" from="1" to="#qsubdata.RecordCount#" step="1">
			<cfset RecordFields[j] = ArrayNew(1)>
			<cfif attributes.cols gt 1><td></cfif>
			<cfif attributes.useFieldset>
				<fieldset>
			</cfif>
			<cfif Len(attributes.label)>
				<cfoutput>
				<cfif attributes.useFieldset>
					<legend>#qsubdata[attributes.label][j]#</legend>
				<cfelseif ParentAtts.format eq "semantic">
					<strong class="sebSubFormLabel">#qsubdata[attributes.label][j]#</strong>
				<cfelse>
					<tr><td valign="top" colspan="2"><strong class="sebSubFormLabel">#qsubdata[attributes.label][j]#</strong></td></tr>
				</cfif>
				</cfoutput>
			</cfif>
			<cfset numFieldsets = numFieldsets + 1>
			<cfif ParentAtts.format EQ "table"><table></cfif>
			<cfloop index="i" from="1" to="#ArrayLen(aFields)#" step="1">
				<cfscript>
				prefix = "#attributes.prefix#e#qsubdata[attributes.pkfield][j]#_";
				RecordFields[j][i] = Duplicate(aFields[i]);
				RecordFields[j][i].dbfield = "#RecordFields[j][i].fieldname#";
				RecordFields[j][i].fieldname = "#prefix##RecordFields[j][i].fieldname#";
				if ( StructKeyExists(RecordFields[j][i],"subquery") AND Len(RecordFields[j][i].subquery) ) {
					if ( StructKeyExists(Caller,RecordFields[j][i].subquery) AND isQuery(Caller[RecordFields[j][i].subquery]) ) {
						Variables[RecordFields[j][i].subquery] = Caller[RecordFields[j][i].subquery];
					}
				}
				if ( Len(RecordFields[j][i].id) ) {
					RecordFields[j][i].id = "#prefix##RecordFields[j][i].id#";
				}
				if ( isDefined("form.#prefix##RecordFields[j][i].fieldname#") AND Len(Form["#prefix##RecordFields[j][i].fieldname#"]) ) {
					RecordFields[j][i].setvalue = Form["#prefix##RecordFields[j][i].fieldname#"];
				} else if ( Len(RecordFields[j][i].dbfield) AND ListFindNoCase(qsubdata.ColumnList, RecordFields[j][i].dbfield) ) {
					RecordFields[j][i].setvalue = qsubdata[RecordFields[j][i].dbfield][j];
				} else {
					RecordFields[j][i].setvalue = RecordFields[j][i].defaultvalue;
				}
				if ( RecordFields[j][i].type eq "delete" ) {
					RecordFields[j][i].type = "subdelete";
				}
				RecordFields[j][i].isInSubFormCT = true;
				</cfscript>
				<cfif StructKeyExists(RecordFields[j][i], "qsubfields") AND isArray(RecordFields[j][i].qsubfields)>
					<cf_sebField attributeCollection="#RecordFields[j][i]#"><cfloop index="k" from="1" to="#ArrayLen(RecordFields[j][i].qsubfields)#" step="1"><cf_sebSubfield attributeCollection="#RecordFields[j][i].qsubfields[k]#"></cfloop></cf_sebField>
				<cfelse>
					<cf_sebField attributeCollection="#RecordFields[j][i]#"><cfoutput>#RecordFields[j][i].GeneratedContent#</cfoutput></cf_sebField>
				</cfif>
			</cfloop>
			<cfif ParentAtts.format EQ "table"></table></cfif>
			<cfif attributes.useFieldset>
				</fieldset>
			</cfif>
			<cfif attributes.cols gt 1></td><cfif (numFieldsets MOD attributes.cols) eq 0></tr><tr></cfif></cfif>
		</cfloop>
		<!--- /Loop through existing records --->
		<!---  Loop through addrows --->
		<cfif attributes.addrows gt 0>
			<cfscript>
			prefix = "#attributes.prefix#a1_";
			AddField = ArrayNew(1);
			</cfscript>
			<cfsavecontent variable="AddOne"><cfif attributes.cols gt 1><td></cfif><cfif attributes.useFieldset><fieldset></cfif>
				<cfloop index="i" from="1" to="#ArrayLen(aFields)#" step="1">
					<cfif aFields[i].type neq "delete">
						<cfscript>
						AddField[i] = Duplicate(aFields[i]);
						AddField[i].dbfield = "#AddField[i].fieldname#";
						AddField[i].fieldname = "#prefix##AddField[i].fieldname#";
						if ( StructKeyExists(AddField[i],"subquery") AND Len(AddField[i].subquery) ) {
							if ( StructKeyExists(Caller,AddField[i].subquery) AND isQuery(Caller[AddField[i].subquery]) ) {
								Variables[AddField[i].subquery] = Caller[AddField[i].subquery];
							}
						}
						if ( Len(aFields[i].id) ) {
							AddField[i].id = "#prefix##AddField[i].id#";
						}
						if ( isDefined("form.#prefix##AddField[i].fieldname#") AND Len(Form["#prefix##AddFields[j][i].fieldname#"]) ) {
							AddField[i].value = Form["#prefix##AddField[i].fieldname#"];
						}
						showField = true;
						if ( (AddField[i].locked eq true) AND (Len(AddField[i].value) eq 0) ) {
							showField = false;
						}
						AddField[i].isInSubFormCT = true;
						</cfscript>
						<cfif showField>
							<cfif ParentAtts.format EQ "table"><table></cfif>
							<cfif StructKeyExists(AddField[i], "qsubfields") AND isArray(AddField[i].qsubfields)>
								<cf_sebField attributeCollection="#AddField[i]#">
								<cfloop index="k" from="1" to="#ArrayLen(AddField[i].qsubfields)#" step="1">
									<cf_sebSubField attributeCollection="#AddField[i].qsubfields[k]#">
								</cfloop>
								</cf_sebField>
							<cfelse>
								<cf_sebField attributeCollection="#AddField[i]#"><cfoutput>#AddField[i].GeneratedContent#</cfoutput></cf_sebField>
							</cfif>
							<cfif ParentAtts.format EQ "table"></table></cfif>
						</cfif>				
					</cfif>
				</cfloop>
				<cfif attributes.useFieldset></fieldset></cfif><cfif attributes.cols gt 1></td></cfif>
			</cfsavecontent>
			<!--- <cfoutput>#AddOne#</cfoutput> --->
			<cfloop index="j" from="1" to="#attributes.addrows#" step="1">
				<cfscript>
				numFieldsets = numFieldsets + 1;
				prefixOne = "#attributes.prefix#a1_";
				prefix = "#attributes.prefix#a#j#_";
				thisAdd = AddOne;
				if ( (attributes.cols gt 1) AND (numFieldsets MOD attributes.cols) eq 0 ) {
					thisAdd = ReplaceNoCase(thisAdd, "</td>", "</td></tr><tr>", "ALL");
				}
				</cfscript>
				<cfoutput>#ReplaceNoCase(thisAdd, prefixOne, prefix, "ALL")#</cfoutput>
			</cfloop>
		</cfif>
		<!--- /Loop through addrows --->
		<cfif attributes.cols gt 1></tr></table></cfif>
	</cfif>
	<!--- /If this subform tag has sebfield tag below it --->
	<cfif ParentAtts.format EQ "table">
	</td><tr>
	</cfif>

	<!--- || HANDLE FORM SUBMISSION || --->
	<cfif isDefined("form.sebformsubmit") AND form.sebformsubmit eq Hash(ParentAtts.formname)>
		<!--- || CHECK FOR DELETIONS || --->
		<cfif qsubdata.RecordCount>
			<cfset hasDeletion = false>
			<cfset arrDeleteRecords = ArrayNew(1)>
			<cfloop index="j" from="1" to="#qsubdata.RecordCount#" step="1">
				<cfscript>
				prefix = "#attributes.prefix#e#qsubdata[attributes.pkfield][j]#_";
				arrDeleteRecords[j] = false;
				for (thisField=1; thisField lte ArrayLen(attributes.qfields); thisField=thisField+1 ) {
					if ( attributes.qfields[thisField].type eq "delete" ) {
						delFieldName = "#prefix##attributes.qfields[thisField].fieldname#";
						if ( StructKeyExists(form, delFieldName) AND Form[delFieldName] AND isDefined("form.pkfield") AND Len(form.pkfield) ) {
							arrDeleteRecords[j] = true;
							hasDeletion = true;
						}
					}
				}
				</cfscript>
				<cfif arrDeleteRecords[j]>
					<cfset RecordID = qsubdata[attributes.pkfield][j]>
					<!---  If this sub table has a file field --->
					<cfif attributes.hasFileField>
						<!--- Delete any files when deleting record (unless 'nameconflict' is overwrite - in which case check for any record using that file first) --->
						<!---  Loop through all fields in main table --->
						<cfloop index="thisField" from="1" to="#ArrayLen(attributes.qfields)#" step="1">
							<!---  If this is a file field, delete the file (unless it is still in use) --->
							<cfif attributes.qfields[thisField].type eq "file">
								<cfset thisFile = attributes.qfields[thisField].destination & qsubdata[attributes.qfields[thisField].dbfield][j]>
								<cfif attributes.qfields[thisField].nameconflict eq "overwrite">
									<cfquery name="qsebformGetDeleteFiles" datasource="#ParentAtts.datasource#" dbtype="ODBC">
									SELECT	#attributes.qfields[thisField].dbfield#
									FROM	#attributes.tablename#
									WHERE	#attributes.fkfield# <> <cfqueryparam value="#form.pkfield#" cfsqltype="CF_SQL_INTEGER">
										AND	#attributes.qfields[thisField].dbfield# = '#attributes.qfields[thisField].value#'
									</cfquery>
									<cfif qsebformGetDeleteFiles.RecordCount eq 0 AND FileExists(thisFile)><cffile action="DELETE" file="#thisFile#"></cfif>
								<cfelse>
									<cfif FileExists(thisFile)><cffile action="DELETE" file="#thisFile#"></cfif>
								</cfif>
							</cfif>
							<!--- /If this is a file field, delete the file (unless it is still in use) --->
						</cfloop>
						<!--- /Loop through all fields in main table --->
					</cfif>
					<!--- /If main record has a file field --->
					<cfquery name="qsebformDelete" datasource="#ParentAtts.datasource#" dbtype="ODBC">
					DELETE
					FROM	#attributes.tablename#
					WHERE	#attributes.pkfield# = <cfqueryparam value="#RecordID#" cfsqltype="CF_SQL_INTEGER">
					</cfquery>
				</cfif>
			</cfloop>
			<cfif hasDeletion>
				<cftry>
					<cfquery name="qsubdata" datasource="#ParentAtts.datasource#">SELECT * FROM #attributes.tablename# WHERE #attributes.fkfield# = #ParentAtts.recordid# <cfif Len(attributes.orderBy)>ORDER BY #attributes.orderBy#</cfif></cfquery>
					<cfcatch><cfset qsubdata = QueryNew('sebform_none')></cfcatch>
				</cftry>
				<cfif attributes.maxrows gt 0>
					<cfset attributes.qsubdata = qsubdata>
					<cfset attributes.addrows = attributes.maxrows - qsubdata.RecordCount>
				</cfif>
			</cfif>
		</cfif>
	</cfif>
</cfcase>

</cfswitch>
