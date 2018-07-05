<!---
1.0 RC9 (Build 121)
Last Updated: 2011-10-11
Created by Steve Bryant 2004-06-01
Information: http://www.bryantwebconsulting.com/docs/sebtags/?version=1.0
Documentation:
http://www.bryantwebconsulting.com/docs/sebtags/sebmenu-basics.cfm?version=1.0
Tim Jackson provided the original tags as well as the inpiration and brilliant implementation of consistency for admin sections.
---><cfsilent>
<cfif isDefined("ThisTag.ExecutionMode") AND ( (Not ThisTag.HasEndTag) OR ThisTag.ExecutionMode eq "End" )>
	<cfset TagName = "cf_sebMenuSubItem"><cfset ParentTag = "cf_sebMenuItem">
	<cfparam name="attributes.Label" default="Admin">
	<cfparam name="attributes.Link" default="admin_mgr.cfm">
	<cfparam name="attributes.target" default="">
	<cfparam name="attributes.pages" default="">
	<cfif ListFindNoCase(GetBaseTagList(), ParentTag)>
		<cfassociate basetag="#ParentTag#" datacollection="items">
	<cfelse>
		<cfthrow message="&lt;#TagName#&gt; must be called as a custom tag between &lt;#ParentTag#&gt; and &lt;/#ParentTag#&gt;" type="cftag">
	</cfif>
	<cfif Right(attributes.link,1) EQ "/">
		<cfset attributes.folder = attributes.link>
	<cfelseif ListLen(attributes.link,"/") GT 1>
		<cfset attributes.folder = ListDeleteAt(attributes.link,ListLen(attributes.link,"/"),"/")>
		<cfif Right(attributes.folder,1) NEQ "/">
			<cfset attributes.folder = "#attributes.folder#/">
		</cfif>
	<cfelse>
		<cfset attributes.folder = "">
	</cfif>
</cfif>
</cfsilent>