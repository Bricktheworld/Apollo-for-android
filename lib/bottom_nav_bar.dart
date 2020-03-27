import 'dart:ui';

import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRect(
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
                color: Theme.of(context).primaryColor.withOpacity(0.8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    IconButton(
                      padding: EdgeInsets.all(20),
                      icon: Icon(
                        Icons.account_circle,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        print('test');
                      },
                    )
                  ],
                ))));
  }
}
