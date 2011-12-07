<cfif ThisTag.ExecutionMode EQ "End"><cfsilent>
	<cfif NOT StructKeyExists(Attributes,"NoticeMgr")>
		<cfif StructKeyExists(Caller,"NoticeMgr")>
			<cfset Attributes.NoticeMgr = Caller.NoticeMgr>
		<cfelseif StructKeyExists(Application,"NoticeMgr")>
			<cfset Attributes.NoticeMgr = Application.NoticeMgr>
		</cfif>
	</cfif>
	<cfif NOT StructKeyExists(Attributes,"DataKeys")>
		<cfset Attributes.DataKeys = "">
		<cfset ii = 1>
		<cfloop condition="#ii# GT 0">
			<cfset sFind = ReFindNoCase("\[\w[\w\d-]*\]",ThisTag.GeneratedContent,ii,true)>
			<cfset ii = sFind.pos[1] + sFind.len[1]>
			<cfif ii>
				<cfset word = Mid(ThisTag.GeneratedContent,sFind.pos[1]+1,sFind.len[1]-2)>
				<cfif NOT ListFindNoCase(Attributes.DataKeys,word)>
					<cfset Attributes.DataKeys = ListAppend(Attributes.DataKeys,word)>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>
	<cfparam name="Attributes.NoticeMgr">
	<cfparam name="Attributes.action" default="addText"><!--- addText or addHTML --->
	<cfparam name="Attributes.Component">
	<cfparam name="Attributes.Name">
	<cfparam name="Attributes.Subject">
	<cfparam name="Attributes.DataKeys" type="string">
	<cfparam name="Attributes.trim" type="boolean" default="true">
	
	<cfset Contents = ThisTag.GeneratedContent>
	<cfset ThisTag.GeneratedContent = "">
	<cfif Attributes.trim>
		<cfset Contents = Trim(Contents)>
	</cfif>
	
	<cfinvoke component="#Attributes.NoticeMgr#" method="addNotice">
		<cfinvokeargument name="Component" value="#Attributes.Component#">
		<cfinvokeargument name="Name" value="#Attributes.Name#">
		<cfinvokeargument name="Subject" value="#Attributes.Subject#">
		<cfif Attributes.action EQ "addHTML">
			<cfinvokeargument name="HTML" value="#Contents#">
		<cfelse>
			<cfinvokeargument name="Text" value="#Contents#">
		</cfif>
		<cfinvokeargument name="DataKeys" value="#Attributes.DataKeys#">
	</cfinvoke>
	
</cfsilent></cfif>