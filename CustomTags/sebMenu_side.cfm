<cfoutput>
<cfif isDefined("ThisTag.ExecutionMode") AND ThisTag.ExecutionMode EQ "End">
<div id="sebMenu" style="width:#attributes.width#px;">
<table cellpadding="0" cellspacing="0" border="0" id="sebMenuTable">
<tr>
	<td id="sebTab">
		<ul id="sebMenuSideNav">
		<cfloop index="i" from="1" to="#ArrayLen(ThisTag.tabs)#" step="1">
			<li>
				<a href="#ThisTag.tabs[i].LinkURL#"<cfif CurrTab eq i> class="active"</cfif>>#ThisTag.tabs[i].Label#</a>
				<cfif CurrTab eq i><cfset ItemScope = ThisTag.tabs[i]>
				<ul><cfloop index="j" from="1" to="#ArrayLen(ItemScope.items)#" step="1">
					<li><a href="#ItemScope.items[j].Link#"<cfif ListLast(ListFirst(ItemScope.items[j].Link,"?"),"/") EQ ListLast(CGI.SCRIPT_NAME,"/")> class="active"</cfif>>#ItemScope.items[j].Label#</a></li></cfloop>
				</ul>
				</cfif>
			</li>
		</cfloop>
		</ul>
	</td>
	<td id="sebMenuBody">
</cfif>
<cfif isDefined("ThisTag.ExecutionMode") AND ThisTag.ExecutionMode EQ "Start" AND ListFindNoCase("end,EndPage", attributes.action)>
	</td>
</tr>
</table>
</div>
</cfif>
</cfoutput>