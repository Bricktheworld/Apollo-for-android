import 'package:apollo/custom_app_bar.dart';
import 'package:apollo/dismissible.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:draw/draw.dart';
import '../slidable_list_tile.dart';
import '../AuthModel.dart';
import '../post_view.dart';
import '../page_route.dart';

class FrontPageView extends StatefulWidget {
  @required
  final AuthModel model;

  const FrontPageView({Key key, this.model}) : super(key: key);

  @override
  _FrontPageViewState createState() => _FrontPageViewState();
}

class _FrontPageViewState extends State<FrontPageView> {
  List<Submission> _posts = <Submission>[];
  Redditor currentUser;
  StreamSubscription<UserContent> stream;
  var _postsTemp = <Submission>[];
  bool _alreadyLoading = true;
  double _offset = 0.0;
  listen() async {
    if (stream != null) stream.cancel();
    _posts = <Submission>[];
    setState(() {});

    _loadPosts();
    // THIS ISN'T SLOW FOR SOME REASON?????????
  }

  _loadPosts() {
    int i = 0;
    String after;
    if (_posts.length > 1) {
      after = _posts.last.fullname;
    } else {
      after = null;
    }
    if (stream != null) stream.cancel();
    stream = widget.model.reddit.front
        .best(limit: 25, after: after)
        .listen((s) async {
      if (!_posts.contains(s)) {
        i++;
        _posts.add(s);

        if (i >= 25) {
          if (this.mounted) setState(() {});
          _alreadyLoading = false;
          stream.cancel();
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    listen();
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
      child: Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        appBar: CustomAppBar(title: 'FrontPage'),
        body: _buildList(),
      ),
    );
  }

  _buildList() {
    return Container(
      color: Theme.of(context).backgroundColor,
      child: RefreshIndicator(
        onRefresh: () async {},
        child: ListView.builder(
          shrinkWrap: false,
          physics: BouncingScrollPhysics(),
          itemCount: _posts.length,
          itemBuilder: (BuildContext context, int index) {
            if (index > _posts.length - 10 && !_alreadyLoading) {
              _alreadyLoading = true;
              debugPrint("loading more: " + _posts.length.toString());
              _loadPosts();
            }
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
                  TransparentRoute(
                    builder: (context) => PostView(
                      submission: post,
                      comments: post.comments,
                      numComments: post.numComments,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      // floatingActionButton: Padding(
      //   padding: const EdgeInsets.only(bottom: 60),
      //   child: FloatingActionButton(
      //     onPressed: () async {
      //       if (widget.model.reddit != null) {
      //         _posts = <Submission>[];
      //         setState(() {});
      //         _loadPosts();
      //       } else {
      //         widget.model.login(context, listen);
      //       }
      //     },
      //     child: Icon(Icons.refresh),
      //     backgroundColor: Theme.of(context).secondaryHeaderColor,
      //   ),
      // ),
    );
  }
}
