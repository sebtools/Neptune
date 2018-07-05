<cfparam name="attributes.starthour" type="numeric" default="6">
<cfparam name="attributes.endhour" type="numeric" default="20">
<cfparam name="attributes.hasJQuery" type="boolean" default="false">
<cfparam name="attributes.librarypath" type="string" default="/lib/">

<cfset attributes.starthour = Int(attributes.starthour)>
<cfset attributes.endhour = Int(attributes.endhour)>

<cfif attributes.starthour LT 0>
	<cfset attributes.starthour = 0>
</cfif>
<cfif attributes.starthour GT 22>
	<cfset attributes.starthour = 22>
</cfif>
<cfif attributes.endhour LT 1>
	<cfset attributes.endhour = 1>
</cfif>
<cfif attributes.endhour GT 23>
	<cfset attributes.endhour = 23>
</cfif>

<cfif NOT isDefined("request.sebField_jtime")>
	<cfsavecontent variable="head"><cfoutput><cfif NOT attributes.hasJQuery><script src="#attributes.librarypath#jquery.js"></script></cfif><link rel="stylesheet" href="#attributes.librarypath#jquery/jquery.clockpick.1.2.9.css" type="text/css"><script src="#attributes.librarypath#jquery/jquery.clockpick.1.2.9.min.js"></script></cfoutput></cfsavecontent>
	<cfhtmlhead text="#head#">
<cfsavecontent variable="head2"><cfoutput><script type="text/javascript">$(function() {
	$( 'input[type="text"].jtime' ).clockpick();
});</script></cfoutput></cfsavecontent>
<cfhtmlhead text="#head2#">
	<cfset request.sebField_jtime = now()>
</cfif>

<cfset attributes.fieldname = "#attributes.fieldname#">

<cfif isDate(attributes.value)><cfset attributes.value = TimeFormat(attributes.value)></cfif>
<cfsavecontent variable="input"><cfoutput><input type="text" name="#attributes.fieldname#"<cfif Len(attributes.id)> id="#attributes.id#"</cfif> value="#HTMLEditFormat(attributes.value)#"<cfloop index="thisHtmlAtt" list="#liHtmlAtts#"><cfif Len(attributes[thisHtmlAtt])> #thisHtmlAtt#="#attributes[thisHtmlAtt]#"</cfif></cfloop><cfif Len(attributes.length)> maxlength="#attributes.length#"</cfif>/></cfoutput></cfsavecontent>
