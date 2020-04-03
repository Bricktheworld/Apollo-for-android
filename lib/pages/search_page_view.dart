import 'package:flutter/material.dart';

import '../custom_app_bar.dart';

class SearchPageView extends StatefulWidget {
  SearchPageView({Key key}) : super(key: key);

  @override
  _SearchPageViewState createState() => _SearchPageViewState();
}

class _SearchPageViewState extends State<SearchPageView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: CustomAppBar(title: 'Search'),
    );
  }
}
