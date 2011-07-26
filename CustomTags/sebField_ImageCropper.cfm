<cfparam name="attributes.maxWidth" type="numeric" />
<cfparam name="attributes.maxHeight" type="numeric" />

<cfset imgSrc = "#attributes.urlpath##attributes.value#">
<cfset imgPath = "#attributes.destination##attributes.value#">

<cfimage action="read" source="#imgPath#" name="myImg">

<cfset attributes.maxWidth = Min(attributes.maxWidth,myImg.width)>
<cfset attributes.maxHeight = Min(attributes.maxHeight,myImg.height)>

<cfif isDefined("Form.sebformsubmit") AND Form.sebformsubmit eq Hash(ParentAtts.formname)>
	<cfif
			StructKeyExists(Form,"#attributes.fieldname#_height")
		AND	StructKeyExists(Form,"#attributes.fieldname#_width")
		AND	Form["#attributes.fieldname#_height"] GT 0
		AND	Form["#attributes.fieldname#_width"] GT 0
	>
		<cfset imageCrop(
					myImg,
					Form["#attributes.fieldname#_x1"],
					Form["#attributes.fieldname#_y1"],
					Form["#attributes.fieldname#_width"],
					Form["#attributes.fieldname#_height"]
		)>
		<cfimage action="write" source="#myImg#" destination="#imgPath#" overwrite="yes">
	</cfif>
</cfif>

<cfset x1Onload = (myImg.width / 2) - Int(attributes.maxWidth/2) />
<cfset x2Onload = (myImg.width / 2) + Int(attributes.maxHeight/2) />
<cfset y1Onload = (myImg.height / 2) - Int(attributes.maxWidth/2) />
<cfset y2Onload = (myImg.height / 2) + Int(attributes.maxHeight/2) />

<cfsavecontent variable="input"><cfoutput><cf_imageCropper
		imageCropperName="#attributes.fieldname#"
		scriptSrc="/lib/cfImageCropper/" 
		displayOnInit="true"
		imgSrc="#imgSrc#"
		imgWidth="#myImg.width#"
		imgHeight="#myImg.height#"
		minWidth="#attributes.maxWidth#"
		maxWidth="#attributes.maxWidth#"
		minHeight="#attributes.maxHeight#"
		maxHeight="#attributes.maxHeight#"
		x1OnLoad="#x1Onload#"
		x2OnLoad="#x2Onload#"
		y1OnLoad="#y1Onload#"
		y2OnLoad="#y2Onload#"><input type="hidden" name="#attributes.fieldname#" value="#attributes.value#" /></cfoutput></cfsavecontent>