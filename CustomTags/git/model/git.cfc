<cfcomponent>

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="path_repo" type="string" required="true" hint="The folder to your repository.">
	<cfargument name="path_exec" type="string" default="git.cmd" hint="The path to execute git commands.">
	
	<cfset setRepoPath(Arguments.path_repo)>
	<cfset Variables.path_exec = Arguments.path_exec>
	
	<cfreturn This>
</cffunction>

<cffunction name="branch" access="public" returntype="any" output="no">
	<cfargument name="Args" type="string" default="">
	<cfargument name="active" type="boolean" default="false">
	
	<cfset var aBranches = git("branch",Arguments.Args,"array")>
	<cfset var qResults = QueryNew("name,active")>
	<cfset var ii = 0>
	<cfset var name = "">
	<cfset var isActive = false>
	
	<cfloop index="ii" from="1" to="#ArrayLen(aBranches)#">
		<cfset aBranches[ii] = Trim(aBranches[ii])>
		<cfset name = ListLast(aBranches[ii]," ")>
		<cfset isActive = ( Left(aBranches[ii],1) EQ "*" )>
		
		<cfif isActive AND Arguments.active>
			<cfreturn name>
		</cfif>
		
		<cfset QueryAddRow(qResults)>
		<cfset QuerySetCell(qResults,"name",name)>
		<cfset QuerySetCell(qResults,"active",isActive)>
	</cfloop>
	
	<cfreturn qResults>
</cffunction>

<cffunction name="git" access="public" returntype="any" output="no">
	<cfargument name="Command" type="string" required="true">
	<cfargument name="Args" type="string" required="false" default="">
	<cfargument name="returntype" type="string" default="string">
	
	<cfscript>
	var oRuntime = 0;
	var ExecName = "#getDirectoryFromPath(getCurrentTemplatePath())#git.bat";
	var ExecArgs = "#Variables.path_git# #Variables.path_work# #Arguments.Command#";
	var ExecString = "";
	//var process = oRuntime.exec("#Variables.path_exec# --git-dir=#Variables.path_git# --work-tree=#Variables.path_work# #Arguments.Command# #Arguments.Args#");
	var process = 0;
	var exitCode = 0;
	var result = 0;
	var finished = false;
	var tries = 0;
	
	if ( Len(Trim(Arguments.Args)) ) {
		ExecArgs = "#ExecArgs# #Arguments.Args#";
	}
	
	ExecString = "#ExecName# #ExecArgs#";
	</cfscript>
	
	<cfif Arguments.Command EQ "pull">
		<cfexecute name="#ExecName#" arguments="#ExecArgs#" timeout="120"></cfexecute>
	<cfelse>
		<cfscript>
		oRuntime = CreateObject("java", "java.lang.Runtime").getRuntime();
		process = oRuntime.exec(ExecString);
		while( !finished ) {
			try {
				//do stuff like readin input and all
				exitCode = process.exitValue(); //proc is your child process
				finished = true;
			} catch(java.lang.IllegalThreadStateException e){
				tries = tries + 1;
				if ( tries LTE 10 ) {
					sleep(60);
				} else {
					finished = true;
				}
			}
		}
		result = convertInputStream(process.getInputStream(),Arguments.returntype);
		</cfscript>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="convertInputStream" access="private" output="false" returntype="any">
	<cfargument name="inputStream" type="any" required="true">
	<cfargument name="returntype" type="string" default="string">
	
	<cfscript>
	var result = "";
	var inS = createobject("java","java.io.InputStreamReader").init(Arguments.inputStream);
	var inVar = createObject("java","java.io.BufferedReader").init(inS);
	var line = inVar.readLine();
	
	switch ( Arguments.returntype ) {
			case "array":
				result = ArrayNew(1);
			break;
	}
	while ( IsDefined("line") ) {
		switch ( Arguments.returntype ) {
			case "array":
				ArrayAppend(result,line);
			break;
			default:
				result = result & chr(13) & chr(10) & line;
		}
		
		line = inVar.readLine();
		
	} 
	</cfscript>
	
	<cfreturn result>
</cffunction>

<cffunction name="setRepoPath" access="private" returntype="void" output="false">
	<cfargument name="folder" type="any">
	
	<cfset folder = ListChangeDelims(folder,"/","\")>
	<cfif Right(folder,1) NEQ "/">
		<cfset folder = folder & "/">
	</cfif>
	<cfif NOT DirectoryExists(Arguments.folder)>
		<cfthrow type="GitCFC" message="Unable to find directory: #Arguments.folder#">
	</cfif>
	
	<cfif ListLast(Arguments.folder,"/") EQ ".git">
		<cfset Variables.path_git = Arguments.folder>
		<cfset Variables.path_work = ListDeleteAt(Arguments.folder,ListLen(Arguments.folder,"/"),"/") & "/">
	<cfelse>
		<cfset Variables.path_work = Arguments.folder>
		<cfset Variables.path_git = "#Arguments.folder#.git/">
		<cfif NOT DirectoryExists(Variables.path_git)>
			<cfthrow type="GitCFC" message="Unable to find .git folder in: #Arguments.folder#">
		</cfif>
	</cfif>
	
</cffunction>

<cffunction name="onMissingMethod" access="public" returntype="any" output="no">
	
	<cfset var method = Arguments.MissingMethodName>
	<cfset var args = Arguments.MissingMethodArguments>
	<cfset var sArgs = StructNew()>
	
	<cfset sArgs["Command"] = method>
	<cfif ArrayLen(args)>
		<cfif ArrayLen(args) EQ 1 AND isSimpleValue(args[1])>
			<cfset sArgs["Args"] = args[1]>
		<cfelse>
			<cfthrow type="GitCFC" message="Command #method# must take a single string for its arguments.">
		</cfif>
	</cfif>
	
	<cfreturn git(ArgumentCollection=sArgs)>
</cffunction>
<!---
Other ColdFusion Git projects:
https://github.com/andyj/CFGit
https://github.com/rickosborne/rickosborne/tree/master/coldfusion/git-gateway
http://www.markdrew.co.uk/blog/post.cfm/using-git-with-cfml
http://bytestopshere.wordpress.com/2011/02/22/git-deployer-in-coldfusion-need-help/
--->
</cfcomponent>