import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

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
    print("const");
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
  String? _token;
  String _getTokenURL = 'https://flutter-f8ded-default-rtdb.firebaseio.com/home.json';                                           //url to get token from
  String _requestURL =
      'https://flutter-f8ded-default-rtdb.firebaseio.com/home.json';         //url to get request token from
  Function? _loading;

  Function(String token, CasiUser user) _onSuccess =
      (String token, CasiUser user) => {};
  Function(dynamic err) _onError = (dynamic err) => {};

  CasiLogin(String clientId, String accessToken, Function? loading,
      {Function(String token, CasiUser user)? onSuccess,
      Function(dynamic err)? onError}) {
    this.clientId = clientId;
    this._loading = loading;
    this._onSuccess = onSuccess ?? _onSuccess;
    this._onError = onError ?? _onError;
    final claimSet = JwtClaim(
      expiry: new DateTime.now().add(new Duration(minutes: 5)),
      otherClaims: {
        'data': {'clientId': clientId}
      },
    );

    this.secret = issueJwtHS256(claimSet, accessToken);
  }

  CasiLogin.fromToken(String? token) {
    this._token = token;
  }

  Future<void> signIn() async {
    try {
      _loading!(true);
      var requestTokenResponse = await http.post(Uri.parse(_requestURL),
          body: json.encode({
            'key1': 'val1',                                        //POST request body to get request token
            'key2': 'val2',
          }));
      String requestToken = json.decode(
          requestTokenResponse.body)['name'];                     //Key of request token in response
      print(requestToken);
      _loginURL =
          'https://auth.devclub.in';                              //construct login url using request token

      final ChromeSafariBrowser webview = new Webview(
          getTokenURL: _getTokenURL,
          fetchUserDetails: fetchUserDetails,
          onSuccess: this._onSuccess,
          onError: this._onError,
          secret: this.secret,
          loading: _loading
          );

      await webview.open(
          url: Uri.parse(_loginURL),
          options: ChromeSafariBrowserClassOptions(
              android: AndroidChromeCustomTabsOptions(
                  addDefaultShareMenuItem: false, enableUrlBarHiding: true),
              ios: IOSSafariOptions(barCollapsingEnabled: true)));
      _loading!(false);
    } catch (e) {
      _loading!(false);
      this._onError("login failed");
      print(e);
    }
  }

  Future<CasiUser> fetchUserDetails(String token) async {
    print(token);
    
    // final response = await http.post(Uri.parse("https://casi-user-api.herokuapp.com/api/getUser"),     //test, uncomment for testing
    // body: json.encode({                                                                                //manual login (without refresh token).
    //   "key": "val"                                                                                     //test
    // })                                                                                                 //test
    // );                                                                                                 //test
    // final jsonData = json.decode(response.body);                                                       //test
    // print(jsonData['user']);                                                                           //test
    // print("user detail fetched");                                                                      //test
    // return CasiUser.fromJson(jsonData['user']);                                                        //test    

    final response =                                                                     //actual
        await http.post(Uri.parse(this._serverUrl + '/profile'), headers: {              //actual
      'Cookie': "rememberme=${token};",                                                  //actual
    });                                                                                  //actual
    final jsonData = jsonDecode(response.body);                                          //actual
    if (response.statusCode == 200) {                                                    //actual
      print('user detail fetched');                                                      //actual
      return CasiUser.fromJson(jsonData['user']);                                        //actual
    } else {                                                                             //actual
      throw Exception(jsonData['msg']);                                                  //actual
    }                                                                                    //actual
  }

  Future<CasiUser> refreshToken(
      {Function(String token)? onRefreshSuccess}) async {
    if (_token == null) throw Exception("No token found");
    String? toSendToken = _token;

    // final response = await http.post(Uri.parse("https://casi-user-api.herokuapp.com/api/getUser"),   //test, uncomment for testing
    //   body: json.encode({                                                                            //refresh token functions.
    //     'key': 'val',                                                                                //This API will always return
    //   })                                                                                             //a response similar to that returned
    // );                                                                                               //by CASI on posting the token.
    // final jsonData = json.decode(response.body);                                                     //test
    // return CasiUser.fromJson(jsonData['user']);                                                      //test
    
    final response = await http.post(                                                             //actual                
        Uri.parse(this._serverUrl + '/auth/refresh-token'),                                       //actual
        body: {'rememberme': toSendToken});                                                       //actual
    final jsonData = jsonDecode(response.body);                                                   //actual
    if (response.statusCode == 200) {                                                             //actual
      if (onRefreshSuccess != null) {                                                             //actual
        onRefreshSuccess(                                                                         //actual
            response.headers['set-cookie']!.split(';')[0].split('=')[1]);                         //actual
      }                                                                                           //actual
      return CasiUser.fromJson(jsonData['user']);                                                 //actual
    } else {                                                                                      //actual
      throw Exception(jsonData['msg']);                                                           //actual
    }                                                                                             //actual
  }
}

class Webview extends ChromeSafariBrowser {
  String getTokenURL;
  Function fetchUserDetails;
  Function onSuccess;
  Function onError;
  String secret;
  Function? loading;
  Webview(
      {
      required this.getTokenURL,
      required this.fetchUserDetails,
      required this.onSuccess,
      required this.onError,
      required this.secret,
      required this.loading,
      }
  );

  @override
  void onClosed() async {
    try {
      loading!(true);
      var tokenResponse = await http.post(Uri.parse(getTokenURL),
          body: json.encode({
            'key1': 'val1',                                      //POST request body to get oauth token
            'key2': 'val2',
          }));

      String token = json.decode(
          tokenResponse.body)['name'];                           //Enter json key of token in response
      print(token);
      print("ok");
      CasiUser user = await fetchUserDetails(token);
      loading!(false);
      print("x");
      this.onSuccess(token, user);
    } catch (e) {
      loading!(false);
      print("edg");
      this.onError("login failed");
    }
  }
}
