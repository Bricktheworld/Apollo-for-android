import 'package:flutter/material.dart';

class AccountPageView extends StatefulWidget {
  AccountPageView({Key key}) : super(key: key);

  @override
  _AccountPageViewState createState() => _AccountPageViewState();
}

class _AccountPageViewState extends State<AccountPageView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
      ),
    );
  }
}
