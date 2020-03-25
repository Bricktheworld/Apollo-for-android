import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import './main_scroll_view.dart';
import './hex_color.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          primaryColor: HexColor("1b202a"),
          primaryColorDark: HexColor("1b202a"),
          // splashColor: HexColor(""),
          splashFactory: InkRipple.splashFactory,
          pageTransitionsTheme: PageTransitionsTheme(builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          })),
      home: MainScrollView(),
    );
  }
}
