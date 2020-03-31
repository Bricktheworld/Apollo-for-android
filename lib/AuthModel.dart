import 'dart:async';

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
  Stream<UserContent> stream;
  Map<Subreddit, SubPreload> subStreams = Map();

  void updateReddit(Reddit client) {
    reddit = client;
    notifyListeners();
  }

  login(BuildContext context, Function callback) async {
    debugPrint('attempting to log in');
    final userAgent =
        'android:com.bricktheworld.github.apollo:v0.0.2 (by /u/bricktheworld)';
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

      final authUrl = redditTemp.auth
          .url(['*'], 'aslkdjflakwejfoiaehroijaewofire', compactLogin: true);
      Navigator.push(
          context,
          MaterialPageRoute(
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

  preloadSubredditPosts(Subreddit data) async {
    if (subStreams.containsKey(data)) return;
    SubPreload subStream = new SubPreload();
    subStream.stream = data.hot();
    // await for (UserContent s in data.hot()) {
    //   subStream.posts.add(s);
    //   if (subStream.posts.length >= 100) {
    //     // subStream.subscription.cancel();

    //     notifyListeners();
    //     debugPrint(data.displayName +
    //         " preloaded " +
    //         subStream.posts.length.toString() +
    //         " posts");
    //     return;
    //   }
    // }
    subStream.subscription = subStream.stream.listen((s) {
      subStream.posts.add(s);
      if (subStream.posts.length >= 100) {
        subStream.subscription.cancel();

        // notifyListeners();
        debugPrint(data.displayName +
            " preloaded " +
            subStream.posts.length.toString() +
            " posts");
      }
    });
    subStreams[data] = subStream;
  }
}

class SubPreload {
  Stream<UserContent> stream;
  StreamSubscription<UserContent> subscription;
  List<Submission> posts = <Submission>[];
}
