import 'dart:ui';
import 'dart:convert';
import 'dart:async';

import 'package:apollo/hex_color.dart';
import 'package:apollo/post_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:draw/draw.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:uni_links/uni_links.dart';
import 'package:flutter/services.dart' show PlatformException;

import '../page_route.dart';
import './front_page_view.dart';
import './mail_page_view.dart';
import './account_page_view.dart';
import './settings_page_view.dart';
import './search_page_view.dart';
import '../AuthModel.dart';
import './subreddit_list.dart';

class HomeView extends StatefulWidget {
  final AuthModel model;
  const HomeView({Key key, this.model}) : super(key: key);
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  PersistentTabController _controller;

  String _latestLink = 'Unknown';
  Uri _latestUri;

  StreamSubscription _sub;

  @override
  void initState() {
    _controller = PersistentTabController(initialIndex: 0);
    super.initState();
    initPlatformState();
    // widget.model.reddit.user.me().then((Redditor redditor) {
    //   debugPrint(redditor.displayName);
    // });
  }

  @override
  void dispose() {
    if (_sub != null) _sub.cancel();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.

  initPlatformState() async {
    await initPlatformStateForStringUniLinks();
  }

  /// An implementation using a [String] link
  initPlatformStateForStringUniLinks() async {
    // Attach a listener to the links stream
    _sub = getLinksStream().listen((String link) {
      // if (!mounted) return;
      setState(() {
        _latestLink = link ?? 'Unknown';
        _latestUri = null;
        debugPrint(_latestLink);
        try {
          if (link != null) _latestUri = Uri.parse(link);
        } on FormatException {}
      });
    }, onError: (err) {
      if (!mounted) return;
      setState(() {
        _latestLink = 'Failed to get latest link: $err.';
        _latestUri = null;
      });
    });

    // Attach a second listener to the stream
    getLinksStream().listen((String link) async {
      debugPrint('got link: $link');
      String url = link
          .substring(link.indexOf('path=') + 5, link.indexOf('&variant='))
          .replaceAll("%2F", "/");
      debugPrint("https://reddit.com" + url);

      SubmissionRef submissionRef =
          SubmissionRef.withPath(widget.model.reddit, url);
      Submission submission = await submissionRef.populate();
      Navigator.push(
        context,
        TransparentRoute(
          builder: (context) => PostView(
            submission: submission,
            comments: submission.comments,
            numComments: submission.numComments,
          ),
        ),
      );
      // debugPrint(submission.data.toString());
      // widget.model.loadPostFromLink(link);
    }, onError: (err) {
      print('got err: $err');
    });

    // Get the latest link
    String initialLink;
    Uri initialUri;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      initialLink = await getInitialLink();
      debugPrint('initial link: $initialLink');
      if (initialLink != null) {
        String url = initialLink
            .substring(initialLink.indexOf('path=') + 5,
                initialLink.indexOf('&variant='))
            .replaceAll("%2F", "/");
        debugPrint("https://reddit.com" + url);

        SubmissionRef submissionRef =
            SubmissionRef.withPath(widget.model.reddit, url);
        Submission submission = await submissionRef.populate();
        Navigator.push(
          context,
          TransparentRoute(
            builder: (context) => PostView(
              submission: submission,
              comments: submission.comments,
              numComments: submission.numComments,
            ),
          ),
        );
      }
      if (initialLink != null) initialUri = Uri.parse(initialLink);
    } on PlatformException {
      initialLink = 'Failed to get initial link.';
      initialUri = null;
    } on FormatException {
      initialLink = 'Failed to parse the initial link as Uri.';
      initialUri = null;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _latestLink = initialLink;
      _latestUri = initialUri;
    });
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
