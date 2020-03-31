import 'dart:ui';

import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({Key key, this.title}) : super(key: key);
  final String title;
  @override
  Widget build(BuildContext context) {
    return PreferredSize(
        preferredSize: Size.fromHeight(50.0),
        child: ClipRRect(
            child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AppBar(
            elevation: 0.0,
            title: new Container(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Text(title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                      fontSize: 15,
                    )),
              ],
            )),
            // backgroundColor: Theme.of(context).primaryColor,
            backgroundColor: Colors.transparent,
          ),
        )));
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
