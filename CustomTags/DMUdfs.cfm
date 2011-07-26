<cfsilent>
<!---
I supply UDFs for DMQuery/DMSQL/DMParam
Version 1.0 Beta 1 (build 4)
Updated: 2010-10-01
Updated: 2010-05-30
--->
<cfscript>
function convertSQLArray(aRawSQL) {
	var aResult = ArrayNew(1);
	var ii = 0;
	var jj = 0;
	var marker = "";
	var MarkerLoc = 0;
	
	//Convert SQL statements
	if ( StructKeyExists(ThisTag,"aSQLs") ) {
		for ( ii=1; ii LTE ArrayLen(aRawSQL); ii=ii+1 ) {
			//while ( Len(Trim(aRawSQL[ii])) ) {
			if ( isSimpleValue(aRawSQL[ii]) ) {
				if ( Len(Trim(aRawSQL[ii])) ) {
					for ( jj=1; jj LTE ArrayLen(ThisTag.aSQLs); jj=jj+1 ) {
						marker = "[DataMgrSQL:#jj#]";
						MarkerLoc = FindNoCase(marker,aRawSQL[ii]);
						//Replace marker with SQL Array
						if ( MarkerLoc ) {
							if ( MarkerLoc GT 1 ) {
								ArrayAppend(aResult,Left(aRawSQL[ii],MarkerLoc-1));
							}
							ArrayAppend(aResult,ThisTag.aSQLs[jj].sql);
							//Drop added text so we can continue loop
							if ( MarkerLoc GT 1 ) {
								aRawSQL[ii] = ReplaceNoCase(aRawSQL[ii],Left(aRawSQL[ii],MarkerLoc-1),"","ONE");
							}
							aRawSQL[ii] = ReplaceNoCase(aRawSQL[ii],marker,"","ONE");
						}
					}
					if ( Len(Trim(aRawSQL[ii])) ) {
						ArrayAppend(aResult,aRawSQL[ii]);
					}
				}
			} else {
				ArrayAppend(aResult,aRawSQL[ii]);
			}
		}
		//da(aResult);
	} else {
		aResult = aRawSQL;
	}
	return aResult;
}
function getDMSQLArray() {
	var aResult = ArrayNew(1);
	var ii = 0;
	marker = "";
	//Loop over params and inject struct of attributes of each
	if ( StructKeyExists(ThisTag,"aParams") ) {
		for ( ii = 1; ii LTE ArrayLen(ThisTag.aParams); ii=ii+1 ) {
			marker = "[DataMgrParam:#ii#]";
			ArrayAppend(aResult,Left(ThisTag.GeneratedContent,FindNoCase(marker,ThisTag.GeneratedContent)-1));
			ArrayAppend(aResult,ThisTag.aParams[ii]);
			//Drop added text so we can continue loop
			ThisTag.GeneratedContent = ReplaceNoCase(ThisTag.GeneratedContent,Left(ThisTag.GeneratedContent,FindNoCase(marker,ThisTag.GeneratedContent)-1),"","ONE");
			ThisTag.GeneratedContent = ReplaceNoCase(ThisTag.GeneratedContent,marker,"","ONE");
		}
	}
	ArrayAppend(aResult,ThisTag.GeneratedContent);
	aResult = convertSQLArray(aResult);
	//Make sure to clear out generated content
	ThisTag.GeneratedContent = "";
	return aResult;
}
</cfscript>
</cfsilent>