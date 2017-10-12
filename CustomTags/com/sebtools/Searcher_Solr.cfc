<!--- Last Updated: 2015-09-24 --->
<!--- Created by Joshua Scott - 09/24/2015 --->
<!--- Information: sebtools.com --->

<cfcomponent displayname="Searcher" hint="I manage search functionality using Solr. I will usually be extended by a site-specific search object." extends="Searcher">

<cffunction name="init" access="public" returntype="any" output="no" hint="I initialize and return this object.">
	<cfargument name="CollectionPath" type="string" required="yes">
	<cfargument name="DataMgr" type="any" required="yes">
	<cfargument name="sendpage" type="string" default="">
	<cfargument name="excludedirs" type="string" default="">
	<cfargument name="excludefiles" type="string" default="">
	<cfargument name="UseGoogleSyntax" type="boolean" default="false">
	<cfargument name="Deployer" type="any" required="false">
	
	<cfreturn initInternal(argumentCollection=arguments)>
</cffunction>

<cffunction name="correctURL" access="private" returntype="string" output="no">
	<cfargument name="ResultURL" type="string" required="yes">
	<!--- Solr has no problem figuring out the correct URL, so we'll just return it untouched. --->
	<cfreturn Arguments.ResultURL>
</cffunction>

<cffunction name="create_Actual" access="public" returntype="void" output="no" hint="I create the given collection.">
	<cfargument name="CollectionName" type="string" required="yes">
	<cfargument name="recreate" type="boolean" default="false">
	
	<cfset var qCollections = 0>
	<cfset var isExisting = false>
	
	<cflock timeout="120" throwontimeout="No" name="Searcher_CheckCollection_#arguments.CollectionName#" type="EXCLUSIVE">
		<cfcollection action="LIST" name="qCollections" engine="solr">
		<!--- <cfdump var="#qCollections#"><cfabort> --->
		
		<cfif ListFindNoCase(ValueList(qCollections.name),arguments.CollectionName)>
			<cfset isExisting = true>
		</cfif>
		
		<!--- arguments.recreate OR NOT  --->
		<cfif NOT isExisting>
			<cftry>
				<cflock timeout="40" throwontimeout="No" name="Searcher_CreateCollection_#arguments.CollectionName#" type="EXCLUSIVE">
					<cfcollection action="CREATE" collection="#arguments.CollectionName#" path="#variables.path#" language="English" engine="solr">
				</cflock>
				<cfcatch>
						<cfset deleteDirectory("#variables.path##getDirDelim()##LCase(arguments.CollectionName)#")>
						<cfcollection action="LIST" name="qCollections" engine="solr">
						<cfloop query="qCollections">
							<cfif name EQ CollectionName>
								<cflock timeout="40" throwontimeout="Yes" name="Searcher_DeleteCollection_#arguments.CollectionName#" type="EXCLUSIVE">
									<cfset deleteDirectory(path)>
									<cfcollection action="DELETE" collection="#name#">
								</cflock>
							</cfif>
						</cfloop>
						<cflock timeout="40" throwontimeout="No" name="Searcher_CreateCollection_#arguments.CollectionName#" type="EXCLUSIVE">
							<cfcollection action="CREATE" collection="#arguments.CollectionName#" path="#variables.path#" language="English" engine="solr">
						</cflock>
				</cfcatch>
			</cftry>
		</cfif>
	</cflock>
	
	<!--- If this collection isn't already known to Searcher, add it. --->
	<cfset addCollection(arguments.CollectionName)>
	
</cffunction>

</cfcomponent>