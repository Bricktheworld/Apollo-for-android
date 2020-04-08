import 'dart:async';

import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
import 'package:video_player/video_player.dart';
import 'package:transparent_image/transparent_image.dart';
import 'dart:convert';
import './hex_color.dart';
import './dismissible.dart';
import './comment_tree.dart';

class PostView extends StatefulWidget {
  final Submission submission;
  final CommentForest comments;
  final int numComments;
  PostView({
    Key key,
    this.submission,
    this.comments,
    this.numComments,
  }) : super(key: key);

  @override
  _PostViewState createState() => _PostViewState();
}

enum PostType {
  video,
  image,
  gif,
  text,
  link,
  unknown,
}

class _PostViewState extends State<PostView> {
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;
  double _expandedHeight = 80;
  CommentForest comments;
  CommentForest moreComments;
  List commentThreads = [];
  bool _upvoted = false;
  double offset = 0;
  bool _pastThreshold = false;
  String mediaLink = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initController();
    _upvoted = widget.submission.vote == VoteState.upvoted;
    if (widget.submission.comments == null) {
      widget.submission.refreshComments().whenComplete(() {
        setState(() {
          comments = widget.submission.comments;
          commentThreads = widget.submission.comments.comments;
          // debugPrint(comments.comments[1].replies.comments.length.toString());
        });
      });
    } else {
      comments = widget.submission.comments;
      commentThreads = widget.submission.comments.comments;
    }
  }

  _initController() {
    Map<String, dynamic> submissionJSON =
        jsonDecode(widget.submission.toString());
    if (widget.submission.data["secure_media"] != null &&
        widget.submission.data["secure_media"]["reddit_video"] != null) {
      _controller = VideoPlayerController.network(widget
          .submission.data["secure_media"]["reddit_video"]["fallback_url"]
          .toString());
    } else if (submissionJSON["crosspost_parent_list"] != null &&
        submissionJSON["crosspost_parent_list"][0]["secure_media"]
                ["reddit_video"] !=
            null) {
      _controller = VideoPlayerController.network(
          submissionJSON["crosspost_parent_list"][0]["secure_media"]
                  ["reddit_video"]["fallback_url"]
              .toString());
    }
    if (_controller == null) return;
    _initializeVideoPlayerFuture = _controller.initialize();
    _initializeVideoPlayerFuture.whenComplete(() {
      _expandedHeight = (_controller.value.size.height *
              MediaQuery.of(context).size.width /
              _controller.value.size.width)
          .clamp(0, MediaQuery.of(context).size.height * 4 / 5);
      setState(() {});
    });
  }

  Widget _buildVideo() {
    return SliverAppBar(
      leading: Container(),
      expandedHeight: _expandedHeight,
      floating: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Column(
          children: <Widget>[
            ClipRRect(
              child: FutureBuilder(
                future: _initializeVideoPlayerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    _controller.play();
                    _controller.setLooping(true);
                    debugPrint(_controller.value.size.height.toString());
                    // If the VideoPlayerController has finished initialization, use
                    // the data it provides to limit the aspect ratio of the VideoPlayer.
                    return ConstrainedBox(
                        constraints: BoxConstraints(
                            maxHeight:
                                MediaQuery.of(context).size.height * 4 / 5),
                        child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,

                            // Use the VideoPlayer widget to display the video.
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: <Widget>[
                                VideoPlayer(_controller),
                                VideoProgressIndicator(
                                  _controller,
                                  allowScrubbing: true,
                                )
                              ],
                            )));
                  } else {
                    // If the VideoPlayerController is still initializing, show a
                    // loading spinner.
                    return Center(
                      child: SizedBox(
                        height: 3,
                        width: MediaQuery.of(context).size.width,
                        child: LinearProgressIndicator(
                          backgroundColor: Theme.of(context).accentColor,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    Image image;
    image = Image.network(
      mediaLink,
      loadingBuilder: (BuildContext context, Widget child,
          ImageChunkEvent loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes
                : null,
          ),
        );
      },
    );
    Completer<Image> completer = Completer<Image>();
    image.image
        .resolve(new ImageConfiguration())
        .addListener(new ImageStreamListener((ImageInfo info, bool _) {
      setState(() {
        _expandedHeight = (info.image.height *
                MediaQuery.of(context).size.width /
                info.image.width)
            .clamp(0, MediaQuery.of(context).size.height * 4 / 5);
      });
      completer.complete();
    }));

    return SliverAppBar(
      leading: Container(),
      expandedHeight: _expandedHeight,
      floating: false,
      flexibleSpace: FlexibleSpaceBar(
        background: image,
      ),
    );
  }

  Widget _buildPostHeader() {
    return SliverToBoxAdapter(
      child: Container(
        child: Material(
          color: Theme.of(context).primaryColor,
          child: Container(
            padding: EdgeInsets.only(bottom: 20, left: 0, right: 0, top: 10),
            child: DismissibleCustom(
              background: Container(
                color: Theme.of(context).backgroundColor,
                padding: EdgeInsets.symmetric(horizontal: 20),
                alignment: AlignmentDirectional.center,
              ),
              secondaryBackground: Container(
                color: _getCurrentPullColor(),
                padding: EdgeInsets.only(right: 20),
                alignment: Alignment((1.2 + offset * 2), 0),
                child: Icon(
                  _getCurrentIcon(),
                  color: Colors.white,
                  size: 25,
                ),
              ),
              dismissThresholds: {
                DismissDirection.endToStart: 0.2,
                DismissDirection.startToEnd: 1,
              },
              onDismissed: (direction, extent) {
                double percentage =
                    extent.abs() / MediaQuery.of(context).size.width;
                if (percentage < 0.4) {
                  _toggleVote();
                }
              },
              onMove: (extent) {
                setState(() {
                  offset = extent / MediaQuery.of(context).size.width;
                  _pastThreshold = offset.abs() > 0.2;
                });
              },
              movementDuration: Duration(milliseconds: 200),
              key: Key(widget.submission.id),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.only(
                      right: 8,
                      left: 17,
                    ),
                    child: Row(
                      // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Flexible(
                          flex: 100,
                          child: Text(
                            widget.submission.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                      padding: EdgeInsets.only(
                        top: 20,
                        left: 20,
                        right: 20,
                      ),
                      child: Row(
                        children: <Widget>[
                          Text("r/" + widget.submission.subreddit.displayName,
                              style: TextStyle(
                                color: Theme.of(context).accentColor,
                                fontSize: 12,
                              )),
                          Spacer(
                            flex: 2,
                          ),
                          Text(widget.submission.author,
                              style: TextStyle(
                                color: Theme.of(context).accentColor,
                                fontSize: 12,
                              )),
                          Spacer(
                            flex: 2,
                          ),
                          Text(_timeSince(widget.submission.createdUtc),
                              style: TextStyle(
                                color: Theme.of(context).accentColor,
                                fontSize: 12,
                              )),
                          Spacer(
                            flex: 20,
                          )
                        ],
                      )),
                  Container(
                      padding: EdgeInsets.only(
                        top: 20,
                        left: 20,
                        right: 20,
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.arrow_upward,
                            color: _upvoted
                                ? Theme.of(context).secondaryHeaderColor
                                : Theme.of(context).accentColor,
                            size: 15,
                          ),
                          Spacer(
                            flex: 1,
                          ),
                          Text(widget.submission.upvotes.toString(),
                              style: TextStyle(
                                  color: _upvoted
                                      ? Theme.of(context).secondaryHeaderColor
                                      : Theme.of(context).accentColor,
                                  fontSize: 12)),
                          Spacer(
                            flex: 3,
                          ),
                          Icon(Icons.comment,
                              color: Theme.of(context).accentColor, size: 15),
                          Spacer(
                            flex: 1,
                          ),
                          Text(widget.submission.numComments.toString(),
                              style: TextStyle(
                                color: Theme.of(context).accentColor,
                                fontSize: 12,
                              )),
                          Spacer(flex: 40),
                        ],
                      ))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComments() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (comments.comments[index] is MoreComments) {
            debugPrint("is more comments");
            // moreComments = comments.comments[index].comments;
            return Container();
          }
          return CommentTree(
            comment: comments.comments[index],
          );
        },
        childCount: commentThreads.length,
      ),
    );
  }

  Widget _buildCommentLoadingIndicator() {
    return SliverToBoxAdapter(
      child: commentThreads.length > 0
          ? Container()
          : SizedBox(
              height: 3,
              width: MediaQuery.of(context).size.width,
              child: LinearProgressIndicator(
                backgroundColor: Theme.of(context).accentColor,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
    );
  }

  List<Widget> _buildSlivers() {
    if (_determinePostType(widget.submission) == PostType.video) {
      return <Widget>[
        _buildVideo(),
        _buildPostHeader(),
        _buildComments(),
        _buildCommentLoadingIndicator(),
        SliverFillRemaining(),
      ];
    } else if (_determinePostType(widget.submission) == PostType.image) {
      return <Widget>[
        _buildImage(),
        _buildPostHeader(),
        _buildComments(),
        _buildCommentLoadingIndicator(),
        SliverFillRemaining(),
      ];
    } else if (_determinePostType(widget.submission) == PostType.text) {
      return <Widget>[
        _buildPostHeader(),
        _buildComments(),
        _buildCommentLoadingIndicator(),
        SliverFillRemaining(),
      ];
    } else {
      return <Widget>[
        _buildPostHeader(),
        _buildComments(),
        _buildCommentLoadingIndicator(),
        SliverFillRemaining(),
      ];
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    if (_controller != null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: CustomAppBar(title: widget.submission.title),
      backgroundColor: Theme.of(context).backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: BouncingScrollPhysics(),
          slivers: _buildSlivers(),
        ),
      ),
    );
  }

  PostType _determinePostType(Submission post) {
    // debugPrint(post.toString());
    Map<String, dynamic> submission = jsonDecode(post.toString());
    //detecting crosspost
    if (submission["crosspost_parent_list"] != null) {
      debugPrint("cross Post");
      //detecting cross post containing media of some kind inside the "secure_media" tag in the json
      //this not being true does not necessarily mean that there is no video or media of some kind, weird quirk in how reddit handles these things
      if (submission["crosspost_parent_list"][0] != null &&
          submission["crosspost_parent_list"][0]["secure_media"] != null) {
        //if the "secure_media" tag contains "reddit_video" tag, then it means that the media type is a video
        if (submission["crosspost_parent_list"][0]["secure_media"]
                ["reddit_video"] !=
            null) {
          debugPrint("contains video: " +
              submission["crosspost_parent_list"][0]["secure_media"]
                      ["reddit_video"]["fallback_url"]
                  .toString());
          return PostType.video;
        } else {}
      }
    } else if (submission["secure_media"] != null) {
      if (submission["secure_media"]["reddit_video"] != null) {
        debugPrint("is a video: " +
            submission["secure_media"]["reddit_video"]["fallback_url"]
                .toString());
        return PostType.video;
      } else {
        if (post.url.toString() != null &&
            post.url.toString().contains("gfycat")) {
          debugPrint("is a gif: " + post.url.toString() + ".gif");
          mediaLink = post.url.toString();
          return PostType.gif;
        } else {
          debugPrint("is a picture: " + post.url.toString());
          mediaLink = post.url.toString();
          return PostType.image;
        }
      }
    } else {
      String link = post.url.toString();
      if (link.contains(".jpg") ||
          link.contains(".gif") ||
          link.contains(".png") ||
          link.contains(".jpeg")) {
        debugPrint("some kind of image/gif: " + post.url.toString());
        mediaLink = post.url.toString();
        return PostType.image;
      } else {
        debugPrint("not an image");
        return PostType.text;
      }
    }
  }

  _timeSince(DateTime date) {
    Duration difference = new DateTime.now().difference(date);

    if (difference.inDays / 365 > 1) {
      return (difference.inDays / 365).floor().toString() + " years ago";
    } else if (difference.inDays / 30 > 1) {
      return (difference.inDays / 30).floor().toString() + " months ago";
    }
    if (difference.inDays > 1) {
      return difference.inDays.toString() + " days ago";
    }
    if (difference.inHours > 1) {
      return difference.inHours.toString() + " hours ago";
    }
    if (difference.inMinutes > 1) {
      return difference.inMinutes.toString() + " minutes ago";
    }
    return difference.inSeconds.floor().toString() + " seconds ago";
  }

  Color _getCurrentPullColor() {
    if (_pastThreshold) {
      if (offset.abs() > 0.4) {
        return HexColor('#00AC37');
      } else {
        return Theme.of(context).secondaryHeaderColor;
      }
    } else {
      return Theme.of(context).backgroundColor;
    }
  }

  IconData _getCurrentIcon() {
    if (_pastThreshold) {
      if (offset.abs() > 0.4) {
        return Icons.bookmark;
      } else {
        return Icons.arrow_upward;
      }
    } else {
      return Icons.arrow_upward;
    }
  }

  _toggleVote() {
    if (widget.submission.vote == VoteState.upvoted) {
      try {
        widget.submission.clearVote();
        setState(() {
          _upvoted = false;
        });
        // _posts[index].clearVote();
      } catch (e) {}
    } else {
      try {
        // widget.upVote();
        widget.submission.upvote();
        setState(() {
          _upvoted = true;
        });
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }
}
