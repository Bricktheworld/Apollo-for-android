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

  beginPreloadPosts(List<Subreddit> data) {
    subs = data;
    preloadSubredditPosts(0);
  }

  preloadSubredditPosts(int index) async {
    // if (subStreams.containsKey(data)) return;
    int numCompleted = 0;
    int numberOfSimultaneousStreams = 3;
    for (int i = 0; i < 3; i++) {
      if (index + i < subs.length) {
        // debugPrint("loading " + subs[index + i].displayName);
        SubPreload subStream = new SubPreload();
        subStream.stream = subs[index + i].hot(limit: 25);

        subStream.subscription = subStream.stream.listen((s) {
          Submission post = s;
          // post.refreshComments();
          subStream.posts.add(post);

          if (subStream.posts.length >= 25) {
            subStream.subscription.cancel();
            subStreams[subs[index + i].id] = subStream;
            // callback();
            numCompleted++;

            notifyListeners();
            // debugPrint(subs[index + i].displayName +
            //     " preloaded " +
            //     subStream.posts.length.toString() +
            //     " posts");
            if (numCompleted >= numberOfSimultaneousStreams) {
              if (numberOfSimultaneousStreams == 3) {
                preloadSubredditPosts(
                  index + 3,
                );
              } else {
                debugPrint("finished loading");
              }
            }
            // if (index + 1 < subs.length) {
            //   preloadSubredditPosts(index + 1);
            // }

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
