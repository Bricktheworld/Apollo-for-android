import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import './pages/front_page_view.dart';
import './hex_color.dart';
import 'package:provider/provider.dart';
import 'package:draw/draw.dart';
import './pages/home_view.dart';
import './AuthModel.dart';
import './pages/subreddit_list.dart';
import 'package:cupertino_back_gesture/cupertino_back_gesture.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

enum UniLinksType { string, uri }

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  dispose() {
    super.dispose();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthModel>(
        create: (context) => AuthModel(),
        child: MaterialApp(
          theme: ThemeData(
              primaryColor: HexColor("1b202a"),
              secondaryHeaderColor: HexColor("FF6C00"),
              primaryColorDark: HexColor("1b202a"),
              backgroundColor: HexColor("#2C3038"),
              canvasColor: Colors.transparent,
              accentColor: HexColor('7b7f8a'),
              // splashColor: HexColor(""),
              splashFactory: InkRipple.splashFactory,
              pageTransitionsTheme: PageTransitionsTheme(builders: {
                TargetPlatform.android:
                    CupertinoPageTransitionsBuilderCustomBackGestureWidth(),
                TargetPlatform.iOS:
                    CupertinoPageTransitionsBuilderCustomBackGestureWidth(),
              })),
          home: Consumer<AuthModel>(builder: (context, model, child) {
            return HomeView(
              model: model,
            );
          }),
        ));
  }
}
