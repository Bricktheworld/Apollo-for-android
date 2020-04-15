import 'dart:async';

import 'package:apollo/page_route.dart';
import 'package:provider/provider.dart';
import 'package:draw/draw.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import './pages/login_screen.dart';

class AuthModel with ChangeNotifier {
  Reddit reddit;
  Redditor user;
  List<Submission> posts;
  List<Subreddit> subs;
  Stream<UserContent> stream;
  Map<String, SubPreload> subStreams = Map();

  void updateReddit(Reddit client) {
    reddit = client;
    notifyListeners();
  }

  login(BuildContext context, Function callback) async {
    if (reddit != null && reddit.auth.isValid) {
      debugPrint('already logged in');
      _startFetching(callback);
    }
    debugPrint('attempting to log in');
    final userAgent =
        'android:com.bricktheworld.github.apollo:v0.0.4 (by /u/bricktheworld)';
    final configUri = Uri.parse('draw.ini');
    final credentialsJson = await loadCredentials();
    if (credentialsJson == null) {
      Reddit redditTemp = Reddit.createWebFlowInstance(
          userAgent: userAgent,
          configUri: configUri,
          clientId: 'zSdAudnVnFwgeQ',
          clientSecret: 'ie1HFUPU4ot57BnRD9f1HECL2rs',
          redirectUri: Uri.parse("https://www.reddit.com/r/android"));
      reddit = redditTemp;
      notifyListeners();

      final authUrl =
          redditTemp.auth.url(['*'], 'logging in', compactLogin: true);
      Navigator.push(
          context,
          TransparentRoute(
              builder: (context) => LoginScreen(
                  loginUri: authUrl.toString(),
                  redirectUri: "https://www.reddit.com/r/android",
                  callback: (data) => {_authUser(data, context, callback)})));
    } else {
      Reddit redditTemp = Reddit.restoreAuthenticatedInstance(credentialsJson,
          userAgent: userAgent,
          clientId: 'zSdAudnVnFwgeQ',
          clientSecret: 'ie1HFUPU4ot57BnRD9f1HECL2rs');
      reddit = redditTemp;
      notifyListeners();
      _startFetching(callback);
    }
  }

  _startFetching(Function callback) {
    callback();
  }

  _authUser(authCode, BuildContext context, Function callback) async {
    await reddit.auth.authorize(authCode);
    await writeCredentials(reddit.auth.credentials.toJson());
    user = await reddit.user.me();
    debugPrint(reddit.auth.credentials.toJson());
    Navigator.of(context).pop();
    _startFetching(callback);
  }

  loadCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    debugPrint(prefs.getString('credentials'));
    return prefs.getString('credentials');
  }

  writeCredentials(cred) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('credentials', cred);
  }

  beginPreloadPosts(List<Subreddit> data) {
    subs = data;
    preloadSubredditPosts(0);
  }

  preloadSubredditPosts(int index) async {
    int numCompleted = 0;
    int numberOfSimultaneousStreams = 3;
    for (int i = 0; i < 3; i++) {
      if (index + i < subs.length) {
        SubPreload subStream = new SubPreload();
        subStream.stream = subs[index + i].hot(limit: 10);

        subStream.subscription = subStream.stream.listen((s) {
          Submission post = s;
          subStream.posts.add(post);

          if (subStream.posts.length >= 10) {
            subStream.subscription.cancel();
            subStreams[subs[index + i].id] = subStream;
            numCompleted++;

            notifyListeners();
            if (numCompleted >= numberOfSimultaneousStreams) {
              if (numberOfSimultaneousStreams == 3) {
                preloadSubredditPosts(
                  index + 3,
                );
              } else {
                debugPrint("finished loading");
              }
            }
          }
        });
      } else {
        numberOfSimultaneousStreams--;
      }
    }
  }
}

class SubPreload {
  Stream<UserContent> stream;
  StreamSubscription<UserContent> subscription;
  List<Submission> posts = <Submission>[];
}
