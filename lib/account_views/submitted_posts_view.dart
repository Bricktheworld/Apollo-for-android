import 'package:apollo/custom_app_bar.dart';
import 'package:apollo/slidable_comment_tile.dart';
import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
import 'dart:async';

import '../post_view.dart';
import '../slidable_list_tile.dart';

class SubmittedPostsView extends StatefulWidget {
  final Redditor currentUser;

  SubmittedPostsView({Key key, this.currentUser}) : super(key: key);

  @override
  _SubmittedPostsViewState createState() => _SubmittedPostsViewState();
}

class _SubmittedPostsViewState extends State<SubmittedPostsView> {
  List _posts = [];
  StreamSubscription<UserContent> _stream;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  _loadPosts() async {
    debugPrint("loading");
    String after;
    if (_posts.length > 1) {
      after = _posts.last.fullname;
    } else {
      after = null;
    }
    if (_stream != null) _stream.cancel();
    _stream = widget.currentUser.stream.submissions().listen((s) async {
      _posts.insert(0, s);
      if (this.mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        appBar: CustomAppBar(
          title: "Submitted",
        ),
        backgroundColor: Theme.of(context).backgroundColor,
        body: ListView.builder(
          physics: BouncingScrollPhysics(),
          itemCount: _posts.length,
          itemBuilder: (BuildContext context, int index) {
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
