<%-- --------------------------------------------------------------------------
 - File Name   : callback.jsp(로그인 샘플)
 - Include     : 
 - Author      : WIZVERA
 - Last Update : 2023/07/31
-------------------------------------------------------------------------- --%>
<%@page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
	//passkey 트랜잭션 결과조회 API를 사용한 결과 조회
	String txId = request.getParameter("svcTxId");
	String type = request.getParameter("type");
	String accessToken = ACCESS_TOKEN;
	
	URL url = new URL("https://svc.passkeys.kr/webauthn/api/v1/clients/check-tx");
	HttpsURLConnection conn = (HttpsURLConnection) url.openConnection();
	conn.setRequestMethod("POST");
	conn.setRequestProperty("Content-Type", "application/json");
	
	String userHandle = resJson.getString("userHandle");
	System.out.println("userHandle=[" + userHandle + "]");
%>
