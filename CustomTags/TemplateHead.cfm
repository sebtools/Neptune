<!---
I can be used to add multiple items to the head.
I must be called before <cf_Template>, but I can be used multiple times on one page.
--->
<cfscript>
if ( NOT StructKeyExists(Caller,"TemplateAttributes") ) {
	Caller["TemplateAttributes"] = {};
}
if ( NOT StructKeyExists(Caller["TemplateAttributes"],"head") ) {
	Caller["TemplateAttributes"]["head"] = "";
}
if ( ThisTag.ExecutionMode EQ "End" ) {
	Caller["TemplateAttributes"]["head"] &= ThisTag.GeneratedContent;
	ThisTag.GeneratedContent = "";
}
</cfscript>
