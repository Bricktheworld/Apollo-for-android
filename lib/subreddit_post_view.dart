import 'package:apollo/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:draw/draw.dart';
import './slidable_list_tile.dart';
import './AuthModel.dart';

class SubredditPostView extends StatefulWidget {
  @required
  final AuthModel model;
  @required
  final Subreddit sub;

  const SubredditPostView({Key key, this.model, this.sub}) : super(key: key);

  @override
  _SubredditPostViewState createState() => _SubredditPostViewState();
}

class _SubredditPostViewState extends State<SubredditPostView> {
  List<Submission> _posts = <Submission>[];
  Redditor currentUser;
  StreamSubscription<UserContent> stream;
  var _postsTemp = <Submission>[];

  listen() async {
    if (stream != null) stream.cancel();
    if (widget.model.subStreams.containsKey(widget.sub)) {
      _posts = widget.model.subStreams[widget.sub].posts;
    } else {
      _posts = <Submission>[];
      setState(() {});
    }
    // await for (UserContent submission in widget.sub.hot()) {
    //   Submission s = await (submission as Submission).populate();
    //   _posts.add(s);
    //   setState(() {});
    //   debugPrint('new post: ' + s.title);
    //   // print(s.body);
    //   // print(s.selftext);
    //   // print(s.url);
    // }

    stream = widget.sub.hot().listen((s) async {
      if (!this.mounted) {
        stream.cancel();
        return;
      }

      if (!_posts.contains(s)) {
        Submission submission = await (s as Submission).populate();
        _posts.add(submission);
        if (_posts.length % 100 == 0 && this.mounted) setState(() {});
        // if (_posts.length > 700) stream.pause();
      }
    });
  }

  @override
  @override
  void initState() {
    super.initState();
    listen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        appBar: CustomAppBar(title: 'r/' + widget.sub.displayName),
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
            onTap: () {},
          );
        },
      ),
      floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 60),
          child: FloatingActionButton(
            onPressed: () async {
              if (widget.model.reddit != null) {
                listen();
              } else {
                widget.model.login(context, listen);
              }
            },
            child: Icon(Icons.refresh),
            backgroundColor: Theme.of(context).secondaryHeaderColor,
          )),
    );
  }
}
