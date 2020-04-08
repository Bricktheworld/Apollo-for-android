import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

class PopupWebView extends StatefulWidget {
  final String url;
  PopupWebView({
    Key key,
    this.url,
  }) : super(key: key);

  @override
  _PopupWebViewState createState() => _PopupWebViewState();
}

class _PopupWebViewState extends State<PopupWebView> {
  final flutterWebviewPlugin = new FlutterWebviewPlugin();

  StreamSubscription _onDestroy;

  @override
  void dispose() {
    // Every listener should be canceled, the same should be done with this stream.
    _onDestroy.cancel();
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
  }

  @override
  Widget build(BuildContext context) {
    return new WebviewScaffold(
        url: widget.url,
        appBar: new AppBar(
          title: new Text("Some web page"),
        ));
  }
}
