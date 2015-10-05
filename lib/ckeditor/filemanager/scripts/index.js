//Create local namespace
var fmHelpers = {};

fmHelpers.getQueryVariable = function(variable)
{
       var query = window.location.search.substring(1);
       var vars = query.split("&");
       for (var i=0;i<vars.length;i++) {
               var pair = vars[i].split("=");
               if(pair[0] == variable){return pair[1];}
       }
       return(false);
}

fmHelpers.getFileRoot = function()
{
	var customFileRoot = fmHelpers.getQueryVariable('fileroot'),
		customServerRoot = fmHelpers.getQueryVariable('serverroot');

	if (customFileRoot) {
		if(customServerRoot == 'true') {
			customFileRoot = '/' + customFileRoot;
		}
	}
	
	// Replace \ with /
	customFileRoot = customFileRoot.replace(/\\/g,'/');
	
	return customFileRoot;
}