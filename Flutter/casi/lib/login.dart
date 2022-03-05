import './casi_user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

String tokenKey = 'casiToken';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  void loading(bool isLoading) {
    if (isLoading)
      setState(() => _isLoading = isLoading);
    else
      Future.delayed(const Duration(milliseconds: 1000), () {
        setState(() => _isLoading = isLoading);
      });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: _isLoading
            ? Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      FlutterLogo(size: 150),
                      SizedBox(height: 50),
                      CircularProgressIndicator(),
                    ],
                  ),
                ),
              )
            : Container(
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
    return OutlinedButton(
      onPressed: onPressed(context, loading),
      style: ButtonStyle(
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
        )),
        side: MaterialStateProperty.all<BorderSide>(
            BorderSide(width: 1, color: Colors.grey)),
      ),
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
    Key? key,
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
              ElevatedButton(
                  onPressed: () async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    prefs.remove(tokenKey);
                    Navigator.of(context).pop();
                  },
                  child: Text('Logout'),
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.red),
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

void Function() onPressed(BuildContext context, Function loading) {
  return () async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? oldToken = prefs.getString(tokenKey);

    String clientId = '5fb37f35c2e2bb00497b4ddd';
    String secret =
        'qQ5kcWMgwURm9t6g00p4Ji5lNKDt6VFz7ekN2Qhy4BtJlRxsWXXmef6n0yrvwIi5';

    void onLogin(CasiUser user) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(user),
        ),
      );
    }

    try {
      loading(true);
      CasiUser user = await CasiLogin.fromToken(oldToken).refreshToken(
          onRefreshSuccess: (String newToken) {
        prefs.setString(tokenKey, newToken);
        print(newToken);
      });
      onLogin(user);
      loading(false);
    } catch (e) {
      await CasiLogin(clientId, secret, loading,
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
              TextButton(
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
