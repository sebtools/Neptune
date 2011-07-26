/******************************************************************************
qForm JavaScript API

Author: Dan G. Switzer, II
Date:   December 10, 2000
Build:  138

Description:
This library provides a API to forms on your page. This simplifies retrieval
of field values by providing methods to retrieve the values from fields,
without having to do complicate coding.

To contribute money to further the development of the qForms API, see:
http://www.pengoworks.com/qForms/donations/

GNU License
---------------------------------------------------------------------------
This library provides common methods for interacting with HTML forms
Copyright (C) 2001  Dan G. Switzer, II

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for mser details.
You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
******************************************************************************/
var _jsver = 11;
for( var z=2; z < 6; z++ ) document.write("<scr"+"ipt language=\"JavaScript1." + z + "\">_jsver = 1" + z + ";</scr"+"ipt>");
function _a(){
this.version = "138";
this.instances = 0;
this.objects = new Object();
this.librarypath = "";
this.autodetect = true;
this.modules = new Array("field", "functions|12", "validation");
this.packages = new Object();
this.validators = new Array();
this.containers = new Object();
this.jsver = new Object();
for( var z=1; z < 9; z++ ) this.jsver["1" + z] = "1." + z;
this.errorColor = "red";
this.styleAttribute = "backgroundColor";
this.useErrorColorCoding = (document.all || document.getElementById) ? true : false;
this.validateAll = false;
this.allowSubmitOnError = false;
this.customValidators = 0;
this.resetOnInit = false;
this.showStatusMsgs = true;
this.reAttribs = "gi";
return true;
}
qFormAPI = new _a();
function _a_setLibraryPath(path){
if( path.substring(path.length-1) != '/' ) path += '/';
this.librarypath = path;
return true;
}
_a.prototype.setLibraryPath = _a_setLibraryPath;
function _a_include(src, path, ver){
var source = src;
if( !source ) return true;
if( !path ) var path = this.librarypath + "qforms/";
if( !ver ) var ver = "";
if( source.substring(source.length-3) != ".js" ) source += ".js";
var thisPackage = source.substring(0,source.length-3);
var strJS = "<scr"+"ipt language=\"JavaScript";
var strEJS = "\"></scr"+"ipt>";
if( this.packages[thisPackage] ) return true;
if( thisPackage == "*" ){
for( var i=0; i < this.modules.length; i++ ){
var source = this.modules[i];
var ver = "99";
if( source.indexOf("|") > -1 ){
ver = source.substring(source.indexOf("|") + 1);
source = source.substring(0, source.indexOf("|"));
}
if( _jsver > ver && this.autodetect ){
document.write(strJS + this.jsver[ver] + "\" src=\"" + path + source + "_js" + ver + ".js" + strEJS);
} else {
document.write(strJS + "\" src=\"" + path + source + ".js" + strEJS);
}
this.packages[source] = true;
}
} else {
if( !this.autodetect || _jsver < 12 || ver.length == 0 ){
document.write(strJS + "\" src=\"" + path + source + strEJS);
} else if( this.autodetect && (parseInt(_jsver, 10) >= parseInt(ver, 10)) ){
source = source.substring(0,source.length-3) + "_js" + ver + source.substring(source.length-3);
document.write(strJS + this.jsver[ver] + "\" src=\"" + path + source + strEJS);
} else {
document.write(strJS + "\" src=\"" + path + source + strEJS);
}
}

this.packages[thisPackage] = true;
return true;
}
_a.prototype.include = _a_include;

function _a_unload(){
var isFramed = false;
for( obj in qFormAPI.objects ){
qFormAPI.objects[obj]._status = "idle";
if( !!qFormAPI.objects[obj]._frame ) isFramed = true;
}
if( isFramed ){
this.objects = new Object();
this.containers = new Object();
}
return true;
}
_a.prototype.unload = _a_unload;

function _a_validate(qForm){
if( !this.validateAll ) return qFormAPI.objects[qForm].validate();
var aryErrors = new Array();
for( obj in qFormAPI.objects ){
qFormAPI.objects[obj].checkForErrors();
for( var i=0; i < qFormAPI.objects[obj]._queue.errors.length; i++ ){
aryErrors[aryErrors.length] = qFormAPI.objects[obj]._queue.errors[i];
}
}
if( aryErrors.length == 0 ) return true;
var strError = "The following error(s) occurred:\n";
for( var i=0; i < aryErrors.length; i++ ) strError += " - " + aryErrors[i] + "\n";
var result = false;
if( this._allowSubmitOnError && this._showAlerts ) result = confirm(strError + "\nAre you sure you want to continue?");
else if( this._allowSubmitOnError && !this._showAlerts ) result = true;
else alert(strError);
return result;
}
_a.prototype.validate = _a_validate;

function _a_reset(hardReset){
for( obj in qFormAPI.objects ) qFormAPI.objects[obj].reset(hardReset);
return true;
}
_a.prototype.reset = _a_reset;
function _a_getFields(){
stcAllData = new Object();
for( obj in qFormAPI.objects ){
var tmpStruct = qFormAPI.objects[obj].getFields();
for( field in tmpStruct ){
if( !stcAllData[field] ){
stcAllData[field] = tmpStruct[field];
} else {
stcAllData[field] += "," + tmpStruct[field];
}
}
}
return stcAllData;
}
_a.prototype.getFields = _a_getFields;
function _a_setFields(struct, rd, ra){
for( obj in qFormAPI.objects ) qFormAPI.objects[obj].setFields(struct, rd, ra);
}
_a.prototype.setFields = _a_setFields;
function _a_dump(){
var str = "";
formData = this.getFields();
for( field in formData ) str += field + " = " + formData[field] + "\n";
alert(str);
}
_a.prototype.dump = _a_dump;
function qForm(name, parent, frame){
if( name == null ) return true;
if( !name ) return alert("No form specified.");
qFormAPI.instances++;
if( qFormAPI.instances ==  1 ) window.onunload = new Function(_functionToString(window.onunload, ";qFormAPI.unload();"));
this._name = name;
this._parent = (!!parent) ? parent : null;
this._frame = (!!frame) ? frame : null;
this._status = null;
this._queue = new Object();
this._queue.errorFields = ",";
this._queue.errors = new Array();
this._queue.validation = new Array();
this._showAlerts = true;
this._allowSubmitOnError = qFormAPI.allowSubmitOnError;
this._locked = false;
this._skipValidation = false;
qFormAPI.objects[this._name] = this;
this._pointer = "qFormAPI.objects['" + this._name + "']";
this.init();
return true;
}
new qForm(null, null, null);
function _q_init(){
if( !this._name ) return false;
if( this._parent && document.layers ) this._form = this._parent + ".document." + this._name;
else this._form = "document." + this._name;
if( this._frame ) this._form = this._frame + "." + this._form;
this.obj = eval(this._form);
if( !this.obj ) return alert("The form \"" + this._name + "\" does not exist. This error \nwill occur if the Form object was initialized before the form \nhas been created or if it simply doesn't exist. Please make \nsure to initialize the Form object after page loads to avoid \npotential problems.");
this.onSubmit = new Function(_functionToString(this.obj.onsubmit, ""));
var strSubmitCheck = this._pointer + ".submitCheck();";
if( this._frame )	strSubmitCheck = "top." + strSubmitCheck;
this.obj.onsubmit = new Function("return " + strSubmitCheck);
this._fields = new Array();
this._pointers = new Object();
for( var j=0; j < this.obj.elements.length; j++ ) this.addField(this.obj.elements[j].name);
this._status = "initialized";
if( qFormAPI.resetOnInit ) this.reset();
return true;
}
qForm.prototype.init = _q_init;
function _q_addField(field){
if( typeof field == "undefined" || field.length == 0 ) return false;
o = this.obj[field];
if( typeof o == "undefined" ) return false;
if( typeof o.type == "undefined" ) o = o[0];
if( (!!o.type) && (typeof this[field] == "undefined") && (field.length > 0) ){
this[field] = new Field(o, field, this._name);
this._fields[this._fields.length] = field;
this._pointers[field.toLowerCase()] = this[field];
}
return true;
}
qForm.prototype.addField = _q_addField;
function _q_removeField(field){
if( typeof this[field] == "undefined" ) return false;
var f = this._fields;
for( var i=0; i < f.length; i++ ){
if( f[i] == field ){
var fp = i;
break;
}
}

if( _jsver >= 12 ){
delete this[field];
f.splice(fp,1);
delete this._pointers[field.toLowerCase()];

var q = this._queue.validation;
for( var j=0; j < q.length; j++ ){
if( q[j][0] == field ){
q.splice(j,1);
j--;
}
}
}
return true;
}
qForm.prototype.removeField = _q_removeField;
function _q_submitCheck(){
if( this._status == "submitting" || this._status == "validating" ) return false;
this._status = "submitting";
var result = qFormAPI.validate(this._name);
if( result ){
var x = this.onSubmit();
if( typeof x == "boolean" ) result = x;
}
if( !result ){
this._status = "idle";
} else {
_setContainerValues(this);
}
return result;
}
qForm.prototype.submitCheck = _q_submitCheck;
qForm.prototype.onSubmit = new Function("");
function _q_addMethod(name, fn, type){
if( arguments.length < 2 ) return alert("To create a new method, you must specify \nboth a name and function to run: \n  obj.addMethod(\"checkTime\", _isTime);");
var type = _param(arguments[2], "from").toLowerCase();
if( type == "field" ) type = "Field";
else type = "qForm";
if( typeof fn == "function" ){
strFN = fn.toString();
strFN = strFN.substring(strFN.indexOf(" "), strFN.indexOf("("));
eval(type + ".prototype." + name + " = " + strFN);
} else {
var fnTemp = new Function(fn);
eval(type + ".prototype." + name + " = fnTemp;");
}
return true;
}
qForm.prototype.addMethod = _q_addMethod;
function _q_addEvent(event, cmd, append){
if( arguments.length < 2 ) return alert("Invalid arguments. Please use the format \naddEvent(event, command, [append]).");
var append = _param(arguments[2], true, "boolean");
_addEvent(this._pointer + ".obj", arguments[0], arguments[1], append);
return true;
}
qForm.prototype.addEvent = _q_addEvent;
function _q_required(fields, value){
var value = _param(arguments[1], true, "boolean");
aryField = _removeSpaces(fields).split(",");

for( var i=0; i < aryField.length; i++ ){
if( !this[aryField[i]] ) return alert("The form field \"" + aryField[i] + "\" does not exist.");
this[aryField[i]].required = value;
}
return true;
}
qForm.prototype.required = _q_required;
function _q_optional(fields){
this.required(fields, false);
return true;
}
qForm.prototype.optional = _q_optional;
function _q_forceValidation(fields, value){
var value = _param(arguments[1], true, "boolean");
aryField = _removeSpaces(fields).split(",");
for( var i=0; i < aryField.length; i++ ){
if( !this[aryField[i]] ) return alert("The form field \"" + aryField[i] + "\" does not exist.");
this[aryField[i]].validate = value;
}
return true;
}
qForm.prototype.forceValidation = _q_forceValidation;
function _q_submit(){
var x = false;
if( this._status == "submitting" ) return false;
if( this.obj.onsubmit() )	x = this.obj.submit();
return (typeof x == "undefined") ? true : x;
}
qForm.prototype.submit = _q_submit;
function _q_disabled(status){
var objExists = (typeof this.obj.disabled == "boolean") ? true : false;
if( arguments.length == 0 ) var status = (this.obj.disabled) ? false : true;
if( !objExists ) this._locked = status;
else this.obj.disabled = status;
return true;
}
qForm.prototype.disabled = _q_disabled;
function _q_reset(hardReset){
if( this._status == null ) return false;
for( var j=0; j < this._fields.length; j++ ){
this[this._fields[j]].setValue(((!!hardReset) ? null : this[this._fields[j]].defaultValue), true, false);
if( this[this._fields[j]]._queue.dependencies.length > 0 ) this[this._fields[j]].enforceDependency();
}
return true;
}
qForm.prototype.reset = _q_reset;
function _q_getFields(){
if( this._status == null ) return false;
struct = new Object();
for( var j=0; j < this._fields.length; j++ ) struct[this._fields[j]] = this[this._fields[j]].getValue();
return struct;
}
qForm.prototype.getFields = _q_getFields;
function _q_setFields(struct, rd, ra){
if( this._status == null ) return false;
var resetDefault = _param(arguments[1], false, "boolean");
var resetAll = _param(arguments[2], true, "boolean");
if( resetAll ) this.reset();
for( key in struct ){
var obj = this._pointers[key.toLowerCase()];
if( obj ){
obj.setValue(struct[key], true, false);
if(resetDefault) obj.defaultValue = struct[key];
}
}
return true;
}
qForm.prototype.setFields = _q_setFields;
function _q_hasChanged(){
if( this._status == null ) return false;
var b = false;
for( var j=0; j < this._fields.length; j++ ){
if( this[this._fields[j]].getValue() != this[this._fields[j]].defaultValue ){
b = true;
break;
}
}
return b;
}
qForm.prototype.hasChanged = _q_hasChanged;
function _q_changedFields(){
if( this._status == null ) return false;
struct = new Object();
for( var j=0; j < this._fields.length; j++ ){
if( this[this._fields[j]].getValue() != this[this._fields[j]].defaultValue ){
struct[this._fields[j]] = this[this._fields[j]].getValue();
}
}
return struct;
}
qForm.prototype.changedFields = _q_changedFields;
function _q_dump(){
var str = "";
var f = this.getFields();
for( fld in f ) str += fld + " = " + f[fld] + "\n";
alert(str);
}
qForm.prototype.dump = _q_dump;
function Field(form, field, formName, init){
if( arguments.length > 3 ) return true;
this._queue = new Object();
this._queue.dependencies = new Array();
this._queue.validation = new Array();
this.qForm = qFormAPI.objects[formName];
this.name = field;
this.path = this.qForm._form + "['" + field + "']";
this.pointer = this.qForm._pointer + "['" + field + "']";
this.obj = eval(this.path);
this.locked = false;
this.description = field.toLowerCase();
this.required = false;
this.validate = false;
this.container = false;
this.type = (!this.obj.type && !!this.obj[0]) ? this.obj[0].type : this.obj.type;
this.validatorAttached = false;
var value = this.getValue();
this.defaultValue = value;
this.lastValue = value;
this.init();
return true;
}
new Field(null, null, null, true);
function _f_init(){
if( qFormAPI.useErrorColorCoding && this.obj.style ) this.styleValue = (!!this.obj.style[qFormAPI.styleAttribute]) ? this.obj.style[qFormAPI.styleAttribute].toLowerCase() : "";
if( document.layers && (this.type == "radio" || this.type == "checkbox") && !!this.obj[0] ){
this.addEvent("onclick", "return " + this.pointer + ".allowFocus();");
} else {
this.addEvent("onfocus", "return " + this.pointer + ".allowFocus();");
}
}
Field.prototype.init = _f_init;
function _f_allowFocus(){
if( qFormAPI.useErrorColorCoding && this.obj.style ){
if( this.qForm._queue.errorFields.indexOf(","+this.name+",") > -1 ) this.obj.style[qFormAPI.styleAttribute] = this.styleValue;
}
this.lastValue = this.getValue();
var result = this.checkIfLocked();
if( (this.type.indexOf("select") > -1) && !result ){
this.resetLast();
this.blur();
}
if( !result ) this.onFocus();
return result;
}
Field.prototype.allowFocus = _f_allowFocus;
Field.prototype.onFocus = new Function("");
function _f_addEvent(event, cmd, append){
if( arguments.length < 2 ) return alert("Invalid arguments. Please use the format \naddEvent(event, command, [append]).");
var append = _param(arguments[2], true, "boolean");
if( (this.type == "radio" || this.type == "checkbox") && !!this.obj[0] ){
for( var i=0; i < this.obj.length; i++ ) _addEvent(this.path + "[" + i + "]", arguments[0], arguments[1], append);
} else {
_addEvent(this.path, arguments[0], arguments[1], append);
}
return true;
}
Field.prototype.addEvent = _f_addEvent;
function _f_disabled(s){
var status = arguments[0];
var oField = (this.type == "radio") ? this.obj[0] : this.obj;
var objExists = (typeof oField.disabled == "boolean") ? true : false;
if( arguments.length == 0 ) var status = (oField.disabled) ? false : true;
if( !objExists ) this.locked = status;
else {
if( !!this.obj[0] && this.type.indexOf("select") == -1 ) for( var i=0; i < this.obj.length; i++ ) this.obj[i].disabled = status;
else this.obj.disabled = status;
}
return true;
}
Field.prototype.disabled = _f_disabled;
function _f_checkIfLocked(showMsg){
var bShowMsg = _param(arguments[0], this.qForm._showAlerts);
if( this.isLocked() ){
this.blur();
if( bShowMsg ) alert("This field is disabled.");
return false;
}
return true;
}
Field.prototype.checkIfLocked = _f_checkIfLocked;
function _f_isLocked(){
var isLocked = this.locked;
if( this.qForm._locked ) isLocked = true;
return isLocked;
}
Field.prototype.isLocked = _f_isLocked;
function _f_isDisabled(){
if( typeof this.obj.disabled == "boolean" ){
var isDisabled = this.obj.disabled;
if( this.qForm.obj.disabled ) isDisabled = true;
return isDisabled;
} else {
return false;
}
}
Field.prototype.isDisabled = _f_isDisabled;
function _f_focus(){
if( !!this.obj.focus ) this.obj.focus();
}
Field.prototype.focus = _f_focus;
function _f_blur(){
if( !!this.obj.blur ) this.obj.blur();
}
Field.prototype.blur = _f_blur;
function _f_select(){
if( !!this.obj.select ) this.obj.select();
}
Field.prototype.select = _f_select;
function _f_reset(){
this.setValue(this.defaultValue, true, false);
}
Field.prototype.reset = _f_reset;
function _f_getValue(){
var type = (this.type.substring(0,6) == "select") ? "select" : this.type;
var value = new Array();
if( type == "select" ){
if( this.type == "select-one" && !this.container ){
value[value.length] = (this.obj.selectedIndex == -1) ? "" : this.obj[this.obj.selectedIndex].value;
} else {
for( var i=0; i < this.obj.length; i++ ){
if( (this.obj[i].selected || this.container) && (!this.dummyContainer) ){
	value[value.length] = this.obj[i].value;
}
}
}
} else if( (type == "checkbox") || (type == "radio") ){
if( !!this.obj[0] && !this.obj.value ){
for( var i=0; i < this.obj.length; i++ ) if( this.obj[i].checked  ) value[value.length] = this.obj[i].value;
} else if( this.obj.checked ){
value[value.length] = this.obj.value;
}
} else {
value[value.length] = this.obj.value;
}
return value.join(",");
}
Field.prototype.getValue = _f_getValue;
function _f_setValue(value, bReset, doEvents){
this.lastValue = this.getValue();
var reset = _param(arguments[1], true, "boolean");
var doEvents = _param(arguments[2], true, "boolean");
var type = (this.type.substring(0,6) == "select") ? "select" : this.type;
var v;

if( type == "select" ){
var bSelectOne = (this.type == "select-one") ? true : false;
var orig = value;
value = "," + value + ",";
bLookForFirst = true;
if( !this.container ){
for( var i=0; i < this.obj.length; i++ ){
v = this.obj[i].value;
bSelectItem = (value.indexOf("," + v + ",") > -1) ? true : false;
if( bSelectItem && (bLookForFirst || !bSelectOne) ) this.obj[i].selected = true;
else if( reset || bSelectOne) this.obj[i].selected = false;
if( bSelectItem && bLookForFirst ) bLookForFirst = false;
}
if( bSelectOne && bLookForFirst ){
if( this.defaultValue == orig ) if( this.obj.length > 0 ) this.obj[0].selected = true;
else this.setValue(this.defaultValue);
}
} else {
newValues = new Object();
for( var i=0; i < this.boundContainers.length; i++ ){
var sCName = this.qForm._name + "_" + this.boundContainers[i];
if( qFormAPI.containers[sCName] ){
	for( key in qFormAPI.containers[sCName] ){
		if( value.indexOf("," + key + ",") > -1 ){
			newValues[key] = qFormAPI.containers[sCName][key];
		}
	}
}
}
this.populate(newValues, reset)
}

} else if( (type == "checkbox") || (type == "radio") ){
if( !!this.obj[0] && !this.obj.value ){
value = "," + value + ",";
for( var i=0; i < this.obj.length; i++ ){
if( value.indexOf("," + this.obj[i].value + ",") > -1 ) this.obj[i].checked = true;
else if( reset ) this.obj[i].checked = false;
}
} else if( this.obj.value == value ){
this.obj.checked = true;
} else if( reset ){
this.obj.checked = false;
}
} else {
this.obj.value = (!value) ? "" : value;
}
if( doEvents ){
this.triggerEvent("onblur");
if( this.lastValue != value ) this.triggerEvent("onchange");
}
this.onSetValue();
return true;
}
Field.prototype.setValue = _f_setValue;
Field.prototype.onSetValue = new Function("");
function _f_triggerEvent(event){
oEvent = eval("this.obj." + event);
if( (this.obj.type == "checkbox") || (this.obj.type == "radio") && !!this.obj[0] ){
for( var k=0; k < this.obj.length; k++ ){
oEvent = eval("this.obj[k]." + event);
if( typeof oEvent == "function" ) oEvent();
}
} else if( typeof oEvent == "function" ){
oEvent();
}
}
Field.prototype.triggerEvent = _f_triggerEvent;
function _q_addValidator(name, fn){
if( arguments.length < 2 ) return alert("To create a new validation object, you must specify \nboth a name and function to run: \n  obj.addValidator(\"isTime\", __isTime);");
if( typeof fn == "string" ){
var _func = new Function(fn);
_addValidator(name, _func);
} else {
_addValidator(name, fn);
}
return true;
}
qForm.prototype.addValidator = _q_addValidator;
function _f_validateExp(expression, error, cmd){
var expression = _param(arguments[0], "false");
var error = _param(arguments[1], "An error occurred on the field '\" + this.description + \"'.");
var cmd = _param(arguments[2]);

var strFn = "if( " + expression + " ){ this.error = \"" + error + "\";}";
if( cmd.length > 0 ) strFn += cmd;
strValidateExp = "_validateExp" + qFormAPI.customValidators;
_addValidator(strValidateExp, new Function(strFn));
eval(this.pointer + ".validate" + strValidateExp + "();");
qFormAPI.customValidators++;
}
Field.prototype.validateExp = _f_validateExp;

function _addValidator(name, fn, alwaysRun){
var alwaysRun = _param(arguments[2], false, "boolean");
if( arguments.length < 2 ) return alert("To create a new validation object, you must specify \nboth a name and function to run: \n  _addValidator(\"isTime\", __isTime);");
if( name.substring(0,2).toLowerCase() == "is" ) name = name.substring(2);
for( var a=0; a < qFormAPI.validators.length; a++ ) if( qFormAPI.validators[a] == name ) return alert("The " + name + " validator has already been loaded.");
qFormAPI.validators[qFormAPI.validators.length] = name;
if( qFormAPI.showStatusMsgs && name.substring(0,12) != "_validateExp" ){
window.status = "Initializing the validate" + name + "() and is" + name + "() validation scripts...";
setTimeout("window.status = ''", 100);
}
var strFN = fn.toString();
var strName = strFN.substring(strFN.indexOf(" "), strFN.indexOf("("));
var strArguments = strFN.substring( strFN.indexOf("(")+1, strFN.indexOf(")") );
while( strArguments.indexOf(" ") > -1 ) strArguments = strArguments.substring( 0, strArguments.indexOf(" ") ) + strArguments.substring( strArguments.indexOf(" ")+1 );
var strBody = "var display = (this.qForm._status == 'validating') ? false : true;\n";
strBody += "if( (display && this.isLocked()) || this.qForm._status.substring(0,5) == 'error') return false;\n this.value = this.getValue();";
if( !alwaysRun ) strBody += "if( !display && this.value.length == 0 && !this.required ) return false;\n";
strBody += "this.error = '';\n";
strBody += strFN.substring( strFN.indexOf("{")+1, strFN.lastIndexOf("}") );
strBody += "if( this.error.length > 0 && !!errorMsg) this.error = errorMsg;\n";
strBody += "if( display && this.error.length > 0 ){\n";
strBody += "if( this.qForm._status.indexOf('_ShowError') > -1 ){\n";
strBody += "this.qForm._status = 'error';\n";
strBody += "alert(this.error);\n";
strBody += "setTimeout(this.pointer + \".focus();\", 1);\n";
strBody += "setTimeout(this.pointer + \".qForm._status = 'idle';\", 100);\n";
strBody += "} return false;\n";
strBody += "} else if ( display ){ return true; } return this.error;\n";
var strNewFN = "new Function(";
var aryArguments = strArguments.split(",");
for( var i=0; i < aryArguments.length; i++ ){
if(aryArguments[i] != "") strNewFN += "\"" + aryArguments[i] + "\",";
}
var strRuleFN = strNewFN;
strNewFN += "\"errorMsg\",strBody);";
eval("Field.prototype.is" + name + " = " + strNewFN);
var strRule = "var cmd = this.pointer + '.is" + name + "';\n";
strRule += "cmd += '( ';\n";
strRule += "for( i=0; i < arguments.length; i++ ){ \n";
strRule += "if( typeof arguments[i] == 'string' ) cmd += '\"' + arguments[i] + '\",';\n";
strRule += "else cmd += arguments[i] + ',';\n";
strRule += "}\n";
strRule += "cmd = cmd.substring(0, cmd.length-1);\n";
strRule += "cmd += ')';\n";
strRule += "this.qForm._queue.validation[this.qForm._queue.validation.length] = new Array(this.name, cmd);\n";
strRule += "this._queue.validation[this._queue.validation.length] = cmd;\n";
strRule += "if( !this.validatorAttached ){ this.addEvent('onblur', this.pointer + '.checkForErrors()');";
strRule += "this.validatorAttached = true;}\n";
strRule += "return true;\n";
strRuleFN += "\"errorMsg\",strRule);";
eval("Field.prototype.validate" + name + " = " + strRuleFN);
return true;
}
function _f_checkForErrors(){
if( !this.validate || this.qForms._skipValidation ) return true;
this.qForm._status += "_ShowError";
for( var i=0; i < this._queue.validation.length; i++ ) if( !eval(this._queue.validation[i]) ) break;
setTimeout(this.pointer + ".qForm._status = 'idle';", 100);
return true;
}
Field.prototype.checkForErrors = _f_checkForErrors;
function _q_validate(){
if( !qFormAPI.packages.validation || this._skipValidation ) return true;
this.checkForErrors();
if( this._queue.errors.length == 0 ) return true;
var result = this.onError();
if( result == false ) return true;
var strError = "The following error(s) occurred:\n";
for( var i=0; i < this._queue.errors.length; i++ ) strError += " - " + this._queue.errors[i] + "\n";
var result = false;
if( this._allowSubmitOnError && this._showAlerts ) result = confirm(strError + "\nAre you sure you want to continue?");
else if( this._allowSubmitOnError && !this._showAlerts ) result = true;
else alert(strError);
return result;
}
qForm.prototype.validate = _q_validate;
function _q_checkForErrors(){
var status = this._status;
this._status = "validating";
this._queue.errors = new Array();
aryQueue = new Array();
this._queue.errorFields = ",";
for( var j=0; j < this._fields.length; j++ ){
if( this[this._fields[j]].required ) aryQueue[aryQueue.length] = new Array(this._fields[j], this._pointer + "['" + this._fields[j] + "'].isNotEmpty('The " + this[this._fields[j]].description + " field is required.');");
if( qFormAPI.useErrorColorCoding && this[this._fields[j]].obj.style ) this[this._fields[j]].obj.style[qFormAPI.styleAttribute] = this[this._fields[j]].styleValue;
}
for( var i=0; i < aryQueue.length; i++ ) this[aryQueue[i][0]].throwError(eval(aryQueue[i][1]));
for( var i=0; i < this._queue.validation.length; i++ ) this[this._queue.validation[i][0]].throwError(eval(this._queue.validation[i][1]));
this.onValidate();
this._status = status;
return true;
}
qForm.prototype.checkForErrors = _q_checkForErrors;
qForm.prototype.onValidate = new Function("");
qForm.prototype.onError = new Function("");
function _f_throwError(error){
var q = this.qForm;
if( (typeof error == "string") && (error.length > 0) && (q._queue.errorFields.indexOf("," + this.name + ",") == -1) ){
q._queue.errors[q._queue.errors.length] = error;
q._queue.errorFields += this.name + ",";
if( qFormAPI.useErrorColorCoding && this.obj.style ) this.obj.style[qFormAPI.styleAttribute] = qFormAPI.errorColor;
return true;
}
return false;
}
Field.prototype.throwError = _f_throwError;
function _addEvent(obj, event, cmd, append){
if( arguments.length < 3 ) return alert("Invalid arguments. Please use the format \n_addEvent(object, event, command, [append]).");
var append = _param(arguments[3], true, "boolean");
var event = arguments[0] + "." + arguments[1].toLowerCase();
var objEvent = eval(event);
var strEvent = (objEvent) ? objEvent.toString() : "";
strEvent = strEvent.substring(strEvent.indexOf("{")+1, strEvent.lastIndexOf("}"));
strEvent = (append) ? (strEvent + cmd) : (cmd + strEvent);
strEvent += "\n";
eval(event + " = new Function(strEvent)");
return true;
}
function _functionToString(fn, cmd, append){
if( arguments.length < 1 ) return alert("Invalid arguments. Please use the format \n_functionToString(function, [command], [append]).");
var append = _param(arguments[2], true, "boolean");
var strFunction = (!fn) ? "" : fn.toString();
strFunction = strFunction.substring(strFunction.indexOf("{")+1, strFunction.lastIndexOf("}"));
if( cmd ) strFunction = (append) ? (strFunction + cmd + "\n") : (cmd + strFunction + "\n");
return strFunction;
}
function _param(v, d, t){
if( typeof d == "undefined" ) d = "";
if( typeof t == "undefined" ) t = "string";
if( t == "number" && typeof v == "string" ) var v = parseFloat(arguments[0]);
var value = (typeof v != "undefined" && typeof v == t.toLowerCase()) ? v : d;
return value;
}
function _removeSpaces(v){
while( v.indexOf(" ") > -1 ) v = v.substring( 0, v.indexOf(" ") ) + v.substring( v.indexOf(" ")+1 );
return v;
}
function _setContainerValues(obj){
for( var i=0; i < obj._fields.length; i++ ){
if( obj[obj._fields[i]].container && obj[obj._fields[i]].type.substring(0,6) == "select" ){
for( var x=0; x < obj[obj._fields[i]].obj.length; x++ ){
obj[obj._fields[i]].obj[x].selected = (!obj[obj._fields[i]].dummyContainer);
}
}
}
}
