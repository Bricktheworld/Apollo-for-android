import 'package:apollo/custom_app_bar.dart';
import 'package:apollo/slidable_comment_tile.dart';
import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
import 'dart:async';

import '../dismissible.dart';
import '../post_view.dart';
import '../slidable_list_tile.dart';

class SubmittedCommentsView extends StatefulWidget {
  final Redditor currentUser;

  SubmittedCommentsView({Key key, this.currentUser}) : super(key: key);

  @override
  _SubmittedCommentsViewState createState() => _SubmittedCommentsViewState();
}

class _SubmittedCommentsViewState extends State<SubmittedCommentsView> {
  List _posts = [];
  StreamSubscription<UserContent> _stream;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  _loadPosts() async {
    debugPrint("loading");
    if (_stream != null) _stream.cancel();
    _stream = widget.currentUser.stream.comments().listen((s) async {
      _posts.insert(0, s);
      if (this.mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return DismissibleCustom(
      dismissThresholds: {
        DismissDirection.startToEnd: 0.3,
      },
      key: Key('subreddit_post_view'),
      onDismissed: (direction, amount) {
        Navigator.pop(context);
      },
      direction: DismissDirection.startToEnd,
      onMove: (amount) {
        debugPrint(amount.toString());
      },
      child: Container(
        child: Scaffold(
          appBar: CustomAppBar(
            title: "Comments",
          ),
          backgroundColor: Theme.of(context).backgroundColor,
          body: ListView.builder(
            physics: BouncingScrollPhysics(),
            itemCount: _posts.length,
            itemBuilder: (BuildContext context, int index) {
              if (_posts[index] is Comment) {
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
      ),
    );
  }
}
