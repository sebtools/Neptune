<cfcomponent extends="com.sebtools.Records" output="no">

<cfset variables.prefix = "util">
<cfset variables.types = "boolean,date,email,float,guid,integer,text,url">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="Manager" type="any" required="true">
	
	<cfset initInternal(ArgumentCollection=Arguments)>
	
	<cfset resetCache()>
	
	<cfreturn This>
</cffunction>

<cffunction name="populate" access="public" returntype="any" output="no" hint="I add the given setting if it doesn't yet exist.">
	<cfargument name="string" type="string" required="true">
	
	<cfset var qSettings = 0>
	<cfset var result = Arguments.string>
	
	<cfif ReFindNoCase("\[.*\]",result)>
		<cfset qSettings = getSettings()>
		<cfoutput query="qSettings">
			<cfset result = ReplaceNoCase(result,"[#SettingName#]",qSettings[getValueField(type)][CurrentRow])>
		</cfoutput>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="addSetting" access="public" returntype="any" output="no" hint="I add the given setting if it doesn't yet exist.">
	
	<cfset var qCheck = getSettings(SettingName=Arguments.SettingName,ExcludeComponent=Arguments.Component,fieldlist="SettingID,Component")>
	
	<cfif qCheck.RecordCount>
		<cfset throwError(Message="A setting of this name is already being used by another component (""#qCheck.Component#"").",ErrorCode="NameConflict")>
	</cfif>
	
	<!---
	Only take action if this doesn't already exists for this component.
	(we don't want to update because the admin may have change the notice from the default settings)
	--->
	<cfif NOT hasSettings(SettingName=Arguments.SettingName,Component=Arguments.Component)>
		<cfif NOT StructKeyExists(Arguments,"type")>
			<cfset Arguments.type = "text">
		</cfif>
		<cfif NOT StructKeyExists(Arguments,"SettingLabel")>
			<cfset Arguments.SettingLabel = Arguments.SettingName>
		</cfif>
		<cfset saveSetting(ArgumentCollection=arguments)>
	</cfif>
	
</cffunction>

<cffunction name="getFieldsArray" access="public" returntype="array" output="no">
	
	<cfset var qSettings = 0>
	<cfset var aResults = 0>
	
	<cfif StructKeyExists(Arguments,"SettingID") AND Len(Arguments.SettingID) AND NOT isNumeric(Arguments.SettingID)>
		<cfset qSettings = getSettings(SettingNames=Arguments.SettingID,fieldlist="SettingID,SettingName,SettingLabel,type,ValueText,Help")>
		<cfset aResults = ArrayNew(1)>
		
		<cfoutput query="qSettings">
			<cfset ArrayAppend(aResults,StructNew())>
			<cfset aResults[ArrayLen(aResults)]["name"] = SettingName>
			<cfset aResults[ArrayLen(aResults)]["type"] = type>
			<cfset aResults[ArrayLen(aResults)]["label"] = SettingLabel>
			<cfset aResults[ArrayLen(aResults)]["defaultValue"] = ValueText>
			<cfif Len(ValueText)>
				<cfset aResults[ArrayLen(aResults)]["size"] = Len(ValueText) + 2>
			</cfif>
			<cfif Len(Help)>
				<cfset aResults[ArrayLen(aResults)]["Help"] = Help>
			</cfif>
		</cfoutput>
		
		<cfreturn aResults>
	<cfelse>
		<cfreturn Super.getFieldsArray(ArgumentCollection=Arguments)>
	</cfif>
</cffunction>

<cffunction name="getFieldsStruct" access="public" returntype="struct" output="no">
	
	<cfset var sFields = StructNew()>
	<cfset var aFields = 0>
	<cfset var ii = 0>
	
	<cfset aFields = getFieldsArray(argumentCollection=arguments)>
	
	<cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
		<cfif StructKeyExists(aFields[ii],"name")>
			<cfset sFields[aFields[ii]["name"]] = aFields[ii]>
		</cfif>
	</cfloop>
	
	<cfreturn sFields>
</cffunction>

<cffunction name="getSettingID" access="public" returntype="string" output="no" hint="I get the ID for the requested setting.">
	<cfargument name="SettingName" type="string" required="yes">
	
	<cfset var qSetting = getSettings(SettingName=Arguments.SettingName,fieldlist="SettingID")>
	<cfset var result = 0>
	
	<cfif qSetting.RecordCount>
		<cfset result = qSetting.SettingID>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getSettingValue" access="public" returntype="any" output="no" hint="I get the value for the requested setting.">
	<cfargument name="SettingName" type="string" required="yes">
	
	<cfset var qSetting = 0>
	<cfset var field = "">
	<cfset var result = "">
	
	<cfif NOT StructKeyExists(Variables.sSettings,Arguments.SettingName)>
		<cfset qSetting = getSettings(SettingName=Arguments.SettingName,fieldlist="SettingID,type,ValueText,ValueInteger,ValueFloat,ValueDate,ValueBoolean")>
		
		<cfif qSetting.RecordCount>
			<cfset field = getValueField(qSetting.type)>
			<cfset Variables.sSettings[Arguments.SettingName] = qSetting[field][1]>
		</cfif>
	</cfif>
	
	<cfif StructKeyExists(Variables.sSettings,Arguments.SettingName)>
		<cfset result = Variables.sSettings[Arguments.SettingName]>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getValueField" access="public" returntype="string" output="no" hint="I get the name of the field that will hold the value for the given type.">
	<cfargument name="type" type="string" required="yes">
	
	<cfset var result = "">
	
	<cfswitch expression="#Arguments.type#">
	<cfcase value="boolean">
		<cfset result = "ValueBoolean">
	</cfcase>
	<cfcase value="date">
		<cfset result = "ValueDate">
	</cfcase>
	<cfcase value="float">
		<cfset result = "ValueFloat">
	</cfcase>
	<cfcase value="integer">
		<cfset result = "ValueInteger">
	</cfcase>
	<cfdefaultcase>
		<cfset result = "ValueText">
	</cfdefaultcase>
	</cfswitch>
	
	<cfreturn result>
</cffunction>

<cffunction name="saveSetting" access="public" returntype="any" output="no">
	
	<cfset var qSettings = 0>
	<cfset var result = 0>
	
	<cfif isMultiEdit(ArgumentCollection=Arguments)>
		<cfset qSettings = getSettings(fieldlist="SettingID,SettingName")>
		<cfoutput query="qSettings">
			<cfif StructKeyExists(Arguments,"#qSettings['SettingName'][CurrentRow]#")>
				<cfset saveRecord(SettingID=qSettings['SettingID'][CurrentRow],Value=Arguments["#qSettings['SettingName'][CurrentRow]#"])>
			</cfif>
		</cfoutput>
	<cfelse>
		<cfset result = saveRecord(ArgumentCollection=Arguments)>
	</cfif>
	
	<cfset resetCache()>
	
	<cfreturn result>
</cffunction>
<cffunction name="validateSetting" access="public" returntype="struct" output="no">
	
	<cfset Arguments = validateSettingType(ArgumentCollection=Arguments)>
	<cfset Arguments = validateSettingValue(ArgumentCollection=Arguments)>
	
	<cfreturn Arguments>
</cffunction>

<cffunction name="validateSettingType" access="private" returntype="struct" output="no">
	
	<cfset var oSetting = 0>
	
	<cfif StructKeyExists(Arguments,"type")>
		<cfif isUpdate(ArgumentCollection=Arguments)>
			<cfset StructDelete(Arguments,"type")>
			<cfset oSetting = RecordObject(Record=Arguments,fields="type")>
			<cfset Arguments.type = oSetting.get("type")>
		<cfelse>
			<cfif NOT ListFindNoCase(variables.types,Arguments.type)>
				<cfset throwError("#Arguments.type# is not a valid type. Valid types are: #variables.types#.")>
			</cfif>
		</cfif>
	</cfif>
	
	<cfreturn Arguments>
</cffunction>

<cffunction name="validateSettingValue" access="private" returntype="struct" output="no">
	
	<cfset var oSetting = RecordObject(Record=Arguments,fields="type")>
	
	<cfif StructKeyExists(Arguments,"SettingValue")>
		<cfset Arguments.Value = Arguments.SettingValue>
		<cfset StructDelete(Arguments,"SettingValue")>
	</cfif>
	
	<cfif StructKeyExists(Arguments,"ValueText") AND NOT StructKeyExists(Arguments,"Value")>
		<cfset Arguments.Value = Arguments.ValueText>
	</cfif>
	
	<cfif StructKeyExists(Arguments,"Value")>
		<cfswitch expression="#oSetting.get('type')#">
		<cfcase value="boolean">
			<cfset Arguments.ValueBoolean = Arguments.Value>
			<cfset Arguments.ValueText = YesNoFormat(Arguments.Value)>
		</cfcase>
		<cfcase value="date">
			<cfset Arguments.ValueDate = Arguments.Value>
			<cfset Arguments.ValueText = DateFormat(Arguments.Value)>
		</cfcase>
		<cfcase value="float">
			<cfset Arguments.ValueFloat = Arguments.Value>
			<cfset Arguments.ValueText = NumberFormat(Arguments.Value)>
		</cfcase>
		<cfcase value="integer">
			<cfset Arguments.ValueInteger = Arguments.Value>
			<cfset Arguments.ValueText = NumberFormat(Arguments.Value)>
		</cfcase>
		<cfdefaultcase>
			<cfset Arguments.ValueText = Arguments.Value>
		</cfdefaultcase>
		</cfswitch>
	</cfif>
	
	<cfreturn Arguments>
</cffunction>

<cffunction name="isMultiEdit" access="private" returntype="boolean" output="no">
	
	<cfset var qSettings = getSettings(fieldlist="SettingID,SettingName")>
	<cfset var result = false>
	
	<cfoutput query="qSettings">
		<cfif StructKeyExists(Arguments,"#qSettings['SettingName'][CurrentRow]#")>
			<cfreturn true>
		</cfif>
	</cfoutput>
	
	<cfreturn false>
</cffunction>

<cffunction name="resetCache" access="private" output="no">
	<cfset Variables.sSettings = StructNew()>
</cffunction>

<cffunction name="xml" access="public" output="yes">
<tables prefix="#variables.prefix#">
	<table entity="Setting" universal="true" Specials="CreationDate,LastUpdateDate">
		<field name="Component" label="Component" type="text" Langth="120" help="A unique identifier for the component or program using this setting" />
		<field name="type" label="type" type="text" Length="250" sebcolumn="false" default="text" />
		<field name="SettingLabel" label="Label" type="text" Length="250" />
		<field name="Help" label="Label" type="text" Length="250" />
		<field name="ValueText" label="Text Value" type="text" Length="250" />
		<field name="ValueInteger" label="Integer Value" type="integer" />
		<field name="ValueFloat" label="Float Value" type="float" />
		<field name="ValueDate" label="Date Value" type="date" />
		<field name="ValueBoolean" label="Boolean Value" type="boolean" />
		<filter name="ExcludeComponent" field="Component" operator="NEQ" />
	</table>
</tables>
</cffunction>

</cfcomponent>