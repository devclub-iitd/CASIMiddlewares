import 'dart:convert';

import 'package:casi/casi_user.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

String tokenKey = 'casiToken';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FlutterLogo(size: 150),
                SizedBox(height: 50),
                _signInButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _signInButton() {
    return OutlineButton(
      splashColor: Colors.grey,
      onPressed: onPressed(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      highlightElevation: 0,
      borderSide: BorderSide(color: Colors.grey),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(image: AssetImage("assets/dcLogo.png"), height: 35.0),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                'Continue with CASI',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final CasiUser user;

  const HomeScreen(
    this.user, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Welcome, ${user.username}', style: TextStyle(fontSize: 20)),
              RaisedButton(
                onPressed: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.remove(tokenKey);
                  Navigator.of(context).pop();
                },
                child: Text('Logout'),
                color: Colors.red,
                textColor: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Function onPressed(BuildContext context) {
  return () async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String oldToken = prefs.getString(tokenKey);
    print("OldToken: " + oldToken ?? "");
    String clientId = '5faecde9a36bf00cba428d9b';
    String secret =
        // 'o8ggsY3EeNeCdl0U3izDF1LvR0cU33zopJeFHltapvle8bBChvzHT5miRN23o5v0';
        '4rYPKHaAPMz9ZabR8M6m5rglgySh9v0e3bhiOAAd7DeigV7tfNFzlGHic6FWnZ7D';

    void onLogin(CasiUser user) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(user),
        ),
      );
    }

    try {
      CasiUser user = await CasiLogin.fromToken(oldToken).refreshToken(
          onRefreshSuccess: (String newToken) {
        print("newToken: " + newToken ?? "");
        prefs.setString(tokenKey, newToken);
      });
      onLogin(user);
    } catch (e) {
      await CasiLogin(clientId, secret,
          onSuccess: (String token, CasiUser user) {
        print(token);
        prefs.setString(tokenKey, token);
        onLogin(user);
      }, onError: (dynamic e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('An Error Occured!'),
            content: Text(e.toString()),
            actions: <Widget>[
              FlatButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Try Again'),
              )
            ],
          ),
        );
        print(e);
      }).signIn();
    }
  };
}
