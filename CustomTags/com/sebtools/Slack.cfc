<cfcomponent displayname="Slack" hint="Slack Messaging Integration" output="false">
	
<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="WebHookURL" type="string" required="yes">
	<cfargument name="isProduction" type="boolean" default="true">

	<cfset variables.WebHookURL = arguments.WebHookURL>
	<cfset variables.isProduction = arguments.isProduction>

	<cfreturn This>
</cffunction>

<cffunction name="getWebHookURL" access="public" returntype="string" output="no">
	<cfreturn variables.WebHookURL>
</cffunction>

<cffunction name="sendNotice" access="public" returntype="void" output="no">
	<cfargument name="Message" type="string" required="yes">
	<cfargument name="image_url" type="string" required="no">
	<cfargument name="icon_emoji" type="string" required="no" hint="List of Emojis: http://www.emoji-cheat-sheet.com/">
	<cfargument name="icon_type" type="string" required="no">
	<cfargument name="sitename" type="string" required="no">
	<cfargument name="notice_type" type="string" default="Notification">

	<cfset var sMessage = StructNew()>

	<cfif variables.isProduction>
		<cfset sMessage["text"] = Arguments.Message>

		<cfif StructKeyExists(arguments,'image_url') AND len(arguments.image_url)>
			<cfset sMessage["icon_url"] = arguments.image_url />	
		</cfif>

		<cfif StructKeyExists(arguments,'sitename') AND len(arguments.sitename)>
			<cfset sMessage["username"] = arguments.sitename & ' #Arguments.notice_type#'>	
		<cfelse>
			<cfset sMessage["username"] = Arguments.notice_type>	
		</cfif>

		<cfif StructKeyExists(arguments,'icon_type') AND len(arguments.icon_type)>
			<cfswitch expression="#arguments.icon_type#">
				<cfcase value="warning">
					<cfset sMessage["icon_emoji"] = ':warning:'>		
				</cfcase>
				<cfcase value="exclaim">
					<cfset sMessage["icon_emoji"] = ':exclamation:'>		
				</cfcase>
				<cfcase value="success">
					<cfset sMessage["icon_emoji"] = ':white_check_mark:'>		
				</cfcase>
				<cfcase value="failure">
					<cfset sMessage["icon_emoji"] = ':x:'>		
				</cfcase>
				<cfcase value="event">
					<cfset sMessage["icon_emoji"] = ':loudspeaker:'>		
				</cfcase>
				<cfcase value="bang">
					<cfset sMessage["icon_emoji"] = ':heavy_exclamation_mark:'>		
				</cfcase>
				<cfcase value="bangbang">
					<cfset sMessage["icon_emoji"] = ':bangbang:'>		
				</cfcase>
				<cfcase value="time">
					<cfset sMessage["icon_emoji"] = '#getTimeEmoji()#'>		
				</cfcase>
				<cfcase value="timer">
					<cfset sMessage["icon_emoji"] = ':hourglass_flowing_sand:'>		
				</cfcase>
			</cfswitch>
		</cfif>

		<cfif StructKeyExists(arguments,'icon_emoji') AND len(arguments.icon_emoji)>
			<cfset sMessage["icon_emoji"] = arguments.icon_emoji>	
		</cfif>

		<!--- default icon --->
		<cfif NOT StructKeyExists(sMessage,'icon_url') AND NOT StructKeyExists(sMessage,'icon_emoji')>
			<cfset sMessage["icon_emoji"] = ':loudspeaker:'>	
		</cfif>

		<cfif Left(sMessage["icon_emoji"],1) NEQ ":">
			<cfset sMessage["icon_emoji"] = ":" & sMessage["icon_emoji"]>
		</cfif>
		<cfif Right(sMessage["icon_emoji"],1) NEQ ":">
			<cfset sMessage["icon_emoji"] = sMessage["icon_emoji"] & ":">
		</cfif>

		<cfif NOT ( StructKeyExists(Arguments,"WebHookURL") AND Len(Trim(Arguments.WebHookURL)))>
			<cfset Arguments.WebHookURL = Variables.WebHookURL>
		</cfif>

		<cfhttp url="#Arguments.WebHookURL#" method="post">
			<cfhttpparam type="body" value="#SerializeJSON(sMessage)#">
		</cfhttp>
	</cfif>

</cffunction>

<cffunction name="getTimeEmoji" access="public" returntype="string" output="false" hint="">
	<cfargument name="time" type="date" default="#now()#">

	<cfreturn ":clock#getSlackTime()#:">
</cffunction>

<cffunction name="getSlackTime" access="private" returntype="string" output="false" hint="">
	<cfargument name="time" type="date" default="#now()#">

	<cfreturn ReReplaceNoCase(TimeFormat(roundTime(Time=Arguments.time,RoundingQuotient=30),'hmm'),'00$','')>
</cffunction>

<cffunction name="roundTime" access="private" returntype="string" output="false" hint="">
	<cfargument name="Time" type="date" required="true">
	<cfargument name="RoundingType" type="string" default="Nearest" hint="I determine whether to round up or to the nearest RoundingQuotient. Possible values are Nearest and Up.">
	<cfargument name="RoundingQuotient" type="numeric" default="15" hint="I determine the interval to which time is rounded (in minutes).">

	<cfset var Hours = 0>
	<cfset var Minutes = 0>
	<cfset var Remainder = 0>
	<cfset var RoundedTime = "">
	
	<cfset Hours = Hour(Arguments.Time)>
	<cfset Minutes = Minute(Arguments.Time)>
	<cfset Remainder = Minutes % Arguments.RoundingQuotient>
	<cfset Floor = Int(Minutes/Arguments.RoundingQuotient)>
	
	<cfif Arguments.RoundingType EQ "Nearest">
		<cfif Remainder/Arguments.RoundingQuotient LT 0.5>
			<cfset Minutes = Arguments.RoundingQuotient * Floor>
		<cfelse>
			<cfset Minutes = Arguments.RoundingQuotient * (Floor + 1)>
		</cfif>
	<cfelseif Arguments.RoundingType EQ "Up">
		<cfif Remainder GT 0 OR (Hours EQ 0 AND Remainder EQ 0 AND Minutes LT Arguments.RoundingQuotient)>
			<cfset Minutes = Arguments.RoundingQuotient * (Floor + 1)>
		</cfif>
	</cfif>
	
	<cfscript>
	//Now we have to carry the minutes column (so to speak) if Minutes = 60
	if ( Minutes EQ 60 ) {
		Minutes = 0;
		Hours = Hours + 1;
	}
	//In case we carry in to the next day
	while ( Hours GTE 24 ) {
		Arguments.Time = DateAdd("d",1,Arguments.Time);
		Hours = Hours - 24;
	}
	</cfscript>
	
	<!--- And finally, we'll return the rounded time as a date/time value. Seconds can be set to zero since we are rounding to the minute. --->
	<cfset RoundedTime = DateFormat(Arguments.Time,"yyyy-mm-dd") & " " & TimeFormat(CreateTime(Hours,Minutes,0))>
	
	<cfreturn RoundedTime>
</cffunction>

</cfcomponent>
