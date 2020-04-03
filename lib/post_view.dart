import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
import 'package:video_player/video_player.dart';
import 'dart:convert';
import 'package:transparent_image/transparent_image.dart';
import './AuthModel.dart';
import './custom_app_bar.dart';
import './slidable_comment_tile.dart';

class PostView extends StatefulWidget {
  Submission submission;
  PostView({Key key, this.submission}) : super(key: key);

  @override
  _PostViewState createState() => _PostViewState();
}

class _PostViewState extends State<PostView> {
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;
  double _expandedHeight = 200;
  int numComments = 0;
  List comments = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initController();
    widget.submission.refreshComments().whenComplete(() {
      setState(() {
        comments = widget.submission.comments.toList();
        numComments = comments.length;
      });
    });
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

  Widget _determinePostType(Submission post) {
    debugPrint(post.toString());
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
          return FutureBuilder(
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
                        maxHeight: MediaQuery.of(context).size.height * 4 / 5),
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
                return Center(child: CircularProgressIndicator());
              }
            },
          );
        } else {}
      }
    } else if (submission["secure_media"] != null) {
      if (submission["secure_media"]["reddit_video"] != null) {
        debugPrint("is a video: " +
            submission["secure_media"]["reddit_video"]["fallback_url"]
                .toString());
        return FutureBuilder(
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
                      maxHeight: MediaQuery.of(context).size.height * 4 / 5),
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
              return Center(child: CircularProgressIndicator());
            }
          },
        );
      } else {
        if (post.url.toString() != null &&
            post.url.toString().contains("gfycat")) {
          debugPrint("is a gif: " + post.url.toString() + ".gif");
        } else {
          debugPrint("is a picture: " + post.url.toString());
        }
      }
    } else {
      String link = post.url.toString();
      if (link.contains(".jpg") ||
          link.contains(".gif") ||
          link.contains(".png") ||
          link.contains(".jpeg")) {
        debugPrint("some kind of image/gif: " + post.url.toString());
        // return FadeInImage.memoryNetwork(
        //     placeholder: kTransparentImage, image: post.url.toString());
      } else {
        debugPrint("not an image");
      }
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    if (_controller != null) _controller.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: CustomAppBar(title: widget.submission.title),
      backgroundColor: Theme.of(context).backgroundColor,
      body: CustomScrollView(
        // physics: BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: _expandedHeight,
            floating: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                children: <Widget>[
                  ClipRRect(
                    child: _determinePostType(widget.submission),
                    // Image.network(
                    //   widget.submission.thumbnail.toString(),
                    //   height: MediaQuery.of(context).size.height / 3.6,
                    //   width: MediaQuery.of(context).size.width,
                    //   fit: BoxFit.cover,
                    // ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
              child: Container(
            child: Material(
                color: Theme.of(context).primaryColor,
                child: Container(
                    padding:
                        EdgeInsets.only(bottom: 20, left: 0, right: 0, top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.only(
                            right: 20,
                            left: 20,
                          ),
                          child: Row(
                            // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Icon(
                                Icons.arrow_upward,
                                color: Theme.of(context).accentColor,
                              ),
                              Text(widget.submission.upvotes.toString(),
                                  style: TextStyle(
                                      color: Theme.of(context).accentColor,
                                      fontSize: 20)),
                              Spacer(flex: 3),
                              Flexible(
                                  flex: 100,
                                  child: Text(widget.submission.title,
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 20))),
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
                                Text(
                                    "r/" +
                                        widget.submission.subreddit.displayName,
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
                                Icon(Icons.comment,
                                    color: Theme.of(context).accentColor,
                                    size: 15),
                                Spacer(
                                  flex: 1,
                                ),
                                Text(numComments.toString(),
                                    style: TextStyle(
                                      color: Theme.of(context).accentColor,
                                      fontSize: 12,
                                    )),
                                Spacer(flex: 40),
                              ],
                            ))
                      ],
                    ))),
          )),
          SliverFillRemaining(
            child: RefreshIndicator(
              onRefresh: () async {},
              child: ListView.builder(
                itemCount: numComments,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Text("test"),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
