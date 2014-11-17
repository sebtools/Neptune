<cfcomponent displayname="AppLoader" extends="mxunit.framework.TestCase" output="no">
	
<cfset Variables.TestAppLoader = CreateObject("component","OldAppLoader").init()>
<cfset Variables.ActualAppLoader = CreateObject("component","_framework.AppLoader").init()>

<cffunction name="shouldAppLoaderComponentsMatch" access="public" returntype="void" output="no"
	hint="The getComponents method of the actual AppLoader must return the same data as the test AppLoader"
	mxunit:transaction="rollback"
>
	<cfset var TestXML = getXML()>
	<cfset var TestData = 0>
	<cfset var ActualData = 0>
	<cfset var sArgs = {RootPath="."}>
	
	<cfset TestData = Variables.TestAppLoader.getComponents(TestXML,sArgs)>
	<cfset ActualData = Variables.ActualAppLoader.getComponents(TestXML,sArgs)>
	
	<cfset assertEquals(TestData,ActualData,"Actual AppLoader did not return the same data as the test AppLoader")>
	
</cffunction>

<cffunction name="shouldAppLoaderUseCache" access="public" returntype="void" output="no"
	hint="The getComponents method of AppLoader must use cached data for the internal components array for the same XML."
	mxunit:transaction="rollback"
>
	<cfset var TestXML = getXML()>
	<cfset var aComponents1 = 0>
	<cfset var aComponents2 = 0>
	<cfset var aComponents3 = 0>
	<cfset var RunTime1 = 0>
	<cfset var RunTime2 = 0>
	<cfset var RunTime3 = 0>
	<cfset var sArgs = {RootPath="."}>
	
	<cfset aComponents1 = Variables.ActualAppLoader.getComponents(TestXML,sArgs)>
	<cfset RunTime1 = Variables.ActualAppLoader.getWhenComponentsLoaded()>
	
	<cfset sleep(1500)>
	
	<cfset aComponents2 = Variables.ActualAppLoader.getComponents(TestXML,sArgs)>
	<cfset RunTime2 = Variables.ActualAppLoader.getWhenComponentsLoaded()>
	
	<cfset assertEquals(aComponents1,aComponents2,"AppLoader did not return the same data for subsequent calls to getComponents() with the same XML.")>
	<cfset assertEquals(RunTime1,RunTime2,"AppLoader did not use the cache for a matching value of the XML.")>
	
	<cfset sleep(1500)>
	
	<cfset aComponents3 = Variables.ActualAppLoader.getComponents(ReplaceNoCase(TestXML,"ProjectMgr2Harvest","ProjectMgr3Harvest"),sArgs)>
	<cfset RunTime3 = Variables.ActualAppLoader.getWhenComponentsLoaded()>
	
	<cfset assertNotEquals(aComponents1,aComponents3,"AppLoader returned the same data for subsequent calls to getComponents() with different XML.")>
	<cfset assertNotEquals(RunTime1,RunTime3,"AppLoader used the cache for a non-matching value of the XML.")>
	
</cffunction>

<cffunction name="getXML" access="private" returntype="string" output="no">
	<cfset var TestXML = "">
	
	<cfsavecontent variable="TestXML">
<site>
	<arguments>
		<argument name="SecurityKey" type="string" />
		<argument name="MailServer" type="string" />
		<argument name="MailFrom" type="string" />
	</arguments>
	<components>
		<component name="CFIMAGE" path="Example">
		</component>
		<component name="POIUtility" path="Example">
		</component>
		<component name="IIS" path="Example">
		</component>
		<component name="DataMgr" path="Example">
			<argument name="datasource" arg="datasource" />
		</component>
		<component name="DataMgrSim" path="Example">
			<argument name="datasource" value="" />
		</component>
		<component name="FileMgr" path="Example">
			<argument name="UploadPath" arg="UploadPath" />
			<argument name="UploadURL" arg="UploadURL" />
		</component>
		<component name="Manager" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="FileMgr" component="FileMgr" />
			<argument name="CFIMAGE" component="CFIMAGE" />
			<argument name="RootURL" ifmissing="skiparg" />
			<argument name="RootPath" ifmissing="skiparg" />
		</component>
		<component name="EvilDecapsulation" path="Example">
			<argument name="SponsorID" config="DefaultSponsorID" />
			<argument name="DomainName" config="DefaultDomainName" />
			<argument name="MailServer" config="DefaultMailServer" />
			<argument name="MailFrom" config="DefaultMailFrom" />
			<argument name="SysAdminEmail" config="DefaultSysAdminEmail" />
			<argument name="DevProd" config="DevProd" />
			<argument name="MailServerPub" config="DefaultMailServerPub" />
			<argument name="MailFromPub" config="DefaultMailFromPub" />
		</component>
		<component name="Mailer" path="Example">
			<argument name="MailServer" config="DefaultMailServer" />
			<argument name="From" config="DefaultMailFrom" />
			<argument name="To" config="DefaultSysAdminEmail" />
			<argument name="DataMgr" component="DataMgr" />
			<argument name="EvilDecapsulation" component="EvilDecapsulation" />
		</component>
		<component name="MailerPub" path="Example">
			<argument name="MailServer" config="DefaultMailServerPub" />
			<argument name="From" config="DefaultMailFromPub" />
			<argument name="To" config="DefaultSysAdminEmail" />
			<argument name="DataMgr" component="DataMgr" />
			<argument name="EvilDecapsulation" component="EvilDecapsulation" />
			<argument name="publisher" value="true" />
		</component>
		<component name="Deployer" path="Example">
			<argument name="DataMgr" component="DataMgr" />
		</component>
		<component name="DeploymentsUtil" path="Example">
			<argument name="Deployer" component="Deployer" />
			<argument name="DataMgr" component="DataMgr" />
		</component>
		<component name="ReportMgr" path="Example">
			<argument name="datasource" arg="datasource" />
		</component>
		<component name="Scrubber" path="Example">
		</component>
		<component name="SessionMgr" path="Example">
			<argument name="scope" value="Client" />
		</component>
		<component name="Util" path="Example">
		</component>
		<component name="Capitalizer" path="Example">
			<argument name="DataMgr" component="DataMgr" />
		</component>
		<component name="Articulate" path="Example">
			<argument name="FileMgr" component="FileMgr" />
		</component>
		<component name="Alerts" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="NewsStories" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="ArticleRatings" path="Example">
			<argument name="DataMgr" component="DataMgr" />
		</component>
		<component name="ArticleTypeGroups" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="ArticleTypeHeaders" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="Assignments" path="Example">
			<argument name="DataMgr" component="DataMgr" />
		</component>
		<component name="Auditor" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="Mailer" component="Mailer" />
		</component>
		<component name="BestPracticeMinutes" path="Example">
			<argument name="Manager" component="Manager" />
			<argument name="VideoConverter" component="VideoConverter" />
			<argument name="Articulate" component="Articulate" />
		</component>
		<component name="CMS" path="Example">
			<argument name="DataMgr" component="DataMgr" />
		</component>
		<component name="Codes" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="Designs" path="Example">
			<argument name="Manager" component="Manager" />
			<argument name="RootPath" config="RootPath" />
		</component>
		<component name="DocSets" path="Example">
			<argument name="DataMgr" component="DataMgr" />
		</component>
		<component name="DocSetDocuments" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="FileMgr" component="FileMgr" />
		</component>
		<component name="Domains" path="Example">
			<argument name="Manager" component="Manager" />
			<argument name="IIS" component="IIS" />
		</component>
		<component name="EmailSponsors" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="EmailSubscribers" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="EmailSends" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="Events" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="FinancialInstitutions" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="Forms" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="HandbookMgr" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="uploaddir" config="UploadPath" />
		</component>
		<component name="Importer" path="Example">
			<argument name="Manager" component="Manager" />
			<argument name="POIUtility" component="POIUtility" />
		</component>
		<component name="Journals" path="Example">
			<argument name="DataMgr" component="DataMgr" />
		</component>
		<component name="Links" path="Example">
			<argument name="DataMgr" component="DataMgr" />
		</component>
		<component name="Locations" path="Example">
			<argument name="DataMgr" component="DataMgr" />
		</component>
		<component name="MailAlerts" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="Mailer" component="MailerPub" />
		</component>
		<component name="OfflineTraining" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="NewsletterTemplates" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="NoticeMgr" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="Mailer" component="MailerPub" />
		</component>
		<component name="OrgGroups" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="FileMgr" component="FileMgr" />
		</component>
		<component name="PayPal" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="OrgAssociations" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="PersonnelTypes" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="Positions" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="Policies" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="uploaddir" config="UploadPath" />
		</component>
		<component name="Polls" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="PollOptions" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="PollVotes" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="LawFirms" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="ProspectDatabase" path="Example">
			<argument name="DataMgr" component="DataMgr" />
		</component>
		<component name="ReportMgr2" path="Example">
			<argument name="DataMgr" component="DataMgr" />
		</component>
		<component name="SampleHandbooks" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="FileMgr" component="FileMgr" />
		</component>
		<component name="SamplePolicies" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="FileMgr" component="FileMgr" />
		</component>
		<component name="Scheduler" path="Example">
			<argument name="DataMgr" component="DataMgr" />
		</component>
		<component name="Sections" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="Services" path="Example">
			<argument name="DataMgr" component="DataMgr" />
		</component>
		<component name="ServiceSidebars" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="SpamFilter" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="getNewDefs" value="true" />
		</component>
		<component name="SponsorDocCats" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="SponsorDocs" component="SponsorDocs" />
		</component>
		<component name="SponsorDocs" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="Notifier" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="Mailer" component="Mailer" />
		</component>
		<component name="Tracker" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="Sections" component="Sections" />
		</component>
		<component name="TrainingConverter" path="Example">
			<argument name="DataMgr" component="DataMgr" />
		</component>
		<component name="TrainingSpreadsheets" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="UserQuiz2" path="Example">
			<argument name="DataMgr" component="DataMgr" />
		</component>
		<component name="WorkplacePolicies" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="Zones" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="ArticleNotices" path="Example">
			<argument name="datasource" config="datasource" />
			<argument name="NoticeMgr" component="NoticeMgr" />
			<argument name="Articles" component="Articles" />
			<argument name="NewsletterTemplates" component="NewsletterTemplates" />
			<argument name="Scheduler" component="Scheduler" />
		</component>
		<component name="ArticleReports" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="Scheduler" component="Scheduler" />
		</component>
		<component name="OrgTraining2" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="Assignments" component="Assignments" />
		</component>
		<component name="ProfileMgr" path="Example">
			<argument name="Manager" component="Manager" />
			<argument name="Assignments" component="Assignments" />
		</component>
		<component name="Profiler" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="Codes" component="Codes" />
		</component>
		<component name="Reporter" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="Scheduler" component="Scheduler" />
		</component>
		<component name="TrainingMgr2" path="Example">
			<argument name="Manager" component="Manager" />
			<argument name="Assignments" component="Assignments" />
			<argument name="VideoConverter" component="VideoConverter" />
			<argument name="CFLMS" component="CFLMS" />
		</component>
		<component name="TrainingPreviews" path="Example">
			<argument name="NoticeMgr" component="NoticeMgr" />
			<argument name="Scheduler" component="Scheduler" />
		</component>
		<component name="UserTraining2" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="Assignments" component="Assignments" />
		</component>
		<component name="TrainingNotices" path="Example">
			<argument name="NoticeMgr" component="NoticeMgr" />
			<argument name="Scheduler" component="Scheduler" />
		</component>
		<component name="Transfer" path="Example">
			<argument name="dsn_test" config="datasource" />
			<argument name="dsn_live" value="TitusSQL" />
			<argument name="NetworkSource" config="DefaultLocalNetworkPath" />
			<argument name="NetworkDestination" config="DefaultLiveNetworkPath" />
			<argument name="Articles" component="Articles" />
			<argument name="SponsorDocs" component="SponsorDocs" />
			<argument name="TrainingMgr2" component="TrainingMgr2" />
		</component>
		<component name="ArticleSearcher" path="Example">
			<argument name="sendpage" value="/search.htm" />
			<argument name="DataMgr" component="DataMgr" />
			<argument name="Articles" component="Articles" />
			<argument name="Searcher" component="Searcher" ifmissing="skiparg" />
		</component>
		<component name="LossScenarios" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="Searcher" component="Searcher" ifmissing="skiparg" />
		</component>
		<component name="TrainingExports" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="Mailer" component="Mailer" />
			<argument name="OrgTraining" component="OrgTraining2" />
			<argument name="Scheduler" component="Scheduler" />
		</component>
		<component name="PasswordHelper" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="Users" path="Example">
			<argument name="Manager" component="Manager" />
			<argument name="Mailer" component="Mailer" />
			<argument name="Profiler" component="Profiler" />
			<argument name="Assignments" component="Assignments" />
			<argument name="NoticeMgr" component="NoticeMgr" />
			<argument name="UserTraining" component="UserTraining2" />
			<argument name="ProfileMgr" component="ProfileMgr" />
			<argument name="EvilDecapsulation" component="EvilDecapsulation" />
			<argument name="Capitalizer" component="Capitalizer" />
			<argument name="PasswordHelper" component="PasswordHelper" />
			<argument name="Scheduler" component="Scheduler" />
		</component>
		<component name="UserMgr" path="Example">
			<argument name="Users" component="Users" />
		</component>
		<component name="ArticleFeedbacks" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="Mailer" component="Mailer" />
			<argument name="Articles" component="Articles" />
			<argument name="UserMgr" component="UserMgr" />
		</component>
		<component name="OrgMgr" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="UserMgr" component="UserMgr" />
			<argument name="Notifier" component="Notifier" />
			<argument name="OrgTraining" component="OrgTraining2" />
			<argument name="OrgGroups" component="OrgGroups" />
			<argument name="Locations" component="Locations" />
			<argument name="Profiler" component="Profiler" />
			<argument name="Domains" component="Domains" />
			<argument name="Designs" component="Designs" />
			<argument name="ProfileMgr" component="ProfileMgr" />
			<argument name="HandbooksMgr" component="HandbooksMgr" />
			<argument name="Codes" component="Codes" />
		</component>
		<component name="OldSeminars" path="Example">
			<argument name="DataMgr" component="DataMgr" />
		</component>
		<component name="ArticleTypes" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="Articles" component="Articles" />
			<argument name="OrgMgr" component="OrgMgr" />
		</component>
		<component name="Maintenance" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="Scheduler" component="Scheduler" />
			<argument name="Tracker" component="Tracker" />
			<argument name="OrgMgr" component="OrgMgr" />
			<argument name="TrainingMgr" component="TrainingMgr2" />
		</component>
		<component name="HandbooksMgr" path="Example">
			<argument name="Manager" component="Manager" />
			<argument name="Mailer" component="Mailer" />
		</component>
		<component name="InsuranceTypes" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="OrgMgr" component="OrgMgr" />
			<argument name="Assignments" component="Assignments" />
		</component>
		<component name="Recruiter" path="Example">
			<argument name="Manager" component="Manager" />
			<argument name="Mailer" component="MailerPub" />
			<argument name="Scheduler" component="Scheduler" />
			<argument name="UserMgr" component="UserMgr" />
			<argument name="OrgMgr" component="OrgMgr" />
		</component>
		<component name="Subsections" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="Sections" component="Sections" />
			<argument name="OrgMgr" component="OrgMgr" />
		</component>
		<component name="FunctionPanel" path="Example">
			<argument name="Sections" component="Sections" />
			<argument name="Subsections" component="Subsections" />
		</component>
		<component name="TempCodes" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="Scheduler" component="Scheduler" />
			<argument name="Codes" component="Codes" />
			<argument name="OrgMgr" component="OrgMgr" />
		</component>
		<component name="Security" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="Sections" component="Sections" />
			<argument name="UserTraining" component="UserTraining2" />
			<argument name="PasswordHelper" component="PasswordHelper" />
			<argument name="NoticeMgr" component="NoticeMgr" />
			<argument name="Users" component="Users" />
		</component>
		<component name="Segregator" path="Example">
			<argument name="ArticleTypes" component="ArticleTypes" />
			<argument name="InsuranceTypes" component="InsuranceTypes" />
		</component>
		<component name="SuggestionBox" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="Mailer" component="Mailer" />
			<argument name="OrgMgr" component="OrgMgr" />
			<argument name="UserMgr" component="UserMgr" />
		</component>
		<component name="System" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="Sections" component="Sections" />
			<argument name="Security" component="Security" />
		</component>
		<component name="Registration" path="Example">
			<argument name="Profiler" component="Profiler" />
			<argument name="NoticeMgr" component="NoticeMgr" />
			<argument name="OrgMgr" component="OrgMgr" />
			<argument name="UserMgr" component="UserMgr" />
			<argument name="Recruiter" component="Recruiter" />
			<argument name="EvilDecapsulation" component="EvilDecapsulation" />
			<argument name="Notifier" component="Notifier" />
			<argument name="ProfileMgr" component="ProfileMgr" />
			<argument name="UserTraining" component="UserTraining2" />
		</component>
		<component name="CFLMS" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="FileMgr" component="FileMgr" />
			<argument name="Manager" component="Manager" />
			<argument name="SessionMgr" component="SessionMgr" />
		</component>
		<component name="xChubbWebinars" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="xChubbSig_CaseStudies" path="Example">
			<argument name="DataMgr" component="DataMgr" />
		</component>
		<component name="xBeazley_AEPodcastEpisodes" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="FileMgr" component="FileMgr" />
		</component>
		<component name="xBeazley_AEReporters" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="FileMgr" component="FileMgr" />
		</component>
		<component name="xOsig_SchoolImporter" path="Example">
			<argument name="DataMgr" component="DataMgr" />
			<argument name="OrgMgr" component="OrgMgr" />
			<argument name="Locations" component="Locations" />
		</component>
		<component name="xCanfield_Sponsors" path="Example">
			<argument name="DataMgr" component="DataMgr" />
		</component>
		<component name="Webinars" path="Example">
			<argument name="Manager" component="Manager" />
			<argument name="Sponsors" component="xCanfield_Sponsors" />
		</component>
		<component name="xCanfield_Webinars" path="Example">
			<argument name="Manager" component="Manager" />
			<argument name="Sponsors" component="xCanfield_Sponsors" />
		</component>
		<component name="xCanfield_TimeZones" path="Example">
			<argument name="Manager" component="Manager" />
			<argument name="Sponsors" component="xCanfield_Sponsors" />
		</component>
		<component name="xCanfield_ETrainings" path="Example">
			<argument name="Manager" component="Manager" />
			<argument name="Sponsors" component="xCanfield_Sponsors" />
		</component>
		<component name="xCanfield_TrainingTools" path="Example">
			<argument name="Manager" component="Manager" />
			<argument name="Sponsors" component="xCanfield_Sponsors" />
		</component>
		<component name="xManchester_AcknowledgmentMgr" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="xManchester_TrainingResources" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="xTravelers_PLDocuments" path="Example">
			<argument name="Manager" component="Manager" />
			<argument name="SessionMgr" component="SessionMgr" />
			<argument name="Zones" component="Zones" />
		</component>
		<component name="ProjectMgrMailer" path="Example">
			<argument name="DataMgr" ifmissing="skiparg" />
			<argument name="MailServer" ifmissing="skiparg" />
			<argument name="From" arg="ProjectMgr_Mail_From" ifmissing="skiparg" />
			<argument name="Mode" arg="MailMode" ifmissing="skiparg" />
		</component>
		<component name="ProjectMgrMailCheck" path="Example">
			<argument name="MailServer" arg="ProjectMgr_Mailserver" ifmissing="skipcomp" />
			<argument name="username" arg="ProjectMgr_Mail_username" ifmissing="skipcomp" />
			<argument name="password" arg="ProjectMgr_Mail_password" ifmissing="skipcomp" />
		</component>
		<component name="ProjectObserver" path="Example">
		</component>
		<component name="ProjectMgrUsers" path="Example">
			<argument name="Manager" />
		</component>
		<component name="ProjectMgr" path="Example">
			<argument name="Manager" />
			<argument name="POIUtility" ifmissing="skiparg" />
			<argument name="NoticeMgr" ifmissing="skiparg" />
			<argument name="Scheduler" ifmissing="skiparg" />
			<argument name="MailCheck" component="ProjectMgrMailCheck" ifmissing="skiparg" />
			<argument name="Mailer" component="ProjectMgrMailer" ifmissing="skiparg" />
			<argument name="Users" component="ProjectMgrUsers" />
			<argument name="Observer" component="ProjectObserver" ifmissing="skiparg" />
		</component>
		<component name="BullyingQA" path="Example">
			<argument name="Manager" component="Manager" />
			<argument name="VideoConverter" component="VideoConverter" />
		</component>
		<component name="VideoConverter" path="Example">
			<argument name="FileMgr" component="Manager" />
		</component>
		<component name="RSSReader" path="Example">
			<argument name="Manager" component="Manager" />
			<argument name="Scheduler" component="Scheduler" ifmissing="skiparg" />
		</component>
		<component name="RemoteKeys" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="RulesMgr" path="Example">
			<argument name="Manager" />
			<argument name="RootPath" />
		</component>
		<component name="Harvest" path="Example">
			<argument name="subdomain" value="mccalmongroup" />
			<argument name="username" value="sbryant@mccalmon.com" />
			<argument name="password" value="boomer33" />
		</component>
		<component name="NoAnswerErrors" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="ArticleShares" path="Example">
			<argument name="Manager" component="Manager" />
		</component>
		<component name="Articles" path="Example">
			<argument name="Manager" component="Manager" />
			<argument name="NewsStories" component="NewsStories" />
			<argument name="ArticleShares" component="ArticleShares" />
		</component>
		<component name="ProjectMgr2Harvest" path="Example">
			<argument name="Manager" component="Manager" />
			<argument name="ProjectMgr" component="ProjectMgr" />
			<argument name="Harvest" component="Harvest" />
			<argument name="Scheduler" component="Scheduler" ifmissing="skiparg" />
		</component>
		<component name="Deployments" path="Example">
			<argument name="Manager" component="Manager" />
			<argument name="Deployer" component="Deployer" />
			<argument name="Designs" component="Designs" />
			<argument name="OrgMgr" component="OrgMgr" />
			<argument name="Codes" component="Codes" />
			<argument name="CMS" component="CMS" />
			<argument name="DevProd" config="DevProd" />
			<argument name="RootPath" ifmissing="skiparg" />
		</component>
		<component name="Twitter" path="Example">
			<argument name="ConsumerKey" arg="TwitterConsumerKey" ifmissing="error" />
			<argument name="ConsumerSecret" arg="TwitterConsumerSecret" ifmissing="error" />
			<argument name="Mailer" component="Mailer" />
		</component>
	</components>
	<postactions>
	</postactions>
</site>
	</cfsavecontent>
	
	<cfreturn TestXML>
</cffunction>

</cfcomponent>