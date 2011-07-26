<!---
DESCRIPTION:
Cold Fusion custom tag to embed all submitted form fields as hidden
fields in another form. Designed to be used within multi part forms.
To use just call this module between the <FORM> and </FORM> tags.

ATTRIBUTES:
None.

NOTES:
Tag processes the comma delimited list of field names available as
FORM.fieldnames (this variable is automatically available if any
form fields were submitted). Each field is checked to see that
it has not already been processed (if there were multiple fields
with the same name then they'd appear multiple times in the
FORM.fieldnames list), and then it is written out as a hidden
FORM field (INPUT TYPE="hidden").

USAGE:
To use, just include <CF_EmbedFields> anywhere between the <FORM>
and </FORM> tags (or <CFFORM> and </CFFORM>). Any passed form
fields will automatically be embedded. If no form fields are
present then nothing is embedded, and processing continues.

AUTHOR:
Ben Forta (ben@stoneage.com) 7/15/97

Edits:
Steve Bryant  12/30/2004
I rewrote the tag into a very compact cfscript-based solution that gives off no extra white space.

Steve Bryant  01/31/2007
I added the "ignorefields" attribute.
--->
<cfparam name="attributes.ignorefields" default=""><!--- Optionally ignore selected fields --->
<cfscript>
if ( isDefined("Form.FieldNames") ) {
	 for (field in Form) {
	 	if ( field NEQ "FieldNames" AND NOT ListFindNoCase(attributes.ignorefields,field) ) {
			WriteOutput('<input type="hidden" name="#field#" value="#Form[field]#" />');
		}
	 }
}
</cfscript>