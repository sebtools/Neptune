<cfif ThisTag.ExecutionMode EQ "End"><cfsilent>
	<cfif NOT StructKeyExists(attributes,"NoticeMgr")>
		<cfif StructKeyExists(Caller,"NoticeMgr")>
			<cfset attributes.NoticeMgr = Caller.NoticeMgr>
		<cfelseif StructKeyExists(Application,"NoticeMgr")>
			<cfset attributes.NoticeMgr = Application.NoticeMgr>
		</cfif>
	</cfif>
	<cfparam name="attributes.NoticeMgr">
	<cfparam name="attributes.action" default="addText"><!--- addText or addHTML --->
	<cfparam name="attributes.Component">
	<cfparam name="attributes.Name">
	<cfparam name="attributes.Subject">
	<cfparam name="attributes.DataKeys">
	<cfparam name="attributes.trim" type="boolean" default="true">
	
	<cfset Contents = ThisTag.GeneratedContent>
	<cfset ThisTag.GeneratedContent = "">
	<cfif attributes.trim>
		<cfset Contents = Trim(Contents)>
	</cfif>
	
	<cfinvoke component="#attributes.NoticeMgr#" method="addNotice">
		<cfinvokeargument name="Component" value="#attributes.Component#">
		<cfinvokeargument name="Name" value="#attributes.Name#">
		<cfinvokeargument name="Subject" value="#attributes.Subject#">
		<cfif attributes.action EQ "addHTML">
			<cfinvokeargument name="HTML" value="#Contents#">
		<cfelse>
			<cfinvokeargument name="Text" value="#Contents#">
		</cfif>
		<cfinvokeargument name="DataKeys" value="#attributes.DataKeys#">
	</cfinvoke>
	
</cfsilent></cfif>