<cfsilent>
<cfset Variables.udfs = true>

<cfif NOT StructKeyExists(variables,"da")>
	<cffunction name="da" access="private" returntype="void" output="no">
		<cfdump var="#Arguments#">
		<cfabort>
	</cffunction>
</cfif>

<cfif NOT StructKeyExists(variables,"ListIntegers")>
	<cfscript>
	function ListIntegers(list) { return ReReplaceNoCase(ReReplaceNoCase(list,'[^0-9]',',','ALL'),',{2,}',',','ALL'); }
	</cfscript>
</cfif>

<cfif NOT StructKeyExists(variables,"makeCompName")>
	<cfscript>
	function makeCompName(str) { return variables.Manager.makeCompName(str); }
	</cfscript>
</cfif>

<cfif false AND NOT StructKeyExists(variables,"QueryRowToStruct")>
	<cfscript>
	/**
	* Makes a row of a query into a structure.
	*
	* @param query      The query to work with.
	* @param row      Row number to check. Defaults to row 1.
	* @return Returns a structure.
	* @author Nathan Dintenfass (nathan@changemedia.com)
	* @version 1, December 11, 2001
	*/
	function QueryRow2ToStruct(query){
	    //by default, do this to the first row of the query
	    var row = 1;
	    //a var for looping
	    var ii = 1;
	    //the cols to loop over
	    var cols = listToArray(query.columnList);
	    //the struct to return
	    var stReturn = structnew();
	    //if there is a second argument, use that for the row number
	    if(arrayLen(arguments) GT 1)
	        row = arguments[2];
	    //loop over the cols and build the struct from the query row
	    for(ii = 1; ii lte arraylen(cols); ii = ii + 1){
	        stReturn[cols[ii]] = query[cols[ii]][row];
	    }
	    //return the struct
	    return stReturn;
	}
	</cfscript>
</cfif>

<cfif NOT StructKeyExists(variables,"StructKeyHasLen")>
	<cfscript>
	function StructKeyHasLen(struct,key){
	    return ( StructKeyExists(struct,key) AND Len(Trim(struct[key])) );
	}
	</cfscript>
</cfif>

<cfif NOT StructKeyExists(variables,"StructKeyHasVal")>
	<cfscript>
	function StructKeyHasVal(struct,key){
	    return ( StructKeyExists(struct,key) AND Val(struct[key]) );
	}
	</cfscript>
</cfif>

<cfif NOT StructKeyExists(variables,"TrimAll")>
	<cfscript>
	function TrimAll(str) {
		var wschars = "160,194";
		str = Trim(str);
		//Trim right
		while ( Len(str) AND ListFindNoCase(wschars,Asc(Right(str,1))) ) {
			if ( Len(str) GT 1 ) {
				str = Trim(Left(str,Len(str)-1));
			} else {
				return "";
			}
		}
		//Trim left
		while ( Len(str) AND ListFindNoCase(wschars,Asc(Left(str,1))) ) {
			if ( Len(str) GT 1 ) {
				str = Trim(Right(str,Len(str)-1));
			} else {
				return "";
			}
		}
		return str;
	}
	</cfscript>
</cfif>

<!--- If this is called as a custom tag, then make the functions available to the caller. --->
<cfif StructKeyExists(Variables,"ThisTag")>
	<!--- Optional "returnvar" argument to put functions into the specified variable. --->
	<cfif StructKeyHasLen(Attributes,"returnvar")>
		<cfif NOT StructKeyExists(Caller,Attributes.returnvar)>
			<cfset Caller[Attributes.returnvar] = {}>
		</cfif>
		<cfset scope = Caller[Attributes.returnvar]>
	<cfelse>
		<!--- If no returnvar specified, then just put them in Variables scope on the calling page. --->
		<cfset scope = Caller>
	</cfif>
	<cfloop collection="#Variables#" item="varname">
		<cfif isCustomFunction(Variables[varname]) AND NOT StructKeyExists(scope,varname)>
			<cfset scope[varname] = Variables[varname]>
		</cfif>
	</cfloop>
</cfif>

</cfsilent>
