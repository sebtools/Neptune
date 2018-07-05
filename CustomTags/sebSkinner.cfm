<cfsilent>
<cfscript>
TagName = "cf_sebForm";
if ( StructKeyExists(request, "cftags") ) {
	if ( StructKeyExists(request.cftags, TagName) ) {
		StructAppend(attributes, request.cftags[TagName], "no");
	}
	if ( StructKeyExists(request.cftags, "sebtags") ) {
		StructAppend(attributes, request.cftags["sebtags"], "no");
	}
}
</cfscript>
<cfparam name="skin" default="">
<cfparam name="librarypath" default="/lib/">
<cfdirectory name="qSkinFiles" action="list" directory="#ExpandPath(attributes.librarypath)#skins/" filter="*.css">
<cfset qSkins = QueryNew("skin")>
<cfset QueryAddRow(qSkins,qSkinFiles.RecordCount)>
<cfloop query="qSkinFiles">
	<cfset QuerySetCell(qSkins,"skin",reverse(ListRest(reverse(name),".")),CurrentRow)>
</cfloop>
<cfscript>
if ( isDefined("Session") AND StructKeyExists(Session,"sebskin") ) {
	attributes.skin = Session.sebskin;
}
if ( StructKeyExists(URL,"sebskin") AND Len(URL.sebskin) AND ListFindNoCase(ValueList(qSkins.skin),URL.sebskin) ) {
	attributes.skin = URL.sebskin;
	if ( isDefined("Session") ) {
		Session.sebskin = attributes.skin;
	}
}
if ( Len(attributes.skin) ) {
	request.cftags["sebtags"]["skin"] = attributes.skin;
}
</cfscript>
</cfsilent>
<div style="height:22px;padding:4px 24px;background-color:#EEEE99;margin-bottom:10px;border:1px solid #333333;">
	<form>
		<label for="sebskinner-skin" style="font-family:Verdana;font-size:11px;">Skin</label>
		<select name="sebskin" id="sebskinner-skin">
			<option value=""></option>
			<cfoutput query="qSkins">
				<option value="#skin#"<cfif attributes.skin EQ qSkins.skin[CurrentRow]> selected="selected"</cfif>>#skin#</option>
			</cfoutput>
		</select>
		<input type="submit" value="Change">
	</form>
</div>
<cfexit>