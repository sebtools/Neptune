<!---
2006-02-08: SEB: Fixed problem setting url.EzCalendarDate to invalid date if no date set.
2007-01-31: SEB: Fixed problem of passing out any URL vars that are on the page.
--->

<!--- Required paramenters --->

<!--- Optional paramenters --->
<cfparam name="attributes.width" default="700" type="numeric">
<cfparam name="attributes.defaultlink" default="" type="string">
<cfparam name="attributes.bgcolor" default="white" type="string">
<cfparam name="attributes.bordercolor" default="##DD9D9D9" type="string">
<cfparam name="attributes.borderwidth" default="2px" type="string">
<cfparam name="attributes.border" default="#attributes.borderwidth# solid ###attributes.borderwidth#" type="string">
<cfparam name="attributes.headerbgcolor" default="##A8D1FF" type="string">
<cfparam name="attributes.headerfontcolor" default="" type="string">
<cfparam name="attributes.celloffborder" default="1px solid ##D9D9D9" type="string">
<cfparam name="attributes.celloffcolor" default="" type="string">
<cfparam name="attributes.cellonborder" default="1px solid ##D9D9D9" type="string">
<cfparam name="attributes.celloncolor" default="##FFFFD7" type="string">
<cfparam name="attributes.UseEzStyles" default="true" type="boolean">
<cfparam name="attributes.Accessible" default="false" type="boolean">
<cfparam name="attributes.AllowListView" default="false" type="boolean">
<cfparam name="attributes.ShowFuture" default="false" type="boolean">
<cfparam name="attributes.linkcolor" default="Blue" type="string">
<cfparam name="attributes.linkhovercolor" default="Blue" type="string">
<cfparam name="attributes.linkfont" default="Tahoma" type="string">
<cfparam name="attributes.linkhoverfont" default="#attributes.linkfont#" type="string">
<cfparam name="attributes.linkfontsize" default="xx-small" type="string">
<cfparam name="attributes.linkhoverfontsize" default="#attributes.linkfontsize#" type="string">
<cfparam name="attributes.AllowEasyEventSelect" default="no" type="boolean">
<cfparam name="attributes.LimitDatesByEvents" default="yes" type="boolean">
<cfparam name="attributes.ShowPast" default="yes" type="boolean">

<cfset dDefaultDate = CreateDate(Year(now()),Month(now()),1)>

<!--- These variables are used by the calendar on round trips. --->
<cfparam name="attributes.View" default="Calendar" type="string">
<cfparam name="url.View" default="#attributes.View#" type="string">
<cfparam name="url.EzCalendarDate" type="string" default="">

<cfparam name="form.lstEZCalendarMonth" type="string" default="">
<cfparam name="form.lstEzCalendarYear" type="string" default="">

<!--- This is just set so that changing the name of the tag is easier. --->
<cfset ThisTagName = "EzCalendar">

<!--- Make sure closing tag is specifed.--->
<cfif thisTag.HasEndTag EQ "No">
  <!--- If not, abort the tag--->
  <cfabort showError="The CF_#ThisTagName# tag requires that a CF_#ThisTagName# end tag be specfied.">
</cfif>

<cfset cQuerystring = "">
<cfloop collection="#url#" item="cURLVar">
	<cfif NOT FindNoCase(cURLVar,cQuerystring) AND cURLVar NEQ "EzCalendarDate">
		<cfif cQuerystring EQ "">
			<cfset cQuerystring = "#LCase(cURLVar)#=#url[cURLVar]#">
		<cfelse>
			<cfset cQuerystring = "#cQuerystring#&#LCase(cURLVar)#=#url[cURLVar]#">
		</cfif>
	</cfif>
</cfloop>

<cfset thisPage = "#CGI.SCRIPT_NAME#?#cQuerystring#"><!--- Use this variable so that it can be manipulated prior to use --->

<!--- If url.EzCalendarDate is available, set date from it and strip it from subsequent self-links so it will continue to work. --->
<cfif (NOT isDefined("form.lstEzCalendarMonth") AND NOT isDefined("form.lstEzCalendarYear"))
	OR ((isDefined("form.lstEzCalendarMonth") AND NOT isNumeric(form.lstEzCalendarMonth))
		OR (isDefined("form.lstEzCalendarYear") AND NOT isNumeric(form.lstEzCalendarYear)))>
	<cfif isDefined("url.EzCalendarDate") and isDate(url.EzCalendarDate) AND (url.EzCalendarDate neq dDefaultDate)>

		<cfset form.lstEzCalendarMonth = Month(url.EzCalendarDate)>
		<cfset form.lstEzCalendarYear = Year(url.EzCalendarDate)>
	<cfelseif isNumeric("form.lstEzCalendarMonth") AND isNumeric("form.lstEzCalendarYear")>
		<cfset url.EzCalendarDate = "#form.lstEzCalendarMonth#-01-#form.lstEzCalendarYear#">
	<cfelse>
		<cfset url.EzCalendarDate = dDefaultDate>
		<cfset form.lstEzCalendarMonth = Month(url.EzCalendarDate)>
		<cfset form.lstEzCalendarYear = Year(url.EzCalendarDate)>
	</cfif>
</cfif>

<cfset thisPage = ReplaceNoCase(thisPage, "&EzCalendarDate=#DateFormat(url.EzCalendarDate,'yyyy-mm-dd')#", "")>

 <!--- Set calendar defaults if not already set. --->
<cfif IsDefined("form.lstEzCalendarMonth")>
	<cfset nSelectedMonth = form.lstEzCalendarMonth>
<cfelse>
	<cfset nSelectedMonth = month(now())>
</cfif>

<cfif IsDefined("form.lstEzCalendarYear")>
	<cfset nSelectedYear = form.lstEzCalendarYear>
<cfelse>
	<cfset nSelectedYear = year(now())>
</cfif>

<!--- The date of the month being shown (so that tag has a date-object to use for calculation) --->
<cfset dCalDate = CreateDate(nSelectedYear,nSelectedMonth,1)>
<!--- Do not allow past date. --->
<cfif NOT attributes.ShowPast>
	<cfset thisDate = "#month(now())#/01/#year(now())#"> 
	<cfif dateCompare(dCalDate,thisDate,"d") EQ -1>
		<cfset dCalDate = thisDate>
	</cfif>
</cfif>
<cfset caller.EzCalendar = StructNew()>
<cfset caller.EzCalendar.StartDate = DateFormat(dCalDate,"MM/DD/YYYY")>
<cfset caller.EzCalendar.EndDate = "#Month(dCalDate)#/#DaysInMonth(dCalDate)#/#Year(dCalDate)#">

<cfif ThisTag.ExecutionMode EQ "End">

<cfif attributes.UseEzStyles><!--- include default CSS if "UseEzStyles" is true --->
<!--- Add styles to header --->
<cfsavecontent variable="cEzCalendarStyles">
<cfoutput>
<style type="text/css">
.EzCalendar {
	background-color:#attributes.bgcolor#;
	width: #attributes.width#px;
	border: #attributes.border#;
}
.EzCalendar_Month {
	font-size: 22px;
	line-height: 22px;
}
.EzCalendar_Year {
	font-size: 22px;
	line-height: 22px;
	text-align: right;
}
.EzCalendar_Date_Selector_Row {
	text-align: center; 
	font-size: 20px;
}
a.EzCalendar_Month_Changer_Arrows, a.EzCalendar_Month_Changer_Arrows:hover {
	text-decoration:none;
}
.EzCalendar_Header_Day_Row {
	text-align: center;
	font-weight: 900;
	height: 20px;
}<cfif Len(attributes.headerfontcolor)>
.EzCalendar_Header_Day_Row td {
	color: #attributes.headerfontcolor#
}
</cfif>
.EzCalendar_Header_Day {
	width: 100px; 
	background-color: #attributes.headerbgcolor#;
}
td.EzCalendar_Day {
	border: #attributes.celloffborder#;
	background-color: #attributes.celloffcolor#;
	vertical-align: top; 
	height: 90px; 
	width: 100px;
}
.EzCalDayLabel {
	font-size: 10px;
}
td.EzCalendar_Day_Hover, td.EzCalendar_Day:hover {
	border: #attributes.cellonborder#; 
	background-color: #attributes.celloncolor#;
	vertical-align: top; 
	height: 90px; 
	width: 100px;
}
div.EzCalendarItemContent a {font-family: #attributes.linkfont#; font-size: #attributes.linkfontsize#; color: #attributes.linkcolor#;}
div.EzCalendarItemContent a:hover {font-family: #attributes.linkfont#; font-size: #attributes.linkhoverfontsize#; color: #attributes.linkhovercolor#;}


.EzCalendarLink:Link {font-family: #attributes.linkfont#; font-size: #attributes.linkfontsize#; color: #attributes.linkcolor#;}
.EzCalendarLink:Visited {font-family: #attributes.linkfont#; font-size: #attributes.linkfontsize#; color: #attributes.linkcolor#;}
.EzCalendarLink:Active {font-family: #attributes.linkfont#; font-size: #attributes.linkfontsize#; color: #attributes.linkcolor#;}
A.EzCalendarLink:Hover {font-family: #attributes.linkfont#; font-size: #attributes.linkhoverfontsize#; color: #attributes.linkhovercolor#;}

</style>
</cfoutput>
</cfsavecontent>
<cfhtmlhead text="#cEzCalendarStyles#">
</cfif>

<!--- Find all the EzCalendarItems for this month and year. --->
<cfif IsDefined("ThisTag.EzCalendarItems")>
	<cfset aEzCalendarItems = ArrayNew(1)>
	<cfloop from="1" to="#ArrayLen(ThisTag.EzCalendarItems)#" index="EzCalendarItem">
		<cfif Year(ThisTag.EzCalendarItems[EzCalendarItem].date) EQ nSelectedYear 
			AND Month(ThisTag.EzCalendarItems[EzCalendarItem].date) EQ nSelectedMonth>
			<cfset ArrayAppend(aEzCalendarItems,ThisTag.EzCalendarItems[EzCalendarItem])>
		</cfif>
	</cfloop>
</cfif>

<!---Find the start day  the month--->
<cfset nFirstDayOfMonth = DayOfWeek(CreateDate(nSelectedYear,nSelectedMonth,1))>
<!---Find the total no of days in the month--->
<cfset nTotalDaysInMonth = DaysInMonth(CreateDate(nSelectedYear,nSelectedMonth,1))>

<!--- Create list of years --->
<cfset cYears = "">
<cfset nStartYear = Year(Now()) - 5>
<cfset nEndYear = Year(Now()) + 5>
<cfloop from="#nStartYear#" to="#nEndYear#" index="nYear">
	<cfset cYears = ListAppend(cYears,nYear)>
</cfloop>

<cfif attributes.defaultlink NEQ "">
	<cfif FindNoCase("?",attributes.defaultlink)>
		<cfset attributes.defaultlink = attributes.defaultlink & "&amp;">
	<cfelse>
		<cfset attributes.defaultlink = attributes.defaultlink & "?">
	</cfif>
</cfif>

<cfset MinDate = DateAdd("yyyy",-5,now())>
<cfset MaxDate = DateAdd("yyyy",5,now())>

<!--- <cfif now() lt dCalDate>
	<cfset bHavePreLink = true>
<cfelse>
	<cfset bHavePreLink = false>
</cfif>
<cfif now() gte DateAdd("m",1,dCalDate)>
	<cfset bHaveNextLink = true>
<cfelse>
	<cfset bHaveNextLink = false>
</cfif> --->
<cfset MinDateDefault = DateAdd("yyyy",-5,now())>
<cfset MaxDateDefault = DateAdd("yyyy",5,now())>

<cfif IsDefined("ThisTag.EzCalendarItems") AND attributes.LimitDatesByEvents>
	<cfset MinDate = now()>
	<cfset MaxDate = now()>

	<cfloop from="1" to="#ArrayLen(ThisTag.EzCalendarItems)#" index="EzCalendarItem">
		<cfif ThisTag.EzCalendarItems[EzCalendarItem].date lt MinDate>
			<cfset MinDate = ThisTag.EzCalendarItems[EzCalendarItem].date>
		</cfif>
		<cfif ThisTag.EzCalendarItems[EzCalendarItem].date gt MaxDate>
			<cfset MaxDate = ThisTag.EzCalendarItems[EzCalendarItem].date>
		</cfif>
	</cfloop>
<cfelse>
	<cfset MinDate = MinDateDefault>
	<cfset MaxDate = MaxDateDefault>
</cfif>

<cfif NOT attributes.ShowPast>
	<cfset MinDate = now()>
</cfif>

<cfif attributes.ShowFuture>
	<cfset MaxDate = MaxDateDefault>
</cfif>

<cfset MinDate = CreateDate(Year(MinDate),Month(MinDate),1)>
<cfset MaxDate = CreateDate(Year(MaxDate),Month(MaxDate),1)>

<cfif dCalDate lte MinDate>
	<cfset bHavePreLink = false>
<cfelse>
	<cfset bHavePreLink = true>
</cfif>
<cfif dCalDate gte MaxDate>
	<cfset bHaveNextLink = false>
<cfelse>
	<cfset bHaveNextLink = true>
</cfif>

<cfoutput>

<cfset cCurrentTemplate = getFileFromPath(CGI.SCRIPT_NAME)>
<cfif FindNoCase("?",cCurrentTemplate)>
	<cfset cCurrentTemplate = "#cCurrentTemplate#&">
<cfelse>
	<cfset cCurrentTemplate = "#cCurrentTemplate#?">
</cfif>
<!---
dCalDate: #dCalDate#
MinDateDefault: #MinDateDefault#
MaxDateDefault: #MaxDateDefault#
MinDate: #MinDate#
MaxDate: #MaxDate#
bHavePreLink: #bHavePreLink#
bHaveNextLink: #bHaveNextLink#
--->
<form id="EzCalendar" method="post" action="#thisPage#">
<table class="EzCalendar">
	<cfif attributes.AllowListView>
		<tr>
			<td colspan="3" align="center">
				<cfif url.view EQ "Calendar">
					<a href="#cCurrentTemplate#view=List&EzCalendarDate=#url.EzCalendarDate#">List View</a>
				<cfelse>
					<a href="#cCurrentTemplate#view=Calendar&EzCalendarDate=#url.EzCalendarDate#">Calendar View</a>
				</cfif>
			</td>
		</tr>
	</cfif>
	<tr>
		<td class="EzCalendar_Month">#MonthAsString(nSelectedMonth)#</td>
		<td style="width: 100%;">&nbsp;</td>
		<td class="EzCalendar_Year">#nSelectedYear#</td>
	</tr>
	<tr>
		<td colspan="3" class="EzCalendar_Date_Selector_Row">
			<cfif bHavePreLink>
				<a href="#thisPage#&amp;EzCalendarDate=#DateFormat(DateAdd('m',-1,dCalDate),'yyyy-mm-dd')#" class="EzCalendar_Month_Changer_Arrows" title="Previous Month">&laquo;</a>
			</cfif>
			<cfif Year(MinDate) eq Year(MaxDate)>
			<select id="lstEzCalendarMonth" name="lstEzCalendarMonth" size="1"><cfloop index="i" from="#Month(MinDate)#" to="#Month(MaxDate)#" step="1">
				<option value="#i#" <cfif nSelectedMonth EQ i>selected</cfif>>#MonthAsString(i)#</option></cfloop>
			</select>
			<input type="hidden" name="lstEzCalendarYear" value="#Year(MinDate)#"/>
			<cfelse>
			<select id="lstEzCalendarMonth" name="lstEzCalendarMonth" size="1"><cfloop index="i" from="1" to="12" step="1">
				<option value="#i#" <cfif nSelectedMonth EQ i>selected</cfif>>#MonthAsString(i)#</option></cfloop>
			</select>
			<select id="lstEzCalendarYear" name="lstEzCalendarYear" size="1"><cfloop index="cYear" from="#Year(MinDate)#" to="#Year(MaxDate)#" step="1">
				<option value="#cYear#" <cfif nSelectedYear EQ cYear>selected</cfif>>#cYear#</option></cfloop>
			</select>
			</cfif>
			<!--- <select id="lstEzCalendarYear" name="lstEzCalendarYear" size="1"><cfloop list="#cYears#" index="cYear">
				<option value="#cYear#" <cfif nSelectedYear EQ cYear>selected</cfif>>#cYear#</option></cfloop>
			</select> --->
			<cfif attributes.Accessible><input type="submit" value="Go"/></cfif><!--- Go button only appears in accessible mode --->
			<cfif bHaveNextLink>
				<a href="#thisPage#&amp;EzCalendarDate=#DateFormat(DateAdd('m',+1,dCalDate),'yyyy-mm-dd')#" class="EzCalendar_Month_Changer_Arrows" title="Next Month">&raquo;</a>
			</cfif>
		</td>
	</tr>
	<tr>
		<td colspan="3">&nbsp;</td>
	</tr>
	<tr>
		<td colspan="3">
			<cfif attributes.View EQ "List">
				<table id="EzCalendar_List">
					<cfif NOT isDefined("aEzCalendarItems")>
						<tr>
							<td>No events for this month</td>
						</tr>
					<cfelse>
						<cfloop from="1" to="#ArrayLen(aEzCalendarItems)#" index="EzCalendarItem">
							<cfswitch expression="#Right(Day(aEzCalendarItems[EzCalendarItem].date),1)#">
								<cfcase value="1">
									<cfset cDayEnding = "st">
								</cfcase>
								<cfcase value="2">
									<cfset cDayEnding = "nd">
								</cfcase>
								<cfcase value="3">
									<cfset cDayEnding = "rd">
								</cfcase>
								<cfdefaultcase>
									<cfset cDayEnding = "th">
								</cfdefaultcase>
							</cfswitch>
							<tr>
								<td>							
									<cfif Len(aEzCalendarItems[EzCalendarItem].link)>
										<a class="EzCalendar" href="#aEzCalendarItems[EzCalendarItem].link#">#DayOfWeekAsString(DayOfWeek(aEzCalendarItems[EzCalendarItem].date))# - #Day(aEzCalendarItems[EzCalendarItem].date)##cDayEnding# - #aEzCalendarItems[EzCalendarItem].body#</a><br/><br/>
									<cfelse>
										#DayOfWeekAsString(DayOfWeek(aEzCalendarItems[EzCalendarItem].date))# - #Day(aEzCalendarItems[EzCalendarItem].date)##cDayEnding# - #aEzCalendarItems[EzCalendarItem].body#<br/><br/>
									</cfif>
								</td>
							</tr>
						</cfloop>
					</cfif>
				</table>
			<cfelse>
				<table id="EzCalendar_Calendar">
					<tr class="EzCalendar_Header_Day_Row">
						<td class="EzCalendar_Header_Day">Sun</td>
						<td class="EzCalendar_Header_Day">Mon</td>
						<td class="EzCalendar_Header_Day">Tues</td>
						<td class="EzCalendar_Header_Day">Wed</td>
						<td class="EzCalendar_Header_Day">Thurs</td>
						<td class="EzCalendar_Header_Day">Fri</td>
						<td class="EzCalendar_Header_Day">Sat</td>
					</tr>
					<!--- Set counter. --->
					<cfset nRunningDays = 1>
					<cfset nDayNum = 1>

					<!--- 
						Generic "hack" to fix logic below. 
						Causing problem with months starting on the 7th day of the week 
						Several sites using this code, didn't want to rework my logic too much :p
					--->
					<cfif nFirstDayOfMonth GT 0>
						<cfset nStop = nTotalDaysInMonth + 1>
					<cfelse>
						<cfset nStop = nTotalDaysInMonth>
					</cfif>

					<cfloop condition="#nRunningDays# LTE #nStop#">
						<tr>
							<!--- Loop through week. --->
							<cfset nWeekEndDay = nRunningDays + 6>
							<cfloop from="#nRunningDays#" to="#nWeekEndDay#" index="nDay">
								<cfif nDay GTE nFirstDayOfMonth AND nDayNum LTE nTotalDaysInMonth>
									<td class="EzCalendar_Day" id="EzCaldaycell-#nDayNum#">
										<cfif attributes.Accessible AND Len(attributes.defaultlink) gt 1>
											<a href="#attributes.defaultlink#date=#Year(dCalDate)#-#Month(dCalDate)#-#nDayNum#" class="EzCalDayLabel">#nDayNum#</a>
										<cfelse>
											<span class="EzCalDayLabel">#nDayNum#</span>
										</cfif>

										<div class="EzCalendarItemContent">
										<cfif IsDefined("aEzCalendarItems")>
											<cfloop from="1" to="#ArrayLen(aEzCalendarItems)#" index="EzCalendarItem">
												<cfif Day(aEzCalendarItems[EzCalendarItem].date) EQ nDayNum>
													<cfif Len(aEzCalendarItems[EzCalendarItem].link)>
														<a href="#aEzCalendarItems[EzCalendarItem].link#" class="EzCalendarLink">#aEzCalendarItems[EzCalendarItem].body#</a><br/><br/>
													<cfelse>
														#aEzCalendarItems[EzCalendarItem].body#<br/><br/>
													</cfif>
												</cfif>
											</cfloop>
										</cfif>
										</div>
									</td>
									<cfset nDayNum = nDayNum + 1>
								<cfelse>
									<td></td>
								</cfif>
							</cfloop>

							<!--- Increment days. --->
							<cfset nRunningDays = nRunningDays + 6>
						</tr>
					</cfloop>
				</table>
			</cfif>
		</td>
	</tr>
</table>
</form>
<!--- <cfif NOT attributes.Accessible> --->
<script type="text/javascript">
function submit_ezcalendar_form() {
	document.getElementById('EzCalendar').submit();
}
function ezCalEvents() {
	var i = 0;
	var ezCalendarCal;
	var ezCalendarCalCells;
	if ( document.getElementById ) {
		ezCalendarCal = document.getElementById('EzCalendar_Calendar');
		ezCalendarCalCells = ezCalendarCal.getElementsByTagName('td');
		//Assign mouseover for class to each day cell (has class 'EzCalendar_Day')
		for (i=1; i < ezCalendarCalCells.length; i++) {
			if (ezCalendarCalCells[i].className == 'EzCalendar_Day') {
				ezCalendarCalCells[i].onmouseover = function() {this.className='EzCalendar_Day_Hover'};
				ezCalendarCalCells[i].onmouseout = function() {this.className='EzCalendar_Day'};
				<cfif Len(attributes.defaultlink) gt 1>//assign click to default page for cell
					ezCalendarCalCells[i].onclick = function() {window.location='#attributes.defaultlink#date=#Year(dCalDate)#-#Month(dCalDate)#-' + this.id.replace('EzCaldaycell-','')};
				<cfelse>
					<cfif attributes.AllowEasyEventSelect>
					if (ezCalendarCalCells[i].getElementsByTagName('a').length == 1) {
						ezCalendarCalCells[i].onclick = function() {window.location=this.getElementsByTagName('a')[0].href};
					}
					</cfif>
				</cfif>
			}
		}
		<cfif NOT attributes.Accessible><!--- Only user onchange events if calendar is not accessible --->
		document.getElementById('lstEzCalendarMonth').onchange = function() {submit_ezcalendar_form()};
		document.getElementById('lstEzCalendarYear').onchange = function() {submit_ezcalendar_form()};
		</cfif>
	}
}
ezCalEvents();
</script>
<!--- </cfif> --->
</cfoutput>
</cfif>