<!---
1.0 RC8 (Build 120)
Last Updated: 2011-01-16
Created by Steve Bryant 2004-06-01
Information: sebtools.com
Documentation:
http://www.bryantwebconsulting.com/cftags/cf_sebSubForm.htm
---><cfset TagName = "cf_sebRelForm"><cfset ParentTag = "cf_sebForm">
<cfif Not isDefined("ThisTag.ExecutionMode") OR Not ListFindNoCase(GetBaseTagList(), ParentTag)><cfthrow message="&lt;#TagName#&gt; must be called as a custom tag between &lt;#ParentTag#&gt; and &lt;/#ParentTag#&gt;" type="cftag"></cfif>

<cfswitch expression="#ThisTag.ExecutionMode#">

<cfcase value="Start">
	<cfassociate basetag="#ParentTag#" datacollection="subforms">
	<cfparam name="attributes.datatable">
	<cfparam name="attributes.relatetable">
	<cfparam name="attributes.datapkfield">
	<cfparam name="attributes.fkfield">
	<cfparam name="attributes.orderBy" default="">
	<cfparam name="attributes.cols" default="1" type="numeric">
	<cfparam name="attributes.useFieldset" default="true" type="boolean">
	<cfset ParentAtts = request.cftags[ParentTag].attributes>
	<cfif Not Len(ParentAtts.datasource)><cfthrow message="&lt;#TagName#&gt;: datasource attribute for &lt;#ParentTag#&gt; must be provided in order to use &lt;#TagName#&gt;" type="cftag"></cfif>
	<cfquery name="qdatadata" datasource="#ParentAtts.datasource#">SELECT * FROM #attributes.datatable#<cfif Len(attributes.orderBy)> ORDER BY #attributes.orderBy#</cfif></cfquery>
	<cfquery name="qdatadata" datasource="#ParentAtts.datasource#">SELECT * FROM #attributes.datatable#<cfif Len(attributes.orderBy)> ORDER BY #attributes.orderBy#</cfif></cfquery>
	<cfscript>
	if ( Not StructKeyExists(request, "cftags") ) {
		request.cftags = StructNew();
	}
	if ( Not StructKeyExists(request.cftags, TagName) ) {
		request.cftags[TagName] = StructNew();
	}
	request.cftags[TagName].fieldsnum = 0;
	/*
	if ( Not StructKeyExists(request.cftags[TagName], "attributes") ) {
		request.cftags[TagName].attributes = StructNew();
	}
	request.cftags[TagName].attributes = attributes;
	*/
	</cfscript>
</cfcase>

<cfcase value="End">
	<!--- Check to see if updates to table are needed --->
	<cfscript>
	attributes.qdatadata = qdatadata;
	attributes.qdatadata_RecordCount = qdatadata.RecordCount;
	attributes.qdatadata_ColumnList = qdatadata.ColumnList;
	attributes.qfields = ThisTag.qfields;
	attributes.GeneratedContent = Trim(ThisTag.GeneratedContent);
	attributes.hasFileField = false;

	ThisTag.GeneratedContent = "";
	RecordFields = ArrayNew(1);
	AddFields = ArrayNew(1);
	if ( isDefined("ThisTag.qfields") ) {
		sFields = Duplicate(ThisTag.qfields);
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
			/*
			if ( Not ListFindNoCase(qsubdata.ColumnList, ThisTag.qfields[thisField].dbfield)  ) {
				doSQLDDL = true;
			}
			*/
			
			//Check for type=file
			if ( arrFields[thisField].type eq "file" ) {
				attributes.hasFileField = true;
			}
		}
	}
	
	numFieldsets = 0;
	</cfscript>
	<!--- Create/Alter table if it needs it (and if the altertable attribute is true) --->
	<!--- <cfif ParentAtts.altertable AND doSQLDDL>
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
	</cfif> --->
	
	<!---  If this subform tag has qfield tag below it --->
	<cfif isDefined("sFields") AND isArray(sFields)>
		<cfif attributes.cols gt 1><table><tr></cfif>
		<!---  Loop through existing records --->
		<cfloop index="j" from="1" to="#qsubdata.RecordCount#" step="1">
			<cfset RecordFields[j] = ArrayNew(1)>
			<cfif attributes.cols gt 1><td></cfif>
			<cfif attributes.useFieldset><fieldset></cfif>
			<cfset numFieldsets = numFieldsets + 1>
			<cfloop index="i" from="1" to="#ArrayLen(sFields)#" step="1">
				<cfscript>
				prefix = "relform_#attributes.tablename#_e#qsubdata[attributes.pkfield][j]#_";
				RecordFields[j][i] = Duplicate(sFields[i]);
				RecordFields[j][i].fieldname = "#prefix##RecordFields[j][i].fieldname#";
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
					<cf_qfield attributeCollection="#RecordFields[j][i]#"><cfloop index="k" from="1" to="#ArrayLen(RecordFields[j][i].qsubfields)#" step="1"><cf_qsubfield attributeCollection="#RecordFields[j][i].qsubfields[k]#"></cfloop></cf_qfield>
				<cfelse>
					<cf_qfield attributeCollection="#RecordFields[j][i]#"><cfoutput>#RecordFields[j][i].GeneratedContent#</cfoutput></cf_qfield>
				</cfif>
			</cfloop>
			<cfif attributes.useFieldset></fieldset></cfif>
			<cfif attributes.cols gt 1></td><cfif (numFieldsets MOD attributes.cols) eq 0></tr><tr></cfif></cfif>
		</cfloop>
		<!--- /Loop through existing records --->
		<!---  Loop through addrows --->
		<cfif attributes.addrows gt 0>
			<cfscript>
			prefix = "subform_#attributes.tablename#_a1_";
			AddField = ArrayNew(1);
			</cfscript>
			<cfsavecontent variable="AddOne"><cfif attributes.cols gt 1><td></cfif><cfif attributes.useFieldset><fieldset></cfif>
				<cfloop index="i" from="1" to="#ArrayLen(sFields)#" step="1">
					<cfif sFields[i].type neq "delete">
						<cfscript>
						AddField[i] = Duplicate(sFields[i]);
						AddField[i].fieldname = "#prefix##AddField[i].fieldname#";
						if ( Len(sFields[i].id) ) {
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
							<cfif StructKeyExists(AddField[i], "qsubfields") AND isArray(AddField[i].qsubfields)>
								<cf_qfield attributeCollection="#AddField[i]#">
								<cfloop index="k" from="1" to="#ArrayLen(AddField[i].qsubfields)#" step="1">
									<cf_qsubfield attributeCollection="#AddField[i].qsubfields[k]#">
								</cfloop>
								</cf_qfield>
							<cfelse>
								<cf_qfield attributeCollection="#AddField[i]#"><cfoutput>#AddField[i].GeneratedContent#</cfoutput></cf_qfield>
							</cfif>
						</cfif>				
					</cfif>
				</cfloop>
				<cfif attributes.useFieldset></fieldset></cfif><cfif attributes.cols gt 1></td></cfif>
			</cfsavecontent>
			<!--- <cfoutput>#AddOne#</cfoutput> --->
			<cfloop index="j" from="1" to="#attributes.addrows#" step="1">
				<cfscript>
				numFieldsets = numFieldsets + 1;
				prefixOne = "subform_#attributes.tablename#_a1_";
				prefix = "subform_#attributes.tablename#_a#j#_";
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
	<!--- /If this subform tag has qfield tag below it --->
	<!--- || HANDLE FORM SUBMISSION || --->
	<cfif isDefined("form.sebformsubmit") AND form.sebformsubmit eq Hash(ParentAtts.formname)>
		<!--- || CHECK FOR DELETIONS || --->
		<cfif qsubdata.RecordCount>
			<cfset hasDeletion = false>
			<cfset arrDeleteRecords = ArrayNew(1)>
			<cfloop index="j" from="1" to="#qsubdata.RecordCount#" step="1">
				<cfscript>
				prefix = "subform_#attributes.tablename#_e#qsubdata[attributes.pkfield][j]#_";
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
					DELETE FROM	#attributes.tablename#
					WHERE		#attributes.pkfield# = <cfqueryparam value="#RecordID#" cfsqltype="CF_SQL_INTEGER">
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
