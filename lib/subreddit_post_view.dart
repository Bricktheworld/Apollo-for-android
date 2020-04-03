import 'package:apollo/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:draw/draw.dart';
import './slidable_list_tile.dart';
import './AuthModel.dart';
import './post_view.dart';

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
    if (widget.model.subStreams.containsKey(widget.sub.id)) {
      _posts = widget.model.subStreams[widget.sub.id].posts;
    } else {
      _posts = <Submission>[];
      setState(() {});
    }
    //THIS ISN'T SLOW FOR SOME REASON?????????
    stream = widget.sub.hot(limit: 90).listen((s) async {
      if (!_posts.contains(s)) {
        _posts.add(s);

        // if (_posts.length % 100 == 0) {
        // stream.cancel();
        if (this.mounted) {
          setState(() {});
        } else {
          stream.cancel();
          return;
        }

        // notifyListeners();
        debugPrint(widget.sub.displayName +
            " loaded " +
            _posts.length.toString() +
            " posts");
      }
      // }
    });
  }

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
      body: RefreshIndicator(
          onRefresh: () async {},
          child: ListView.builder(
            shrinkWrap: false,
            physics: BouncingScrollPhysics(),
            itemCount: _posts.length,
            itemBuilder: (BuildContext context, int index) {
              Submission post = _posts[index];
              return SlidableListTile(
                post: post,
                upVote: () {
                  try {
                    post.upvote();
                  } catch (e) {}
                },
                clearVote: () {
                  try {
                    post.clearVote();
                  } catch (e) {}
                },
                // numComments: 0,
                onTap: () {
                  // debugPrint(post.toString());
                  // debugPrint(post.data.toString());
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PostView(
                                submission: post,
                              )));
                },
              );
            },
          )),
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
