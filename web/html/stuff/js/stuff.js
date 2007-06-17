
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
  return (num - (num % 1))
}

function checkPrefixForm(obj) {
  if (obj.prefix.value.indexOf('.') > 0) {
    alert('Your prefix cannot contain dots.');
    obj.prefix.focus();
    obj.prefix.select();
    return false;
  }
  return true;
}

function checkLoginForm(obj) {
  if (!obj.user.value || !obj.pass.value) {
    alert('Please enter a username and a password to log in.');
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
    alert('Please provide a username for your new account.');
    obj.newuser.focus();
    return false;
  }

  if (obj.newuser.value.indexOf('.') > 0) {
    alert('Sorry, usernames cannot contain dots.');
    obj.newuser.focus();
    return false;
  }
  if (obj.newuser.value.indexOf(' ') > 0) {
    alert('Sorry, usernames cannot contain spaces.');
    obj.newuser.focus();
    return false;
  }
  if (obj.newuser.value.indexOf('@') > 0) {
    alert('Sorry, usernames cannot contain @ signs.');
    obj.newuser.focus();
    return false;
  }

  if (obj.newuser.value && !obj.newpass.value) {
    alert ('Please specify a password for your new account.');
    return false;
  }
  if ((obj.newpass.value) && (obj.newpass.value != obj.confirm.value)) {
    alert('Your passwords do not match - please try again.');
    obj.newpass.focus();
    return false;
  }
  if (!obj.realemail.value) {
    alert('Please provide the real email address where you want your email forwarded.');
    obj.realemail.focus();
    return false;
  }
  return true;
}

function checkPassForm(obj) {
  if (!obj.currentpassword.value) {
    alert('Please enter your current password.');
    obj.currentpassword.focus();
    return false;
  }
  if (obj.newpassword.value != obj.newpasswordconfirm.value) {
    alert('Your passwords do not match - please try again');
    obj.newpassword.focus();
    return false;
  } 
  return true;
}
