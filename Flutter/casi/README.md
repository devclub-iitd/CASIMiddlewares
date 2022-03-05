# FlutterCASI

A sample flutter mobile app to integrate [CASI](https://auth.devclub.in/) for authentication.

## Setup

1. Register your client at [Register](https://auth.devclub.in/client/register) and obtain the `config` file.
2. Copy the file `casi_user.dart` into your project. Make sure that the `minSdkVersion` in `android/app/build.gradle` file in the root project directory is `>=17`. Add the following dependencies to `pubspec.yaml`
 ```
dependencies:
  http: ^0.13.3
  flutter_inappwebview: ^5.3.2
  dart_jsonwebtoken: ^2.4.0
  jwt_decode: ^0.3.1
  flutter_webview_plugin: ^0.4.0
  
  # Optional - Shared Preferences is used in this example app just to store the token.
  shared_preferences: ^2.0.6
```

## Usage

### Classes

#### [`CasiLogin`](https://github.com/alphaaviral/CASIMiddlewares/blob/1295ffca291bda8db85df0d5d76f2559675505b8/Flutter/casi/lib/casi_user.dart#L36) 
This class is responsible for logging in a user through CASI. It has two constructors
1. **Default Constructor**
     - `String clientId` : The client-id in the `config` file given to the client at the time of registration at CASI. For details on how to register visit [Register](https://auth.devclub.in/client/register)
     - `String accessToken` : The client access-token in the `config` file given to the client at the time of registration at CASI.
     - `Function loading`: The callback function when the webview is loading. Takes a `bool` as parameter to perform loading/not-loading action. Function should be defined inside the class containing the widget to be changed on loading.
     - (Optional) `Function onSuccess`: The callback function when the user logs in successfully. [Signature](https://github.com/alphaaviral/CASIMiddlewares/blob/1295ffca291bda8db85df0d5d76f2559675505b8/Flutter/casi/lib/casi_user.dart#L55)
     - (Optional) `Function onError`: The callback function when there is a error in logging in the user. [Signature](https://github.com/alphaaviral/CASIMiddlewares/blob/1295ffca291bda8db85df0d5d76f2559675505b8/Flutter/casi/lib/casi_user.dart#L56)
    
    Use the function [`CasiLogin.signIn`](https://github.com/alphaaviral/CASIMiddlewares/blob/1295ffca291bda8db85df0d5d76f2559675505b8/Flutter/casi/lib/casi_user.dart#L68) of the object to launch a web view that will allow the user to login through CASI.
2. **[`CasiLogin.fromToken`](https://github.com/alphaaviral/CASIMiddlewares/blob/1295ffca291bda8db85df0d5d76f2559675505b8/Flutter/casi/lib/casi_user.dart#L64) constructor:**
   - `String token`: If you already have a token you can instantiate an object of the class with this token.

#### Methods
1. [`CasiLogin.refreshToken`](https://github.com/alphaaviral/CASIMiddlewares/blob/1295ffca291bda8db85df0d5d76f2559675505b8/Flutter/casi/lib/casi_user.dart#L170). Use this function to refresh this token once the class has been initialised with a token. This method will throw an error if there is no token in the object or if the token was invalid. If no error is thrown it will return a `CasiUser` object corresponding to the object of the token. You can provide an optional callback `onRefreshSuccess` to determine what to do with the new token. Also you can use this function to refresh arbitrary tokens by supplying the optional parameter `oldToken`.


#### [`CasiUser`](https://github.com/alphaaviral/CASIMiddlewares/blob/1295ffca291bda8db85df0d5d76f2559675505b8/Flutter/casi/lib/casi_user.dart#L8) 
It is the model class for user data that CASI returns after logging in. You can have a look at its definition to know about the fields that it contains.


#### [`Webview`](https://github.com/alphaaviral/CASIMiddlewares/blob/1295ffca291bda8db85df0d5d76f2559675505b8/Flutter/casi/lib/casi_user.dart#L192)
It extends the ChromeSafariBrowser class and is used to override the default onClosed() method, which is executed when the webview is closed.

### Example
For a better understanding take a look at the [`onPressed`](https://github.com/alphaaviral/CASIMiddlewares/blob/1295ffca291bda8db85df0d5d76f2559675505b8/Flutter/casi/lib/login.dart#L134) to have an idea of what a `Login with CASI` Button should do when pressed.
1. It first extracts the token from `SharedPreferences`. 
2. It uses the `CasiLogin.fromToken` constructor to create an object using the token extracted above.
3. It tries to refresh the token extracted above. If this succeeds then it uses the `CasiUser` object returned by `CasiLogin.refreshToken` to proceed further.
4. If an error was thrown above it is caught and a Login is attempted by the `CasiLogin.signIn` method which uses a web-view to allow the user to login through CASI.

