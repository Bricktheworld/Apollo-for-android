import 'dart:ui';
import 'dart:convert';

import 'package:apollo/hex_color.dart';
import 'package:apollo/post_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:draw/draw.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';

import './front_page_view.dart';
import './mail_page_view.dart';
import './account_page_view.dart';
import './settings_page_view.dart';
import './search_page_view.dart';
import '../AuthModel.dart';
import './subreddit_list.dart';

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  PersistentTabController _controller;

  @override
  void initState() {
    _controller = PersistentTabController(initialIndex: 0);
    super.initState();
  }

  List<PersistentBottomNavBarItem> _tabBarItems() {
    return [
      PersistentBottomNavBarItem(
        icon: Icon(Icons.home),
        title: ("Posts"),
        activeColor: HexColor("237CCA"),
        inactiveColor: Colors.grey,
        isTranslucent: true,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.mail),
        title: ("Inbox"),
        activeColor: HexColor("237CCA"),
        inactiveColor: Colors.grey,
        isTranslucent: true,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.person),
        title: ("Account"),
        activeColor: HexColor("237CCA"),
        inactiveColor: Colors.grey,
        isTranslucent: true,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.search),
        title: ("Search"),
        activeColor: HexColor("237CCA"),
        inactiveColor: Colors.grey,
        isTranslucent: true,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.settings),
        title: ("Settings"),
        activeColor: HexColor("237CCA"),
        inactiveColor: Colors.grey,
        isTranslucent: true,
      ),
    ];
  }

  List<Widget> _buildScreens() {
    return [
      Consumer<AuthModel>(builder: (context, model, child) {
        return SubredditListView(
          model: model,
          preloadSubredditPosts: (List<Subreddit> subs) {
            model.beginPreloadPosts(subs);
          },
        );
      }),
      Consumer<AuthModel>(builder: (context, model, child) {
        return MailPageView();
      }),
      Consumer<AuthModel>(builder: (context, model, child) {
        return AccountPageView(model: model);
      }),
      Consumer<AuthModel>(builder: (context, model, child) {
        return SearchPageView(
          model: model,
        );
      }),
      Consumer<AuthModel>(builder: (context, model, child) {
        return SettingsPageView();
      }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      controller: _controller,
      items: _tabBarItems(),
      screens: _buildScreens(),
      showElevation: false,
      navBarCurve: NavBarCurve.none,
      backgroundColor: Theme.of(context).primaryColor,
      iconSize: 26.0,
      navBarStyle:
          NavBarStyle.style1, // Choose the nav bar style with this property
      onItemSelected: (index) {
        print(index);
      },
      // bottomSheet: BottomNavBar(),
    );
  }
}
