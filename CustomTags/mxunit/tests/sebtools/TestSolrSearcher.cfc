<cfcomponent extends="mxunit.framework.TestCase">
	
	<cffunction name="setUp">
		<cfset args = StructNew() />
		<cfset args.CollectionPath = 'collections' />
		<cfset args.DataMgr = CreateObject('component','com.sebtools.DataMgr').init('TitusDev') />

		<cfset variables.searcher = CreateObject('component','com.sebtools.Searcher_Solr').init(argumentCollection=args) />
	</cffunction>
	
	<cffunction name="tearDown">
	
	</cffunction>
	
	<cffunction name="testShouldCreateCollection">
		<cftry>
			<cfset searcher.create('Test') />
			<cfcatch type="any">
				<cfset fail("Could not create test collection.")>
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="testShouldGetCollections">
		<cfset searcher.create('Test') />
		<cfset assertTrue(ListContainsNoCase(searcher.getCollections(),'test'),"Did not return test collection.") />
	</cffunction>

</cfcomponent>