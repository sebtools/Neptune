<!---
1.0 RC8 (Build 120)
Last Updated: 2011-01-16
--->
<cfscript>
sebtools = StructNew();
sebtools.skins = StructNew();

sebtools.skins.carpediem = StructNew();
sebtools.skins.carpediem.format = "semantic";
sebtools.skins.carpediem.shape = "bar";
sebtools.skins.carpediem.menutype = "drop-down";

sebtools.skins.deepblue = StructNew();
sebtools.skins.deepblue.format = "table";

sebtools.skins.graybar = StructNew();
sebtools.skins.graybar.format = "semantic";
sebtools.skins.graybar.shape = "bar";
sebtools.skins.graybar.menutype = "bar";

sebtools.skins.halo = StructNew();
sebtools.skins.halo.format = "table";
sebtools.skins.halo.shape = "bar";
sebtools.skins.halo.menutype = "bar";

sebtools.skins.panels = StructNew();
sebtools.skins.panels.format = "table";
sebtools.skins.panels.shape = "bar";
sebtools.skins.panels.menutype = "bar";

sebtools.skins.plain = StructNew();
sebtools.skins.plain.format = "table";
sebtools.skins.plain.shape = "round";
sebtools.skins.plain.menutype = "roundtab";

sebtools.skins.silver = StructNew();
sebtools.skins.silver.format = "table";
sebtools.skins.silver.shape = "round";
sebtools.skins.silver.menutype = "roundtab";

sebtools.skins.slateBlue = StructNew();
sebtools.skins.slateBlue.format = "table";
sebtools.skins.slateBlue.shape = "bar";
sebtools.skins.slateBlue.menutype = "bar";

sebtools.skins.slateGreen = StructNew();
sebtools.skins.slateGreen.format = "table";
sebtools.skins.slateGreen.shape = "bar";
sebtools.skins.slateGreen.menutype = "bar";

sebtools.skins.slateTeal = StructNew();
sebtools.skins.slateTeal.format = "table";
sebtools.skins.slateTeal.shape = "bar";
sebtools.skins.slateTeal.menutype = "bar";

sebtools.skins.tim = StructNew();
sebtools.skins.tim.format = "table";
sebtools.skins.tim.shape = "round";
sebtools.skins.tim.menutype = "roundtab";

if ( StructKeyExists(Attributes,"returnvar") ) {
	if ( NOT StructKeyExists(Caller,attributes.returnvar) ) {
		Caller[attributes.returnvar] = StructNew();
	}
	if ( NOT isStruct(Caller[attributes.returnvar]) ) {
		Caller[attributes.returnvar] = StructNew();
	}
	if ( NOT StructKeyExists(Caller[attributes.returnvar],"sebtools") ) {
		Caller[attributes.returnvar]["sebtools"] = StructNew();
	}
	Caller[attributes.returnvar]["sebtools"] = sebtools;
}
</cfscript>