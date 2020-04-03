import 'package:flutter/material.dart';

import '../custom_app_bar.dart';

class SettingsPageView extends StatefulWidget {
  SettingsPageView({Key key}) : super(key: key);

  @override
  _SettingsPageViewState createState() => _SettingsPageViewState();
}

class _SettingsPageViewState extends State<SettingsPageView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: CustomAppBar(title: 'Settings'),
    );
  }
}
