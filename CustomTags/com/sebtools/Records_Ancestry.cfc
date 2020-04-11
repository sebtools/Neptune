<cfcomponent displayname="Records (Ancestry)" extends="com.sebtools.Records" output="no">

<cffunction name="getAncestors" access="public" returntype="string" output="no">

	<cfset var sMeta = getMetaStruct()>
	<cfset var PrimaryKeyName = sMeta.arg_pk>
	<cfset var ParentKeyName = "Parent#PrimaryKeyName#">
	<cfset var ii = 0>
	<cfset var NumRecs = numRecords()>
	<cfset var sGet = 0>
	<cfset var qRecord = 0>
	<cfset var result = "">

	<cfset Arguments = convertArgs(ArgumentCollection=Arguments)>

	<cfset sGet = {"#PrimaryKeyName#"=Arguments[PrimaryKeyName]}>
	<cfset qRecord = getRecord(ArgumentCollection=sGet,fieldlist=ParentKeyName)>

	<cfscript>
	if ( Val(qRecord[ParentKeyName][1]) ) {
		result = qRecord[ParentKeyName][1];
	}
	//Traverse up the tree to find all of the parents (but no more times than records exist)
	while ( ii LT NumRecs AND Val(qRecord[ParentKeyName][1]) ) {
		sGet = {"#PrimaryKeyName#"=qRecord[ParentKeyName][1]};
		qRecord = getRecord(ArgumentCollection=sGet,fieldlist=ParentKeyName);
		//Prepend if there is a parent that isn't already in the list.
		if ( Val(qRecord[ParentKeyName][1]) AND NOT ListFindNoCase(result,qRecord[ParentKeyName][1]) ) {
			result = ListPrepend(result,qRecord[ParentKeyName][1]);
		} else {
			break;
		}
		ii = ii + 1;
	}
	</cfscript>

	<cfreturn result>
</cffunction>

<cffunction name="getAncestorNamesParentID" access="public" returntype="string" output="no">
	<cfargument name="AncestorNames" type="string" required="yes">

	<cfset var sMeta = getMetaStruct()>
	<!--- The last item on the AncestorNames list will be the label of the direct parent. --->
	<cfset var sRecord = {
		"#sMeta.field_label#"=Trim(ListLast(Arguments.AncestorNames,"|")),
		fieldlist="#sMeta.arg_pk#"
	}>
	<cfset var qRecord = 0>

	<!--- If no AncesterNames value is passed, then no ancestor (return NULL) --->
	<cfif NOT Len(Arguments.AncestorNames)>
		<cfreturn "">
	</cfif>

	<cfif ListLen(Arguments.AncestorNames,"|") GT 1>
		<cfset sRecord["AncestorNames"] = getAncestorNamesParentNames(Arguments.AncestorNames)>
	<cfelse>
		<cfset sRecord["AncestorNames"] = "">
	</cfif>

	<!--- Find the ancestor record indicated --->
	<cfset qRecord = getRecords(ArgumentCollection=sRecord)>

	<!--- If an ancestor record is found, return its id. --->
	<cfif qRecord.RecordCount>
		<cfreturn qRecord[sMeta.arg_pk][1]>
	</cfif>

	<!--- If no record found, then no ancestor (return NULL) --->
	<cfreturn "">
</cffunction>

<cffunction name="getAncestorNamesParentNames" access="public" returntype="string" output="no">
	<cfargument name="AncestorNames" type="string" required="yes">

	<cfset var result = "">

	<!--- If AncestorNames has more than one value then the values before the first will be the AncestorNames for the parent. --->
	<cfif ListLen(Arguments.AncestorNames,"|") GT 1>
		<cfset result = ListDeleteAt(
			Arguments.AncestorNames,
			ListLen(
				Arguments.AncestorNames,
				"|"
			),
			"|"
		)>
	</cfif>

	<cfreturn result>
</cffunction>

<cffunction name="getAncestorNames" access="public" returntype="string" output="no">
	<cfargument name="Ancestors" type="string" required="yes">

	<cfset var sMeta = getMetaStruct()>
	<cfset var qAncestors = 0>
	<cfset var sAdvSQL = {}>
	<cfset var OrderBy = "">
	<cfset var ii = 0>
	<cfset var result = "">
	<cfset var sArgs = 0>

	<!--- Put records in order of list of ancestors --->
	<cfset OrderBy = "case #sMeta.pkfields# ">
	<cfloop index="ii" from="1" to="#ListLen(Arguments.Ancestors)#">
		<cfset OrderBy = "#OrderBy# WHEN #ListGetAt(Arguments.Ancestors,ii)# THEN #ii#">
	</cfloop>
	<cfset OrderBy = "#OrderBy# ELSE #ii+1#">
	<cfset OrderBy = "#OrderBy# END">

	<cfset sAdvSQL["ORDER BY"] = ArrayNew(1)>
	<cfset ArrayAppend(sAdvSQL["ORDER BY"],OrderBy)>

	<cfset sArgs = {
		"#sMeta.method_Plural#"=Arguments.Ancestors,
		fieldlist="#sMeta.field_label#",
		AdvSQL=sAdvSQL
	}>

	<cfset qAncestors = getRecords(ArgumentCollection=sArgs)>

	<cfoutput query="qAncestors">
		<cfset result = ListAppend(result,qAncestors[sMeta.field_label][CurrentRow],"|")>
	</cfoutput>

	<cfreturn result>
</cffunction>

<cffunction name="saveRecord" access="public" returntype="string" output="no">

	<cfset var result = 0>

	<cfset result = Super.saveRecord(ArgumentCollection=Arguments)>

	<cfset setAncestors(result)>

	<cfreturn result>
</cffunction>

<cffunction name="setAncestors" access="public" returntype="void" output="no">

	<cfset var sMeta = getMetaStruct()>
	<cfset var sDescend = 0>
	<cfset var qDescendants = 0>
	<cfset var ancestor = "">

	<cfset Arguments = convertArgs(ArgumentCollection=Arguments)>

	<cfset sDescend = {"Parent#sMeta.arg_pk#"=Arguments[sMeta.arg_pk],fieldlist=sMeta.arg_pk}>
	<cfset qDescendants = getRecords(ArgumentCollection=sDescend)>

	<cfset Arguments.Ancestors = getAncestors(Arguments[sMeta.arg_pk])>
	<cfif Len(Arguments.Ancestors)>
		<cfset Arguments.AncestorNames = getAncestorNames(Arguments.Ancestors)>
	<cfelse>
		<cfset Arguments.AncestorNames = "">
	</cfif>

	<cfset variables.DataMgr.saveRecord(tablename=variables.table,data=Arguments,fieldlist="#sMeta.arg_pk#,Ancestors,AncestorNames")>

	<cfif NOT ( StructKeyExists(Arguments,"recurse") AND Arguments.recurse EQ false )>
		<cfloop query="qDescendants">
			<cfset setAncestors(qDescendants[sMeta.arg_pk][CurrentRow])>
		</cfloop>
	</cfif>

</cffunction>

<cffunction name="validateRecord" access="public" returntype="struct" output="no">

	<cfset var sArgs = Super.validateRecord(ArgumentCollection=Arguments)>

	<cfset sArgs = validateAncestry(ArgumentCollection=sArgs)>

	<cfreturn sArgs>
</cffunction>

<cffunction name="convertArgs" access="private" returntype="struct" output="no">

	<cfset var sMeta = getMetaStruct()>

	<!--- If primary key argument isn't passed in by name, then get it from the first argument. --->
	<cfif NOT StructKeyExists(Arguments,sMeta.arg_pk)>
		<cfset Arguments[sMeta.arg_pk] = Arguments[1]>
		<cfset StructDelete(Arguments,"1")>
	</cfif>

	<cfreturn Arguments>
</cffunction>

<cffunction name="validateAncestry" access="private" returntype="struct" output="no" hint="I make sure that the ancestry can work.">

	<cfset var sMeta = getMetaStruct()>
	<cfset var qBefore = 0>
	<cfset var sRec = 0>

	<!--- Make sure that the label doesn't contain a pipe. --->
	<cfif
			StructKeyExists(Arguments,smeta.label_Singular)
		AND	isSimpleValue(Arguments[smeta.label_Singular])
		AND	Len(Arguments[smeta.label_Singular])
		AND	Arguments[smeta.label_Singular] CONTAINS "|"
	>
		<cfset Arguments[smeta.label_Singular] = ReplaceNoCase(Arguments[smeta.label_Singular],"|","&##124;","ALL")>
	</cfif>

	<!--- Allow parent value to be set using ancestor arguments --->
	<cfif NOT StructKeyExists(Arguments,"Parent#sMeta.arg_pk#")>
		<cfif StructKeyHasLen(Arguments,"Ancestors")>
			<cfset Arguments["Parent#sMeta.arg_pk#"] = ListLast(Arguments.Ancestors)>
		<cfelseif StructKeyHasLen(Arguments,"AncestorNames")>
			<cfset Arguments["Parent#sMeta.arg_pk#"] = getAncestorNamesParentID(Arguments.AncestorNames)>
			<cfif NOT Val(Arguments["Parent#sMeta.arg_pk#"])>
				<cfset StructDelete(Arguments,"Parent#sMeta.arg_pk#")>
				<cfif StructKeyExists(Arguments,"createMissingAncestors") AND Arguments.createMissingAncestors IS true>
					<cfinvoke
						component="#This#"
						method="save#variables.methodSingular#"
						returnvariable="Arguments.Parent#sMeta.arg_pk#"
					>
						<cfinvokeargument name="#smeta.field_label#" value="#ListLast(Arguments.AncestorNames,'|')#">
						<cfinvokeargument name="AncestorNames" value="#getAncestorNamesParentNames(Arguments.AncestorNames)#">
						<cfinvokeargument name="createMissingAncestors" value="true">
					</cfinvoke>
				<cfelse>
					<cfthrow type="#smeta.method_Plural#" message="AncestorNames (#Arguments.AncestorNames#) passed in for which no value was found.">
				</cfif>
			</cfif>
		<cfelse>
			<cfset Arguments["Parent#sMeta.arg_pk#"] = "">
		</cfif>
	</cfif>

	<!--- Make sure that a record cannot change its parent --->
	<cfif StructKeyExists(Arguments,"#sMeta.arg_pk#") AND StructKeyExists(Arguments,"Parent#sMeta.arg_pk#")>
		<cfset sRec = {"#sMeta.arg_pk#"=Arguments[sMeta.arg_pk],fieldlist="Parent#sMeta.arg_pk#"}>
		<cfset qBefore = getRecord(ArgumentCollection=sRec)>
		<cfif
			qBefore.RecordCount
			AND
			qBefore["Parent#sMeta.arg_pk#"][1] NEQ Arguments["Parent#sMeta.arg_pk#"]
		>
			<cfthrow type="#smeta.method_Plural#" message="Parent #LCase(smeta.label_Plural)# may not be altered.">
		</cfif>
	</cfif>

	<!--- Make sure than a record is not its own ancestor --->
	<cfset StructDelete(Arguments,"Ancestors")>
	<cfset StructDelete(Arguments,"AncestorNames")>
	<cfif
			StructKeyExists(Arguments,"#sMeta.arg_pk#")
		AND StructKeyExists(Arguments,"Parent#sMeta.arg_pk#")
		AND	isNumeric(Arguments["#sMeta.arg_pk#"])
		AND	isNumeric(Arguments["Parent#sMeta.arg_pk#"])
	>
		<cfset Arguments.Ancestors = getAncestors(Arguments["Parent#sMeta.arg_pk#"])>
		<cfif ( Arguments["Parent#sMeta.arg_pk#"] EQ Arguments["#sMeta.arg_pk#"] OR ListFindNoCase(Arguments.Ancestors,Arguments["#sMeta.arg_pk#"]) )>
			<cfset variables.Parent.throwError("A #LCase(sMeta.label_Singular)# cannot be a child of itself.")>
		</cfif>
	</cfif>

	<cfreturn Arguments>
</cffunction>

</cfcomponent>
