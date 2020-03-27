import 'dart:ui';

import 'package:apollo/hex_color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import './front_page_view.dart';
import './AuthModel.dart';
import './bottom_nav_bar.dart';

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  TabController _tabController;

  @override
  void initState() {
    _tabController = new TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthModel>(builder: (context, model, child) {
        return FrontPageView(
          reddit: model.reddit,
          updateClient: (data) => model.updateReddit(data),
        );
      }),
      bottomSheet: BottomNavBar(),
    );
  }
}
