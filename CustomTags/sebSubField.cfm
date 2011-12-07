<!---
1.0 RC9 (Build 121)
Last Updated: 2011-10-11
Created by Steve Bryant 2004-06-01
Information: http://www.bryantwebconsulting.com/docs/sebtags/?version=1.0
Documentation:
http://www.bryantwebconsulting.com/docs/sebtags/sebfield-mult-value-fields.cfm?version=1.0
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