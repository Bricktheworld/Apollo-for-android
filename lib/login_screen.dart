import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

class LoginScreen extends StatefulWidget {
  final String redirectUri;
  final String loginUri;
  final Function callback;

  const LoginScreen({Key key, this.redirectUri, this.loginUri, this.callback})
      : super(key: key);

  @override
  _LoginScreenState createState() => new _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final flutterWebviewPlugin = new FlutterWebviewPlugin();

  StreamSubscription _onDestroy;
  StreamSubscription<String> _onUrlChanged;
  StreamSubscription<WebViewStateChanged> _onStateChanged;

  String token;

  @override
  void dispose() {
    // Every listener should be canceled, the same should be done with this stream.
    _onDestroy.cancel();
    _onUrlChanged.cancel();
    _onStateChanged.cancel();
    flutterWebviewPlugin.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // flutterWebviewPlugin.close();

    // Add a listener to on destroy WebView, so you can make came actions.
    _onDestroy = flutterWebviewPlugin.onDestroy.listen((_) {
      print("destroy");
    });

    _onStateChanged =
        flutterWebviewPlugin.onStateChanged.listen((WebViewStateChanged state) {
      print("onStateChanged: ${state.type} ${state.url}");
    });

    // Add a listener to on url changed
    _onUrlChanged = flutterWebviewPlugin.onUrlChanged.listen((String url) {
      setState(() {
        print("URL changed: $url");
        if (url.startsWith(widget.redirectUri)) {
          RegExp regExp = new RegExp("code=(.*)");
          this.token = regExp.firstMatch(url)?.group(1);
          print("token $token");

          _saveToken(token);
          Navigator.of(context).pushNamedAndRemoveUntil(
              "/home", (Route<dynamic> route) => false);
          flutterWebviewPlugin.close();
        }
      });
    });
  }

  _saveToken(token) {
    token = token;
    widget.callback(token);
  }

  @override
  Widget build(BuildContext context) {
    return new WebviewScaffold(
        url: widget.loginUri,
        appBar: new AppBar(
          title: new Text("Login to Reddit"),
        ));
  }
}
