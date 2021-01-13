<cfcomponent output="false">
	<!---//
		Mustache.cfc

		This component is a ColdFusion implementation of the Mustache logic-less templating language (see http://mustache.github.com/.)

		Key features of this implemenation:

		* Enhanced whitespace management - extra whitespace around conditional output is automatically removed
		* Partials
		* Multi-line comments
		* And can be extended via the onRenderTag event to add additional rendering logic

		Homepage:     https://github.com/rip747/Mustache.cfc
		Source Code:  https://github.com/rip747/Mustache.cfc.git

		NOTES:
		reference for string building
		http://www.aliaspooryorik.com/blog/index.cfm/e/posts.details/post/string-concatenation-performance-test-128
	//--->

	<!--- namespace for Mustache private variables (to avoid name collisions when extending Mustache.cfc) --->
	<cfset variables.Mustache = structNew() />
	<cfset variables.Mustache.Pattern=createObject("java","java.util.regex.Pattern") />

	<!--- captures the ".*" match for looking for formatters (see #2) and also allows nested structure references (see #3), removes looking for comments --->
	<cfset variables.Mustache.TagRegEx = variables.Mustache.Pattern.compile("\{\{(\{|&|\>)?\s*((?:\w+(?:(?:\.\w+){1,})?)|\.)(.*?)\}?\}\}", 32)/>
	<!--- Partial regex --->
	<cfset variables.Mustache.PartialRegEx = variables.Mustache.Pattern.compile("\{\{\>\s*((?:\w+(?:(?:\.\w+){1,})?)|\.)(.*?)\}?\}\}", 32)/>
	<!--- captures nested structure references --->
	<cfset variables.Mustache.SectionRegEx = variables.Mustache.Pattern.compile("\{\{\s*(##|\^)\s*(\w+(?:(?:\.\w+){1,})?)\s*}}(.*?)\{\{\s*/\s*\2\s*\}\}", 32)/>
	<!--- captures nested structure references --->
	<cfset variables.Mustache.CommentRegEx = variables.Mustache.Pattern.compile("((^\r?\n?)|\s+)?\{\{!.*?\}\}(\r?\n?(\r?\n?)?)?", 40)/>
	<!--- captures nested structure references --->
	<cfset variables.Mustache.HeadTailBlankLinesRegEx = variables.Mustache.Pattern.compile(javaCast("string", "(^(\r?\n))|((?<!(\r?\n))(\r?\n)$)"), 32)/>
	<!--- for tracking partials --->
	<cfset variables.Mustache.partials = {}/>
	<!--- Raising Errors --->
	<cfset variables.Mustache.RaiseErrors = "true">

	<cffunction name="init" access="public" output="false"
		hint="initalizes and returns the object">
		<cfargument name="partials" hint="the partial objects" default="#StructNew()#">
		<cfargument name="raiseErrors" hint="raise errors if template is not found" default="true">

		<cfset setPartials(arguments.partials)/>
		<cfset setRaiseErrors(arguments.RaiseErrors)>

		<cfreturn this/>
	</cffunction>

	<cffunction name="render" access="public" output="false"
		hint="main function to call to a new template">
		<cfargument name="template" default="#readMustacheFile(ListLast(getMetaData(this).name, '.'))#"/>
		<cfargument name="context" default="#this#"/>
		<cfargument name="partials" hint="the partial objects" required="true" default="#structNew()#"/>
		<cfargument name="options" hint="options object (can be used in overridden functions to pass additional instructions)" required="false" default="#structNew()#"/>

		<!--- Replace partials in template --->
		<cfset arguments.template=replacePartialsInTemplate(arguments.template,arguments.partials) />

		<cfset var results = renderFragment(argumentCollection=arguments)/>

		<!--- remove single blank lines at the head/tail of the stream --->
		<cfset results = variables.Mustache.HeadTailBlankLinesRegEx.matcher(javaCast("string", results)).replaceAll("")/>

		<cfreturn results/>
	</cffunction>

	<cffunction name="replacePartialsInTemplate" access="private" output="false">
		<cfargument name="template" />
		<cfargument name="partials"/>

		<cfset local.matches = ReFindNoCaseValues(arguments.template, variables.Mustache.PartialRegEx)/>

		<cfif arrayLen(local.matches)>
			<cfset local.partial = getPartial(trim(local.matches[2]),arguments.partials) />
			<cfset local.result= ReplaceNoCase(arguments.template,local.matches[1],local.partial) />
		<cfelse>
			<cfset local.result=arguments.template />
		</cfif>

		<cfreturn local.result />

	</cffunction>

	<cffunction name="renderFragment" access="private" output="false"
		hint="handles all the various fragments of the template">
		<cfargument name="template"/>
		<cfargument name="context"/>
		<cfargument name="partials"/>
		<cfargument name="options"/>

		<!--- clean the comments from the template --->
		<cfset arguments.template = variables.Mustache.CommentRegEx.matcher(javaCast("string", arguments.template)).replaceAll("$3")/>

		<cfset structAppend(arguments.partials, variables.Mustache.partials, false)/>
		<cfset arguments.template = renderSections(arguments.template, arguments.context, arguments.partials, arguments.options)/>
		<cfreturn renderTags(arguments.template, arguments.context, arguments.partials, arguments.options)/>
	</cffunction>

	<cffunction name="renderSections" access="private" output="false">
		<cfargument name="template"/>
		<cfargument name="context"/>
		<cfargument name="partials"/>
		<cfargument name="options" />

		<cfset var local = {}/>
		<cfset var lastSectionPosition = -1/>

		<cfloop condition = "true">
			<cfset local.matches = ReFindNoCaseValues(arguments.template, variables.Mustache.SectionRegEx)/>

			<cfif arrayLen(local.matches) eq 0>
				<cfbreak/>
			</cfif>

			<cfset local.tag = local.matches[1]/>
			<cfset local.type = local.matches[2]/>
			<cfset local.tagName = local.matches[3]/>
			<cfset local.inner = local.matches[4]/>
			<cfset local.rendered = renderSection(local.tagName, local.type, local.inner, arguments.context, arguments.partials, arguments.options)/>

			<!--- look to see where the current tag exists in the output; which we use to see if starting whitespace should be trimmed ---->
			<cfset local.sectionPosition = find(local.tag, arguments.template)/>

			<!--- trims out empty lines from appearing in the output --->
			<cfif len(trim(local.rendered)) eq 0>
				<cfset local.rendered = "$2"/>
			<cfelse>
				<!--- escape the backreference --->
				<cfset local.rendered = replace(local.rendered, "$", "\$", "all")/>
			</cfif>

			<!--- if the current section is in the same place as the last template, we do not need to clean up whitespace--because it's already been managed --->
			<cfif local.sectionPosition lt lastSectionPosition>
				<!--- do not remove whitespace before the output, because we have already cleaned it --->
				<cfset local.whiteSpaceRegex = ""/>
				<!--- rendered content was empty, so we just want to replace all the text --->
				<cfif local.rendered eq "$2">
					<!--- no whitespace to clean up --->
					<cfset local.rendered = ""/>
				</cfif>
			<cfelse>
				<!--- clean out the extra lines of whitespace from the output --->
				<cfset local.whiteSpaceRegex = "(^\r?\n?)?(\r?\n?)?"/>
			</cfif>
			<!--- we use a regex to remove unwanted whitespacing from appearing --->
			<cfset arguments.template = variables.Mustache.Pattern.compile(javaCast("string", local.whiteSpaceRegex & "\Q" & local.tag & "\E(\r?\n?)?"), 40).matcher(javaCast("string", arguments.template)).replaceAll(local.rendered)/>

			<!--- track the position of the last section ---->
			<cfset lastSectionPosition = local.sectionPosition />
		</cfloop>

		<cfreturn arguments.template/>
	</cffunction>

	<cffunction name="renderSection" access="private" output="false">
		<cfargument name="tagName"/>
		<cfargument name="type"/>
		<cfargument name="inner"/>
		<cfargument name="context"/>
		<cfargument name="partials"/>
		<cfargument name="options"/>

		<cfset var local = {}/>

		<cfset local.ctx = get(arguments.tagName, arguments.context, arguments.partials, arguments.options)/>

		<cfif arguments.type neq "^" and isStruct(local.ctx) and !StructIsEmpty(local.ctx)>
			<cfreturn renderFragment(arguments.inner, local.ctx, arguments.partials, arguments.options)/>
		<cfelseif arguments.type neq "^" and isQuery(local.ctx) AND local.ctx.recordCount>
			<cfreturn renderQuerySection(arguments.inner, local.ctx, arguments.partials, arguments.options)/>
		<cfelseif arguments.type neq "^" and isArray(local.ctx) and !arrayIsEmpty(local.ctx)>
			<cfreturn renderArraySection(arguments.inner, local.ctx, arguments.partials, arguments.options)/>
		<cfelseif arguments.type neq "^" and structKeyExists(arguments.context, arguments.tagName) and isCustomFunction(arguments.context[arguments.tagName])>
			<cfreturn renderLambda(arguments.tagName, arguments.inner, arguments.context, arguments.partials, arguments.options)/>
		</cfif>

		<cfif arguments.type eq "^" xor convertToBoolean(local.ctx)>
			<cfreturn arguments.inner/>
		</cfif>

		<cfreturn ""/>
	</cffunction>

	<cffunction name="renderLambda" access="private" output="false"
		hint="render a lambda function (also provides a hook if you want to extend how lambdas works)">
		<cfargument name="tagName"/>
		<cfargument name="template" />
		<cfargument name="context" />
		<cfargument name="partials"/>
		<cfargument name="options"/>

		<cfset var local = {} />

		<!--- if running on a component --->
		<cfif isObject(arguments.context)>
			<!--- call the function and pass in the arguments --->
			<cfinvoke component="#arguments.context#" method="#arguments.tagName#" returnvariable="local.results">
				<cfinvokeargument name="1" value="#arguments.template#" />
			</cfinvoke>
		<!--- otherwise we have a struct w/a reference to a function or closure --->
		<cfelse>
			<cfset local.fn = arguments.context[arguments.tagName] />
			<cfset local.results = local.fn(arguments.template) />
		</cfif>

		<cfreturn local.results />
	</cffunction>

	<cffunction name="convertToBoolean" access="private" output="false">
		<cfargument name="value"/>

		<cfif isBoolean(arguments.value)>
			<cfreturn arguments.value/>
		</cfif>
		<cfif isSimpleValue(arguments.value)>
			<cfreturn arguments.value neq ""/>
		</cfif>
		<cfif isStruct(arguments.value)>
			<cfreturn !StructIsEmpty(arguments.value)>
		</cfif>
		<cfif isQuery(arguments.value)>
			<cfreturn arguments.value.recordcount neq 0/>
		</cfif>
		<cfif isArray(arguments.value)>
			<cfreturn !arrayIsEmpty(arguments.value)>
		</cfif>

		<cfreturn false>
	</cffunction>

	<cffunction name="renderQuerySection" access="private" output="false">
		<cfargument name="template"/>
		<cfargument name="context"/>
		<cfargument name="partials"/>
		<cfargument name="options"/>

		<cfset var results = []/>

		<!--- trim the trailing whitespace--so we don't print extra lines --->
		<cfset arguments.template = rtrim(arguments.template)/>

		<cfloop query="arguments.context">
			<cfset arrayAppend(results, renderFragment(arguments.template, arguments.context, arguments.partials, arguments.options))/>
		</cfloop>
		<cfreturn arrayToList(results, "")/>
	</cffunction>

	<cffunction name="renderArraySection" access="private" output="false">
		<cfargument name="template"/>
		<cfargument name="context"/>
		<cfargument name="partials"/>
		<cfargument name="options"/>

		<cfset var local = {}/>

		<!--- trim the trailing whitespace--so we don't print extra lines --->
		<cfset arguments.template = rtrim(arguments.template)/>

		<cfsavecontent variable="local.results"><cfloop array="#arguments.context#" index="local.item"><cfoutput>#renderFragment(arguments.template, local.item, arguments.partials, arguments.options)#</cfoutput></cfloop></cfsavecontent>

		<cfreturn local.results />
	</cffunction>

	<cffunction name="renderTags" access="private" output="false">
		<cfargument name="template"/>
		<cfargument name="context"/>
		<cfargument name="partials"/>
		<cfargument name="options"/>

		<cfset var local = {}/>

		<cfloop condition = "true" >

			<cfset local.matches = ReFindNoCaseValues(arguments.template, variables.Mustache.TagRegEx)/>

			<cfif arrayLen(local.matches) eq 0>
				<cfbreak/>
			</cfif>

			<cfset local.tag = local.matches[1]/>
			<cfset local.type = local.matches[2]/>
			<cfset local.tagName = local.matches[3]/>
			<!--- gets the ".*" capture --->
			<cfset local.extra = local.matches[4]/>
			<cfset arguments.template = replace(arguments.template, local.tag, renderTag(local.type, local.tagName, arguments.context, arguments.partials, arguments.options, local.extra))/>

		</cfloop>

		<cfreturn arguments.template/>
	</cffunction>

	<cffunction name="renderTag" access="private" output="false">
		<cfargument name="type"/>
		<cfargument name="tagName"/>
		<cfargument name="context"/>
		<cfargument name="partials"/>
		<cfargument name="options"/>
		<cfargument name="extra" hint="The text appearing after the tag name"/>

		<cfset var local = {}/>
		<cfset var results = ""/>
		<cfset var extras = listToArray(arguments.extra, ":")/>

		<cfif arguments.type eq "!">
			<cfreturn ""/>
		<cfelseif (arguments.type eq "{") or (arguments.type eq "&")>
			<cfset arguments.value = get(arguments.tagName, arguments.context, arguments.partials, arguments.options)/>
			<cfset arguments.valueType = "text"/>
			<cfset results = textEncode(arguments.value, arguments.options, arguments)/>
		<cfelseif arguments.type eq ">">
			<cfset arguments.value = renderPartial(arguments.tagName, arguments.context, arguments.partials, arguments.options)/>
			<cfset arguments.valueType = "partial"/>
			<cfset results = arguments.value/>
		<cfelse>
			<cfset arguments.value = get(arguments.tagName, arguments.context, arguments.partials, arguments.options)/>
			<cfset arguments.valueType = "html"/>
			<cfset results = htmlEncode(arguments.value, arguments.options, arguments)/>
		</cfif>

		<cfreturn onRenderTag(results, arguments)/>
	</cffunction>

	<cffunction name="textEncode" access="private" output="false"
		hint="Encodes a plain text string (can be overridden)">
		<cfargument name="input"/>
		<cfargument name="options"/>
		<cfargument name="callerArgs" hint="Arguments supplied to the renderTag() function"/>

		<!--- we normally don't want to do anything, but this function is manually so we can overwrite the default behavior of {{{token}}} --->
		<cfreturn arguments.input/>
	</cffunction>

	<cffunction name="htmlEncode" access="private" output="false"
		hint="Encodes a string into HTML (can be overridden)">
		<cfargument name="input"/>
		<cfargument name="options"/>
		<cfargument name="callerArgs" hint="Arguments supplied to the renderTag() function"/>

		<cfreturn htmlEditFormat(arguments.input)/>
	</cffunction>

	<cffunction name="onRenderTag" access="private" output="false"
		hint="override this function in your methods to provide additional formatting to rendered content">
		<cfargument name="rendered"/>
		<cfargument name="callerArgs" hint="Arguments supplied to the renderTag() function"/>

		<!--- do nothing but return the passed in value --->
		<cfreturn arguments.rendered/>
	</cffunction>

	<cffunction name="renderPartial"  access="private" output="false"
		hint="If we have the partial registered, use that, otherwise use the registered text">
		<cfargument name="name" hint="the name of the partial" required="true">
		<cfargument name="context" hint="the context" required="true">
		<cfargument name="partials" hint="the partial objects" required="true">
		<cfargument name="options"/>

		<cfif structKeyExists(arguments.partials, arguments.name)>
			<cfreturn this.render(arguments.partials[arguments.name], arguments.context, arguments.partials, arguments.options)/>
		<cfelse>
			<cfreturn this.render(readMustacheFile(arguments.name), arguments.context, arguments.partials, arguments.options)/>
		</cfif>

	</cffunction>

	<cffunction name="readMustacheFile" access="private" output="false">
		<cfargument name="filename"/>

		<cfset var template= ""/>
		<cftry>
			<cffile action="read" file="#getDirectoryFromPath(getMetaData(this).path)##arguments.filename#.mustache" variable="template"/>
			<cfcatch type="any">
				<cfif getRaiseErrors()>
					<cfthrow type="Mustache.TemplateMissing" message="Cannot not find `#arguments.filename#` template"/>
				<cfelse>
					<cfreturn ""/>
				</cfif>
			</cfcatch>
		</cftry>
		<cfreturn trim(template)/>
	</cffunction>

	<cffunction name="get" access="private" output="false">
		<cfargument name="key"/>
		<cfargument name="context"/>
		<cfargument name="partials"/>
		<cfargument name="options"/>

		<cfset var local = {}/>

		<!--- if we are the implicit iterator --->
		<cfif arguments.key eq ".">
			<cfreturn toString(context) />
		<!--- if we're a nested key, do a nested lookup --->
		<cfelseif find(".", arguments.key)>
			<cfset local.key = listRest(arguments.key, ".")/>
			<cfset local.root = listFirst(arguments.key, ".")/>
			<cfif structKeyExists(arguments.context, local.root)>
				<cfreturn get(local.key, context[local.root], arguments.partials, arguments.options)/>
			<cfelse>
				<cfreturn ""/>
			</cfif>
		<cfelseif isStruct(arguments.context) && structKeyExists(arguments.context, arguments.key) >
			<cfif isCustomFunction(arguments.context[arguments.key])>
				<cfreturn renderLambda(arguments.key, '', arguments.context, arguments.partials, arguments.options)/>
			<cfelse>
				<cfreturn arguments.context[arguments.key]/>
			</cfif>
		<cfelseif isQuery(arguments.context)>
			<cfif listContainsNoCase(arguments.context.columnList, arguments.key)>
				<cfreturn arguments.context[arguments.key][arguments.context.currentrow]/>
			<cfelse>
				<cfreturn ""/>
			</cfif>
		<cfelse>
			<cfreturn ""/>
		</cfif>
	</cffunction>

	<cffunction name="ReFindNoCaseValues" access="private" output="false">
		<cfargument name="text"/>
		<cfargument name="re"/>

		<cfset var local = {}>

		<cfset local.results = []/>
		<cfset local.matcher = arguments.re.matcher(arguments.text)/>
		<cfset local.i = 0/>
		<cfset local.nextMatch = ""/>
		<cfif local.matcher.Find()>
			<cfloop index="local.i" from="0" to="#local.matcher.groupCount()#">
				<cfset local.nextMatch = local.matcher.group(JavaCast("int",local.i))/>
				<cfif isDefined('local.nextMatch')>
					<cfset arrayAppend(local.results, local.nextMatch)/>
				<cfelse>
					<cfset arrayAppend(local.results, "")/>
				</cfif>
			</cfloop>
		</cfif>

		<cfreturn local.results/>
	</cffunction>

	<cffunction name="getPartial" access="private" output="false">
		<cfargument name="name" hint="the name of the partial" required="true">
		<cfargument name="partials" hint="the partials object" required="false">

		<cfif structKeyExists(variables.Mustache.partials,arguments.name)>
			<cfreturn variables.Mustache.partials[arguments.name] />
		<cfelseif structKeyExists(arguments,"partials") and structKeyExists(arguments.partials, arguments.name)>
			<cfreturn arguments.partials[arguments.name] />
		<cfelse>
			<!--- Fetch from file as last resort --->
			<cfreturn readMustacheFile(arguments.name) />
		</cfif>
	</cffunction>

	<cffunction name="getPartials" access="public" output="false">
		<cfreturn variables.Mustache.partials/>
	</cffunction>

	<cffunction name="setPartials" access="public" output="false">
		<cfargument name="partials" required="true">
		<cfargument name="options"/>

		<cfset variables.Mustache.partials = arguments.partials/>
	</cffunction>

	<cffunction name="getRaiseErrors" access="public" output="false">
		<cfreturn variables.Mustache.RaiseErrors>
	</cffunction>
	<cffunction name="setRaiseErrors" access="public" output="false">
		<cfargument name="value" type="boolean" required="true">
		<cfset variables.Mustache.RaiseErrors = arguments.value>
	</cffunction>

</cfcomponent>
