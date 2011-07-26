<cfparam name="attributes.maxfiles" type="numeric" default="3">
<cfif NOT isDefined("request.sebField_MultiFileJS")>
	<cfsavecontent variable="head"><cfoutput><script src="/lib/multifile_compressed.js"></script></cfoutput></cfsavecontent>
	<cfhtmlhead text="#head#">
	<cfset request.sebField_MultiFileJS = now()>
</cfif>

<cfset attributes.fieldname = "#attributes.fieldname#">
<cfset ParentAtts.enctype = "multipart/form-data">

<cfsavecontent variable="input"><cfoutput>
<input type="hidden" name="#attributes.fieldname#">
<input type="file" name="#attributes.fieldname#_1" id="#attributes.id#">
<div id="files_list_#attributes.id#"></div>
<script>
// Create an instance of the multiSelector class, pass it the output target and the max number of files -->
var multi_selector_#attributes.id# = new MultiSelector( document.getElementById('files_list_#attributes.id#'), #attributes.maxfiles#, '#attributes.fieldname#');
// Pass in the file element -->
multi_selector_#attributes.id#.addElement( document.getElementById('#attributes.id#') );
</script>
</cfoutput></cfsavecontent>