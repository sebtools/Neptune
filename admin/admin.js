if ( typeof(sessionMinutes) == "undefined" ) { sessionMinutes = 3;}
if ( typeof(expireAction) == "undefined" ) { expireAction = 'alert';}
if ( typeof(adminFolder) == "undefined" ) { adminFolder = '/' + location.pathname.split('/')[1] + '/'; }
if ( typeof(loginPage) == "undefined" ) { loginPage = adminFolder + 'login.cfm?reason=timeout';}
if ( typeof(alivePage) == "undefined" ) { alivePage = adminFolder + 'keepalive.cfm';}

oneMinute = (60 * 1000);
nTimeout = sessionMinutes * oneMinute;
nMinutesRemaining = sessionMinutes;

function sessionRedirect(){ alert("sessionRedirect(): " + loginPage);window.location = loginPage; }
function sessionAlive(){var oImage = new Image();oImage.src = alivePage + '?d=' + new Date();}
function sessionWarning() { alert('Your session has expired.'); }

function sessionStatus() {
	nMinutesRemaining -= 1;
	if ( nMinutesRemaining > 0 ) {
		if ( nMinutesRemaining <= 5 ) {
			window.status = 'Your session will expire in ' + nMinutesRemaining + ' minutes.';
		}
		setTimeout('sessionStatus()', oneMinute );//Change the session every minute
	} else {
		window.status = 'Your session has expired.';
	}
	
}

switch ( expireAction ) {
	case "alert":
		setTimeout('sessionStatus()', oneMinute );//Change the session every minute
		setTimeout('sessionWarning()', nTimeout);
	break;
	case "keepalive":
		setInterval('sessionAlive()', nTimeout-oneMinute );//keep alive should be called a minute before the session expires
	break;
	case "redirect":
		setTimeout('sessionStatus()', oneMinute );//Change the session every minute
		setTimeout('sessionRedirect()', nTimeout);
	break;
}