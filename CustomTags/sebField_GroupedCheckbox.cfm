<cfsilent>
	<cfparam name="attributes.fieldtype" default="checkbox">
<!--- Make sure subquery exists --->
<cfif
	NOT (
				StructKeyExists(attributes,"subquery")
			AND	StructKeyExists(Caller,attributes.subquery)
			AND	isQuery(Caller[attributes.subquery])
		)
>
	<cfthrow type="sebField" message="sebField type GroupedCheckbox requires the name of a query to be passed in to the subquery attribute.">
</cfif>
<cfset qRecords = Caller[attributes.subquery]>
<!--- Make sure groupfield column exists --->
<cfif NOT ( StructKeyExists(attributes,"groupfield") AND ListFindNoCase(qRecords.ColumnList,attributes.groupfield) )>
	<cfthrow type="sebField" message="sebField type GroupedCheckbox requires a groupfield attribute representing a field in the query.">
</cfif>
<!--- Default grouplabel to groupfield --->
<cfif NOT ( StructKeyExists(attributes,"grouplabel") AND ListFindNoCase(qRecords.ColumnList,attributes.grouplabel) )>
	<cfset attributes.grouplabel = attributes.groupfield>
</cfif>

</cfsilent><cfsavecontent variable="input">
<cfoutput><fieldset class="checkbox" id="#attributes.id#_set"<cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt]) AND thisHtmlAtt neq "size"> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop>></cfoutput>
	<cfoutput query="qRecords" group="#attributes.groupfield#">
		<div class="#attributes.id#_groupout" id="#attributes.id#_groupout_#qRecords[attributes.groupfield][CurrentRow]#">
			<strong class="#attributes.id#_grouplabel" id="#attributes.id#_grouplabel_#qRecords[attributes.groupfield][CurrentRow]#">#qRecords[attributes.grouplabel][CurrentRow]#</strong>
			<div class="#attributes.id#_groupin" id="#attributes.id#_groupin_#qRecords[attributes.groupfield][CurrentRow]#"><cfoutput><cfset thisID = "#attributes.id#_#CurrentRow#">
				<input type="#attributes.fieldtype#" id="#thisID#" name="#attributes.fieldname#" value="#HTMLEditFormat(qRecords[attributes.subvalues][CurrentRow])#"<cfif ListFindNoCase(attributes.value,qRecords[attributes.subvalues][CurrentRow])> checked="checked"</cfif>/> <label id="lbl-#thisID#" for="#thisID#">#qRecords[attributes.subdisplays][CurrentRow]#</label><br/></cfoutput>
			</div>
		</div>
	</cfoutput>
</fieldset>
</cfsavecontent>
