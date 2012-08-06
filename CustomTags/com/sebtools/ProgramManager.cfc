<!--- 1.0 Beta 3 (Build 35) --->
<!--- Last Updated: 2011-11-23 --->
<!--- Information: sebtools.com --->
<cfcomponent>

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="Manager" type="any" required="yes">
	<cfargument name="NoticeMgr" type="any" required="no">
	<cfargument name="Scheduler" type="any" required="no">
	<cfargument name="ErrorEmail" type="string" required="no">
	<cfargument name="Observer" type="any" required="no">
	
	<cfset initInternal(argumentCollection=arguments)>
	
	<cfreturn this>
</cffunction>

<cffunction name="initInternal" access="public" returntype="any" output="no" hint="I initialize and return this object.">
	<cfargument name="Manager" type="any" required="yes">
	<cfargument name="NoticeMgr" type="any" required="no">
	<cfargument name="Scheduler" type="any" required="no">
	<cfargument name="ErrorEmail" type="string" required="no">
	<cfargument name="Observer" type="any" required="no">
	
	<!--- Copy initialization arguments to variables so that they will be persistent with component but not available outside component --->
	<cfscript>
	var key = "";
	var xmlcustom = getMethodOutputValue(variables,"customxml");
	
	variables.sMe = getMetaData(This);
	variables.CurrentFolder = getDirectoryFromPath(variables.sMe.Path);
	
	loadComponentData();
	
	for (key in arguments) {
		variables[key] = arguments[key];
		if ( StructKeyExists(arguments,key) AND isObject(arguments[key]) ) {
			This[key] = arguments[key];
		}
	}
	
	variables.DataMgr = variables.Manager.DataMgr;
	variables.FileMgr = variables.Manager.FileMgr;
	variables.datasource = variables.DataMgr.getDatasource();
	
	variables.xDefs = loadXML(getMethodOutputValue(variables,"xml"));
	This.xDefs = variables.xDefs;
	if ( Len(Trim(xmlcustom)) ) {
		//Make sure to use prefix attribute in customxml
		if (
				StructKeyExists(variables.xDefs.tables.XmlAttributes,"prefix")
			AND	Len(Trim(variables.xDefs.tables.XmlAttributes["prefix"]))
		) {
			xmlcustom = ReplaceNoCase(xmlcustom,'<tables>','<tables prefix="#variables.xDefs.tables.XmlAttributes.prefix#">');
		}
		variables.xDefsCustom = loadXML(xmlcustom);
	}
	loadCustomFields();
	
	if ( StructKeyExists(arguments,"NoticeMgr") ) {
		This.NoticeMgr = variables.NoticeMgr;
		loadNotices();
	}
	if ( StructKeyExists(arguments,"Scheduler") ) {
		This.Scheduler = variables.Scheduler;
		loadScheduledTask();
	}
	loadComponents();
	
	variables.SendEmailOnError = true;
	
	if ( StructKeyExists(This,"Observer") AND StructKeyExists(This.Observer,"setSubject") ) {
		This.Observer.setSubject(This);
	}
	</cfscript>
	
	<cfreturn This>
</cffunction>

<cffunction name="getCustomExtension" access="public" returntype="string" output="false" hint="">
	
	<cfset var result = "">
	
	<cfif StructKeyExists(variables,"CustomSuffix") AND isSimpleValue(variables.CustomSuffix) AND Len(Trim(variables.CustomSuffix))>
		<cfset result = variables.CustomSuffix>
	<cfelseif ListLen(ListLast(variables.me.fullname,"."),"_") EQ 2>
		<cfset result = ListLast(variables.me.fullname,"_")>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getMeData" access="public" returntype="struct" output="false" hint="">
	
	<cfset var sThis = 0>
	<cfset var filename = "">
	
	<cfif NOT StructKeyExists(Variables,"me")>
		<cfset sThis = getMetaData(This)>
		<cfset filename = ListLast(sThis.name,".")>
		
		<cfset variables.me = StructNew()>
		<cfset variables.me["fullname"] = filename>
		<cfset variables.me["name"] = ListFirst(variables.me["fullname"],"_")>
		<cfset variables.me["path"] = reverse(ListRest(reverse(sThis.name),"."))>
		<cfif StructKeyExists(sThis,"DisplayName")>
			<cfset variables.me["label"] = sThis.DisplayName>
		<cfelse>
			<cfset variables.me["label"] = variables.me["name"]>
		</cfif>
		<cfset variables.me["dir"] = getDirectoryFromPath(sThis.path)>
	</cfif>
	
	<cfreturn Variables.me>
</cffunction>

<cffunction name="loadComponentData" access="public" returntype="void" output="false" hint="">
	
	<cfset getMeData()>
	
</cffunction>

<cffunction name="getPrefix" access="public" returntype="string" output="no">
	
	<cfreturn Variables.prefix>
</cffunction>

<cffunction name="getServiceComponent" access="public" returntype="any" output="no">
	<cfargument name="name" type="string" required="true">
	
	<cfset var result = arguments.name>
	
	<cfif StructKeyExists(This,arguments.name)>
		<cfset result = This[arguments.name]>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getComponentsList" access="public" returntype="string" output="false" hint="">
	
	<cfset var qComponentFiles = 0>
	<cfset var comp = "">
	<cfset var result = "">
	
	<cfdirectory directory="#variables.me.dir#" name="qComponentFiles" filter="*.cfc">
	
	<cfloop query="qComponentFiles">
		<cfset comp = ListFirst(name,".")>
		<cfif
				ListLen(comp,"_") EQ 1
			AND	comp NEQ variables.me.name
			AND	comp NEQ variables.me.fullname
			AND NOT ListFindNoCase(result,comp)
		>
			<cfset result = ListAppend(result,comp)>
		</cfif>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<cffunction name="getComponentTableName" access="public" returntype="string" output="false" hint="">
	<cfargument name="Comp" type="any" required="true">
	
	<cfset var sCompData = 0>
	<cfset var qInfo = 0>
	<cfset var result = "">
	
	<cfif isObject(arguments.Comp)>
		<cfset sCompData = getMetaData(arguments.Comp)>
	<cfelseif isStruct(arguments.Comp)>
		<cfset sCompData = arguments.Comp>
	<cfelse>
		<cfthrow message="Comp argument must be a component or a structure." type="ProgramManager">
	</cfif>
	
	<cfquery name="qInfo" dbtype="query">
	SELECT	name
	FROM	variables.qTables
	WHERE	methodPlural = '#ListLast(sCompData.name,".")#'
	</cfquery>
	
	<cfif qInfo.RecordCount EQ 1>
		<cfset result = qInfo.name>
	<cfelse>
		<cfquery name="qInfo" dbtype="query">
		SELECT	name
		FROM	variables.qTables
		WHERE	entities = '#ListLast(sCompData.name,".")#'
		</cfquery>
		<cfif qInfo.RecordCount EQ 1>
			<cfset result = qInfo.name>
		<cfelse>
			<cfif
					StructKeyExists(sCompData,"extends")
				AND	StructKeyExists(sCompData.extends,"name")
				AND	NOT (
							ListLast(sCompData.extends.name,".") EQ "Records"
						OR	ListLast(sCompData.extends.name,".") EQ "component"
				)
			>
				<cftry>
						<cfset result = getComponentTableName(sCompData.extends)>
				<cfcatch>
					<cfthrow message="Unable to determine table for #ListLast(sCompData.name,".")#." type="ProgramManager">
				</cfcatch>
				</cftry>
			<cfelse>
				<cfthrow message="Unable to determine table for #ListLast(sCompData.name,".")#." type="ProgramManager">
			</cfif>
		</cfif>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getTableName" access="public" returntype="string" output="false" hint="">
	
	<cfset var result = "">
	
	<cfif StructKeyExists(variables,"xDefs")>
	
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getVariable" access="package" returntype="any" output="false" hint="">
	<cfargument name="name" type="string" required="true">
	
	<cfset var result = "">
	
	<cfif StructKeyExists(variables,arguments.name)>
		<cfset result = variables[arguments.name]>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="notifyEvent" access="public" returntype="void" output="no">
	<cfargument name="EventName" type="string" required="true">
	<cfargument name="Args" type="struct" required="false">
	<cfargument name="result" type="any" required="false">
	
	<cfif StructKeyExists(Variables,"Observer") AND StructKeyExists(Variables.Observer,"notifyEvent")>
		<cfset Variables.Observer.notifyEvent(ArgumentCollection=Arguments)>
	</cfif>
	
</cffunction>

<cffunction name="customxml" access="private" returntype="string" output="false" hint="">
	<cfreturn "">
</cffunction>

<cffunction name="loadCustomFields" access="private" returntype="any" output="false" hint="">

</cffunction>

<cffunction name="loadComponents" access="private" returntype="void" output="false" hint="">
	
	<cfset var comps = getComponentsList()>
	<cfset var comp = "">
	
	<cfif StructKeyExists(variables,"qTables")>
		<cfloop query="variables.qTables">
			<cfif Len(Trim(methodPlural))>
				<cfset comp = variables.Manager.makeCompName(methodPlural)>
				<cfif NOT ( StructKeyExists(This,comp) OR ListFindNoCase(comps,comp) )>
					<cfif FileExists("#variables.me.dir##comp#.cfc")>
						<cfset loadComponent(comp)>
					<cfelse>
						<cfset loadComponent(name=comp,table=name,path="com.sebtools.Records")>
					</cfif>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfloop list="#comps#" index="comp">
		<cfif NOT StructKeyExists(This,comp)>
			<cfif StructKeyExists(This,"component_#comp#")>
				<cfinvoke component="#This#" method="component_#comp#">
			<cfelse>
				<cfset loadComponent(comp)>
			</cfif>
		</cfif>
	</cfloop>
	
</cffunction>

<cffunction name="loadNotices" access="private" returntype="any" output="false" hint="">
	
	<cfset var sNotice = StructNew()>
	
</cffunction>

<cffunction name="loadScheduledTask" access="private" returntype="any" output="false" hint="">
	<cfif StructKeyExists(variables,"Scheduler") AND StructKeyExists(This,"runScheduledTask")>
		<cfinvoke component="#variables.Scheduler#" method="setTask">
			<cfinvokeargument name="Name" value="#ListLast(sMe.name,'.')#">
			<cfinvokeargument name="ComponentPath" value="#sMe.name#">
			<cfinvokeargument name="Component" value="#This#">
			<cfinvokeargument name="MethodName" value="runScheduledTask">
			<cfinvokeargument name="interval" value="hourly">
		</cfinvoke>
	</cfif>
</cffunction>

<cffunction name="loadXml" access="private" returntype="any" output="false" hint="">
	<cfargument name="xml" type="string" required="true">
	
	<cfscript>
	var xData = variables.Manager.loadXML(arguments.xml);
	var aTables = XmlSearch(xData,"//table");
	var ii = 0;
	var att = 0;
	var cols = "name,entity,entities,labelField,labelPlural,labelSingular,methodSingular,methodPlural,deletable,sortfield";
	var row = 0;
	
	if ( NOT StructKeyExists(variables,"qTables") ) {
		variables.qTables = QueryNew(cols);
	}
	
	for ( ii=1; ii LTE ArrayLen(aTables); ii=ii+1 ) {
		if (
				NOT ListFindNoCase(ValueList(variables.qTables.name),aTables[ii].XmlAttributes.name)
			AND	NOT ( StructKeyExists(aTables[ii].XmlAttributes,"entity") AND Len(aTables[ii].XmlAttributes["entity"]) AND ListFindNoCase(ValueList(variables.qTables.entity),aTables[ii].XmlAttributes.entity) )
		) {
			QueryAddRow(variables.qTables);
			row = variables.qTables.RecordCount;
			for ( att in aTables[ii].XmlAttributes ) {
				if ( ListFindNoCase(cols,att) ) {
					QuerySetCell(variables.qTables,att,aTables[ii].XmlAttributes[att],row);
				}
			}
			if ( StructKeyExists(aTables[ii].XmlAttributes,"entity") ) {
				QuerySetCell(variables.qTables,"entities",variables.Manager.pluralize(aTables[ii].XmlAttributes["entity"]),row);
			}
			if ( NOT Len(variables.qTables["methodSingular"][row]) ) {
				if ( StructKeyExists(aTables[ii].XmlAttributes,"labelSingular") ) {
					QuerySetCell(variables.qTables,"methodSingular",aTables[ii].XmlAttributes["labelSingular"],row);
				}
			}
			if ( NOT Len(variables.qTables["methodPlural"][row]) ) {
				if ( StructKeyExists(aTables[ii].XmlAttributes,"labelPlural") ) {
					QuerySetCell(variables.qTables,"methodPlural",aTables[ii].XmlAttributes["labelPlural"],row);
				}
			}
			QuerySetCell(variables.qTables,"methodSingular",makeCompName(variables.qTables["methodSingular"][row]),row);
			QuerySetCell(variables.qTables,"methodPlural",makeCompName(variables.qTables["methodPlural"][row]),row);
		}
	}
	</cfscript>
	
	<cfreturn xData>
</cffunction>

<cffunction name="runScheduledTask" access="public" returntype="any" output="false" hint="">
	
</cffunction>

<cffunction name="sendNotice" access="public" returntype="void" output="false" hint="">
	<cfargument name="Action" type="string" required="yes">
	
	<cfif StructKeyExists(variables,"NoticeMgr")>
	
	</cfif>
	
</cffunction>

<cffunction name="component" access="private" returntype="any" output="no" hint="DEPRECATED">
	<cfargument name="name" type="string" required="yes">
	
	<cfset loadComponent(argumentCollection=arguments)>
	
</cffunction>

<cffunction name="getMethodOutputValue" access="private" returntype="string" output="no" hint="DEPRECATED">
	<cfargument name="component" type="any" required="yes">
	<cfargument name="method" type="string" required="yes">
	<cfargument name="args" type="struct" required="no">
	
	<cfset var result = "">
	<cfset var fMethod = component[method]>
	
	<cfif StructKeyExists(arguments,"args")>
		<cfsavecontent variable="result"><cfoutput>#fMethod(argumentCollection=args)#</cfoutput></cfsavecontent>
	<cfelse>
		<cfsavecontent variable="result"><cfoutput>#fMethod()#</cfoutput></cfsavecontent>
	</cfif>
	
	<cfset result = Trim(result)>
	
	<cfreturn result>
</cffunction>

<cffunction name="loadComponent" access="private" returntype="any" output="no" hint="I load a component into memory in this component.">
	<cfargument name="name" type="string" required="yes">
	
	<cfset var ext = getCustomExtension()>
	<cfset var extpath = "">
	
	<cfif NOT StructKeyExists(Arguments,"path")>
		<cfset Arguments.path = "#variables.me.path#.#arguments.name#">
	</cfif>
	
	<cfset extpath = "#getDirectoryFromPath(getCurrentTemplatePath())##arguments.name#_#ext#.cfc">
	
	<cfif Len(ext) AND FileExists(extpath)>
		<cfset Arguments.path = "#Arguments.path#_#ext#">
	</cfif>
	
	<cfset StructAppend(Arguments,loadComponentArguments())>
	
	<cfinvoke component="#Arguments.path#" method="init" returnvariable="this.#name#" ArgumentCollection="#Arguments#"></cfinvoke>
	
	<cfset variables[Arguments.name] = This[Arguments.name]>
	
</cffunction>

<cffunction name="loadComponentArguments" access="private" returntype="any" output="no" hint="I return the arguments to be passed to each component.">
	
	<cfset var sArgs = StructNew()>
	
	<cfset sArgs["Manager"] = variables.Manager>
	<cfset sArgs["Parent"] = This>
	<cfset sArgs[variables.me.name] = This>
	
	<cfreturn sArgs>
</cffunction>

<cffunction name="getErrorType" access="public" returntype="string" output="no">
	
	<cfset getMeData()>
	
	<cfif NOT StructKeyExists(Variables,"ErrorType")>
		<cfset Variables.ErrorType = ListLast(variables.me.name,'.')>
	</cfif>
	
	<cfreturn Variables.ErrorType>
</cffunction>

<cffunction name="getRootURL" access="package" returntype="string" output="no">
	
	<cfset var SiteURL = variables.Manager.getRootURL()>
	<cfset var SitePath = variables.Manager.getRootPath()>
	<cfset var FolderPath = "">
	<cfset var result = "">
	
	<cfif Len(SiteURL)>
		<cfif Len(SitePath)>
			<cfif sMe.Path CONTAINS SitePath>
				<cfset FolderPath = ReplaceNoCase(sMe.Path,SitePath,"")>
				<!--- To commas, for brevity of later code --->
				<cfset FolderPath = ListChangeDelims(FolderPath,",","\")>
			</cfif>
		<cfelse>
			<!--- To commas, for brevity of later code --->
			<cfset FolderPath = ListChangeDelims(sMe.name,",",".")>
		</cfif>
		
		<cfif Len(FolderPath)>
			<!--- Delete File Name --->
			<cfset FolderPath = ListDeleteAt(FolderPath,ListLen(FolderPath))>
			<!--- "model" AND "sys" are used for components --->
			<cfif ListLast(FolderPath) EQ "model" OR ListLast(FolderPath) EQ "sys">
				<cfset FolderPath = ListDeleteAt(FolderPath,ListLen(FolderPath))>
			</cfif>
			<!--- To slashes for use in URL --->
			<cfset FolderPath = ListChangeDelims(FolderPath,"/",",")>
			<!--- Make sure we get an ending slash --->
			<cfif Right(FolderPath,1) NEQ "/">
				<cfset FolderPath = "#FolderPath#/">
			</cfif>
			<cfset result = "#SiteURL##FolderPath#">
		</cfif>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="sendEmailAlert" access="package" returntype="void" output="false" hint="">
	<cfargument name="Subject" type="string" required="yes">
	<cfargument name="html" type="string" required="yes">
	
	<cfset var oMailer = 0>
	
	<cfif StructKeyExists(variables,"NoticeMgr")>
		<cfset oMailer = variables.NoticeMgr.getMailer()>
	</cfif>
	
	<cfif StructKeyExists(variables,"NoticeMgr") AND StructKeyExists(variables,"ErrorEmail") AND Len(Trim(variables.ErrorEmail))>
		<cfinvoke component="#oMailer#" method="send">
			<cfinvokeargument name="To" value="#variables.ErrorEmail#">
			<cfinvokeargument name="Subject" value="#arguments.Subject#">
			<cfinvokeargument name="html" value="#arguments.html#">
		</cfinvoke>
	</cfif>
	
</cffunction>

<cffunction name="throwError" access="public" returntype="void" output="false" hint="">
	<cfargument name="message" type="string" required="yes">
	<cfargument name="errorcode" type="string" default="">
	<cfargument name="detail" type="string" default="">
	<cfargument name="extendedinfo" type="string" default="">
	<cfargument name="sendEmail" type="boolean" default="#variables.SendEmailOnError#">
	
	<cfset var html = "">
	
	<cfif arguments.sendEmail>
		<cfsavecontent variable="html"><cfoutput><cfdump var="#arguments#"></cfoutput></cfsavecontent>
		<cfset sendEmailAlert("#variables.me.label# Error",html)>
	</cfif>
	
	<cfthrow
		type="#getErrorType()#"
		message="#arguments.message#"
		errorcode="#arguments.errorcode#"
		detail="#arguments.detail#"
		extendedinfo="#arguments.extendedinfo#"
	>
	
</cffunction>

<cffunction name="onMissingMethod" access="public" returntype="any" output="no">
	
	<cfset var result = 0>
	<cfset var method = Arguments.missingMethodName>
	<cfset var args = Arguments.missingMethodArguments>
	<cfset var isValidMethod = false>
	<cfset var ii = 0>
	<cfset var sTable = 0>
	
	<cfloop index="ii" from="1" to="#ArrayLen(This.xDefs.tables.table)#">
		<cfset sTable = This.xDefs.tables.table[ii].XmlAttributes>
		<cfif
				StructKeyExists(sTable,"methodPlural")
			AND	StructKeyExists(This,sTable["methodPlural"])
			AND	StructKeyExists(This[sTable["methodPlural"]],method)
		>
			<cfinvoke
				returnvariable="result"
				component="#This[sTable.methodPlural]#"
				method="#method#"
				argumentcollection="#args#"
			/>
			<cfset isValidMethod = true>
			<cfbreak>
		</cfif>
	</cfloop>
	
	<cfif NOT isValidMethod>
		<cfthrow message="The method #method# was not found in component #getCurrentTemplatePath()#" detail=" Ensure that the method is defined, and that it is spelled correctly.">
	</cfif>
	
	<cfif isDefined("result")>
		<cfreturn result>
	</cfif>
	
</cffunction>

<cfscript>
function makeLinkVar(str) {
	return LCase(makeCompName(str));
}
function makeCompName(str) {
	return variables.Manager.makeCompName(str);
}
function makeFileName(str) {
	/* Change special character to underscores */
	var result = ReReplaceNoCase(LCase(str),"[^a-z0-9]","_","ALL");
	var find = FindNoCase("__",result);
	
	/* Remove duplicate underscores */
	while ( find GT 0 ) {
		result = ReplaceNoCase(result,"__","_","ALL");
		find = FindNoCase("__",result);
	}
	
	return result;
}
</cfscript>
</cfcomponent>