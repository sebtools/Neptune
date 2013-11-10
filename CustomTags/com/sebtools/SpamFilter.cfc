<!--- 1.1.5 (Build 16) --->
<!--- Last Updated: 2012-07-27 --->
<!--- Created by Steve Bryant 2007-08-15 --->
<!--- Information: sebtools.com --->
<cfcomponent displayname="Spam Filter" output="false">
<cfset cr = "
">
<cffunction name="init" access="public" returntype="any" output="no" hint="I instantiate and return this component.">
	<cfargument name="DataMgr" type="any" required="yes">
	<cfargument name="getNewDefs" type="boolean" default="0">
	<cfargument name="Scheduler" type="any" required="false">
	
	<cfscript>
	var qWords = 0;
	
	variables.DataMgr = arguments.DataMgr;
	variables.getNewDefs = arguments.getNewDefs;
	
	variables.datasource = variables.DataMgr.getDatasource();
	variables.DataMgr.loadXML(getDbXml(),true,true);
	if ( StructKeyExists(arguments,"Scheduler") ) {
		variables.Scheduler = arguments.Scheduler;
		loadScheduledTask();
	} 
	</cfscript>
	
	<cfif variables.getNewDefs>
		<cfset loadUniversalData()>
	</cfif>
	
	
	<cfset qWords = variables.DataMgr.getRecords("spamWords")>
	
	<!--- Add Default Words --->
	<cfif NOT qWords.RecordCount>
		<cfset loadWords(getDefaultSpamWords())>
	</cfif>
	
	<cfset upgrade()>
	
	<cfreturn this>
</cffunction>

<cffunction name="loadScheduledTask" access="public" returntype="void" output="no">
	<cfif StructKeyExists(variables,"Scheduler")>
		<cfinvoke component="#variables.Scheduler#" method="setTask">
			<cfinvokeargument name="Name" value="SpamFilter">
			<cfinvokeargument name="ComponentPath" value="#sMe.name#">
			<cfinvokeargument name="Component" value="#This#">
			<cfinvokeargument name="MethodName" value="loadUniversalData">
			<cfinvokeargument name="interval" value="weekly">
			<cfinvokeargument name="weekdays" value="Monday">
			<cfinvokeargument name="Hours" value="1,2,3">
		</cfinvoke>
	</cfif>
</cffunction>

<cffunction name="filter" access="public" returntype="struct" output="no" hint="I run the filter on the given structure and return it.">
	<cfargument name="data" type="struct" required="yes">
	<cfargument name="maxpoints" type="numeric" default="0">
	
	<cfif isSpam(argumentCollection=arguments)>
		<cfthrow message="This message appears to be spam." detail="If you feel that you have gotten this message in error, pleas change your entry and try again." type="SpamFilter" errorcode="Spam">
	</cfif>
	
	<cfreturn arguments.data>
</cffunction>

<cffunction name="isSpam" access="public" returntype="boolean" output="no" hint="I indicate whether the given structure is spam.">
	<cfargument name="data" type="struct" required="yes">
	<cfargument name="maxpoints" type="numeric" default="0">
	
	<cfset var pointlimit = arguments.maxpoints>
	<cfset var pointval = 0>
	<cfset var result = false>
	
	<!--- If we don't have a point limit, set it to the number of fields --->
	<cfif NOT pointlimit>
		<cfset pointlimit = getPointLimit(arguments.data)>
	</cfif>
	
	<!--- Run that filter! --->
	<cfset pointval = getPoints(arguments.data)>
	
	<cfif pointval GT pointlimit>
		<cfset result = true>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getPoints" access="public" returntype="numeric" output="no"hint="I return the number of points in the given structure.">
	<cfargument name="data" type="struct" required="yes">
	
	<cfset var pointval = 0>
	<cfset var qWords = variables.DataMgr.getRecords("spamWords")>
	<cfset var qRegExs = variables.DataMgr.getRecords("spamRegExs")>
	<cfset var field = "">
	<cfset var finds = 0>
	<cfset var field2 = "">
	<cfset var duplist = "">
	
	<cfloop collection="#arguments.data#" item="field">
		<cfif isSimpleValue(arguments.data[field]) AND Len(field) AND Len(arguments.data[field]) AND field NEQ "Email">
			<cfloop query="qWords">
				<!--- Get the number of times the word appears --->
				<cfset finds = numWordMatches(arguments.data[field],trim(Word))>
				<cfset pointval = pointval + (finds * Val(points))>
			</cfloop>
			<cfloop query="qRegExs">
				<!--- Get the number of times the expression is matched --->
				<cfset finds = numRegExMatches(arguments.data[field],trim(RegEx),Val(checkcase))>
				<cfset pointval = pointval + (finds * Val(points))>
			</cfloop>
			<!--- Points for duplicate field values --->
			<cfset duplist = ListAppend(duplist,field)>
			<cfloop collection="#arguments.data#" item="field2">
				<cfif
						(field2 NEQ field)
					AND	isSimpleValue(arguments.data[field])
					AND	isSimpleValue(arguments.data[field2])
					AND	(arguments.data[field2] EQ arguments.data[field])
					AND	NOT ListFindNoCase(duplist,field2)
				>
					<cfset pointval = pointval + 1>
					<cfset duplist = ListAppend(duplist,field2)>
				</cfif>
			</cfloop>
		</cfif>
	</cfloop>
	
	<cfreturn pointval>
</cffunction>

<cffunction name="getPointsArray" access="public" returntype="array" output="no"hint="I return an array of details about the points in the given structure.">
	<cfargument name="data" type="struct" required="yes">
	
	<cfset var pointval = 0>
	<cfset var qWords = variables.DataMgr.getRecords("spamWords")>
	<cfset var qRegExs = variables.DataMgr.getRecords("spamRegExs")>
	<cfset var field = "">
	<cfset var finds = 0>
	<cfset var aPoints = ArrayNew(1)>
	<cfset var field2 = "">
	<cfset var duplist = "">
	
	<cfloop collection="#arguments.data#" item="field">
		<cfif isSimpleValue(arguments.data[field]) AND Len(field) AND Len(arguments.data[field]) AND field NEQ "Email">
			<cfloop query="qWords">
				<!--- Get the number of times the word appears --->
				<cfset finds = numWordMatches(arguments.data[field],trim(Word))>
				<cfif finds>
					<cfset pointval = pointval + (finds * points)>
					<cfset ArrayAppend(aPoints,"#(finds * points)#:#trim(Word)#")>
				</cfif>
			</cfloop>
			<cfloop query="qRegExs">
				<!--- Get the number of times the expression is matched --->
				<cfset finds = numRegExMatches(arguments.data[field],trim(RegEx),Val(checkcase))>
				<cfif finds>
					<cfset pointval = pointval + (finds * points)>
					<cfset ArrayAppend(aPoints,"#(finds * points)#:(#Label#):#trim(Regex)#")>
				</cfif>
			</cfloop>
			<!--- Points for duplicate field values --->
			<cfset duplist = ListAppend(duplist,field)>
			<cfloop collection="#arguments.data#" item="field2">
				<cfif
						(field2 neq field)
					AND	isSimpleValue(arguments.data[field])
					AND	isSimpleValue(arguments.data[field2])
					AND	(arguments.data[field2] eq arguments.data[field])
					AND	NOT ListFindNoCase(duplist,field2)
				>
					<cfset pointval = pointval + 1>
					<cfset duplist = ListAppend(duplist,field2)>
					<cfset ArrayAppend(aPoints,"#(1)#:(duplicate):#field2#:#arguments.data[field2]#")>
				</cfif>
			</cfloop>
		</cfif>
	</cfloop>
	
	<cfreturn aPoints>
</cffunction>

<cffunction name="getRegEx" access="public" returntype="query" output="no" hint="I return the requested regex.">
	<cfargument name="RegExID" type="string" required="yes">
	
	<cfreturn variables.DataMgr.getRecord("spamRegExs",arguments)>
</cffunction>

<cffunction name="getRegExs" access="public" returntype="query" output="no" hint="I return all of the regexs.">
	
	<cfreturn variables.DataMgr.getRecords("spamRegExs",arguments)>
</cffunction>

<cffunction name="getWord" access="public" returntype="query" output="no" hint="I return the requested word.">
	<cfargument name="WordID" type="string" required="yes">
	
	<cfreturn variables.DataMgr.getRecord("spamWords",arguments)>
</cffunction>

<cffunction name="getWords" access="public" returntype="query" output="no" hint="I return all of the words.">
	
	<cfreturn variables.DataMgr.getRecords("spamWords",arguments)>
</cffunction>

<cffunction name="loadUniversalData" access="public" returntype="void" output="no" hint="I get external spam definitions.">
	
	<cftry>
		<!--- Do an HTTP call to get a text file with spam words --->
		<cfhttp url="http://www.bryantwebconsulting.com/spamdefs.txt" method="GET" resolveurl="false"></cfhttp>
		
		<!--- Parse the XML file and load new spam words --->
		<cfset loadWords(CFHTTP.FileContent)>
		
		<cfcatch>
		</cfcatch>
	</cftry>
	
	<cftry>
		<!--- Do an HTTP call to get an XML file with spam expressions --->
		<cfhttp url="http://www.bryantwebconsulting.com/spamdefs.xml" method="GET" resolveurl="false"></cfhttp>
		
		<!--- Parse the XML file and load new spam expressions --->
		<cfset variables.DataMgr.loadXML(CFHTTP.FileContent,true,true)>
		
		<cfcatch>
		</cfcatch>
	</cftry>
	
</cffunction>

<cffunction name="loadWords" access="public" returntype="void" output="no"hint="I load the given list of (carriage-return delimited) words to the spam words definitions.">
	<cfargument name="wordlist" type="string" required="yes">
	
	<cfset var word = "">
	<cfset var data = StructNew()>
	
	<cfloop list="#arguments.wordlist#" index="word" delimiters="#cr#">
		<cfset data["Word"] = trim(word)>
		<cfset variables.DataMgr.insertRecord("spamWords",data,"skip")>
	</cfloop>
	
</cffunction>

<cffunction name="removeRegEx" access="public" returntype="void" output="no" hint="I delete the given RegEx.">
	<cfargument name="RegExID" type="string" required="yes">
	
	<cfset variables.DataMgr.deleteRecord("spamRegExs",arguments)>
	
</cffunction>

<cffunction name="removeWord" access="public" returntype="void" output="no" hint="I delete the given Word.">
	<cfargument name="WordID" type="string" required="yes">
	
	<cfset variables.DataMgr.deleteRecord("spamWords",arguments)>
	
</cffunction>

<cffunction name="saveRegEx" access="public" returntype="string" output="no" hint="I save a RegEx.">
	<cfargument name="RegExID" type="string" required="no">
	<cfargument name="RegEx" type="string" required="no">
	<cfargument name="Label" type="string" required="no">
	<cfargument name="points" type="string" required="no">
	
	<cfreturn variables.DataMgr.saveRecord("spamRegExs",arguments)>
</cffunction>

<cffunction name="saveWord" access="public" returntype="string" output="no" hint="I save a Word.">
	<cfargument name="WordID" type="string" required="no">
	<cfargument name="Word" type="string" required="no">
	<cfargument name="points" type="string" required="no">
	
	<cfreturn variables.DataMgr.saveRecord("spamWords",arguments)>
</cffunction>

<cffunction name="numRegExMatches" access="public" returntype="numeric" output="no" hint="I return the number of times the given regular expression is matched in the given string.">
	<cfargument name="string" type="string" require="true">
	<cfargument name="regex" type="string" require="true">
	<cfargument name="checkcase" type="boolean" default="false">
	
	<cfset var result = 0>
	<cfset var sFind = 0>
	
	<cfif arguments.checkcase>
		<cfreturn numRegExCaseMatches(arguments.string,arguments.regex)>
	</cfif>
	
	<cfscript>
	sFind = REFindNoCase(arguments.regex, arguments.string, 1, true);
	while ( sFind.pos[1] GT 0 ) {
		result = result + 1;
		sFind = REFindNoCase(arguments.regex, arguments.string, sFind.pos[1]+sFind.len[1], true );
	}
	</cfscript>
	
	<cfreturn result>
</cffunction>

<cffunction name="getRegExCaseMatches" access="public" returntype="array" output="no" hint="I return an array of the given regular expression is matches in the given string.">
	<cfargument name="string" type="string" require="true">
	<cfargument name="regex" type="string" require="true">
	
	<cfset var aResults = ArrayNew(1)>
	<cfset var sFind = REFind(arguments.regex, arguments.string,1,true)>
	
	<cfscript>
	while ( sFind.pos[1] GT 0 ) {
		ArrayAppend(aResults, Mid(Arguments.string,sFind.pos[1],sFind.len[1]));
		sFind = REFind(arguments.regex, arguments.string, sFind.pos[1]+1,true);
	}
	</cfscript>
	
	<cfreturn aResults>
</cffunction>

<cffunction name="numRegExCaseMatches" access="public" returntype="numeric" output="no" hint="I return the number of times the given regular expression is matched in the given string.">
	<cfargument name="string" type="string" require="true">
	<cfargument name="regex" type="string" require="true">
	
	<cfset var result = 0>
	<cfset var findat = REFind(arguments.regex, arguments.string)>
	
	<cfscript>
	while ( findat GT 0 ) {
		result = result + 1;
		findat = REFind(arguments.regex, arguments.string, findat+1);
	}
	</cfscript>
	
	<cfreturn result>
</cffunction>

<cffunction name="numWordMatches" access="public" returntype="numeric" output="no" hint="I return the number of times the given word is found in the given string.">
	<cfargument name="string" type="string" require="true">
	<cfargument name="word" type="string" require="true">
	
	<cfreturn numRegExMatches(arguments.string,"\b#arguments.word#\b")>
</cffunction>

<cffunction name="upgrade" access="public" returntype="void" output="no">
	
	<cfquery datasource="#variables.datasource#">
	UPDATE	spamRegExs
	SET		RegEx = <cfqueryparam value="^['_a-z0-9-]+(\.['_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*\.(([a-z]{2,3})|(aero|coop|info|museum|name|jobs|travel))$" cfsqltype="CF_SQL_VARCHAR">
	WHERE	RegEx = <cfqueryparam value="['_a-z0-9-]+(\.['_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*\.(([a-z]{2,3})|(aero|coop|info|museum|name|jobs|travel))" cfsqltype="CF_SQL_VARCHAR">
	</cfquery>
	
</cffunction>

<cffunction name="getPointLimit" access="public" returntype="numeric" output="no">
	<cfargument name="struct" type="struct" required="yes">
	
	<cfset var key = "">
	<cfset var result = 0>
	
	<cfloop collection="#arguments.struct#" item="key">
		<cfif StructKeyExists(arguments.struct,key) AND isSimpleValue(arguments.struct[key]) AND Len(Trim(arguments.struct[key])) AND key NEQ "Email">
			<cfset result = result + 1>
		</cfif>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<cffunction name="getDbXml" access="public" returntype="string" output="no" hint="I return the XML for the tables needed for SpamFilter.cfc to work.">
	
	<cfset var tableXML = "">
	
	<cfsavecontent variable="tableXML"><cfoutput>
	<tables>
		<table name="spamWords">
			<field ColumnName="WordID" CF_DataType="CF_SQL_INTEGER" PrimaryKey="true" Increment="true" />
			<field ColumnName="Word" CF_DataType="CF_SQL_VARCHAR" Length="150" />
			<field ColumnName="points" CF_DataType="CF_SQL_INTEGER" Default="1" />
		</table>
		<table name="spamRegExs">
			<field ColumnName="RegExID" CF_DataType="CF_SQL_INTEGER" PrimaryKey="true" Increment="true" />
			<field ColumnName="RegEx" CF_DataType="CF_SQL_VARCHAR" Length="250" />
			<field ColumnName="Label" CF_DataType="CF_SQL_VARCHAR" Length="60" />
			<field ColumnName="points" CF_DataType="CF_SQL_INTEGER" Default="1" />
			<field ColumnName="checkcase" CF_DataType="CF_SQL_BIT" Default="0" />
		</table>
		<data table="spamRegExs" permanentRows="true" checkFields="Label" onexists="update">
			<row Label="Email" points="2" RegEx="^['_a-z0-9-]+(\.['_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*\.(([a-z]{2,3})|(aero|coop|info|museum|name|jobs|travel))$" />
			<row Label="URL" points="2" RegEx="https?://(\w*:\w*@)?[-\w.]+(:\d+)?(/([\w/_.]*(\?\S+)?)?)?" />
			<row Label="URL2" points="2" RegEx="URL=[\w-]+\.+[\w-]{3,}\b" />
			<row Label="Million Dollars" points="3" Regex="\$.*,\d{3},\d{3}(\.d{2})?" />
			<row Label="IP Address" points="3" Regex="\b(((\d{1,2})|(1\d{2})|(2[0-4])|(25[0-5]))\.){3}((\d{1,2})|(1\d{2})|(2[0-4])|(25[0-5]))\b" />
			<row Label="GobbledyGook" points="0" Regex="\b[^\s]*?[bcdfghjklmnpqrstvxwz]{5,}[^\s]*?\b" />
			<row Label="Junk" points="3" Regex="[^a-z\d_\-\.@##\s:;/\+]{5,}" />
			<row Label="Case Changes" points="2" Regex="\b([a-z][A-Z][^ \n\b]*){3,}\b" checkcase="true" />
			<row Label="Words with numbers" points="2" Regex="\b[a-z]+\d+\w+\b" />
		</data>
	</tables>
	</cfoutput></cfsavecontent>
	
	<cfreturn tableXML>
</cffunction>

<cffunction name="getDefaultSpamWords" access="private" returntype="string" output="no">

	<cfset var result = "">
<cfsavecontent variable="result"><cfoutput>-online
4u
adipex
adult book
adult comic
advicer
baccarrat
blackjack
bllogspot
bondage
booker
byob
car-rental-e-site
car-rentals-e-site
carisoprodol
casino
casinos
chatroom
cialis
coolcoolhu
coolhu
credit-card-debt
credit-report-4u
cwas
cyclen
cyclobenzaprine
dating-e-site
day-trading
debt-consolidation
debt-consolidation-consultant
discreetordering
duty-free
dutyfree
equityloans
fioricet
flowers-leading-site
freenet-shopping
freenet
free-site-host.com
gambling-
hair-loss
health-insurancedeals-4u
homeequityloans
homefinance
holdem
holdempoker
holdemsoftware
holdemtexasturbowilson
hotel-dealse-site
hotele-site
hotelse-site
incest
insurance-quotesdeals-4u
insurancedeals-4u
jrcreations
levitra
macinstruct
MILLION UNITED STATES DOLLARS
mortgage-4-u
mortgagequotes
online-gambling
onlinegambling-4u
ottawavalleyag
ownsthis
palm-texas-holdem-game
paxil
penis
pharmacy
phentermine
poker-chip
porn
porno
poze
propecia
pussy
rental-car-e-site
ringtones
roulette 
sex
shemale
shoes
slot-machine
texas-holdem
thorcarlson
top-site
top-e-site
tramadol
trim-spa
ultram
valeofglamorganconservatives
viagra
vioxx
xanax
zolus</cfoutput></cfsavecontent>
	<cfreturn result>
</cffunction>

</cfcomponent>