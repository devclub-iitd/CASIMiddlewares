import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

class CasiUser {
  String username;
  String firstname;
  String lastname;
  String email;
  String? isverified;
  List<String> roles;

  CasiUser({
    required this.email,
    required this.firstname,
    this.isverified,
    required this.lastname,
    required this.roles,
    required this.username,
  });

  factory CasiUser.fromJson(Map<String, dynamic> user) {
    return CasiUser(
      email: user['email'] ?? '',
      firstname: user['firstname'] ?? '',
      lastname: user['lastname'] ?? '',
      roles: List<String>.from(user["roles"].map((x) => x)),
      username: user['username'] ?? '',
    );
  }
}

class CasiLogin {
  String clientId = '';
  String secret = '';
  String _serverUrl = "https://auth.devclub.in";
  String _loginURL = '';
  String _token = '';
  String _requestTokenResponse = '';
  String _requestToken = '';
  String _getTokenURL =
      'https://auth.devclub.in/auth/getAuthToken'; //url to get auth token from
  String _requestURL =
      'https://auth.devclub.in/auth/requestToken'; //url to get request token from
  Function? _loading;

  Function(String token, CasiUser user) _onSuccess =
      (String token, CasiUser user) => {};
  Function(dynamic err) _onError = (dynamic err) => {};

  CasiLogin(String clientId, String accessToken, Function? loading,
      {Function(String token, CasiUser user)? onSuccess,
      Function(dynamic err)? onError}) {
    this.clientId = clientId;
    this._loading = loading;
    this.secret = accessToken;
    this._onSuccess = onSuccess ?? _onSuccess;
    this._onError = onError ?? _onError;
  }

  CasiLogin.fromToken(String? token) {
    this._token = token!;
  }

  Future<void> signIn() async {
    try {
      _loading!(true);
      await getRequestToken();
      print(_requestTokenResponse);
      _loginURL = getLoginURL(_requestTokenResponse);
      bool webviewAvailable = await ChromeSafariBrowser.isAvailable();

      if (webviewAvailable) {
        final ChromeSafariBrowser webview = new Webview(
            getTokenURL: _getTokenURL,
            requestToken: _requestToken,
            fetchUserDetails: fetchUserDetails,
            onSuccess: this._onSuccess,
            onError: this._onError,
            secret: this.secret,
            loading: _loading);

        await webview.open(
            url: Uri.parse(_loginURL),
            options: ChromeSafariBrowserClassOptions(
                android: AndroidChromeCustomTabsOptions(
                    addDefaultShareMenuItem: false, enableUrlBarHiding: true),
                ios: IOSSafariOptions(barCollapsingEnabled: true)));
      } else {
        final webview = new FlutterWebviewPlugin();
        webview.onUrlChanged.listen((url) async {
          if (url.startsWith(this._serverUrl + "/auth/verifyRToken?q=")) {
            webview.close();
            _loading!(true);
            await getToken();
            print(_token);
            CasiUser user = fetchUserDetails(_token);
            _loading!(false);
            this._onSuccess(_token, user);
          }
        });

        await webview.launch(
          _loginURL,
          ignoreSSLErrors: true,
          clearCookies: true,
          clearCache: true,
          userAgent:
              'Mozilla/5.0 (Linux; Android 4.0.4; Galaxy Nexus Build/IMM76B) AppleWebKit/535.19 (KHTML, like Gecko) Chrome/18.0.1025.133 Mobile Safari/535.19',
        );
      }

      _loading!(false);
    } catch (e) {
      _loading!(false);
      this._onError("login failed");
      print(e);
    }
  }

  Future<void> getToken() async {
    final jwt = JWT(
      {'requestToken': _requestToken},
    );
    String tokenJWT =
        jwt.sign(SecretKey(secret), algorithm: JWTAlgorithm.HS256);

    var tokenResponse = await http.post(Uri.parse(_getTokenURL), headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    }, body: {
      'token': tokenJWT,
    });
    this._token = tokenResponse.body;
  }

  Future<void> getRequestToken() async {
    final jwt = JWT(
      {'clientId': clientId},
      issuer: "CASI client",
    );
    String requestJWT =
        jwt.sign(SecretKey(secret), algorithm: JWTAlgorithm.HS256);

    var requestTokenResponse =
        await http.post(Uri.parse(_requestURL), headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    }, body: {
      'jwt': requestJWT,
    });
    this._requestTokenResponse = requestTokenResponse.body;
    Map<String, dynamic> payload = Jwt.parseJwt(_requestTokenResponse);
    this._requestToken = payload['requestToken'];
  }

  String getLoginURL(String requestToken) {
    var loginURL =
        "https://auth.devclub.in/user/login?serviceURL=https://auth.devclub.in/auth/verifyRToken?q=" +
            requestToken;
    return loginURL;
  }

  CasiUser fetchUserDetails(String token) {
    Map<String, dynamic> payload = Jwt.parseJwt(token);
    return CasiUser.fromJson(payload['user']);
  }

  Future<CasiUser> refreshToken(
      {Function(String token)? onRefreshSuccess}) async {
    if (_token == null) throw Exception("No token found");

    String? toSendToken = _token;
    final response = await http.post(
        Uri.parse(this._serverUrl + '/auth/refresh-token'),
        body: {'rememberme': toSendToken});
    final jsonData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      if (onRefreshSuccess != null) {
        onRefreshSuccess(
            response.headers['set-cookie']!.split(';')[0].split('=')[1]);
      }
      return CasiUser.fromJson(jsonData['user']);
    } else {
      throw Exception(jsonData['msg']);
    }
  }
}

class Webview extends ChromeSafariBrowser {
  String getTokenURL;
  String requestToken;
  Function fetchUserDetails;
  Function onSuccess;
  Function onError;
  String secret;
  String _token = '';
  Function? loading;
  Webview({
    required this.getTokenURL,
    required this.requestToken,
    required this.fetchUserDetails,
    required this.onSuccess,
    required this.onError,
    required this.secret,
    required this.loading,
  });

  @override
  void onClosed() async {
    try {
      loading!(true);
      await getToken(requestToken);
      print(_token);
      CasiUser user = fetchUserDetails(_token);
      loading!(false);
      this.onSuccess(_token, user);
    } catch (e) {
      loading!(false);
      this.onError("login failed");
    }
  }

  Future<void> getToken(String requestToken) async {
    final jwt = JWT(
      {'requestToken': requestToken},
    );
    String tokenJWT =
        jwt.sign(SecretKey(secret), algorithm: JWTAlgorithm.HS256);

    var tokenResponse = await http.post(Uri.parse(getTokenURL), headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    }, body: {
      'token': tokenJWT,
    });
    _token = tokenResponse.body;
  }
}
