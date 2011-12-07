<!---
1.0 RC9 (Build 121)
Last Updated: 2011-10-11
Created by Steve Bryant 2004-06-01
Information: http://www.bryantwebconsulting.com/docs/sebtags/?version=1.0
Documentation:
http://www.bryantwebconsulting.com/docs/sebtags/sebgroup-overview.cfm?version=1.0
---><cfsilent>
<cfset TagName = "cf_sebGroup">
<cfset ValidTypes = "accordion,fieldset,ColumnsTable,Column">
<cfset ParentTag = "cf_sebForm"><cfset ParentTag2 = "cf_sebTable">
<cfparam name="attributes.type" type="string" default="fieldset">
<cfparam name="attributes.label" type="string" default="">
<cfparam name="attributes.link" type="string" default="">
<cfparam name="attributes.class" type="string" default="sebGroup">
<cfparam name="attributes.help" type="string" default="">
<cfset htmlatts = "id,style">
<cfscript>
ParentData = getBaseTagData("cf_sebForm");
ParentAtts = ParentData.attributes;
sForm = ParentData.sForm;
</cfscript>
<cfparam name="attributes.minimize" type="boolean" default="#ParentAtts.minimize#">

<cfif ThisTag.ExecutionMode EQ "End" OR (ThisTag.ExecutionMode eq "Start" AND NOT ThisTag.HasEndTag)>
	<cfif StructKeyExists(ThisTag,"aFields")>
		<cfset attributes.aFields = ThisTag.aFields>
		<cfset attributes.fields = "">
		<cfloop index="ii" from="1" to="#ArrayLen(ThisTag.aFields)#">
			<cfset field = ThisTag.aFields[ii].fieldname>
			<cfset attributes.fields = ListAppend(attributes.fields,field)>
			<cfif StructKeyExists(sForm,field) AND Len(Trim(sForm[field]))>
				<cfset ParentData.sEffectiveHasDataFields[field] = true>
			</cfif>
		</cfloop>
	</cfif>
	<cfif ListFindNoCase(GetBaseTagList(), ParentTag2)>
		<cfassociate basetag="#ParentTag2#" datacollection="aGroups">
	<cfelseif ListFindNoCase(GetBaseTagList(), ParentTag)>
		<cfassociate basetag="#ParentTag#" datacollection="aGroups">
	<cfelse>
		<cfthrow message="&lt;#TagName#&gt; must be called as a custom tag between &lt;#ParentTag#&gt; and &lt;/#ParentTag#&gt;" type="cftag">
	</cfif>
</cfif>

<!--- Get parent attributes --->
<cfif ListFindNoCase(GetBaseTagList(), ParentTag)>
	<cfset ParentAtts = request.cftags.cf_sebForm.attributes>
<cfelse>
	<cfset ParentAtts = StructNew()>
</cfif>

<!--- If a component is passed in, try to get field information from it. --->
<cfif
		isDefined("attributes.CFC_Component")
	AND (
				StructKeyExists(attributes.CFC_Component,"getFieldsStruct")
			OR	getMetaData(attributes.CFC_Component).extends.name EQ "_framework.PageController"
			OR	getMetaData(attributes.CFC_Component).extends.name CONTAINS "Master"
			OR	getMetaData(attributes.CFC_Component).extends.name CONTAINS "Records"
		)
	AND	StructKeyExists(ParentAtts,"sFields")
>
	<cftry>
		<cfset StructAppend(ParentAtts.sFields,attributes.CFC_Component.getFieldsStruct(transformer="sebField"),"no")>
		<!--- If component has getFieldStruct, make sure to catch "Master" errors --->
		<cfif NOT ListFindNoCase(attributes.CatchErrTypes,"Master")>
			<cfset ParentAtts.CatchErrTypes = ListAppend(ParentAtts.CatchErrTypes,"Master")>
		</cfif>
		<cfif NOT ListFindNoCase(attributes.CatchErrTypes,"Records")>
			<cfset ParentAtts.CatchErrTypes = ListAppend(ParentAtts.CatchErrTypes,"Records")>
		</cfif>
	<cfcatch>
	</cfcatch>
	</cftry>
</cfif>
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
		<cfif isDefined("sCompMeta") AND isStruct(sCompMeta)>
			<cfif StructKeyExists(sCompMeta,"label_Singular") AND Len(sCompMeta.label_Singular) AND NOT ( StructKeyExists(attributes,"Label") AND Len(attributes.Label) )>
				<cfset attributes.Label = sCompMeta.label_Singular>
			</cfif>
			<cfif StructKeyExists(sCompMeta,"arg_pk") AND Len(sCompMeta.arg_pk) AND NOT ( StructKeyExists(attributes,"pkfield") AND Len(attributes.pkfield) )>
				<cfset attributes.pkfield = sCompMeta.arg_pk>
			</cfif>
			<cfif StructKeyExists(sCompMeta,"method_save") AND Len(sCompMeta.method_save) AND NOT isDefined("attributes.CFC_Method")>
				<cfset attributes.CFC_Method = sCompMeta.method_save>
			</cfif>
			<cfif StructKeyExists(sCompMeta,"method_get") AND Len(sCompMeta.method_get) AND NOT isDefined("attributes.CFC_GetMethod")>
				<cfset attributes.CFC_GetMethod = sCompMeta.method_get>
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
<cfif
		( StructKeyExists(attributes,"fkfield") AND Len(Trim(attributes.fkfield)) )
	AND	(
				StructKeyExists(attributes,"CFC_Component")
			AND	StructKeyExists(attributes,"CFC_Method")
			AND	Len(Trim(attributes.CFC_Method))
		)
	AND	( StructKeyExists(ParentAtts,"sFields") AND StructKeyExists(ParentAtts.sFields,attributes.fkfield) )
>
	<cfset attributes.isFKField = true>
	<cfif ThisTag.ExecutionMode EQ "End" OR (ThisTag.ExecutionMode EQ "Start" AND NOT ThisTag.HasEndTag)>
		<cfif ListFindNoCase(GetBaseTagList(), ParentTag2)>
			<cfassociate basetag="#ParentTag2#" datacollection="aFKGroups">
		<cfelseif ListFindNoCase(GetBaseTagList(), ParentTag)>
			<cfassociate basetag="#ParentTag#" datacollection="aFKGroups">
		</cfif>
	</cfif>
<cfelse>
	<cfset attributes.isFKField = false>
</cfif>

<cfif attributes.isFKField>
	<cfset ParentAtts.sebformjs = true>
</cfif>

<cfif attributes.isFKField AND NOT ( StructKeyExists(attributes,"id") AND Len(Trim(attributes.id)) )>
	<cfset attributes.id = "group-#attributes.fkfield#">
</cfif>
<cfset attributes.CatchErrTypes = ParentAtts.CatchErrTypes>

<!--- HTML attributes ---><!--- (must be after isFkField and related id set) --->
<cfset atts = "">
<cfloop list="#htmlatts#" index="att">
	<cfif StructKeyExists(attributes,att)>
		<cfset atts = "#atts# #att#=""#attributes[att]#""">
	</cfif>
</cfloop>

<cfif attributes.type NEQ "hr" AND NOT ThisTag.HasEndTag>
	<cfthrow message="#TagName# must have an end tag." type="ctag">
</cfif>
</cfsilent>
<cfoutput>
<cfif ThisTag.ExecutionMode eq "End" AND Len(Trim(ThisTag.GeneratedContent))>
<cfif StructKeyExists(ParentAtts,"format") AND ParentAtts.format eq "table">
	<tr><td colspan="2">
</cfif>
<cfswitch expression="#attributes.type#">
<cfcase value="accordion">
<div class="accordion-header"#atts#><cfif Len(attributes.link)><a href="#attributes.link#">#attributes.label#</a><cfelse>#attributes.label#</cfif></div><div class="accordion-body">
</cfcase>
<cfcase value="ColumnsTable">
<div class="#attributes.class#"#atts#><table class="sebFormColumns"><tr>
</cfcase>
<cfcase value="Column">
<td class="#attributes.class#"#atts#>
</cfcase>
<cfcase value="fieldset">
<fieldset class="#attributes.class#"#atts#><legend>#attributes.label#</legend>
</cfcase>
<cfcase value="label">
<div class="#attributes.class#"#atts#><div>#attributes.label#</div>
</cfcase>
<cfcase value="hr">
<hr/>
</cfcase>
</cfswitch>
<cfif StructKeyExists(ParentAtts,"format") AND ParentAtts.format eq "table">
	<table>
</cfif>
#ThisTag.GeneratedContent#
<cfif StructKeyExists(ParentAtts,"format") AND ParentAtts.format eq "table">
	</table>
</cfif>
<cfswitch expression="#attributes.type#">
<cfcase value="accordion">
</div>
</cfcase>
<cfcase value="ColumnsTable">
</tr></table></div>
</cfcase>
<cfcase value="Column">
</td>
</cfcase>
<cfcase value="fieldset">
</fieldset>
</cfcase>
<cfcase value="label">
</div>
</cfcase>
<cfcase value="hr">
</cfcase>
</cfswitch>
<cfset ThisTag.GeneratedContent = "">
<cfif Len(Trim(attributes.help))><div class="sebHelp">#attributes.help#</div></cfif>
<cfif StructKeyExists(ParentAtts,"format") AND ParentAtts.format eq "table">
	</td></tr>
</cfif>
</cfif><!---<cfexit>
<cfif StructKeyExists(ParentAtts,"format") AND ParentAtts.format eq "table">
	<cfif ThisTag.ExecutionMode eq "End"></table></cfif>
	<cfif ThisTag.ExecutionMode eq "Start"><tr><td colspan="2"></cfif>
</cfif>
<cfswitch expression="#attributes.type#">
<cfcase value="accordion">
<cfif ThisTag.ExecutionMode eq "Start"><div class="accordion-header"#atts#><cfif Len(attributes.link)><a href="#attributes.link#">#attributes.label#</a><cfelse>#attributes.label#</cfif></div><div class="accordion-body"><cfelseif ThisTag.ExecutionMode eq "End"></div></cfif>
</cfcase>
<cfcase value="ColumnsTable">
<cfif ThisTag.ExecutionMode eq "Start"><div class="#attributes.class#"#atts#><table class="sebFormColumns"><tr><cfelseif ThisTag.ExecutionMode eq "End"></tr></table></div></cfif>
</cfcase>
<cfcase value="Column">
<cfif ThisTag.ExecutionMode eq "Start"><td class="#attributes.class#"#atts#><cfelseif ThisTag.ExecutionMode eq "End"></td></cfif>
</cfcase>
<cfcase value="fieldset">
<cfif ThisTag.ExecutionMode eq "Start"><fieldset class="#attributes.class#"#atts#><legend>#attributes.label#</legend><cfelseif ThisTag.ExecutionMode eq "End"></fieldset></cfif>
</cfcase>
<cfcase value="label">
<cfif ThisTag.ExecutionMode eq "Start"><div class="#attributes.class#"#atts#><div>#attributes.label#</div><cfelseif ThisTag.ExecutionMode eq "End"></div></cfif>
</cfcase>
<cfcase value="hr">
<cfif ThisTag.ExecutionMode eq "Start"><hr/></cfif>
</cfcase>
</cfswitch>--->
<!---<cfif ThisTag.ExecutionMode eq "End" AND Len(Trim(attributes.help))><div class="sebHelp">#attributes.help#</div></cfif>--->
<!---<cfif StructKeyExists(ParentAtts,"format") AND ParentAtts.format eq "table">
	<cfif ThisTag.ExecutionMode eq "Start"><table></cfif>
	<cfif ThisTag.ExecutionMode eq "End"></td></tr></cfif>
</cfif>--->
</cfoutput>