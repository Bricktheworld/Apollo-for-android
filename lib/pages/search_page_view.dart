import 'package:flutter/material.dart';

class SearchPageView extends StatefulWidget {
  SearchPageView({Key key}) : super(key: key);

  @override
  _SearchPageViewState createState() => _SearchPageViewState();
}

class _SearchPageViewState extends State<SearchPageView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
      ),
    );
  }
}
