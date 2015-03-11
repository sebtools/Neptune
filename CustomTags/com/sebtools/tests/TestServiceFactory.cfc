<cfcomponent DisplayName="Service Factory" extends="com.sebtools.RecordsTester" output="no">

<cffunction name="setUp" access="public" returntype="void" output="no">
	
	<cfset Variables.ServiceFactory = CreateObject("component","admin.meta.model.ServiceFactory").init()>
	
</cffunction>

<cffunction name="shouldLoadXmlFile" access="public" returntype="void" output="no"
	hint="Service Factory should load XML from a file path."
>
	<cfset stub()>
</cffunction>

<cffunction name="shouldLoadXmlString" access="public" returntype="void" output="no"
	hint="Service Factory should load XML from a string."
>
	<cfset stub()>
</cffunction>

<cffunction name="shouldGetSimpleService" access="public" returntype="void" output="no"
	hint="Service Factory should return a service with no dependencies."
>
	<cfset stub()>
</cffunction>

<cffunction name="shouldGetServiceWithValueArgs" access="public" returntype="void" output="no"
	hint="Service Factory should return a service with value dependencies."
>
	<cfset stub()>
</cffunction>

<cffunction name="shouldGetServiceWithDependencies" access="public" returntype="void" output="no"
	hint="Service Factory should return a service with component dependencies."
>
	<cfset stub()>
</cffunction>

<cffunction name="shouldGetServiceWithDeep" access="public" returntype="void" output="no"
	hint="Service Factory should return a service with deep component dependencies."
>
	<cfset stub()>
</cffunction>

<cffunction name="shouldGetServiceWithCircular" access="public" returntype="void" output="no"
	hint="Service Factory should return a service with circular component dependencies."
>
	<cfset stub()>
</cffunction>

<cffunction name="getXML" access="private" returntype="string" output="no">
	<cfset var TestXML = "">
	
	<cfsavecontent variable="TestXML">
<site>
	<arguments>
		<argument name="Value1" type="string" />
		<argument name="Value2" type="string" />
		<argument name="Value3" type="string" />
	</arguments>
	<components>
		<component name="Comp" path="Example">
		</component>
		<component name="CompWithValue" path="Example">
			<argument name="Arg1" arg="Value1" />
		</component>
		<component name="CompWithValues" path="Example">
			<argument name="Arg1" arg="Value1" />
			<argument name="Arg2" arg="Value2" />
		</component>
		<component name="CompWithComp" path="Example">
			<argument name="Arg1" arg="Comp" />
		</component>
		<component name="CompWithComp2" path="Example">
			<argument name="Arg1" arg="Comp" />
			<argument name="Arg2" arg="CompWithValues" />
		</component>
		<component name="CompWithComp3" path="Example">
			<argument name="Arg1" arg="Comp" />
			<argument name="Arg2" arg="CompWithComp2" />
			<argument name="Arg3" arg="Value3" />
		</component>
		<component name="CompWithDeep" path="Example">
			<argument name="Arg1" arg="CompWithComp3" />
			<argument name="Arg2" arg="CompWithComp2" />
			<argument name="Arg3" arg="Value3" />
		</component>
		<component name="CompWithCircle" path="Example">
			<argument name="Arg1" arg="Value1" />
			<argument name="Arg2" arg="CompWithCircle3" />
		</component>
		<component name="CompWithCircle2" path="Example">
			<argument name="Arg1" arg="Value1" />
			<argument name="Arg2" arg="CompWithCircle" />
		</component>
		<component name="CompWithCircle3" path="Example">
			<argument name="Arg1" arg="Value1" />
			<argument name="Arg2" arg="CompWithCircle2" />
		</component>
	</components>
	<postactions>
	</postactions>
</site>
	</cfsavecontent>
	
	<cfreturn TestXML>
</cffunction>

</cfcomponent>