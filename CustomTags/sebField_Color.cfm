<cfif NOT isDefined("request.sebField_ColorJS")>
	<cfsavecontent variable="head">
	<script language=JavaScript src="/lib/Tigra_Color_Picker/picker.js"></script>
	<script type="text/javascript">
	function changeColor(obj) {
		//alert('fired');
		//alert(obj.value);
		var swatch = document.getElementById(obj.name + '-swatch');
		swatch.style.backgroundColor = obj.value;
	}
	</script>
	</cfsavecontent>
	<cfhtmlhead text="#head#">
	<cfset request.sebField_ColorJS = now()>
</cfif>

<cfsavecontent variable="input"><cfoutput>
<input type="Text" name="#attributes.fieldname#" id="#attributes.id#" value="#attributes.value#" size="8" maxlength="7" onChange="changeColor(this);" onLoad="changeColor(this);">
<a href="javascript:TCP.popup(document.getElementById('#attributes.id#'))"><img id="#attributes.fieldname#-swatch" width="21" height="18" border="0" alt="Click Here to Pick up the color" src="/lib/Tigra_Color_Picker/img/swatch.gif" style="background-color:#attributes.value#;vertical-align:bottom;margin-bottom:2px;"></a>
</cfoutput></cfsavecontent>