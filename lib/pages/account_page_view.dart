import 'package:apollo/AuthModel.dart';
import 'package:apollo/account_views/downvoted_posts_view.dart';
import 'package:apollo/account_views/submitted_comments_view.dart';
import 'package:apollo/account_views/submitted_posts_view.dart';
import 'package:apollo/account_views/upvoted_posts_view.dart';
import 'package:apollo/post_view.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:draw/draw.dart';
import '../custom_app_bar.dart';
import '../hex_color.dart';
import '../account_views/saved_posts_view.dart';

class AccountPageView extends StatefulWidget {
  final AuthModel model;
  AccountPageView({Key key, this.model}) : super(key: key);

  @override
  _AccountPageViewState createState() => _AccountPageViewState();
}

class _AccountPageViewState extends State<AccountPageView> {
  StreamSubscription<UserContent> _stream;
  List<Submission> _posts = <Submission>[];
  Redditor _redditor;
  String _accountAge = "Loading...";
  String _postKarma = "Loading...";
  String _commentKarma = "Loading...";
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initUserData();
  }

  _initUserData() async {
    _redditor = await widget.model.reddit.user.me();
    setState(() {
      _accountAge = _timeSince(_redditor.createdUtc);
      _postKarma = _readableInts(_redditor.linkKarma);
      _commentKarma = _readableInts(_redditor.commentKarma);
    });
    // _loadPosts();
  }

  _loadPosts() async {
    int i = 0;
    String after;
    if (_posts.length > 1) {
      after = _posts.last.fullname;
    } else {
      after = null;
    }
    if (_stream != null) _stream.cancel();
    _stream = _redditor.saved(limit: 25, after: after).listen((s) async {
      if (i >= 25) {
        if (this.mounted) setState(() {});
        _stream.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: CustomAppBar(title: 'Account'),
        body: CustomScrollView(
          physics: BouncingScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.only(top: 20),
                height: 120,
                child: Row(
                  children: <Widget>[
                    _buildInfoColumn(_commentKarma, "Comment Karma"),
                    _buildInfoColumn(_postKarma, "Post Karma"),
                    _buildInfoColumn(_accountAge, "Account Age"),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  switch (index) {
                    case 0:
                      return Material(
                        color: Theme.of(context).primaryColor,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SubmittedPostsView(
                                        currentUser: _redditor,
                                      )),
                            );
                          },
                          child: ListTile(
                            leading: Icon(
                              Icons.chrome_reader_mode,
                              color: HexColor("2399FF"),
                            ),
                            title: Text(
                              "Posts",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 13),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: Theme.of(context).accentColor,
                              size: 15,
                            ),
                          ),
                        ),
                      );
                      break;
                    case 1:
                      return Material(
                        color: Theme.of(context).primaryColor,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SubmittedCommentsView(
                                        currentUser: _redditor,
                                      )),
                            );
                          },
                          child: ListTile(
                            leading: Icon(
                              Icons.comment,
                              color: HexColor("2399FF"),
                            ),
                            title: Text(
                              "Comments",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 13),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: Theme.of(context).accentColor,
                              size: 15,
                            ),
                          ),
                        ),
                      );
                      break;
                    case 2:
                      return Material(
                        color: Theme.of(context).primaryColor,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SavedPostsView(
                                        currentUser: _redditor,
                                      )),
                            );
                          },
                          child: ListTile(
                            leading: Icon(
                              Icons.bookmark,
                              color: HexColor("2399FF"),
                            ),
                            title: Text(
                              "Saved",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 13),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: Theme.of(context).accentColor,
                              size: 15,
                            ),
                          ),
                        ),
                      );
                      break;
                    case 3:
                      return Material(
                        color: Theme.of(context).primaryColor,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => UpvotedPostsView(
                                        currentUser: _redditor,
                                      )),
                            );
                          },
                          child: ListTile(
                            leading: Icon(
                              Icons.arrow_upward,
                              color: HexColor("2399FF"),
                            ),
                            title: Text(
                              "Upvoted",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 13),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: Theme.of(context).accentColor,
                              size: 15,
                            ),
                          ),
                        ),
                      );
                      break;
                    case 4:
                      return Material(
                        color: Theme.of(context).primaryColor,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DownvotedPostsView(
                                        currentUser: _redditor,
                                      )),
                            );
                          },
                          child: ListTile(
                            leading: Icon(
                              Icons.arrow_downward,
                              color: HexColor("2399FF"),
                            ),
                            title: Text(
                              "Downvoted",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 13),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: Theme.of(context).accentColor,
                              size: 15,
                            ),
                          ),
                        ),
                      );
                      break;
                    default:
                      return Container();
                  }
                },
                childCount: 5,
              ),
            )
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 60),
          child: FloatingActionButton(
            onPressed: () async {
              if (widget.model.reddit != null) {
                _posts = <Submission>[];
                setState(() {});
                await _initUserData();
              } else {
                widget.model.login(context, _initUserData);
              }
            },
            child: Icon(Icons.refresh),
            backgroundColor: Theme.of(context).secondaryHeaderColor,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String data, String type) {
    return Container(
      width: MediaQuery.of(context).size.width / 3,
      height: MediaQuery.of(context).size.height / 5,
      child: Column(
        children: <Widget>[
          Text(
            data,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
          Text(
            type,
            style: TextStyle(
              color: Theme.of(context).accentColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _timeSince(DateTime date) {
    Duration difference = new DateTime.now().difference(date);

    if (difference.inDays / 365 > 1) {
      return (difference.inDays / 365).toStringAsFixed(1) + "y";
    }
    if (difference.inDays / 30 > 1) {
      return (difference.inDays / 30).toStringAsFixed(1) + "m";
    }
    if (difference.inDays > 1) {
      return difference.inDays.toString() + "d";
    }
    if (difference.inHours > 1) {
      return difference.inHours.toString() + "h";
    }
    if (difference.inMinutes > 1) {
      return difference.inMinutes.toString() + "m";
    }
    return difference.inSeconds.floor().toString() + "s";
  }

  String _readableInts(int input) {
    if (input >= 1000) {
      return (input / 1000).toStringAsFixed(1) + "k";
    } else {
      return input.toString();
    }
  }
}
