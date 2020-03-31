import 'package:apollo/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:draw/draw.dart';
import './login_screen.dart';
import '../slidable_list_tile.dart';
import '../AuthModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FrontPageView extends StatefulWidget {
  final AuthModel model;
  final Stream<UserContent> stream;

  const FrontPageView({Key key, this.model, this.stream}) : super(key: key);

  @override
  _FrontPageViewState createState() => _FrontPageViewState();
}

class _FrontPageViewState extends State<FrontPageView> {
  List<Submission> _posts = <Submission>[];
  Redditor currentUser;
  StreamSubscription<UserContent> stream;
  var _postsTemp = <Submission>[];

  // var reddit;

  @override
  void initState() {
    super.initState();
    // _attemptToAutoLogIn();
    widget.model.login(context, listen);
  }

  listen() {
    if (stream != null) stream.cancel();
    _posts = <Submission>[];
    setState(() {});
    stream = widget.model.reddit.front.best().listen((s) async {
      _posts.add(s);
      setState(() {});
      if (_posts.length > 700) stream.pause();
    });
  }

  cacheSubreddits(subreddits) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('subreddits', subreddits);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        appBar: CustomAppBar(title: 'Front Page'),
        body: _buildList());
  }

  _buildList() {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: ListView.builder(
        shrinkWrap: false,
        physics: BouncingScrollPhysics(),
        itemCount: _posts.length,
        itemBuilder: (BuildContext context, int index) {
          Submission post = _posts[index];
          return SlidableListTile(
            post: post,
            upVote: () => post.upvote(),
            clearVote: () => post.clearVote(),
            numComments: 0,
          );
        },
      ),
      floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 60),
          child: FloatingActionButton(
            onPressed: () async {
              // _initUser();
              if (widget.model.reddit != null) {
                // stream.cancel();
                // await startFetching();
                debugPrint('already logged in');
                listen();
              } else {
                widget.model.login(context, listen);
              }
              // Add your onPressed code here!
            },
            child: Icon(Icons.refresh),
            backgroundColor: Theme.of(context).secondaryHeaderColor,
          )),
    );
  }
}
