<cfsilent>
<!---
CF_MrECache is meant to cache all or part of a page. Similar to cfcache.

ATTRIBUTES
timeSpan (timespan: The interval until the item is flushed from the cache.)
idleTime (timespan: Flushes the cached item if it is not accessed for the specified time span.)
useQueryString (boolean: If true, generates a different cache for each different query string.)
regex (string: If userQueryString="true" and this is provided, the text beyond the file name must match this regex to get cached seperately.)
data (any: Data that should be used in addition to the URL as part of the cache key (use as little extra data as possible).)
id (string: If you wish to override the built in id creation, you can use this attribute to set your own)

Drawback to cfcache:

One drawback from cfcache is that it is unable to capture calling line numbers.
Therefore if you have more than one on a page, you will need to add a data attribute.

Advantages over cfcache:

1. Clearing all file caches in MRECache.cfc:
oMRECache = new com.sebtools.MRECache(id="files");
oMRECache.clearCaches();
This will clear any caches that start with "files" in MRECache.
We use this from Git to detect file changes in the source code and clear the cache.
This allows for long cache times that still stay current.

2. Extra data:
The data attribute can allow for caching the page multiple times depending on different data.
For example, maybe you have a finite list of templates for your site, saved in session scope.
If so, you could call the tag with <CF_MrECache data="#Session.style#">
Then you would get a different cache for that page for each different value of Session.style.

3. Uses CGI.PATH_INFO:
If you have useQueryString="true" then CGI.PATH_INFO will be included in the cache id.

4. Targetted Clearing
Because of how MREcache handles clearing caches, you have a lot of flexibility in how you clear the cache.
oMRECache = new com.sebtools.MRECache(id="files");
If you want to clear all caches for "/example.cfm"
oMRECache.clearCaches("/example.cfm");
You could also clear:
oMRECache.clearCaches("/example.cfm?id=");
for any path starting with that.
Or, you could use a folder.
If you have an "example" folder then you could
oMRECache.clearCaches("/example/");
to clear every page within it from the cache.

5. Targetted caching
If you use useQueryString="true" then you can use the "regex" attribute to define
the acceptable format for the string after the file name.
If the format doesn't match the regex, then only the file path will be used as the cache id.
For example, you could decide to only use the query string if it consists only of an integer id.
<CF_MrECache regex="^\?id=\d+$">

6. DDOS Mitigation
Efforts are put in to make DDOS attacks less impactful for pages using <CF_MrECache>.
By its nature, caching reduces the load on a server, which helps protect from DDOS.
However, if every URL produces a new cache and a DDOS attack spams with tons of URLS
then you could build up an excess of data in RAM.
For legitimate pages, CF_MrECache won't help with this.
However, your page could have lots of values for which it returns the same result.
For example, if you have a product.cfm with 100 products.
product.cfm?id=1 through prouct.cfm?id=100 would al return different product pages.
product.cfm?id=101 and above, however, would all return the same content indicating that no product was found.
CF_MrECache will store a separate key for each page, but will only store the full text of the page once.
This will save space in the cache.
See the bottom of this file for more information.

--->
<cfset Variables.sLocal = StructNew()>
<cfif ThisTag.ExecutionMode EQ "Start">
	<!--- *** ATTRIBUTES *** --->
	<cfparam name="Attributes.useQueryString" type="boolean" default="false"><!--- If true, generates a different cache for each different query string. --->
	<cfparam name="Attributes.data" type="any" default=""><!--- Data that should be used in addition to the URL as part of the cache key (use as little extra data as possible). --->
	<cfparam name="Attributes.regex" type="any" default="">
	<!--- Attributes.timeSpan ---><!--- The interval until the item is flushed from the cache. --->
	<!--- Attributes.idleTime ---><!--- Flushes the cached item if it is not accessed for the specified time span. --->
	<!--- Attributes.id ---><!--- The id of the cache store. Generated from the URL and data attribute if not provided. --->
	<cfif NOT isSimpleValue(Attributes.data)>
		<cfset Attributes.data = SerializeJSON(Attributes.data)>
	</cfif>

	<cfscript>
	Variables.pagekey = CGI.SCRIPT_NAME;
	appendix = CGI.PATH_INFO;
	if ( Len(CGI.QUERY_STRING) ) {
		appendix &= "?#CGI.QUERY_STRING#";
	}
	if ( Len(Attributes.regex) AND NOT REFindNoCase(Attributes.regex, appendix) ) {
		Attributes.useQueryString = false;
	}
	if ( Attributes.useQueryString ) {
		Variables.pagekey &= appendix;
	}
	if ( Len(Attributes.data) ) {
		Variables.pagekey &= ":#Attributes.data#";
	}
	</cfscript>

	<cfparam name="Attributes.id" type="string" default="#Variables.pagekey#">

	<!--- *** PUT ARGUMENTS *** --->
	<cfset sPutArgs = {}>
	<cfif StructKeyExists(Attributes,"timeSpan") AND Len(Attributes.timeSpan)>
		<cfset sPutArgs["timeSpan"] = Attributes.timeSpan>
	</cfif>
	<cfif StructKeyExists(Attributes,"idleTime") AND Len(Attributes.idleTime)>
		<cfset sPutArgs["idleTime"] = Attributes.idleTime>
	</cfif>


	<!--- *** Instantiate MrECache *** --->
	<cfset Variables.MRECache = CreateObject("component","com.sebtools.MrECache").init(id="files")>

	<!--- *** Look for existing cache of page *** --->

	<!--- See note at bottom of the file for explanation of double cache. --->
	<cfset Variables.sLocal.HashName = Variables.MrECache.get("#Attributes.id#")>
	<cfif StructKeyExists(Variables.sLocal,'HashName')>
		<cfset Variables.sLocal.text = Variables.MrECache.get("texts:#Variables.sLocal.HashName#")>
	</cfif>
</cfif>

<!---
*** Output cache if found ***

I know the following line of code is ugly all smashed together like this.
Doing so minimizes the white-space that the custom tag outputs to the page.
Everything in the tag is in cfsilent except the only part of the tag that outputs anything.
So, this line stops cfsilent, conditionally outputs and exits, and restarts cfsilent.
--->
</cfsilent><cfif StructKeyExists(Variables.sLocal,'text')><cfoutput>#variables.sLocal.text#</cfoutput><cfexit></cfif><cfsilent>

<cfif ThisTag.ExecutionMode EQ "End">
	<!--- *** STORE CACHE *** --->

	<!--- The code will only get to the end of the tag if no cache was already found for the page. --->

	<!--- See note at bottom of the file for explanation of double cache. --->
	<cfset HashValue = Hash(ThisTag.GeneratedContent)>
	<cfset Variables.MrECache.put(
		id="#Attributes.id#",
		ArgumentCollection=sPutArgs,
		value=HashValue
	)>
	<cfset Variables.MrECache.put(
		id="texts:#HashValue#",
		ArgumentCollection=sPutArgs,
		value=ThisTag.GeneratedContent
	)>
</cfif>

<!---
FILES PREFIX:

CF_MrECache stores all of its data in a "files" prefix since it is (at least in part) storing data from a file (presumably).
This allows you to create your own instance of MrECache with a "files" id and run clearCaches() on it to clear out any file-based caches.
We do this, for example, from Git any time there are any file changes.
This allows for long cache times that are updated any time the file system changes.

DOUBLE CACHE:

CF_MrECache stores caches in two different caches.
One is by file name or id. This ensures that each file name has its own cache. The value held here is just a hash of the file for that file.
The other references the full value of that hash.

This way if several files store the exact same text then the text is only stored once across all of the files.
This could happen, for example, if useQueryString is true and you had a page with several different invalid values passed in.
If this happened, then each page might return the same result (an explanation that no data could be found).
Since CF_MrECache is just storing a hash of the value for each URI, the data storage for this scenario is minimal.
--->

</cfsilent><!--- OK. One extra line of output after this, because the IDE demands it: --->
