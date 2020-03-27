import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import './front_page_view.dart';
import './hex_color.dart';
import 'package:provider/provider.dart';
import 'package:draw/draw.dart';
import './home_view.dart';
import './AuthModel.dart';
import 'package:cupertino_back_gesture/cupertino_back_gesture.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthModel>(
        create: (context) => AuthModel(),
        child: BackGestureWidthTheme(
            backGestureWidth: BackGestureWidth.fraction(1),
            child: MaterialApp(
                theme: ThemeData(
                    primaryColor: HexColor("1b202a"),
                    secondaryHeaderColor: HexColor("FF6C00"),
                    primaryColorDark: HexColor("1b202a"),
                    backgroundColor: HexColor("#2C3038"),
                    canvasColor: Colors.transparent,
                    // splashColor: HexColor(""),
                    splashFactory: InkRipple.splashFactory,
                    pageTransitionsTheme: PageTransitionsTheme(builders: {
                      TargetPlatform.android:
                          CupertinoPageTransitionsBuilderCustomBackGestureWidth(),
                      TargetPlatform.iOS:
                          CupertinoPageTransitionsBuilderCustomBackGestureWidth(),
                    })),
                home: new HomeView())));
  }
}
