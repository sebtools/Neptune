<cfsilent>
<cfset Variables.udfs = true>

<cfif NOT StructKeyExists(variables,"da")>
	<cffunction name="da" access="private" returntype="void" output="no">
		<cfdump var="#Arguments#">
		<cfabort>
	</cffunction>
</cfif>

<cfif NOT StructKeyExists(variables,"ListToHTML")>
	<cffunction name="ListToHTML" access="public" returntype="string" output="false" hint="I return a list as an HTML list.">
		<cfargument name="list" type="string" required="true">
		<cfargument name="delimiter" type="string" default=",">

		<cfscript>
		var result = "";
		var aItems = 0;
		var ii = 0;

		if ( Len(Trim(Arguments.list)) ) {
			aItems = ListToArray(list,delimiter);
			result = "<ul>";
			for ( ii=1; ii LTE ArrayLen(aItems); ii++ ) {
				result = "#result#<li>#aItems[ii]#</li>";
			}

			result = "#result#</ul>";
		}

		return result;
		</cfscript>
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

<cfif NOT StructKeyExists(variables,"QueryAddRowStruct")>
	<cfscript>
	function QueryAddRowStruct(query,struct) {
		var cols = Arguments.query.ColumnList;
		var col = "";

		QueryAddRow(query);

		for ( col in Arguments.struct ) {
			if ( ListFindNoCase(cols,col) ) {
				querySetCell(Arguments.query, col, Arguments.struct[col]);
			}
		}
	}
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
	function QueryRowToStruct(query){
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

<cfif NOT StructKeyExists(variables,"QueryToArray")>
	<!--- https://www.bennadel.com/blog/124-ask-ben-converting-a-query-to-an-array.htm --->
	<cffunction name="QueryToArray" access="public" returntype="array" output="false" hint="This turns a query into an array of structures.">

		<!--- Define arguments. --->
		<cfargument name="Data" type="query" required="yes" />

		<cfscript>
			// Define the local scope.
			var LOCAL = StructNew();
			// Get the column names as an array.
			LOCAL.Columns = ListToArray( ARGUMENTS.Data.ColumnList );
			// Create an array that will hold the query equivalent.
			LOCAL.QueryArray = ArrayNew( 1 );
			// Loop over the query.
			for (LOCAL.RowIndex = 1 ; LOCAL.RowIndex LTE ARGUMENTS.Data.RecordCount ; LOCAL.RowIndex = (LOCAL.RowIndex + 1)){
				// Create a row structure.
				LOCAL.Row = StructNew();
				// Loop over the columns in this row.
				for (LOCAL.ColumnIndex = 1 ; LOCAL.ColumnIndex LTE ArrayLen( LOCAL.Columns ) ; LOCAL.ColumnIndex = (LOCAL.ColumnIndex + 1)){
					// Get a reference to the query column.
					LOCAL.ColumnName = LOCAL.Columns[ LOCAL.ColumnIndex ];
					// Store the query cell value into the struct by key.
					LOCAL.Row[ LOCAL.ColumnName ] = ARGUMENTS.Data[ LOCAL.ColumnName ][ LOCAL.RowIndex ];
				}
				// Add the structure to the query array.
				ArrayAppend( LOCAL.QueryArray, LOCAL.Row );
			}
			// Return the array equivalent.
			return( LOCAL.QueryArray );
		</cfscript>
	</cffunction>
</cfif>

<cfif NOT StructKeyExists(variables,"StructKeyHasLen")>
	<cfscript>
	function StructKeyHasLen(struct,key){
	    return ( StructKeyExists(Arguments.struct,key) AND Len(Trim(Arguments.struct[key])) );
	}
	</cfscript>
</cfif>

<cfif NOT StructKeyExists(variables,"StructKeyHasVal")>
	<cfscript>
	function StructKeyHasVal(struct,key){
	    return ( StructKeyExists(Arguments.struct,key) AND Val(Arguments.struct[key]) );
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
