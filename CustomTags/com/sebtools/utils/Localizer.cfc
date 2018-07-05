<cfcomponent displayname="Localizer" extends="com.sebtools.Records" output="no">

<cffunction name="init" access="public" returntype="any" output="no" hint="I initialize and return this component.">
	<cfargument name="Manager" type="any" required="true">
	<cfargument name="Locales" type="string" required="true" hint="A comma delimited list of locales to support.">
	<cfargument name="DefaultLocale" type="string" default="en">
	<cfargument name="Settings" type="any" required="false">

	<cfif NOT ListFindNoCase(Arguments.Locales,Arguments.DefaultLocale)>
		<cfset Arguments.Locales = ListPrepend(Arguments.Locales,Arguments.DefaultLocale)>
	</cfif>

	<cfset initInternal(argumentCollection=arguments)>
	
	<cfset Variables.MrECache = CreateObject("component","MrECache").init(
		id="localizer",
		timeSpan=CreateTimeSpan(1,0,0,0)
	)>

	<cfset Variables.dbfields = "PhraseID,PhraseName">
	
	<cfreturn This>
</cffunction>

<cffunction name="addPhrase" access="public" returntype="string" output="no">
	<cfargument name="Phrase" type="string" required="true">

	<cfif NOT StructKeyExists(Arguments,Variables.DefaultLocale)>
		<cfset Arguments[Variables.DefaultLocale] = Arguments.Phrase>
	</cfif>

	<cfset Arguments.Phrase = makePhraseKey(Arguments.Phrase)>

	<cfif hasPhrases(PhraseName=Arguments.Phrase)>
		<cfreturn addPhraseLocales(ArgumentCollection=Arguments)>
	<cfelse>
		<cfreturn savePhrase(ArgumentCollection=Arguments)>
	</cfif>
</cffunction>

<cffunction name="addPhraseLocales" access="public" returntype="string" output="no">
	<cfargument name="Phrase" type="string" required="true">

	<cfset var qPhrases = 0>
	<cfset var sArgs = {}>
	<cfset var loc = "">

	<cfset Arguments.Phrase = makePhraseKey(Arguments.Phrase)>
	<cfset qPhrases = getPhrases(PhraseName=Arguments.Phrase)>

	<!--- If the phrase doesn't exist, add it. --->
	<cfif NOT qPhrases.RecordCount>
		<cfreturn addPhrase(ArgumentCollection=Arguments)>
	</cfif>

	<!--- Only save translations that don't already exist for this phrase --->
	<cfloop list="#Variables.Locales#" index="loc">
		<cfif StructKeyExists(Arguments,loc) AND Len(Arguments[loc]) AND NOT Len(qPhrases[loc][1])>
			<cfset sArgs[loc] = Arguments.loc>
		</cfif>
	</cfloop>

	<!--- Only save a record if at least one translation was added. --->
	<cfif StructCount(sArgs)>
		<cfset sArgs["PhraseID"] = qPhrases.PhraseID>
		<cfset savePhrase(ArgumentCollection=sArgs)>
	</cfif>

	<cfreturn qPhrases.PhraseID>
</cffunction>

<cffunction name="clearCaches" access="public" returntype="void" output="no">

	<cfset Variables.MrECache.clearCaches()>

</cffunction>

<cffunction name="formatLang" access="public" returntype="string" output="no">
	<cfargument name="Locale" type="string" required="true">
	<cfargument name="validate" type="boolean" default="true">

	<cfset var result = ReplaceNoCase(ListFirst(Arguments.Locale),'-','_')>

	<cfif Arguments.validate AND NOT ListFindNoCase(Variables.Locales,Arguments.Locale)>
		<!--- If we can't find the locale given, then use the general version --->
		<cfset result = ListFirst(result,"_")>
		<!--- If we still can't find the locale, then it isn't a valid locale for this instance of Localizer. --->
		<cfif NOT ListFindNoCase(Variables.Locales,result)>
			<cfset throwError('The locale "#Left(Arguments.Locale,5)#" is not a valid locale. Valid locales are: #Variables.Locales#.')>
		</cfif>
	</cfif>

	<cfreturn result>
</cffunction>

<cffunction name="translate" access="public" returntype="string" output="no" hint="I get the requested text in the requested language.">
	<cfargument name="Phrase" type="string" required="true">
	<cfargument name="locale" type="string" default="#Variables.DefaultLocale#">
	<cfargument name="remember" type="boolean" default="false" hint="Create an empty record for the phrase if it doesn't exist.">

	<cfreturn getTranslation(ArgumentCollection=Arguments)>
</cffunction>

<cffunction name="getTranslation" access="public" returntype="string" output="no" hint="I get the requested text in the requested language.">
	<cfargument name="Phrase" type="string" required="true">
	<cfargument name="locale" type="string" default="#Variables.DefaultLocale#">
	<cfargument name="remember" type="boolean" default="false" hint="Create an empty record for the phrase if it doesn't exist.">

	<cfset var result = "">

	<cfset Arguments.locale = formatLang(Arguments.locale)>

	<cfset result = Variables.MrECache.method(
		id="#Arguments.locale#:#makePhraseKey(Arguments.Phrase)#",
		Component=This,
		MethodName="getTranslation_Live",
		Args="#Arguments#"
	)>

	<cfscript>
	//Handle mustache-style parameters in text.
	if ( ReFindNoCase("{{[\w_]+}}",result) ) {
		//First use provided data
		if ( StructKeyExists(Arguments,"data") AND StructCount(Arguments.data) ) {
			for ( key in Arguments.data) {
				result = ReplaceNoCase(result,"{{#key#}}",Arguments.data[key],"ALL");
			}
		}
		//Then translate the parametered phrases.
		if ( ReFindNoCase("{{[\w_]+}}",result) ) {
			result = getNestedTranslation(result,Arguments.locale);
		}
	}
	</cfscript>

	<cfreturn result>
</cffunction>

<cffunction name="getTranslation_Live" access="public" returntype="string" output="no" hint="I get the requested text in the requested language.">
	<cfargument name="Phrase" type="string" required="true">
	<cfargument name="locale" type="string" default="#Variables.DefaultLocale#">
	<cfargument name="remember" type="boolean" default="false" hint="Create an empty record for the phrase if it doesn't exist.">

	<cfset var qPhrases = getRecords(PhraseName=makePhraseKey(Arguments.Phrase),fieldlist="#Arguments.locale#,#Variables.DefaultLocale#")>
	<cfset var result = "">

	<cfif qPhrases.RecordCount>
		<cfif Len(qPhrases[Arguments.locale][1])>
			<cfset result = qPhrases[Arguments.locale][1]>
		<cfelseif Len(qPhrases[Variables.DefaultLocale][1])>
			<cfset result = qPhrases[Variables.DefaultLocale][1]>
		</cfif>
	<cfelseif Arguments.remember>
		<cfset addPhrase(Arguments.Phrase)>
	</cfif>

	<cfif NOT Len(Trim(result))>
		<cfset result = Arguments.Phrase>
	</cfif>

	<cfreturn result>
</cffunction>

<cffunction name="hasPhrases" access="public" returntype="boolean" output="no">
	<cfif StructKeyList(Arguments) EQ 1>
		<cfset Arguments.PhraseName = Arguments[1]>
	</cfif>
	<cfif StructKeyExists(Arguments,"PhraseName")>
		<cfset Arguments.PhraseName = makePhraseKey(Arguments.PhraseName)>
	</cfif>
	
	<cfreturn hasRecords(ArgumentCollection=Arguments)>
</cffunction>

<cffunction name="makePhraseKey" access="public" returntype="string" output="no">
	<cfargument name="string" type="string" required="true">

	<cfset var result = Trim(Arguments.string)>
	
	<!--- Ditch punctuation --->	
	<cfset result = REReplaceNoCase(result,"[.,\/##!$%\^&\*;:{}=\-`~()\?']","","All")>

	<!--- Turn spaces (or any other non-letters) into underscores --->
	<cfset result = REReplaceNoCase(result,"[^\w]+","_","All")>

	<!--- Use a Hash() in place of any key longer than 50. --->
	<cfif Len(result) GT 50>
		<cfset result = Hash(result)>
	</cfif>

	<cfreturn result>
</cffunction>

<cffunction name="savePhrase" access="public" returntype="numeric" output="no">
	<cfargument name="Phrase" type="string" required="true">

	<cfset var result = 0>
	<cfset var key = "">

	<!--- Make sure locales use "_" syntax. --->
	<cfloop collection="#Arguments#" item="key">
		<cfif NOT ListFindNoCase(Variables.dbfields,key)>
			<cfset Arguments[formatLang(key,false)] = Arguments[key]>			
		</cfif>
	</cfloop>

	<cfset Arguments.PhraseName = Arguments.Phrase>

	<cfset result = saveRecord(ArgumentCollection=Arguments)>

	<cfset clearPhraseCache(Arguments.PhraseName)>

	<cfreturn result>
</cffunction>

<cffunction name="validatePhrase" access="public" returntype="struct" output="no">
	
	<cfif NOT isUpdate(ArgumentCollection=Arguments)>
		<cfset Arguments = validateDefaultLanguage(ArgumentCollection=Arguments)>
		<cfset Arguments = validatePhraseKey(ArgumentCollection=Arguments)>
	</cfif>

	<cfreturn Arguments>
</cffunction>

<cffunction name="validateDefaultLanguage" access="public" returntype="struct" output="no">
	
	<cfif NOT ( StructKeyExists(Arguments,Variables.DefaultLocale) AND Len(Trim(Arguments[Variables.DefaultLocale])) )>
		<cfset throwError("You must provide the phrase in the default language (#Variables.DefaultLocale#).")>
	</cfif>

	<cfreturn Arguments>
</cffunction>

<cffunction name="validatePhraseKey" access="public" returntype="struct" output="no">
	
	<!--- Make sure we have a string for the phrase name. --->
	<cfif NOT ( StructKeyExists(Arguments,"PhraseName") AND Len(Trim(Arguments.PhraseName)) )>
		<cfset Arguments.PhraseName = Arguments[Variables.DefaultLocale]>
	</cfif>

	<cfset Arguments.PhraseName = makePhraseKey(Arguments.PhraseName)>

	<cfreturn Arguments>
</cffunction>

<cffunction name="clearPhraseCache" access="private" returntype="void" output="no">
	<cfargument name="Phrase" type="string" required="true">

	<cfset var lang = "">

	<cfloop list="#Variables.Locales#" index="lang">
		<cfset Variables.MrECache.clearCaches("#lang#:#Arguments.Phrase#")>
		<cfset Variables.MrECache.clearCaches("#formatLang(lang)#:#Arguments.Phrase#")>
	</cfloop>

</cffunction>

<cffunction name="getNestedTranslation" access="private" returntype="string" output="no">
	<cfargument name="PartialTranslation" type="string" required="true">
	<cfargument name="locale" type="string" required="true">

	<cfset var result = Arguments.PartialTranslation>
	<cfset var resultBefore = "">
	<cfset var key = 0>
	<cfset var phrase = 0>

	<cfscript>
	do {
		resultBefore = result;//To see if text was changed in this loop.
		for ( key in REMatch('{{[\w_]+}}', result) ) {
			phrase = ReReplaceNoCase(key,"[{|}]","","ALL");//Need to get the phrase inside the curly braces
			if ( hasPhrases(phrase) ) {//Translate phrase if it exists
				result = ReplaceNoCase(result,key,getTranslation(Phrase=phrase,locale=Arguments.locale),"ALL");
			}
		}
	} while ( result NEQ resultBefore );
	</cfscript>

	<cfreturn result>
</cffunction>

<cffunction name="xml" access="public" output="yes"><cfset var lang = "">
<tables prefix="locale">
	<table entity="Phrase" methodPlural="Phrases" Specials="CreationDate,LastUpdateDate">
		<field name="isHTML" label="HTML?" type="boolean" default="false" /><cfloop list="#Variables.Locales#" index="lang">
		<field name="#formatLang(lang,false)#" label="#lang#" type="memo" /></cfloop>
	</table>
</tables>
</cffunction>

</cfcomponent>