import 'package:flutter/material.dart';

import '../custom_app_bar.dart';

class MailPageView extends StatefulWidget {
  MailPageView({Key key}) : super(key: key);

  @override
  _MailPageViewState createState() => _MailPageViewState();
}

class _MailPageViewState extends State<MailPageView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: CustomAppBar(title: 'Inbox'),
      ),
    );
  }
}
