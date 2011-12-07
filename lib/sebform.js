function sebForm() {
	librarypath = typeof(librarypath) != 'undefined' ? librarypath : 42;
	
	if ( typeof(librqFormAPIarypath) != 'undefined' ) {
		qFormAPI.setLibraryPath(librarypath);
		qFormAPI.include("*");
		qFormAPI.librarypath = librarypath;
	}
	
}

sebForm.prototype.addEvent = function(obj, evType, fn) {
	if (obj.addEventListener){
		obj.addEventListener(evType, fn, true);
		return true;
	} else if (obj.attachEvent){
		var r = obj.attachEvent("on"+evType, fn);
		return r;
	} else {
		return false;
	}
}
sebForm.prototype.addEventToId = function(id, evType, fn) {
	addEvent(document.getElementById(id), evType, fn);
}
sebForm.prototype.setStyleById = function(i, p, v) {
	var n = document.getElementById(i);
	n.style[p] = v;
}

//A generic show/hide function that can be effectively extended by other functions
sebForm.prototype.toggleField = function(field,action) {
	if ( !document.getElementById ) {return false;}
	if ( !document.getElementById('lbl-' + field) ) {return false;}
	
	var lblOptions = document.getElementById('lbl-' + field);
	var inpOptions;
	var oOptions;
	var dispType;
	
	if ( document.getElementById(field + '_set') ) {
		inpOptions = document.getElementById(field + '_set');
	} else {
		inpOptions = document.getElementById(field);
	}
	
	if ( lblOptions.parentNode.nodeName == "DIV" ) {
		oOptions = lblOptions.parentNode;
		dispType = 'block';
	} else if ( lblOptions.parentNode.parentNode.nodeName == "DIV" ) {
		oOptions = lblOptions.parentNode.parentNode;
		dispType = 'block';
	} else if ( lblOptions.parentNode.parentNode.nodeName == "TR" ) {
		oOptions = lblOptions.parentNode.parentNode;
		dispType = 'table-row';
	} else if ( lblOptions.parentNode.parentNode.parentNode.nodeName == "TR" ) {
		oOptions = lblOptions.parentNode.parentNode.parentNode;
		dispType = 'table-row';
	}
	
	if ( action == 'hide' ) {
		oOptions.style.display = "none";
		lblOptions.style.display = "none";
		inpOptions.style.display = "none";
	} else {
		try {
			oOptions.style.display = dispType;
		} catch (err) {
			oOptions.style.display = "block";
		}
		lblOptions.style.display = "block";
		inpOptions.style.display = "block";
	}
}
sebForm.prototype.showOptions = function(type) {
	var sebform = this;
	if (!document.getElementById) {return false;}
	if ( arguments.length >= 2 ) {
		field = arguments[1];
	} else {
		field = arguments[0];
	}
	var allOptions = document.getElementById('all' + type + '_1');
	
	if ( allOptions.checked ) {
		sebform.toggleField(field,'hide')
	} else {
		sebform.toggleField(field,'show')
	}
}
sebForm.prototype.getRequiredFields = function(fields){
	var aFields = fields.split(',');
	var ii = 0;
	var aResult = new Array();
	for ( ii in aFields ) {
		if ( jsfrmSebform[aFields[ii]].required == true ) {
			aResult[aResult.length] = aFields[ii];
		}
	}
	
	return aResult;
}
sebForm.prototype.loadFKGroup = function(fkid,groupid,fields) {
	var oField = document.getElementById(fkid);
	var optiontext = '(New ' + oField.title + ')';
	var sebform = this;
	var aReqFields = sebform.getRequiredFields(fields);
	var isFKRequired = false;
	
	if ( jsfrmSebform[fkid].required ) { isFKRequired = true }
	
	var chooseField = function() {
		var ii = 0;
		var isRequired;
		if ( oField.options[oField.selectedIndex].text == optiontext ) {
			sebform.setStyleById(groupid,'display','block');
			isRequired = true;
			jsfrmSebform[fkid].required = false;
		} else {
			sebform.setStyleById(groupid,'display','none');
			isRequired = false;
			jsfrmSebform[fkid].required = isFKRequired;
		}
		for ( ii in aReqFields ) {
			jsfrmSebform[aReqFields[ii]].required = isRequired;
		}
	}
	
	
	
	//if ( oField.options.length > 1 ) {
		chooseField();
		sebform.addEvent(oField,'change',chooseField);
		oField.options[oField.options.length] = new Option(optiontext,'');
	//} else {
	//	sebform.setStyleById(groupid,'display','block');
	//	jsfrmSebform[fkid].required = false;
	//	sebform.toggleField(fkid,"hide");
	//}
}
sebForm.prototype.setFKGroup = function(fkid, groupid, fields){
	var sebform = this;
	sebform.addEvent(window,'load',function(){sebform.loadFKGroup(fkid,groupid,fields)});
}