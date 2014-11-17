<cfcomponent displayname="Manager Test Suite" extends="mxunit.framework.TestCase">

<cffunction name="setUp" access="public" returntype="void" output="no">
	
	<cfset variables.Manager = CreateObject("component","com.sebtools.Manager").init(datasource="TestSQL")>
	
</cffunction>

<cffunction name="shouldDeletesCascade" access="public" returntype="void" output="no" hint="Deletes should cascade as far down as indicated.">
	
	<cfscript>
	var oManager = variables.Manager;
	var xDef = oManager.loadXml('
		<tables prefix="unit">
			<table entity="Cascade Parent" />
			<table entity="Cascade Child">
				<field fentity="Cascade Parent" onRemoteDelete="Cascade" />
				<field name="image" type="image" />
			</table>
			<table entity="Cascade Grandchild">
				<field fentity="Cascade Child" onRemoteDelete="Cascade" />
				<field name="image" type="image" />
			</table>
		</tables>
	');
	var sParent1 = {ParentName="One"};
	var	parentid1 = oManager.saveRecord('unitCascadeParents',sParent1);
	var sParent2 = {ParentName="Two"};
	var parentid2 = oManager.saveRecord('unitCascadeParents',sParent2);
	
	var sChild1 = {ChildName="One",ParentID=parentid1,image="001.jpg"};
	var childid1 = oManager.saveRecord('unitCascadeChildren',sChild1);
	
	var sChild2 = {ChildName="Two",ParentID=parentid1,image="002.jpg"};
	var childid2 = oManager.saveRecord('unitCascadeChildren',sChild2);
	
	var sChild3 = {ChildName="Three",ParentID=parentid1,image="003.jpg"};
	var childid3 = oManager.saveRecord('unitCascadeChildren',sChild3);
	
	var sChild4 = {ChildName="Four",ParentID=parentid2,image="004.jpg"};
	var childid4 = oManager.saveRecord('unitCascadeChildren',sChild4);
	
	var sChild5 = {ChildName="Five",ParentID=parentid2,image="005.jpg"};
	var childid5 = oManager.saveRecord('unitCascadeChildren',sChild5);
	</cfscript>
	
	<cfset sParent = {ParentID=1}>
	<cfset oManager.removeRecord('testParents',sParent)>
	
	<!--- ToDo: Still writing test --->

</cffunction>

<cffunction name="shouldDeletesCascadeError" access="public" returntype="void" output="no" hint="Record should not be deletable if erroring record exists, even down the cascade chain.">
	
	<cfscript>
	var oManager = variables.Manager;
	var xDef = oManager.loadXml('
		<tables prefix="unit">
			<table entity="Cascade Stop Parent" />
			<table entity="Cascade Stop Child">
				<field fentity="Cascade Stop Parent" onRemoteDelete="Cascade" />
				<field name="image" type="image" />
			</table>
			<table entity="Cascade Stop Grandchild">
				<field fentity="Cascade Stop Child" onRemoteDelete="Error" />
				<field name="image" type="image" />
			</table>
		</tables>
	');
	var sParent1 = {ParentName="One"};
	var	parentid1 = oManager.saveRecord('unitCascadeParents',sParent1);
	var sParent2 = {ParentName="Two"};
	var parentid2 = oManager.saveRecord('unitCascadeParents',sParent2);
	
	var sChild1 = {ChildName="One",ParentID=parentid1,image="001.jpg"};
	var childid1 = oManager.saveRecord('unitCascadeChildren',sChild1);
	
	var sChild2 = {ChildName="Two",ParentID=parentid1,image="002.jpg"};
	var childid2 = oManager.saveRecord('unitCascadeChildren',sChild2);
	
	var sChild3 = {ChildName="Three",ParentID=parentid1,image="003.jpg"};
	var childid3 = oManager.saveRecord('unitCascadeChildren',sChild3);
	
	var sChild4 = {ChildName="Four",ParentID=parentid2,image="004.jpg"};
	var childid4 = oManager.saveRecord('unitCascadeChildren',sChild4);
	
	var sChild5 = {ChildName="Five",ParentID=parentid2,image="005.jpg"};
	var childid5 = oManager.saveRecord('unitCascadeChildren',sChild5);
	</cfscript>
	
	<!--- ToDo: Still writing test --->

</cffunction>

</cfcomponent>