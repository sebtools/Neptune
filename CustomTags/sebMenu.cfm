<!---
1.0 RC9 (Build 121)
Last Updated: 2011-10-11
Created by Steve Bryant 2004-06-01
Information: http://www.bryantwebconsulting.com/docs/sebtags/?version=1.0
Documentation:
http://www.bryantwebconsulting.com/docs/sebtags/sebmenu-basics.cfm?version=1.0
Tim Jackson provided the original tags as well as the inpiration and brilliant implementation of consistency for admin sections.
---><cfsilent><cfif isDefined("ThisTag.ExecutionMode") AND ThisTag.ExecutionMode EQ "Start">
<cfscript>
TagName = "cf_sebMenu";
//Default attributes from request.cftags.sebtags structure
if ( StructKeyExists(request, "cftags") AND StructKeyExists(request.cftags, "sebtags") ) {
	StructAppend(attributes, request.cftags["sebtags"], "no");
}
//Default attributes from request.cftags.cf_sebMenu (overrides sebtags defaults)
if ( StructKeyExists(request, "cftags") AND StructKeyExists(request.cftags, TagName) ) {
	StructAppend(attributes, request.cftags[TagName], "no");
}

</cfscript>
<cfparam name="attributes.action" default="StartPage"><!--- options: StartPage,EndPage --->
<cfparam name="attributes.menutype" default=""><!--- options: bar,drop-down,roundtab,squaretab --->
<cfparam name="attributes.width" default="770" type="string">
<cfparam name="attributes.Label" default="Admin Menu:">
<cfparam name="attributes.HasLeftPanel" default="true" type="boolean">
<cfparam name="attributes.LeftLabelWidth" default="135" type="numeric">
<cfparam name="attributes.MainLink" default="">
<cfparam name="attributes.skin" default="">
<cfparam name="attributes.librarypath" default="/lib/">
<cfparam name="attributes.skinpath" default="#attributes.librarypath#skins/">
<cfparam name="attributes.adminpath" default="/admin/">
<cfparam name="attributes.imagepath" default="#attributes.librarypath#">
<cfparam name="attributes.submenubackground" default="##EFEFEF">
<cfparam name="attributes.useQueryString" default="false">

<cfparam name="attributes.MainLinkLabel" default="">
<cfparam name="attributes.LogoutLink" default="/logout.cfm">

<cfparam name="attributes.align" default=""><!--- not required --->
<cfparam name="attributes.TextRight" default="">
<cfparam name="attributes.useSessionMessages" default="false">

<cfparam name="url.sebTab" default=""><!--- indicator of chosen tab --->

<cfinclude template="sebUdf.cfm"><cfinclude template="sebtools.cfm">
<cfset isCustomType = (
							Len(Trim(attributes.menutype))
						AND	( StructKeyExists(sebtools.skins,attributes.skin) AND NOT StructKeyExists(sebtools.skins[attributes.skin],attributes.menutype) )
						AND	FileExists("#getDirectoryFromPath(getCurrentTemplatePath())#sebMenu_#attributes.menutype#.cfm")
)>

</cfif></cfsilent>
<cfif isDefined("ThisTag.ExecutionMode") AND ThisTag.ExecutionMode EQ "End"><cfsilent>
<cfscript>
if ( NOT ( isDefined("ThisTag.items") AND isArray(ThisTag.items) AND ArrayLen(ThisTag.items) ) ) {
	ThisTag.items = ArrayNew(1);
}
if ( isDefined("attributes.data") AND isArray(attributes.data) ) {
	for ( ii=1; ii LTE ArrayLen(attributes.data); ii=ii+1 ) {
		ArrayAppend(ThisTag.items,attributes.data[ii]);
	}
}
//Use skins attribute for skins definitions
if ( StructKeyExists(attributes,"skins") AND isStruct(attributes.skins) ) {
	StructAppend(sebtools.skins,attributes.skins,true);
}
//Set menu-type based on skins/browser/defaults
if (attributes.menutype eq "drop-down") {
	isSFBrowser = false;
	sfBrowsers = "Gecko,MSIE 5.5,MSIE 6,Opera 7";
	for (sf=1; sf lt ListLen(sfBrowsers); sf=sf+1) {
		if ( CGI.USER_AGENT CONTAINS ListGetAt(sfBrowsers,sf) ) {
			isSFBrowser = true;
		}
	}
	if ( Not isSFBrowser ) {
		attributes.menutype = "bar";
	}
}
if ( NOT Len(attributes.menutype) ) {
	if ( StructKeyExists(sebtools.skins, attributes.skin) AND StructKeyExists(sebtools.skins[attributes.skin],"menutype") ) {
		attributes.menutype = sebtools.skins[attributes.skin].menutype;
	} else {
		attributes.menutype = "round";
	}
}

//Get the current file
CurrPage = CGI.SCRIPT_NAME;
if ( attributes.useQueryString AND Len(CGI.QUERY_STRING) ) {
	CurrPage = CurrPage & '?' & CGI.QUERY_STRING;//dre 2006-11-09 in case menu points to a file with a ?.... string
}
CurrFile = ListLast(CurrPage,"/");
CurrPath = ReplaceNoCase(CurrPage,CurrFile,"");
CurrTab = 0;

//Just a simple rename of items to tabs for readability
ThisTag.tabs = ThisTag.items;
//Adjust links, set currTab from url var
for (i=1; i lte ArrayLen(ThisTag.tabs); i=i+1) {
	if ( Len(url.sebTab) ) {
		if ( url.sebTab eq ThisTag.tabs[i].Label ) {
			CurrTab = i;
		}
	} else {
		if ( ThisTag.tabs[i].Link eq CurrPage ) {
			CurrTab = i;
		}
	}
	//Make sure can have query_string var appended directly to it
	if ( ThisTag.tabs[i].Link CONTAINS "?" ) {
		ThisTag.tabs[i].LinkURL = ThisTag.tabs[i].Link & "&amp;";
	} else {
		ThisTag.tabs[i].LinkURL = ThisTag.tabs[i].Link & "?";
	}
	//Add sebTab to link URL
	ThisTag.tabs[i].LinkURL = ThisTag.tabs[i].LinkURL & "sebTab=#URLEncodedFormat(ThisTag.tabs[i].Label)#";
}

//If we don't know currTab yet, check by children/pages
if ( NOT CurrTab ) {
	//  Look in each tab
	for (i=1; i lte ArrayLen(ThisTag.tabs); i=i+1) {
		if ( StructKeyExists(ThisTag.tabs[i],"pages") AND Len(ThisTag.tabs[i].pages) ) {
			//Look for page in pages list
			if ( ListFindNoCase(ThisTag.tabs[i].pages, CurrPage) ) {
				CurrTab = i;
				break;
			}
		}
		//Look for page in sub-items
		if ( StructKeyExists(ThisTag.tabs[i],"items") AND ArrayLen(ThisTag.tabs[i].items) ) {
			//  Look in each sub-item
			for ( j=1; j lte ArrayLen(ThisTag.tabs[i].items); j=j+1 ) {
				if ( CurrPage eq ThisTag.tabs[i].items[j].Link ) {
					CurrTab = i;
					break;
				}
				if ( StructKeyExists(ThisTag.tabs[i].items[j],"pages") AND Len(ThisTag.tabs[i].items[j].pages) ) {
					if ( ListFindNoCase(ThisTag.tabs[i].items[j].pages, CurrPage) ) {
						CurrTab = i;
						break;
					}
				}
			}
			// /Look in each sub-item
		}
		
		if ( CurrTab ) {
			break;
		}
	}
	// /Look in each tab
}

//If we *still* don't know what tab to use, check by directory
if ( NOT CurrTab ) {
	tCurrPath = CurrPath;
	//  March down current folder
	while ( ListLen(tCurrPath) ) {
		//  Look in each tab
		for (i=1; i lte ArrayLen(ThisTag.tabs); i=i+1) {
			if ( tCurrPath eq ThisTag.tabs[i].folder ) {
				CurrTab = i;
				break;
			}
			
			
			if ( NOT CurrTab ) {
				for ( j=1; j lte ArrayLen(ThisTag.tabs[i].items); j=j+1 ) {
					if ( tCurrPath eq ThisTag.tabs[i].items[j].folder ) {
						CurrTab = i;
						break;
					}
				}
			}
			
			if ( CurrTab ) {
				break;
			}
			
		}
		// /Look in each tab
		
		if ( CurrTab ) {
			break;
		} else {
			if ( ListLen(tCurrPath,"/") ) {
				tCurrPath = ListDeleteAt(tCurrPath,ListLen(tCurrPath,"/"),"/");
				if ( Len(tCurrPath) AND Right(tCurrPath,1) neq "/" ) {
					tCurrPath = "#tCurrPath#/";
				}
			} else {
				break;
			}
		}
		
	}
	// /March down current folder
}
/*
if ( NOT CurrTab ) {
	for ( j=ListLen(CurrPath,"/"); j gte 1; j=j-1 ) {
		for (i=1; i lte ArrayLen(ThisTag.tabs); i=i+1) {
			if ( Len(ThisTag.tabs[i].folder) ) {
				if ( tCurrPath eq ThisTag.tabs[i].folder ) {
					CurrTab = i;
				}
			}
		}
		if ( CurrTab ) {
			break;
		} else {
			if ( ListLen(tCurrPath,"/") ) {
				tCurrPath = ListDeleteAt(tCurrPath,ListLen(tCurrPath,"/"),"/");
				if ( Right(tCurrPath,1) neq "/" ) {
					tCurrPath = "#tCurrPath#/";
				}
			} else {
				break;
			}
		}
		
		if ( NOT CurrTab ) {
			//Look for page in sub-items
			if ( StructKeyExists(ThisTag.tabs[i],"items") AND ArrayLen(ThisTag.tabs[i].items) ) {
				//  Look in each sub-item
				for ( j=1; j lte ArrayLen(ThisTag.tabs[i].items); j=j+1 ) {
					if ( CurrPage eq ThisTag.tabs[i].items[j].Link ) {
						CurrTab = i;
						break;
					}
					if ( Len(ThisTag.tabs[i].items[j].pages) ) {
						if ( ListFindNoCase(ThisTag.tabs[i].items[j].pages, CurrPage) ) {
							CurrTab = i;
							break;
						}
					}
				}
				// /Look in each sub-item
			}
		}
		
	}
}
*/
//Set widths based on menu type
if ( attributes.menutype eq "squaretab" ) {
	LeftSideWidth = attributes.LeftLabelWidth;
} else {
	LeftSideWidth = attributes.LeftLabelWidth;// + 9
}
//LeftHRWidth = LeftSideWidth - 5;
//RightSideWidth = attributes.Width - LeftSideWidth - 16;

//Base ItemScope (for site menu items) on whether currTab is indicated
if ( CurrTab ) {
	ItemScope = ThisTag.tabs[CurrTab];
} else {
	ItemScope = ThisTag;
}
</cfscript>

</cfsilent><!--- START OUTPUT ---><cfoutput>
<!-- CurrTab:#CurrTab# -->
<cfif Len(attributes.skin)><cfsavecontent variable="styletag"><style type="text/css">@import url(#attributes.skinpath##attributes.skin#.css);</style></cfsavecontent><cfhtmlhead text="#styletag#"></cfif>
<cfsavecontent variable="styletag"><style type="text/css">##sebMenuMain {width:#attributes.width#px;border:1px solid ##BDBDBD;}</style></cfsavecontent><cfhtmlhead text="#styletag#">

<div<cfif Len(Trim(attributes.skin))> class="sebMenu-skin-#LCase(attributes.skin)#"</cfif>>
<div class="sebMenu-type-#attributes.menutype#">
<cfswitch expression="#attributes.menutype#">
<cfcase value="drop-down">
	<cfsavecontent variable="head1"><script language="JavaScript" src="#attributes.librarypath#nav.js" type="text/javascript"></script><style type="text/css">@import url(#attributes.librarypath#nav.css);</style></cfsavecontent><cfhtmlhead text="#head1#">
	<!--- Drop-Down --->
	<div id="sebTab">
		<div id="nav" style="width:#attributes.width#px;" class="sfMenu">
			<ul><cfloop index="i" from="1" to="#ArrayLen(ThisTag.tabs)#" step="1"><li><a href="#ThisTag.tabs[i].LinkURL#"<cfif CurrTab eq i> class="CurrTab"</cfif>>#ThisTag.tabs[i].Label#</a><cfif StructKeyExists(ThisTag.tabs[i], "items")><ul><cfloop index="j" from="1" to="#ArrayLen(ThisTag.tabs[i].items)#" step="1"><li><a href="#ThisTag.tabs[i].items[j].Link#">#ThisTag.tabs[i].items[j].Label#</a></cfloop></ul></cfif></li></cfloop></ul>
		</div>
		<br/>
	</div>
</cfcase>
<cfcase value="list">
<div id="sebMenu" style="width:#attributes.width#px;">
<table width="#attributes.width#"<cfif Len(attributes.align)> align="#attributes.align#"</cfif> border="0" cellspacing="0" cellpadding="0" id="sebTab">
<tr>
	<td>
		<ul><cfloop index="i" from="1" to="#ArrayLen(ThisTag.tabs)#" step="1">
			<li<cfif CurrTab eq i> class="CurrTab"</cfif>><a href="#ThisTag.tabs[i].LinkURL#">#ThisTag.tabs[i].Label#</a></li></cfloop>
		</ul>
	</td>
</tr>
<tr>
	<td valign="top" id="sebMenuBody">
</cfcase>
<cfdefaultcase><!--  -->
<cfif isCustomType>
	<cfinclude template="sebMenu_#attributes.menutype#.cfm">
<cfelse>
<div id="sebMenu" style="width:#attributes.width#px;">
<div id="sebMenu-topbar" align="left">
<table<!---  width="#attributes.width#" ---><cfif Len(attributes.align)> align="#attributes.align#"</cfif> border="0" cellspacing="0" cellpadding="0" id="sebTab">
<tr><cfif attributes.HasLeftPanel>
	<cfif attributes.menutype eq "roundtab"><td width="9"><img src="#attributes.imagepath#tab_round_topleft.gif" width="9" height="22" border="0" alt=""/></td><cfset LeftTabWidth = attributes.LeftLabelWidth - 26>
	<cfelse><cfset LeftTabWidth = attributes.LeftLabelWidth></cfif><td id="sebTabMenuTop" align="center" class="tab" nowrap="nowrap" width="#LeftTabWidth#"><b id="sebMenuLabel">#attributes.Label#</b></td></cfif><cfloop index="i" from="1" to="#ArrayLen(ThisTag.tabs)#" step="1"><cfif ThisTag.tabs[i].inTabs><cfif attributes.menutype eq "squaretab">
	<td width="1" style="width:1px;background-color:white;"><div style="width:2px;"></div></td><cfelseif attributes.menutype eq "roundtab">
	<td width="17"><img src="#attributes.imagepath#tab_round_separator.gif" width="17" height="22" border="0" alt=""/></td></cfif>
	<td nowrap="nowrap" class="tab<cfif CurrTab eq i> curr</cfif>"><a href="#ThisTag.tabs[i].LinkURL#"<cfif CurrTab eq i> class="CurrTab"</cfif>>#ThisTag.tabs[i].Label#</a></td></cfif></cfloop><cfif attributes.menutype eq "roundtab">
	<td width="9"><img src="#attributes.imagepath#tab_round_topright.gif" width="9" height="22" border="0" alt=""/></td></cfif>
	<td<!---  width="100%" ---> class="clear" align="right">#attributes.TextRight#&nbsp;</td>
</tr>
</table>
</div>
<table width="#attributes.width#" border="0" cellspacing="0" cellpadding="0" id="sebMenuMain">
<tr><cfif attributes.HasLeftPanel>
	<td width="#LeftSideWidth#"<cfif Len(attributes.submenubackground)> bgcolor="#attributes.submenubackground#"</cfif> id="sebTabMenu" valign="top"><cfif Len(attributes.MainLink)>
		<ul><li><a href="#attributes.MainLink#" id="sebMenuMainLink"><cfif Len(attributes.MainLinkLabel)>#attributes.MainLinkLabel#<cfelse>Home</cfif></a></li></ul></cfif><cfif StructKeyExists(ItemScope, "items") AND ArrayLen(ItemScope.items)>
	<hr size="1"/>
	<ul><cfloop index="j" from="1" to="#ArrayLen(ItemScope.items)#" step="1">
		<li><a href="#ItemScope.items[j].Link#">#ItemScope.items[j].Label#</a></li></cfloop>
	</ul>
	<hr size="1" /><cfelse>
	<br/></cfif>
	<ul>
		<cfif ArrayLen(ThisTag.tabs) NEQ 1><li><a href="#attributes.adminpath#">Admin Home</a></li></cfif>
		<li><a href="/" target="_blank">View Site</a></li><cfif Len(attributes.LogoutLink)>
		<li><a href="#attributes.LogoutLink#" id="sebMenuLogoutLink">Logout</a></li></cfif>
	</ul>
	<div><img src="#attributes.librarypath#i.gif" height="1" width="#LeftSideWidth#" alt=""></div>
	</td></cfif>
	<td width="100%" valign="top" id="sebMenuBody" style="padding:8px;">
</cfif>
</cfdefaultcase>
</cfswitch>
<cfif attributes.useSessionMessages>#showSessionMessage()#</cfif>
<!--- ***** --->
</cfoutput><cfset ThisTag.GeneratedContent = "">
</cfif>
<cfif isDefined("ThisTag.ExecutionMode") AND ThisTag.ExecutionMode eq "Start" AND ListFindNoCase("end,EndPage", attributes.action)>
<cfif isCustomType>
	<cfinclude template="sebMenu_#attributes.menutype#.cfm">
<cfelse>
	</td>
</tr>
</table>
</cfif>
</div>
</div>
</cfif>