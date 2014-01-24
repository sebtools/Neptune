<cfsilent>
<!---
<cf_Template
	title=""
	files_css=""
	files_js=""
	meta_description=""
	meta_keywords=""
	head=""
	head_css=""
	head_js="callCustomMethod();"
	showTitle="true"
>
--->
<cfif ThisTag.ExecutionMode EQ "Start">
	<cfscript>
	if (
				StructKeyExists(Caller,"TemplateAttributes")
			AND	isStruct(Caller.TemplateAttributes)
		) {
		StructAppend(attributes,Caller.TemplateAttributes,"no");
	}
	if (
				StructKeyExists(request,"cftags")
			AND	isStruct(request.cftags)
			AND	StructKeyExists(request.cftags,"cf_Template")
			AND	isStruct(request.cftags.cf_Template)
		) {
		StructAppend(attributes,request.cftags.cf_Template,"no");
	}
	</cfscript>
	<cfparam name="attributes.title" default="">
	<cfparam name="attributes.files" default="">
	<cfparam name="attributes.files_css" default="">
	<cfparam name="attributes.files_js" default="">
	<cfparam name="attributes.head" default="">
	<cfparam name="attributes.head_css" default="">
	<cfparam name="attributes.head_js" default="">
	<cfparam name="attributes.HTMLAbove" default="">
	<cfparam name="attributes.HTMLBelow" default="">
	<cfparam name="attributes.use" default="">
	<cfparam name="attributes.format" default="">
	
	
	<cfparam name="attributes.wraptag" default="">
	<cfparam name="attributes.TitleElement" default="h1">
	<cfparam name="attributes.TitleAttributes" default="">
	<cfparam name="attributes.TitleHTML" default="">
	
	<!--- *** SET TITLE *** --->
	<cfif StructKeyExists(Caller,"Title") AND NOT Len(attributes.title)>
		<cfset attributes.title = Caller.Title>
	</cfif>
	
	<cfparam name="attributes.showTitle" default="#(Len(Trim(attributes.title)) GT 0)#" type="boolean">
	
	<cfif
			StructKeyExists(request,"sLayoutTag")
		AND	isStruct(request.sLayoutTag)	
		AND	StructKeyExists(request.sLayoutTag,"HasTitleH1Output")
		AND	request.sLayoutTag.HasTitleH1Output IS true
	>
		<cfset attributes.showTitle = false>
	</cfif>
	
	<!--- *** FILES *** --->
	<cfif StructKeyExists(attributes,"file_css") AND Len(attributes.file_css)>
		<cfset attributes.files_css = ListAppend(attributes.files_css,attributes.file_css)>
	</cfif>
	<cfif StructKeyExists(attributes,"file_js") AND Len(attributes.file_js)>
		<cfset attributes.files_js = ListAppend(attributes.files_js,attributes.file_js)>
	</cfif>
	<cfif Len(attributes.files)>
		<cfloop list="#attributes.files#" index="path">
			<cfif FindNoCase(".css",path)>
				<cfset attributes.files_css = ListAppend(attributes.files_css,path)>
			<cfelseif FindNoCase(".js",path)>
				<cfset attributes.files_js = ListAppend(attributes.files_js,path)>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfif isStruct(attributes.TitleAttributes)>
		<cfset sTitleAtts = Duplicate(attributes.TitleAttributes)>
		<cfset attributes.TitleAttributes = "">
		<cfloop collection="#sTitleAtts#" item="key">
			<cfset attributes.TitleAttributes = ListAppend(attributes.TitleAttributes,"#LCase(key)#=#sTitleAtts[key]#",";")>
		</cfloop>
	</cfif>
	
	<!--- *** GET LAYOUT *** --->
	<cfif StructKeyExists(attributes,"layout") AND NOT isObject(attributes.layout)>
		<cfset StructDelete(attributes,"layout")>
	</cfif>
	<!--- Find layout component --->
	<cfif NOT StructKeyExists(attributes,"layout")>
		<cfif StructKeyExists(Caller,"layout") AND isObject(Caller.layout)>
			<cfset attributes.layout = Caller.layout>
		<cfelseif StructKeyExists(request,"layout") AND isObject(Caller.layout)>
			<cfset attributes.layout = request.layout>
		<cfelse>
			<cfif FileExists(ExpandPath("/layouts/Default.cfc"))>
				<!--- If the Default layout is where it is expected, go ahead and create the layout object --->
				<cfinvoke returnvariable="attributes.layout" component="layouts.Default" method="init">
					<cfinvokeargument name="CGI" value="#CGI#">
					<cfif StructKeyExists(Application,"Framework") AND StructKeyExists(Application.Framework,"Loader") AND isObject(Application.Framework.Loader)>
						<cfinvokeargument name="Factory" value="#Application.Framework.Loader#">
					</cfif>
				</cfinvoke>
				<cfset Caller.layout = attributes.layout>
				<cfset request.layout = attributes.layout>
			<cfelse>
				<!---<cfparam name="attributes.layout">--->
				<!--- Throwing an error because it isn't sufficient for the variable to exists. It also must be an object --->
				<cfthrow message="layout attribute is not defined" type="layout">
			</cfif>
		</cfif>
	</cfif>
	<cfset layout = attributes.layout>
	<cfif Len(attributes.use)>
		<cfset layout = layout.switchLayout(attributes.use)>
	</cfif>
	<cfset sLayoutComp = getMetadata(layout)>
	
	<cfset isExcel = ( ListLast(sLayoutComp.name,".") EQ "Excel" )>
	
	<cfif isExcel>
		<cfset attributes.showTitle = false>
	</cfif>
	
	<!--- *** GET TITLE OUTPUT --->
	<cfif attributes.showTitle>
		<cfif Len(attributes.TitleHTML) AND attributes.TitleHTML CONTAINS "[Title]">
			<cfset TitleOutput = ReplaceNoCase(attributes.TitleHTML,"[Title]",attributes.title,"ALL")>
		<cfelse>
			<cfsavecontent variable="TitleOutput"><cfoutput><#attributes.TitleElement#<cfloop list="#attributes.TitleAttributes#" index="att" delimiters=","><cfif ListLen(att,"=") EQ 2> #ListFirst(att,'=')#="#ListLast(att,'=')#"</cfif></cfloop>>#attributes.Title#</#attributes.TitleElement#></cfoutput></cfsavecontent>
		</cfif>
		<cfset request.sLayoutTag.HasTitleH1Output = true>
	<cfelse>
		<cfset TitleOutput = "">
	</cfif>
	
	<!--- *** META TAGS *** --->
	<cfset sMetaTags = StructNew()>
	<cfloop collection="#attributes#" item="att">
		<cfif ListLen(att,"_") EQ 2 AND ListFirst(att,"_") EQ "meta">
			<cfset sMetaTags[ListLast(att,"_")] = attributes[att]>
		</cfif>
	</cfloop>
	
</cfif>
</cfsilent>
<!--- A hack for PDF support --->
<cfif ThisTag.ExecutionMode EQ "End" AND StructKeyExists(Attributes,"use") AND Attributes.use EQ "PDF">
<cfheader name="Content-Disposition" value="attachment;filename=#ReplaceNoCase(ListLast(CGI.SCRIPT_NAME), ".cfm", ".pdf")#">
<cfcontent type="application/pdf" reset="Yes">
<cfdocument format="PDF" pagetype="letter">
<cfoutput>#ThisTag.GeneratedContent#</cfoutput>
</cfdocument>
<cfabort>
</cfif>
<cfswitch expression="#ThisTag.ExecutionMode#"><cfcase value="start"><cfoutput>
#layout.head(title=attributes.title)#<cfif NOT isExcel><cfif StructCount(sMetaTags)><cfloop collection="#sMetaTags#" item="tag">
	<meta name="#LCase(tag)#" content="#HTMLEditFormat(sMetaTags[tag])#" /></cfloop></cfif><cfif Len(attributes.files_css)><cfloop index="path" list="#attributes.files_css#">
	<link rel="stylesheet" href="#path#" type="text/css" media="all"/></cfloop></cfif><cfif Len(attributes.head_css)>
	<style type="text/css">#attributes.head_css#</style></cfif><cfif Len(attributes.files_js)><cfloop index="path" list="#attributes.files_js#">
	<script type="text/javascript" src="#path#"></script></cfloop></cfif><cfif Len(attributes.head_js)>
	<script type="text/javascript">#attributes.head_js#</script></cfif><cfif Len(attributes.head)>
	#attributes.head#</cfif></cfif>#layout.body()#<cfif Len(TitleOutput)>
#TitleOutput#</cfif><cfif Len(attributes.HTMLAbove) AND NOT StructKeyExists(request,"CF_Template_HTMLAbove")>

#attributes.HTMLAbove#<cfset request.CF_Template_HTMLAbove = true></cfif>
</cfoutput></cfcase><cfcase value="end"><cfoutput><cfif Len(attributes.HTMLBelow) AND NOT StructKeyExists(request,"CF_Template_HTMLBelow")>#attributes.HTMLBelow#<cfset request.CF_Template_HTMLBelow = true>
</cfif>
#layout.end()#</cfoutput></cfcase></cfswitch>