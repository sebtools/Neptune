<!---
1.0 RC8 (Build 120)
Last Updated: 2011-01-16
Created by Steve Bryant 2004-06-01
Information: sebtools.com
Documentation:
http://www.bryantwebconsulting.com/cftags/cf_sebSubField.htm
---><cfsilent>
<cfset TagName = "cf_sebSubField">
<cfset ParentTag = "cf_sebField">
<cfif NOT isDefined("ThisTag.ExecutionMode") OR NOT ListFindNoCase(GetBaseTagList(), ParentTag)>
	<cfthrow message="&lt;#TagName#&gt; must be called as a custom tag between &lt;#ParentTag#&gt; and &lt;/#ParentTag#&gt;" type="cftag">
</cfif>
<cfif ThisTag.ExecutionMode EQ "Start">
	<cfassociate basetag="#ParentTag#" datacollection="qsubfields">
	<cfparam name="attributes.display" default="">
	<cfparam name="attributes.value" default="">
	<cfparam name="attributes.checked" default="false" type="boolean">
	<cfparam name="attributes.other" default="false" type="boolean">
</cfif>
</cfsilent>