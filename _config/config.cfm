<cfscript>
setSetting("datasource","");
setSetting("UploadDir","f");
setSetting("UploadPath","#getSetting('RootPath')##getSetting('UploadDir')##getSetting('dirdelim')#");
setSetting("UploadURL","/#getSetting('UploadDir')#/");
setSetting("UploadURL","/file.cfm?file=");
setSetting("RootURL","http://#CGI.SERVER_NAME#/");
setSetting("MailFrom","/");
setSetting("MailServer","");
setSetting("MailMode","Sim");

request.cftags = StructNew();
request.cftags.sebtags = StructNew();
request.cftags.cf_sebForm = StructNew();
request.cftags.cf_sebColumn = StructNew();
request.cftags.cf_sebMenu = StructNew();

request.cftags.sebtags.librarypath = "/lib/";
request.cftags.sebtags.skin = "silver";
request.cftags.sebtags.xhtml = false;
request.cftags.sebtags.useSessionMessages = true;
request.cftags.sebtags.stripurlvars = "refresh";
request.cftags.sebtags.jqhover = true;

request.cftags.cf_sebForm.UploadFilePath = getSetting('UploadPath');
request.cftags.cf_sebForm.UploadBrowserPath = getSetting('UploadURL');

request.cftags.cf_sebColumn.arrowup = "/lib/icons/MetalButton/Up.gif";
request.cftags.cf_sebColumn.arrowdown = "/lib/icons/MetalButton/Down.gif";

request.cftags.cf_layout = StructNew();
request.cftags.cf_layout.class = "layout-include";
request.cftags.cf_layout.style = "margin-top:30px;";
</cfscript>