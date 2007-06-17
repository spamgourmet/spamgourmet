
  winmiscw = 20;
  winmisch = 40;
  miscw = 0; // scrollbar affects this
  misch = 15;

function centerPopup(loc,winname,winw,winh) {
  varx = (screen.width / 2) - (winw / 2) - (winmiscw / 2);
  vary = (screen.height / 2) - (winh / 2) - (winmisch / 2);
  if (varx < 0) {
    varx = 0;
  }
  if (vary < 0) {
    vary = 0;
  }
  varx = integer(varx);
  vary = integer(vary);
  var args = 'toolbar=0,location=0,directories=0,status=0,menubar=0,scrollbars=1,resizable=1,copyhistory=0,width='+winw+',height='+winh+',top='+vary+',left='+varx;
  window.open(loc, winname, args);
}

function integer(num) {
  return (num - (num % 1));
}

var hastyped = false;

function checkPrefixForm(obj) {
  if (obj.prefix.value.indexOf('.') > 0) {
    alert('<%nodelimitersinprefix%>');
    obj.prefix.focus();
    obj.prefix.select();
    return false;
  }
  return true;
}



function checkLoginForm(obj) {
  if (!obj.user.value || !obj.pass.value) {
    alert('<%enterusernamepassword%>');
    if (!obj.user.value) {
      obj.user.focus();
    } else {
      obj.pass.focus();
    }
    return false;
  }
  return true;
}

function checkNewUserForm(obj) {
  if (!obj.newuser.value) {
    alert('<%provideusername%>');
    obj.newuser.focus();
    return false;
  }

  if (obj.newuser.value.indexOf('.') > 0) {
    alert('<%nodelimitersinusername%>');
    obj.newuser.focus();
    return false;
  }

  if (obj.newuser.value.indexOf('~') > 0) {
    alert('<%nodelimitersinusername%>');
    obj.newuser.focus();
    return false;
  }

  if (obj.newuser.value.indexOf(' ') > 0) {
    alert('<%nospacesinusername%>');
    obj.newuser.focus();
    return false;
  }
  if (obj.newuser.value.indexOf('@') > 0) {
    alert('<%noatsignsinusername%>');
    obj.newuser.focus();
    return false;
  }

  if (obj.newuser.value && !obj.newpass.value) {
    alert ('<%providepassword%>');
    return false;
  }
  if ((obj.newpass.value) && (obj.newpass.value != obj.confirm.value)) {
    alert('<%passwordmismatch%>');
    obj.newpass.focus();
    return false;
  }
  if (!obj.realemail.value) {
    alert('<%provideforwardingaddress%>');
    obj.realemail.focus();
    return false;
  }


  return true;
}

function checkSignUpForm(obj) {
  if (!obj.newuser.value) {
    alert('<%provideusername%>');
    obj.newuser.focus();
    return false;
  }

  if (obj.newuser.value.indexOf('.') > 0) {
    alert('<%nodelimitersinusername%>');
    obj.newuser.focus();
    return false;
  }

  if (obj.newuser.value.indexOf('~') > 0) {
    alert('<%nodelimitersinusername%>');
    obj.newuser.focus();
    return false;
  }

  if (obj.newuser.value.indexOf(' ') > 0) {
    alert('<%nospacesinusername%>');
    obj.newuser.focus();
    return false;
  }
  if (obj.newuser.value.indexOf('@') > 0) {
    alert('<%noatsignsinusername%>');
    obj.newuser.focus();
    return false;
  }

  if (!obj.realemail.value) {
    alert('<%provideforwardingaddress%>');
    obj.realemail.focus();
    return false;
  }

  return true;
}





function checkPassForm(obj) {
  if (!obj.currentpassword.value) {
    alert('<%entercurrentpassword%>');
    obj.currentpassword.focus();
    return false;
  }
  if (obj.newpassword.value != obj.newpasswordconfirm.value) {
    alert('<%passwordmismatch%>');
    obj.newpassword.focus();
    return false;
  } 
  return true;
}


function checkResetPasswordForm(obj) {

  if (!obj.newpassword.value) {
    alert ('<%providepassword%>');
    obj.newpassword.focus();
    return false;
  }
  if ((obj.newpassword.value) && (obj.newpassword.value != obj.newpasswordconfirm.value)) {
    alert('<%passwordmismatch%>');
    obj.newpassword.focus();
    return false;
  }
  return true;
}



