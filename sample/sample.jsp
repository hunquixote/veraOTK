<%-- --------------------------------------------------------------------------
 - File Name   : login.jsp(로그인 샘플)
 - Include     : 
 - Author      : WIZVERA
 - Last Update : 2023/07/31
-------------------------------------------------------------------------- --%>
<%@page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="ko" xml:lang="ko">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta http-equiv="Expires" content="-1" />
    <meta http-equiv="Progma" content="no-cache" />
    <meta http-equiv="cache-control" content="no-cache" />
	<titile>veraOTK Sample</titile>
	<style>
		#txlog {
			width: 90%;
			height: 400px;
		}
	</style>
	<script src="https://svc.passkeys.kr/client/js/wizvera-passkeys.js"></script>
</head>
<body>

<script type="text/javascript">

var passkeyServiceRoot = 'https://svc.passkeys.kr/webauthn/api/v1';
var passkeyClientId = 'local.wizvera.com';
var passkeyOrign = window.location.hostname;
var QRTokenProcessURL = window.location.origin + '/qr-pass.html';
//(필수) QR토큰 생성시 사용되는 기본URL (qrToken 설정시 생략가능)
//QR코드 이미지 URL: <qrTokenProcessURL>?qrToken=<qrToken>&type=<qrTokenType>
var passkeysClient = undefined;
var initWithQR = false;

function initializeClient(withQR) {
	var clientInfo = getClientInfo(withQR);
	if(!clientInfo) return;
	
	var options = {
		passkeyServiceRoot: passkeyServiceRoot, // 패스키 서버 API 서비스 주소
		clientId: clientInfo.clientId,	// 등록된 서비스 ID
		orgin: clientInfo.clientOrign,  // 클라이언트 orgin
		//email: clientInfo.email,		// 사용자 이메일주소
		//phoneNumber: clientInfo.phoneNumber, // 사용자 휴대폰번호
		qrTokenCheckInterval: 3000, // qr토큰 확인시간(ms)
		useExternalQRCodeLibrary: clientInfo.useExteranlQRCode, // 외부 QR코드 생성 라이브러리 사용여부
		qrTokenClassifier: function() {
			// QR인증을 통한 타기기로의 인증이 필요한 경우를 판별하는 함수를 
			// override 해야할 필요가 있는 경우 설정
			return clientInfo.useQRToken;
		},
		qrTokenProcessURL: QRTokenProcessURL, // QR코드로 표시할 URL 주소
		qrCodeHandler: function(qrCodeData, qrCodeCanvas) {
			// QR코드가 생성되면 호출되는 함수, 
			// useExternalQRCodeLibrary가 true면 qrCodeCanvas는 undefined 설정
			console.log(qrCodeData);
			
			var qrCodeContainer = document.getElementByid('qrcode');
			qrCodeContainer.innerHTML = '';
			var text = document.createElement('h5');
			text.innerText = qrCodeData;
			qrCodeContainer.appendChild(text);
			
			// useExternalQRCodeLibrary true면, qrCodeCanvas는 undefined.
			if(clientInfo.useExternalQRCode !== true) {
				qrCodeContainer.appendChild(qrCodeCanvas);
			}
		},
	}; // end options
	
	if(withQR) options.qrToken = clientInfo.qrToken;
	
	try {
		passkeyClient = new WizveraPasskeys(options);
		
		passkeyClient.isSupportAutofillUI().then(function(isAvailable) {
			if(isAvailable){
				enableConditionalUI();
			}
		});
	} catch(error) {
		errorHandler(error);
	}
	
	initWithQR = (withQR === true);
}

function register() {
	if(!passkeyClient) {
		alert('Initialize Error!');
		return;
	}
	
	var email = document.getElementById('email').value.trim();
	var phoneNumber = docuement.getElementById('phoneNumber').value.trim();
	
	if(!email) {
		alert('You must enter your e-mail address!');
		return;
	}
	
	passkeyClient.register({
		email: email,
		phoneNumber: phoneNumber
	}).then(function(result) {
		writeLog(JSON.stringfy(result, null, 2));
		processSignup(result);
	}).catch(function(error) {
		errorHandler(error);
	});
}

function assertion() {
	if(!passkeyClient) {
		alert('Initialize Error!');
		return;
	}
	
	var userHandle = document.getElementById('userHandle').value.trim();
	
	passkeysClient.assertion({
		userHandle: userHandle
	}).then(function(result) {
		writeLog(JSON.stringify(result, null, 2));
		processLogin(result);
	}).catch(function(error) {
		errorHandler(error);
	});
}

function processLogin(result) {
	// TODO: passkey 서명검증 후 처리
	// result.callbackURL 호출
	document.getElementById('assertionBtn').disabled = false;
}

function processSignup(result) {
	// TODO: passkey 등록완료 후 처리
	// result.callbackURL 호출
}

function enableConditionalUI() {
	alert('conditional UI를 사용하면 assertion 버튼은 사용할수 없습니다.');
	document.getElementById('assertionBtn').disabled = true;
	
	passkeysClient.enableAutofillUI({}).then(function(result) {
		writeLog(JSON.stringify(result, null, 2));
		processLogin(result);
	}).catch(function(error) {
		errorHandler(error);
		document.getElementById('assertionBtn').disabled = false;
	});
}

function requestCreateOptions() {
	if(!passkeyClient) {
		alert('Initialize Error!');
		return;
	}
	
	var email = document.getElementById('email').value.trim();
	var phoneNumber = document.getElementById('phoneNumber').value.trim();
	
	if(!email) {
		alert('You must enter your e-mail address!');
		return;
	}
	
	passkeysClient.getPublicKeyCredentialCreationOptions({
		email: email,
		phoneNumber: phoneNumber
	}).then(function(creationOptions) {
		writeLog(JSON.stringify(creationOptions, null, 2));
	}).catch(function(error) {
		errorHandler(error);
	});
}

function cancelQRToken() {
	if(!passkeyClient) {
		alert('Initialize Error!');
		return;
	}
	
	passkeysClient.cancelQRToken({}).then(function(res) {
		//writeLog(JSON.stringify(res, null, 2));
		document.getElementById('qrcode').innerHTML = '';
	}).catch(function(error) {
		errorHandler(error);
	});
}

function checkEmail() {
	if(!passkeyClient) {
		alert('Initialize Error!');
		return;
	}
	
	var email = document.getElementById('email').value.trim();
	if(!email) {
		alert('You must enter your e-mail address!');
		return;
	}
	
	passkeysClient.checkUser({
		email: email
	}).then(function(res) {
		// 등록된 email이면 res는 항상 true를 리턴함
		//writeLog('JSON.stringify(res, null, 2)');
		writeLog('등록된 사용자입니다.');
	}).catch(function(error) {
		errorHandler(error);
	});
}

function requestCode() {
	if(!passkeyClient) {
		alert('Initialize Error!');
		return;
	}
	
	var email = document.getElementById('email').value.trim();
	if(!email) {
		alert('You must enter your e-mail address!');
		return;
	}
	
	passkeysClient.requestAuthCode({
		email: email
	}).then(function(res) {
		//writeLog(JSON.stringify(res, null, 2));
		writeLog('등록된 사용자입니다. email로 인증코드가 전송되었습니다.');
	}).catch(function(error) {
		errorHandler(error);
	});
}

function checkCode() {
	if(!passkeyClient) {
		alert('Initialize Error!');
		return;
	}
	
	var authCode = document.getElementById('authCode').value.trim();
	if(!authCode) {
		alert('You must enter your authCode!');
		return;
	}
	
	passkeysClient.verifyAuthCode({
		authCode: authCode
	}).then(function(res) {
		// 인증코드가 확인되면 res는 항상 true를 리턴함.
		//writeLog(JSON.stringify(res, null, 2));
		writeLog('인증코드가 확인되었습니다.');
	}).catch(function(error) {
		errorHandler(error);
	});
}

function getClientInfo(withQR) {
	var clientId = document.getElementById('clientId').value.trim();
	var clientOrigin = document.getElementById('clientOrigin').value.trim();
	var email = document.getElementById('email').value.trim();
	var phoneNumber = document.getElementById('phoneNumber').value.trim();
	var qrToken = document.getElementById('qrToken').value.trim();
	var useQRToken = document.getElementById('useQRToken').value === 'true';
	var useExternalQRCode = document.getElementById('useExternalQRCode').value === 'true';
	var userHandle = document.getElementById('userHandle').value.trim();
	
	if(!clientId) {
		alert('input clientId');
		return;
	}
	
	if(!clientOrigin) {
		alert('input clientOrigin');
		return;
	}
	/*
	if(!email && !userHandle) {
		alert('input email or userHandle');
		return;
	}
	*/
	if(withQR && !qrToken) {
		alert('input qr-token');
		return;
	}
	
	return {
		clientId: clientId,
		clientOrigin: clientOrigin,
		email: email,
		phoneNumber: phoneNumber,
		qrToken: qrToken,
		useQRToken: useQRToken,
		useExternalQRCode: useExternalQRCode,
		userHandle: userHandle
	};
}

function writeLog(msg) {
	document.getElementById('txlog').textContent = msg;
}

function appendLog(msg, nl) {
	document.getElementById('txlog').textContent += ((nl ? "\n" : "") + msg);
}

function errorLog(error) {
	console.error(error);
	var message = (error.name === 'ServiceError') ? '[' + error.code + '] ' + error.message : error.message;
	writeLog('[' + error.name + ']' + message);
}

function errorHandler(error) {
	errorLog(error);
	var name = error.name;
	var message = error.message;
	var code = (name === 'ServiceError') ? error.code : undefined;
	var description = '';
	
	if(name === 'NotSupportError') {
		description = '[' + name + '] Passkey가 지원되지 않는 브라우저입니다.\n\n' + message;
	} else if(name === 'InvalidOptionsError') {
		description = '[' + name + '] 필수 파라미터 누락: \n\n' + message;
	} else if(name === 'ServerError') {
		description = '[' + name + '] 서버에서 오류가 발생하였습니다: \n\n' + 	message;
	} else if(name === 'GeneralPasskeyError') {
		description = '[' + name + '] Passkey API 오류: \n\n' + message;
	} else if(name === 'AbortOperationError') {
		description = '[' + name + '] Passkey 인증이 취소되었습니다.: \n\n' + message;
	} else if(name === 'ExcludedCredentialError') {
		description = '[' + name + '] 이미 서버에 등록된 Passkey입니다. : \n\n' + message;
	} else if(name === 'ServiceError') {
		if(code === 1014) {
			description = '[' + name + '][' + code + '] 등록되지 않은 사용자입니다.	email 인증을 해주세요. : \n\n' + message;
		} else if(code === 1005) {
			description = '[' + name + '][' + code + '] 등록되지 않은 사용자입니다.	email로 인증코드가 전송되었습니다. : \n\n' + message;
		} else if(code === 1007) {
			description = '[' + name + '][' + code + '] 등록되지 않은 사용자입니다.: \n\n' + message;
		} else if(code === 1006) {
			description = '[' + name + '][' + code + '] 유효하지 않은 인증코드입니다. : \n\n' + message;
		} else {
			description = '[' + name + '][' + code + '] ' + message;
		}
	} else {
		description = '[' + name + '] ' + message;
	}
		alert(description);
	}

	window.addEventListener('DOMContentLoaded', function() {
		document.getElementById('clientId').value = PasskeyClientId;
		document.getElementById('clientOrigin').value = PasskeyOrigin;
		try {
		// throws NotSupportError if not supported
		WizveraPasskeys.IsSupportPasskey();
	} catch(error) {
		errorHandler(error);
	}
});
	
</script>

<h4>Client & UserInfo</h4>

clientId: <input type="text" id="clientId"><br/>
origin: <input type="text" id="clientOrigin"><br/>
email: <input type="text" id="email" autocomplete="username webauthn"><br/>
phoneNumber: <input type="text" id="phoneNumber" disabled><br/>
-<br/>
userHandle: <input type="text" id="userHandle"><br/>
-<br/>
auth-code: <input type="text" id="authCode"><br/>
-<br/>
qr-token: <input type="text" id="qrToken"><br/>
<hr/>

<h4>Passkey API Test</h4>

authenticate with a passkey on another device using QR code: 
<selectid="useQRToken">
	<option value="false" selected>false</option>
	<option value="true">true</option>
</select><br/>

use external qrcode library: 
<select id="useExternalQRCode">
	<option value="false" selected>false</option>
	<option value="true">true</option>
</select><br/>
-<br/>

initialize: <button onclick="initializeClient()">initialize client</button><br/>
initialize with QRToken: <button onclick="initializeClient(true)">initialize client(QRToken)</button><br/>
register: <button onclick="register()">register</button><br/>
assertion: <button onclick="assertion()" id="assertionBtn">assertion</button><br/>
-<br/>
use conditional UI: <button onclick="enableConditionalUI()"
id="conditionalUIBtn">ConditionalMediation(Conditional UI)</button>
<hr/>

<h4>QRCode</h4>
<div id="qrcode"></div>
<hr/>

<h4>email & auth-code validation</h4>
check email: <button onclick="checkEmail()">check email</button><br/>
validate auth-code: <button onclick="checkCode()">validate auth-code</button><br/>
-<br/>
request auth-code for registered email: <button onclick="requestCode()">request auth-code</button><br/>
<hr/>

<h4>etc api test</h4>
request create options: <button
onclick="requestCreateOptions()">/passkey/create</button><br/>
request request options: <button
onclick="requestRequestOptions()">/passkey/request</button><br/>
-<br/>
cancel in progress QRToken: <button onclick="cancelQRToken()">cancel QRToken</button>
<hr/>
<textarea id="txlog" readonly></textarea>
</body>
</html>