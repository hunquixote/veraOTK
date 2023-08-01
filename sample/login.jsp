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
	
	<script src="https://svc.passkeys.kr/client/js/wizvera-passkeys.js"></script>
	<script type="text/javascript">
	// 이용기관 식별자: 31baeff4-39a5-47a7-aaff-528efe9e94e3
	// clientId: app.wizvera.com
	var passkeyClient = null;
	var options = {
		passkeyServiceRoot: 'https://svc.passkeys.kr/webauthn/api/v1', // (필수) veraOTK api 경로 (default:'/')
		clientid: 'app.wizvera.com',  // (필수) 서비스 등록후 서버로부터 발급받은 서비스id (default:'')
		origin: 'local.wizvera.com',  // (필수) client origin (필수, default:'windows.location.hostname')
		email: 'test@wizvera.com',    // 설정시 register(), assertion()등의 함수호출시 생략가능
		phoneNumber: '010-7777-8888', // 설정시 register(), assertion()등의 함수호출시 생략가능
		userHandle: '',               // 서버에 등록후 발급된 사용자 handle, 설정시 assertion() 함수호출시 생략가능
		qrToken: '',                  // 서버로에서 발급받은 QR토큰, QR코드를 통한 veraOTP 등록/인증에 사용
		qrTokenCheckInterval: 3000,   // QR토큰 상태확인 유효시간(milliseconds)(default:3000)
		useExternalQRCodeLibrary: false, // 외부 QR코드 생성 라이브러리 사용여부 (true: QR URL, false: QR URL+이미지)
										 // 내장QR코드: https://github.com/soldair/node-qrcode
		qrTokenClassifier: function() { // QR코드 사용여부 판단하는 함수 오버라이딩 설정
			//true 리턴하면 QR코드 사용, false 리턴하면 장치에 내장된 PasskeyAuthenticator 사용
		},
		qrcodeOptions: {			  // QR코드 이미지 생성시 세부 설정 (default: {"width":300})
			//version: '',
			//errorCorrectionLevel: 'M',
			//maskPattern,
			//margin: 4,
			//scale: 4,
			//small: false,
			width: 300,
			color: {
				//dark: #000000ff,
				//light: #ffffffff
			}
		},
		qrTokenProcessURL: '',	
		// (필수) QR토큰 생성시 사용되는 기본URL (qrToken 설정시 생략가능)
		// QR코드 이미지 URL: <qrTokenProcessURL>?qrToken=<qrToken>&type=<qrTokenType>
		qrCodeHandler: function() { 
		//	(필수) qrTokenClassifier에 의해서 true로 리턴된 경우(QR사용시), 
		//  veraOTP 인증시 veraOTP API 대신 qrCodeHandler가 호출 (qrToken 설정시 생략가능)
		}	
	}
 		
	options.qrTokenClassifier = function() {
   		// userAgent에 Windows가 포함되면 QR코드 사용
   		if(navigator.userAgent.indexOf('Windows') > 0) return true;
   		else return false;
   	}
   	
   	options.qrCodeHandler = function(qrCodeData, qrCodeCanvas) {
   		console.log(qrCodeData);
   		var qrCodeContainer = document.getElementById('qrcode');
   		qrCodeContainer.innerHTML = '';
   		var text = document.createElement('h5');
   		text.innerText = qrCodeData;
   		qrCodeContainer.appendChild(text);
   		// useExternalQRCodeLibrary true면 qrCodeCanvas는 undefined가 리턴됨
   		if(options.useExternalQRCodeLibrary !== true) {
   			qrCodeContainer.appendChild(qrCodeCanvas);
   		}
   	}
   	
	try {
		WizveraPasskeys.IsSupportPasskey();
		passkeyClient = new WizveraPasskeys(options);
	} catch (error) {
		if(error.name === 'NotSupportError') {
			alert('VeraOTK를 지원하지 않는 환경입니다.');
			//return;
		}
	}
	</script>
</head>
<body>
	<script type="text/javascript">
		
		// 사용자 확인(인증코드 발송)
		function TEST_checkUser() {
			if(!passkeyClient) {
				alert('initialize error');
				return;
			}
			var email = document.getElementById('email').value.trim();
			passkeyClient.checkUser({
				email: email
			}).then(function(res) {
				writeLog('등록된 사용자입니다.');
			}).catch(function(error) {
				if(error.name === 'Serviceerror' && error.code === 1005) {
					// 인증코드 발송됨. 인증코드 입력후 검증
					writeLog('해당 메일로 인증코드가 발송되었습니다.');
				}
			});
		}
		
		// 인증코드 확인
		function TEST_verifyAuthCode() {
			if(!passkeyClient) {
				alert('initialize error');
				return;
			}
			var authCode = document.getElementById('authCode').value.trim();
			passkeyClient.verifyAuthCode({
				authCode: authCode
			}).then(function(res) {				
				writeLog('인증코드 정상 확인'); // email 패스키서버에 등록완료
			}).catch(function(error) {
				errorHandler(error);
			});
		}
		
		// 사용자 재확인
		function TEST_requestAuthCode() {
			if(!passkeyClient) {
				alert('initialize error');
				return;
			}
			var email = document.getElementById('email2').value.trim();
			passkeyClient.requestAuthCode({
				email: email
			}).then(function(res) {				
				writeLog('인증코드 발송');
			}).catch(function(error) {
				errorHandler(error);
			});
		}

		// QR인증 취소
		function TEST_cancelQRToken() {
			if(!passkeyClient) {
				alert('initialize error');
				return;
			}
			var email = document.getElementById('email2').value.trim();
			passkeyClient.cancelQRToken({				
			}).then(function(res) {
				document.getElementById('qrcode').innerHTML = '';
				writeLog('QR인증 취소완료');
			}).catch(function(error) {
				errorHandler(error);
			});
		}
		
		// 패스키 생성/등록
		function TEST_register() {
			if(!passkeyClient) {
				alert('initialize error');
				return;
			}
			var email = document.getElementById('email3').value.trim();
			var phoneNumber = document.getElementById('phoneNumber3').value.trim();
			
			passkeyClient.register({
				email: email,
				phoneNumber: phoneNumber
			}).then(function(result) {
				// result.callbackURL 호출하여 서비스 서버의 사용자DB에 인증정보 동기화 필요
				alert('등록완료');
			}).catch(function(error) {
				errorHandler(error);
			});
		}
		
		// 패스키 인증
		function TEST_assertion() {
			if(!passkeyClient) {
				alert('initialize error');
				return;
			}
			var email = document.getElementById('email4').value.trim();
			var phoneNumber = document.getElementById('phoneNumber4').value.trim();
			
			passkeyClient.assertion({
				email: email,
				phoneNumber: phoneNumber
			}).then(function(result) {
				// result.callbackURL 호출하여 서비스 서버의 사용자DB에 인증정보 동기화 필요
				alert('인증완료');
			}).catch(function(error) {
				errorHandler(error);
			});
		}
		
		passkeysClient.isSupportAutofillUI().then(function(isAvailable) {
			if(isAvailable) {
				enableConditionalUI();
			}
		});
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
			
	</script>

    <div id="checkUser" style="display:block;">
    	<h2>사용자 확인<span style="font-size: small;"></span></h2>
	    <form name="emailForm" method="post">
	   	email:  <input type=text id='email' value='jeonghun.kim@wizvera.com'></input>    	
	        	<input type="button" value="사용자 확인" onclick="javascript:TEST_checkUser();" />
	    </form>
    </div>

    <div id="requestAuthCode" style="display:block;">
    	<h2>사용자 재인증<span style="font-size: small;"></span></h2>
	    <form name="emailForm2" method="post">
	    email: <input type=text id='email2' value='jeonghun.kim@wizvera.com'></input>    	
		       <input type="button" value="사용자 재인증" onclick="javascript:TEST_requestAuthCode();" />
	    </form>
    </div>

    <div id="verifyAuthCode" style="display:block;">
    	<h2>인증코드 확인<span style="font-size: small;"></span></h2>
	    <form name="authCodeForm" method="post">
    	인증코드 입력: <input type=text id='authCode' value='000000'></input>    	
		       	   <input type="button" value="인증코드 확인" onclick="javascript:TEST_verifyAuthCode();" />
	    </form>
    </div>

    <div id="cancelQRToken" style="display:block;">
    	<h2>QR인증 취소<span style="font-size: small;"></span></h2>
	    <form name="cancelQRToken" method="post">
       	   <input type="button" value="QR인증 취소" onclick="javascript:TEST_cancelQRToken();" />
	    </form>
    </div>
    
    <div id="register" style="display:block;">
    	<h2>패스키 생성(등록)<span style="font-size: small;"></span></h2>
	    <form name="register" method="post">
    	email: <input type=text id='email3' value='jeonghun.kim@wizvera.com'></input></br>
    	연락처: <input type=text id='phoneNumber3' value='01072827585'></input>
		       	   <input type="button" value="패스키 등록" onclick="javascript:TEST_register();" />
	    </form>
    </div>

    <div id="assertion" style="display:block;">
    	<h2>패스키 인증<span style="font-size: small;"></span></h2>
	    <form name="assertion" method="post">
    	email: <input type=text id='email4' value='jeonghun.kim@wizvera.com'></input></br>
    	연락처: <input type=text id='phoneNumber4' value='01072827585'></input>
		      <input type="button" id="assertionBtn" value="패스키 인증" onclick="javascript:TEST_assertion();" />
	    </form>
    </div>

	<div id="loginform" style="display:block;">
		<h2>로그인<span style="font-size: small;"></span></h2>
		<form name="loginform" method="post">
			<label for="username">이름:</label>
			<input name="username" id="username" autocomplete="username webauthn"></input>
		</form>	
	</div>
            
</body>
</html>