import 'package:apollo/custom_app_bar.dart';
import 'package:apollo/slidable_comment_tile.dart';
import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
import 'dart:async';

import '../post_view.dart';
import '../slidable_list_tile.dart';

class UpvotedPostsView extends StatefulWidget {
  final Redditor currentUser;

  UpvotedPostsView({Key key, this.currentUser}) : super(key: key);

  @override
  _UpvotedPostsViewState createState() => _UpvotedPostsViewState();
}

class _UpvotedPostsViewState extends State<UpvotedPostsView> {
  List _posts = [];
  StreamSubscription<UserContent> _stream;
  bool _alreadyLoading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadPosts();
  }

  _loadPosts() async {
    debugPrint("loading");
    int i = 0;
    String after;
    if (_posts.length > 1) {
      after = _posts.last.fullname;
    } else {
      after = null;
    }
    if (_stream != null) _stream.cancel();
    _stream =
        widget.currentUser.upvoted(limit: 25, after: after).listen((s) async {
      i++;
      _posts.add(s);
      if (i >= 25) {
        _alreadyLoading = false;
        debugPrint("finished loading 25");
        if (this.mounted) setState(() {});
        _stream.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        appBar: CustomAppBar(
          title: "Upvoted",
        ),
        backgroundColor: Theme.of(context).backgroundColor,
        body: ListView.builder(
          physics: BouncingScrollPhysics(),
          itemCount: _posts.length,
          itemBuilder: (BuildContext context, int index) {
            if (index > _posts.length - 10 && !_alreadyLoading) {
              _alreadyLoading = true;
              debugPrint("loading more: " + _posts.length.toString());
              _loadPosts();
            }
            if (_posts[index] is Submission) {
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
                onTap: () {
                  // debugPrint(post.toString());
                  // debugPrint(post.data.toString());
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostView(
                        submission: post,
                        comments: post.comments,
                        numComments: post.numComments,
                      ),
                    ),
                  );
                },
              );
            } else if (_posts[index] is Comment) {
              Comment comment = _posts[index];
              return SlidableCommentTile(
                comment: comment,
                children: <Widget>[],
                depth: 0,
              );
              // debugPrint(_posts[index].toString());
              // return Container();
            } else {
              return Container();
            }
          },
        ),
      ),
    );
  }
}
