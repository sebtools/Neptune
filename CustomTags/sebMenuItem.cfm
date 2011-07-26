<!---
1.0 RC8 (Build 120)
Last Updated: 2011-01-16
Created by Steve Bryant 2004-06-01
Tim Jackson provided the original tags as well as the inpiration and brilliant implementation of consistency for admin sections.
Information: sebtools.com
Documentation:
http://www.bryantwebconsulting.com/cftags/cf_sebform.htm
---><cfsilent>
<cfif isDefined("ThisTag.ExecutionMode") AND ( (Not ThisTag.HasEndTag) OR ThisTag.ExecutionMode eq "End" )>
	<cfset TagName = "cf_sebMenuItem"><cfset ParentTag = "cf_sebMenu">
	<cfparam name="attributes.Label" default="Admin">
	<cfparam name="attributes.Link" default="admin_mgr.cfm">
	<cfparam name="attributes.target" default="">
	<cfparam name="attributes.pages" default="">
	<cfparam name="attributes.intabs" default="true"><!--- dre 2006-11-09 --->
	<cfparam name="attributes.folder" default="">
	<cfif ListFindNoCase(GetBaseTagList(), ParentTag)>
		<cfassociate basetag="#ParentTag#" datacollection="items">
	<cfelse>
		<cfthrow message="&lt;#TagName#&gt; must be called as a custom tag between &lt;#ParentTag#&gt; and &lt;/#ParentTag#&gt;" type="cftag">
	</cfif>
	<cfif StructKeyExists(ThisTag, "items")>
		<cfset attributes.items = ThisTag.items>
	<cfelse>
		<cfset attributes.items = ArrayNew(1)>
	</cfif>
	
	<cfif Len(attributes.folder) AND NOT Right(attributes.folder,1) eq "/">
		<cfset attributes.folder = "#attributes.folder#/">
	</cfif>
	<cfif NOT Len(attributes.folder)>
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
</cfif>
</cfsilent>