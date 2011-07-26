<site>
	<arguments>
	</arguments>
	<components>
		<component name="DataMgr" path="com.sebtools.DataMgr">
			<argument name="datasource" />
		</component>
		<component name="Manager" path="com.sebtools.Manager">
			<argument name="DataMgr" />
			<argument name="UploadPath" />
			<argument name="UploadURL" />
			<argument name="RootURL" ifmissing="skiparg" />
			<argument name="RootPath" ifmissing="skiparg" />
		</component>
		<component name="Mailer" path="com.sebtools.Mailer">
			<argument name="DataMgr" ifmissing="skiparg" />
			<argument name="MailServer" ifmissing="skiparg" />
			<argument name="From" arg="MailFrom" ifmissing="skiparg" />
			<argument name="Mode" arg="MailMode" ifmissing="skiparg" />
		</component>
		<component name="NoticeMgr" path="com.sebtools.NoticeMgr">
			<argument name="DataMgr" ifmissing="skipcomp" />
			<argument name="Mailer" ifmissing="skipcomp" />
		</component>
	</components>
	<postactions>
	</postactions>
</site>