<!--- Default start page for Neptune site: http://www.bryantwebconsulting.com/docs/neptune/ --->
<cf_layout title="Congratulations!">
<cf_layout showTitle="true">

<p>You have now generated the site. Make sure to replace this page with real content.</p>

<p>Visit the administration area by following the link below.</p>

<p><a href="/admin/">View Admin</a></p>

<cfif StructKeyExists(Application,"Admins") AND StructKeyExists(Application.Admins,"getMustChangeAdminID") AND Application.Admins.getMustChangeAdminID()>
<ul>
	<li>username: <strong>admin</strong></li>
	<li>password: <strong>admin</strong></li>
</ul>

<p><em>Change the username and password as soon as you log in!</em></p>
</cfif>

<cf_layout>