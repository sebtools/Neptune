<cfif ThisTag.ExecutionMode NEQ "Start"><cfexit method="exittag"></cfif>
<!--- Required paramenters --->
<cfparam name="attributes.date" type="date">

<!--- Optional paramenters --->
<cfparam name="attributes.link" type="string" default="">
<cfparam name="attributes.body" type="string" default="">

<!--- This is just set so that changing the name of the tag is easier. --->
<cfset ThisTagName = "EzCalendarItem">

<!--- Add item to EzCalendar data. --->
<cfif ListFindNoCase(GetBaseTagList(), "CF_EzCalendar")>
	<cfassociate basetag="CF_EzCalendar" datacollection="EzCalendarItems">
<cfelse>
	<cfabort showError="The CF_#ThisTagName# MUST be nested within a CF_EzCalendar tag">
</cfif>

<!--- Make sure closing tag is specifed.--->
<!--- <cfif thisTag.HasEndTag EQ "No">
  <!--- If not, abort the tag--->
  <cfabort showError="The CF_#ThisTagName# tag requires that a CF_#ThisTagName# end tag be specfied.">
</cfif>
 --->