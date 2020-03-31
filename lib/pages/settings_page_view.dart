import 'package:flutter/material.dart';

class SettingsPageView extends StatefulWidget {
  SettingsPageView({Key key}) : super(key: key);

  @override
  _SettingsPageViewState createState() => _SettingsPageViewState();
}

class _SettingsPageViewState extends State<SettingsPageView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
      ),
    );
  }
}
