<!---
<form file="">
	<field name="" required="" regex="" type="" message="" digitsonly="" filter="" />
</form>

Type
	name=""
	digitsonly = true/false
	regex = ""
	isBoolean = true/false
	isDate = true/false
	isNumeric = true/false
	isInteger = true/false
--->
<cfcomponent displayname="Scrubber">

<cffunction name="init" access="public" returntype="com.sebtools.Scrubber" output="no" hint="I initialize and return this object.">
	
	<cfset variables.Forms = StructNew()>
	<cfset variables.ErrorMessages = StructNew()>
	<cfset variables.Types = StructNew()>
	
	<cfscript>
	addType(name="phone",digitsonly=true,regex="^\d{10}$");
	addType(name="phoneext",digitsonly=true,regex="^\d{10}\d*$");
	addType(name="zipcode",digitsonly=true,regex="^((\d{5})|(\d{9}))$");
	addType(name="ssn",digitsonly=true,regex="^\d{9}$");
	addType(name="date",isDate=true);
	addType(name="boolean",isBoolean=true);
	addType(name="numeric",isNumeric=true);
	addType(name="integer",isInteger=true);
	//addType(name="email",regex="^(\w+\.)*\w+@(\w+\.)+[A-Za-z]+$");
	addType(name="email",regex="^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$");
	</cfscript>
	
	<cfreturn this>
</cffunction>

<cffunction name="addForm" access="public" returntype="void" output="no" hint="I add a form to Scrubber.">
	<cfargument name="formfile" type="string" required="yes">
	<cfargument name="fields" type="struct" required="yes">
	
	<cfset variables.Forms[arguments.formfile] = arguments.fields>
	
</cffunction>

<cffunction name="addFormXML" access="public" returntype="void" output="no" hint="I add a form to Scrubber using XML.">
	<cfargument name="formfile" type="string" required="yes">
	<cfargument name="fieldsXML" type="string" required="yes">
	
	<cfset variables.Forms[arguments.formfile] = xmlForm(arguments.fieldsXML)>
	
</cffunction>

<cffunction name="addType" access="public" returntype="void" output="no" hint="I add a validation type to Scrubber.">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="digitsonly" type="boolean" default="false">
	<cfargument name="regex" type="string" default="">
	<cfargument name="isBoolean" type="boolean" default="false">
	<cfargument name="isDate" type="boolean" default="false">
	<cfargument name="isNumeric" type="boolean" default="false">
	<cfargument name="isInteger" type="boolean" default="false">
	
	<cfset variables.Types[arguments.name] = arguments>
</cffunction>

<cffunction name="scrubField" access="public" returntype="string" output="no" hint="I scrub a field.">
	<cfargument name="data" type="string" required="yes">
	<cfargument name="checks" type="struct" required="yes">
	
	<cfif Len(data)>
	
		<!--- Clear non-digits for digits only --->

		<cfif StructKeyIsTrue(checks,"digitsonly")>
			<cfset data = digitize(data)>
		</cfif>
	
		<cfif StructKeyExists(checks,"type") AND Len(checks.type)>
			<cfif StructKeyIsTrue(variables.Types[checks.type],"digitsonly")>
				<cfset data = digitize(data)>
			</cfif>
		</cfif>

	</cfif>
	
	<cfreturn data>
</cffunction>

<cffunction name="checkField" access="public" returntype="boolean" output="no" hint="I check a field.">
	<cfargument name="data" type="string" required="yes">
	<cfargument name="checks" type="struct" required="yes">
	
	<cfset var isOK = true>
	<cfset var result = "">
	
	<!--- Check required --->
	<cfif StructKeyIsTrue(checks,"required")>
		<cfif Not Len(data)>
			<cfset isOK = false>
		</cfif>
	</cfif>
	
	<cfif Len(data)>
		<!--- Check type --->
		<cfif StructKeyExists(checks,"type") AND Len(checks.type)>
			<cfif Not checkTests(data,variables.Types[checks.type])>
				<cfset isOK = false>
			</cfif>
		</cfif>
	
		<!--- Check particular tests for this field --->	
		<cfif Not checkTests(data,checks)>
			<cfset isOK = false>
		</cfif>
	</cfif>

	<cfreturn isOK>	
</cffunction>

<cffunction name="checkForm" access="public" returntype="void" output="no">
	<cfargument name="formfile" type="string" required="yes">
	<cfargument name="formdata" type="struct" required="yes">
	<cfargument name="sendto" type="string" default="#arguments.formfile#">
	<cfargument name="urlvar" type="string">
	
	<cfset var errors = getFormErrors(arguments.formfile,arguments.formdata)>
	
	<cfif Len(errors)>
		<!--- %%Need to change the way this works so no possibility of cflocation from cfc and no use of CGI --->
		<cfif Right(CGI.SCRIPT_NAME,3) eq "cfc">
			<cfthrow message="Form has missing/invalid data. (#errors#)" type="MethodErr" detail="#errors#" errorcode="invalidfields" extendedinfo="#errors#">
		<cfelse>
			<cfif StructKeyExists(arguments,"urlvar")>
				<cfset sendErrFields(arguments.sendto,errors,arguments.urlvar)>
			<cfelse>
				<cfset sendErrFields(arguments.sendto,errors)>
			</cfif>
		</cfif>
		
	</cfif>

</cffunction>

<cffunction name="getFormErrors" access="public" returntype="string" output="no" hint="I check the given form.">
	<cfargument name="formfile" type="string" required="yes">
	<cfargument name="formdata" type="struct" required="yes">
	
	<cfset var data = arguments.formdata>
	<cfset var thisFieldName = "">
	<cfset var thisField = 0>
	<cfset var arrErrors = ArrayNew(1)>
	<cfset var thisError = "">
	<cfset var isValidField = true>
	
	<!--- Make sure Scrubber is aware of form --->
	<cfif Not StructKeyExists(variables.Forms,arguments.formfile)>
		<cfthrow message="In order to use Scrubber with a form, Scrubber must be aware of that form. If you feel that you got this message in error, please return to the form and try again." type="MethodErr" errorcode="ScrubberNeedsForm">
	</cfif>
	
	<cfloop collection="#variables.Forms[arguments.formfile]#" item="thisFieldName">
		<cfset thisField = variables.Forms[arguments.formfile][thisFieldName]>
		<cfset isValidField = true>
		
		<cfif StructKeyExists(data,thisFieldName)>
			<cfset isValidField = checkField(data[thisFieldName],thisField)>
		<cfelseif StructKeyIsTrue(thisField,"required")>
			<cfset isValidField = false>
		</cfif>
		
		<cfif Not isValidField>
			<cfset ArrayAppend(arrErrors,thisFieldName)>
		</cfif>

	</cfloop>
	
	<cfreturn ArrayToList(arrErrors)>
</cffunction>

<cffunction name="checkTests" access="private" returntype="boolean" output="no" hint="I check to see if the given data passes the given tests.">
	<cfargument name="data" type="string" required="yes">
	<cfargument name="checks" type="struct" required="yes">
	
	<cfset var isOK = true>
	
	<!--- Clear non-digits for digits only --->
	<cfif StructKeyIsTrue(checks,"digitsonly")>
		<cfset data = digitize(data)>
	</cfif>
	
	<!--- Check regex --->
	<cfif StructKeyExists(checks,"regex") AND Len(checks.regex) AND Not ReFindNoCase(checks.regex, data)>
		<cfset isOK = false>
	</cfif>
	
	<!--- check isBoolean --->
	<cfif StructKeyIsTrue(checks,"isBoolean") AND Not isBoolean(data)>
		<cfset isOK = false>
	</cfif>
	
	<!--- check isDate --->
	<cfif StructKeyIsTrue(checks,"isDate") AND Not isDate(data)>
		<cfset isOK = false>
	</cfif>
	
	<!--- check isNumeric --->
	<cfif StructKeyIsTrue(checks,"isNumeric") AND Not isNumeric(data)>
		<cfset isOK = false>
	</cfif>
	
	<!--- check isInteger --->
	<cfif StructKeyIsTrue(checks,"isinteger") AND NOT  ( isNumeric(data) AND Int(data) EQ data )>
		<cfset isOK = false>
	</cfif>
	
	<cfreturn isOK>
</cffunction>

<cffunction name="getForms" access="public" returntype="struct">
	<cfreturn variables.Forms>
</cffunction>

<cffunction name="getTypeList" access="public" returntype="string" output="no" hint="I get a list of all validation types for this Scrubber.">
	
	<cfset var result = "">
	<cfset var thisType = "">
	
	<cfloop collection="#variables.Types#" item="thisType">
		<cfset result = ListAppend(result,thisType)>
	</cfloop>

	<cfreturn result>
</cffunction>

<cffunction name="getTypes" access="public" returntype="struct" output="no" hint="I get the validation types for this Scrubber.">
	
	<cfreturn variables.Types>
</cffunction>

<cffunction name="sendErrFields" access="public" returntype="void" output="no">
	<cfargument name="sendto" type="string" required="yes">
	<cfargument name="errFields" type="string" required="yes">
	<cfargument name="urlvar" type="string" default="errFields">
	
	<cfset var page = sendto>
	
	<cfif FindNoCase("?",page)>
		<cfset page = page & "&">
	<cfelse>
		<cfset page = page & "?">
	</cfif>
	<cfset page = page & "#urlvar#=#errFields#">
	
	<cflocation url="#page#" addtoken="No">

</cffunction>

<cffunction name="startFormHtml" access="public" returntype="string" output="no">
	<cfargument name="formfile" type="string" required="yes">
	<cfargument name="fieldsXML" type="string" required="yes">
	<cfargument name="errMessage" type="string" default="This form has errors.">
	<cfargument name="urlvar" type="string" default="errFields">
	<cfargument name="errClass" type="string" default="err">
	
	<cfif Not StructKeyExists(variables.Forms,arguments.formfile)>
		<cfset addFormXML(arguments.formfile,arguments.fieldsXML)>
	</cfif>
	
	<cfset result = showErrorHtml(formfile,errMessage,urlvar,errClass)>
	
	<cfreturn result>
</cffunction>

<cffunction name="showErrorHtml" access="public" returntype="string" output="no">
	<cfargument name="formfile" type="string" required="yes">
	<cfargument name="errMessage" type="string" default="This form has errors.">
	<cfargument name="urlvar" type="string" default="errFields">
	<cfargument name="errClass" type="string" default="err">
	
	<cfset var result = "">
	
	<cfif StructKeyExists(url,arguments.urlvar) AND Len(url[arguments.urlvar])>
		<cfset result = '<p class="#errClass#">#arguments.errMessage#</p>'>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="digitize" access="private" returntype="string" output="no" hint="I return the numeric digits of the given string.">
	<cfargument name="data" type="string" required="yes">
	
	<cfset var result = "">
	<cfset var i = 0>
	<cfset var digit = "">
	
	<cfscript>
	for (i=1; i lte Len(data); i=i+1 ) {
		digit = Mid(data,i,1);
		if ( isNumeric(digit) ) {
			result = result & digit;
		}
	}
	</cfscript>
	
	<cfreturn result>	
</cffunction>

<cffunction name="StructKeyIsTrue" access="private" returntype="boolean" output="no" hint="I check to see if the given key in the given structure exists and is true.">
	<cfargument name="struct" type="struct" required="yes">
	<cfargument name="key" type="string" required="yes">
	
	<cfset var result = false>
	
	<cfif StructKeyExists(struct,key) AND isBoolean(struct[key]) AND struct[key]>
		<cfset result = true>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="xmlForm" access="private" returntype="struct" output="no" hint="I convert the given XML to the appropriate CFML structure.">
	<cfargument name="myXML" type="string" required="yes">

	<cfscript>
	var i = 1;
	var result = StructNew();
	var fieldname = "";
	var atts = 0;
	
	for (i=1; i lte ArrayLen(myXML.xmlRoot.XmlChildren); i=i+1  ) {
		atts = myXML.xmlRoot.XmlChildren[i].XmlAttributes;
		fieldname = atts.name;
		result[fieldname] = StructNew();
		result[fieldname].required = StructKeyIsTrue(atts,"required");
		result[fieldname].digitsonly = StructKeyIsTrue(atts,"digitsonly");
		if ( StructKeyExists(atts,"regex") ) {
			result[fieldname].regex = atts.regex;
		} else {
			result[fieldname].regex = "";
		}
		if ( StructKeyExists(atts,"type") ) {
			result[fieldname].type = atts.type;
		} else {
			result[fieldname].type = "";
		}
		if ( StructKeyExists(atts,"message") ) {
			result[fieldname].message = atts.message;
		} else {
			result[fieldname].message = "";
		}
		if ( StructKeyExists(atts,"filter") ) {
			result[fieldname].filter = atts.filter;
		} else {
			result[fieldname].filter = "";
		}
		result[fieldname].isBoolean = StructKeyIsTrue(atts,"isBoolean");
		result[fieldname].isDate = StructKeyIsTrue(atts,"isDate");
		result[fieldname].isNumeric = StructKeyIsTrue(atts,"isNumeric");
		result[fieldname].isInteger = StructKeyIsTrue(atts,"isInteger");
	}
	return result;
	</cfscript>
</cffunction>

</cfcomponent>
<!--- 
<cffunction name="phone" access="public" returntype="string" output="no">
	<cfargument name="text" type="string" required="yes">
	
	<cfset var 1 = 0>
	<cfset var nums = 0>
	<cfset var thisChar = "">
	<cfset var result = "">
	
	<cfloop index="i" from="1" to="#Len(arguments.text)#" step="1">
		<cfset thisChar = Mid(arguments.text,i,1)>
		<cfif isNumeric(thisChar)>
			<cfset num = nums + 1>
			<cfset result = result & thisChar>
		</cfif>
	</cfloop>
	
	<cfif Len(result) neq 10>
		<cfthrow message="Phone Number must have ten digits." type="ScrubError" errorcode="ScrubError:PhoneNumber">
	</cfif>
	
	<cfreturn result>
</cffunction>
 --->