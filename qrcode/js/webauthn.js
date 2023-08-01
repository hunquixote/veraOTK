(function (global, undefined) {
    "use strict";

    function detectWebAuthnSupport() {
        if (window.PublicKeyCredential === undefined ||
            typeof window.PublicKeyCredential !== "function") {
            var errorMessage = "Oh no! This browser doesn't currently support WebAuthn."
            if (window.location.protocol === "http:" && (window.location.hostname !== "localhost" && window.location.hostname !== "127.0.0.1")) {
                errorMessage = "WebAuthn only supports secure connections. For testing over HTTP, you can use the origin \"localhost\"."
            }
            alert(errorMessage);
            return false;
        }
        return true;
    }

    function string2buffer(str) {
        return (new Uint8Array(str.length)).map(function (x, i) {
            return str.charCodeAt(i)
        });
    }

    // Encode an ArrayBuffer into a base64 string.
    function bufferEncode(value) {
        return base64js.fromByteArray(value)
            .replace(/\+/g, "-")
            .replace(/\//g, "_")
            .replace(/=/g, "");
    }

    // Don't drop any blanks
    // decode
    function bufferDecode(value) {
        return Uint8Array.from(atob(
            value.replace(/\-/g, "+")
                .replace(/\_/g, "/")), c => c.charCodeAt(0));
    }

    function buffer2string(buf) {
        let str = "";
        if (!(buf.constructor === Uint8Array)) {
            buf = new Uint8Array(buf);
        }
        buf.map(function (x) {
            return str += String.fromCharCode(x)
        });
        return str;
    }

    function sendRequest(url, data, cb) {
        var xhr = new XMLHttpRequest();
        xhr.open("POST", url, true);
        xhr.withCredentials = true;
        xhr.setRequestHeader('content-type', 'application/json; charset=UTF-8');

        xhr.onreadystatechange = function (e) {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;

            if (xhr.status === 200) {
                cb(JSON.parse(xhr.responseText));
            }
            else {
                console.error(e);
            }
        }

        xhr.send(JSON.stringify(data));
    }

    function getPublicKeyCredentialRequestOptions(userData, callback) {
        var url = '/webauthn/webauthn/request';
        sendRequest(url, userData, callback);
    }

    function getPublicKeyCredentialCreationOptions(userData, callback) {
        var url = '/webauthn/webauthn/create';
        sendRequest(url, userData, callback);
    }

    function registerCredential(attestationResponse, callback) {
        var url = '/webauthn/webauthn/register';
        sendRequest(url, attestationResponse, callback);
    }

    function assertCredential(assertionResponse, callback) {
        var url = '/webauthn/webauthn/assertion';
        sendRequest(url, assertionResponse, callback);
    }

    function getPublicKeyCredentialRequestOptionsWithQR(userData, callback) {
        var url = '/webauthn/webauthn/request-with-qr';
        sendRequest(url, userData, callback);
    }

    function getPublicKeyCredentialCreationOptionsWithQR(userData, callback) {
        var url = '/webauthn/webauthn/create-with-qr';
        sendRequest(url, userData, callback);
    }

    function registerCredentialWithQR(attestationResponse, callback) {
        var url = '/webauthn/webauthn/register-with-qr';
        sendRequest(url, attestationResponse, callback);
    }

    function assertCredentialWithQR(assertionResponse, callback) {
        var url = '/webauthn/webauthn/assertion-with-qr';
        sendRequest(url, assertionResponse, callback);
    }

    function register(callback) {
        getPublicKeyCredentialCreationOptions({}, function (result) {
            if (result.code != 0) {
                callback(result);
                return;
            }

            result = result.data;

            result.challenge = bufferDecode(result.challenge);
            result.user.id = bufferDecode(result.user.id);

            if (result.excludeCredentials) {
                if (result.excludeCredentials.length > 0) {
                    callback({ code: 1004, message: 'this user already owns the passkey.' })
                    return;
                }

                for (var i = 0; i < result.excludeCredentials.length; i++) {
                    result.excludeCredentials[i].id = bufferDecode(result.excludeCredentials[i].id);
                }
            }

            result.authenticatorSelection = result.authenticatorSelection || {
                //authenticatorAttachment: "cross-platform", //!!! 
                residentKey: "preferred",                  //!!!
                userVerification: "preferred"              //!!!
            };

            result.extensions = {
                credProps: true,
            };

            navigator.credentials.create({
                publicKey: result,
            }).then(function (credential) {

                var attestation = {
                    id: bufferEncode(new Uint8Array(credential.rawId)),
                    response: {
                        clientDataJSON: bufferEncode(new Uint8Array(credential.response.clientDataJSON)),
                        attestationObject: bufferEncode(new Uint8Array(credential.response.attestationObject)),
                    }
                };

                var transports = [];
                if (credential.response.getTransports) transports = credential.response.getTransports();
                var extensions = credential.getClientExtensionResults();

                attestation.transports = transports
                attestation.extensions = extensions;

                registerCredential(attestation, function (result) {
                    callback(result);
                });
            }).catch(function (error) {
                console.error(error);
                alert(error.message || 'error');
            });
        });
    }

    function auth(callback) {
        getPublicKeyCredentialRequestOptions({}, function (result) {
            if (result.code != 0) {
                callback(result);
                return;
            }

            result = result.data;
            result.challenge = bufferDecode(result.challenge);
            if (result.allowCredentials) {
                for (var i = 0; i < result.allowCredentials.length; i++) {
                    result.allowCredentials[i].id = bufferDecode(result.allowCredentials[i].id);
                }
            }

            navigator.credentials.get({
                publicKey: result
            }).then(function (credential) {
                var assertion = {
                    id: bufferEncode(new Uint8Array(credential.rawId)),
                    response: {
                        clientDataJSON: bufferEncode(new Uint8Array(credential.response.clientDataJSON)),
                        authenticatorData: bufferEncode(new Uint8Array(credential.response.authenticatorData)),
                        signature: bufferEncode(new Uint8Array(credential.response.signature)),
                        userHandle: bufferEncode(new Uint8Array(credential.response.userHandle)),
                    }
                };

                //var buffer = credential.getClientExtensionResults();

                assertCredential(assertion, function (result) {
                    callback(result);
                });

            }).catch(function (error) {
                console.error(error);
                alert(error.message || 'error');
            });
        });
    }

    function registerWithQR(qrToken, callback) {
        getPublicKeyCredentialCreationOptionsWithQR({ qrToken: qrToken }, function (result) {
            if (result.code != 0) {
                callback(result);
                return;
            }

            result = result.data;

            result.challenge = bufferDecode(result.challenge);
            result.user.id = bufferDecode(result.user.id);

            if (result.excludeCredentials) {
                if (result.excludeCredentials.length > 0) {
                    callback({ code: 1004, message: 'this user already owns the passkey.' })
                    return;
                }

                for (var i = 0; i < result.excludeCredentials.length; i++) {
                    result.excludeCredentials[i].id = bufferDecode(result.excludeCredentials[i].id);
                }
            }
            result.authenticatorSelection = result.authenticatorSelection || {
                //authenticatorAttachment: "cross-platform", //!!! 
                residentKey: "preferred",                  //!!!
                userVerification: "preferred"              //!!!
            };

            result.extensions = {
                credProps: true,
            };

            navigator.credentials.create({
                publicKey: result,
            }).then(function (credential) {

                var attestation = {
                    id: bufferEncode(new Uint8Array(credential.rawId)),
                    response: {
                        clientDataJSON: bufferEncode(new Uint8Array(credential.response.clientDataJSON)),
                        attestationObject: bufferEncode(new Uint8Array(credential.response.attestationObject)),
                    }
                };

                var transports = [];
                if (credential.response.getTransports) transports = credential.response.getTransports();
                var extensions = credential.getClientExtensionResults();

                attestation.transports = transports
                attestation.extensions = extensions;

                registerCredentialWithQR(attestation, function (result) {
                    callback(result);
                });
            }).catch(function (error) {
                console.error(error);
                alert(error.message || 'error');
            });
        });
    }

    function authWithQR(qrToken, callback) {
        getPublicKeyCredentialRequestOptionsWithQR({ qrToken: qrToken }, function (result) {
            if (result.code != 0) {
                callback(result);
                return;
            }

            result = result.data;
            result.challenge = bufferDecode(result.challenge);
            if (result.allowCredentials) {
                for (var i = 0; i < result.allowCredentials.length; i++) {
                    result.allowCredentials[i].id = bufferDecode(result.allowCredentials[i].id);
                }
            }

            navigator.credentials.get({
                publicKey: result
            }).then(function (credential) {
                var assertion = {
                    id: bufferEncode(new Uint8Array(credential.rawId)),
                    response: {
                        clientDataJSON: bufferEncode(new Uint8Array(credential.response.clientDataJSON)),
                        authenticatorData: bufferEncode(new Uint8Array(credential.response.authenticatorData)),
                        signature: bufferEncode(new Uint8Array(credential.response.signature)),
                        userHandle: bufferEncode(new Uint8Array(credential.response.userHandle)),
                    }
                };

                //var buffer = credential.getClientExtensionResults();

                assertCredentialWithQR(assertion, function (result) {
                    callback(result);
                });

            }).catch(function (error) {
                console.error(error);
                alert(error.message || 'error');
            });
        });
    }

    var obj = { register: register, auth: auth, registerWithQR: registerWithQR, authWithQR: authWithQR };

    if (typeof define === "function" && define.amd)
        define("webauthn/webauthn", obj);
    else if (typeof module !== "undefined" && module.exports)
        module.exports = obj;
    else if (!global.WebAuthn)
        global.WebAuthn = obj;

})(this);
