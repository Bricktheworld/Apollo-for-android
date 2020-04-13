import 'dart:async';
import 'dart:io';

import 'package:apollo/AuthModel.dart';
import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
import 'package:video_player/video_player.dart';
import 'package:markd/markdown.dart' as Markdown;
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:convert';
import './comment_tree.dart';
import './pages/popup_web_view.dart';
import './link_previewer/link_previewer.dart';
import './link_previewer/content_direction.dart';

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
  album,
  youtube,
  gif,
  text,
  link,
  loading,
}

class _PostViewState extends State<PostView> {
  VideoPlayerController _controller;
  YoutubePlayerController _youtubePlayerController;
  Future<void> _initializeVideoPlayerFuture;
  double _expandedHeight = 80;
  bool _videoLoaded = false;
  CommentForest comments;
  CommentForest moreComments;
  List commentThreads = [];
  bool _upvoted = false;
  double offset = 0;
  bool _pastThreshold = false;
  var _mediaLink;
  String _body = "";
  PostType _postType = PostType.loading;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initPostMedia();
    _upvoted = widget.submission.vote == VoteState.upvoted;
    if (widget.submission.comments == null) {
      widget.submission.refreshComments().whenComplete(() {
        if (this.mounted)
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

  _initPostMedia() async {
    await _determinePostType(widget.submission).whenComplete(() {
      debugPrint("completed: " + _postType.toString());
      if (_postType == PostType.video) {
        _controller = VideoPlayerController.network(_mediaLink);
      } else if (_postType == PostType.youtube) {
        _youtubePlayerController = YoutubePlayerController(
          initialVideoId: YoutubePlayer.convertUrlToId(_mediaLink),
          flags: YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            controlsVisibleAtStart: true,
          ),
        );
      }
      if (this.mounted) setState(() {});
      if (_controller != null) {
        _initializeVideoPlayerFuture = _controller.initialize();
        _initializeVideoPlayerFuture.whenComplete(() {
          _expandedHeight = (_controller.value.size.height *
                  MediaQuery.of(context).size.width /
                  _controller.value.size.width)
              .clamp(0, MediaQuery.of(context).size.height * 4 / 5);
          _videoLoaded = true;
          if (this.mounted) setState(() {});
        });
      }
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
                          ],
                        ),
                      ),
                    );
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

  Widget _buildYoutubeVideo() {
    return SliverAppBar(
      leading: Container(),
      expandedHeight: _expandedHeight,
      floating: false,
      flexibleSpace: FlexibleSpaceBar(
        background: YoutubePlayer(
          controller: _youtubePlayerController,
          showVideoProgressIndicator: true,
          progressColors: ProgressBarColors(
            playedColor: Colors.amber,
            handleColor: Colors.amberAccent,
          ),
          onReady: () {
            setState(() {
              //TODO make this not just 1920 x 1080 aspect ratio hard coded
              _expandedHeight = 1080 * MediaQuery.of(context).size.width / 1920;
            });
            debugPrint(_youtubePlayerController.value.toString());
            // _youtubePlayerController.addListener(() {
            //   debugPrint("some listener");
            // });
          },
        ),
      ),
    );
  }

  Widget _buildVideoScrubber() {
    if (!_videoLoaded) {
      return SliverToBoxAdapter(
        child: Container(),
      );
    } else {
      return SliverToBoxAdapter(
        child: Container(
          child: VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
          ),
        ),
      );
    }
  }

  Widget _buildImage() {
    Image image;
    image = Image.network(
      _mediaLink,
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
    image.image
        .resolve(new ImageConfiguration())
        .addListener(new ImageStreamListener((ImageInfo info, bool _) {
      if (!this.mounted) return;
      setState(() {
        _expandedHeight = (info.image.height *
                MediaQuery.of(context).size.width /
                info.image.width)
            .clamp(0, MediaQuery.of(context).size.height * 4 / 5);
      });
      // completer.complete();
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

  Widget _buildLink() {
    return SliverToBoxAdapter(
      child: Container(
        color: Theme.of(context).primaryColor,
        padding: EdgeInsets.all(10),
        child: LinkPreviewer(
          borderColor: Theme.of(context).accentColor,
          backgroundColor: Theme.of(context).primaryColor,
          link: _mediaLink,
          direction: ContentDirection.horizontal,
          placeholder: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildAlbum() {
    List<Image> images = <Image>[];
    List<double> heights = <double>[];
    for (int i = 0; i < _mediaLink.length; i++) {
      heights.add(80);
      images.add(Image.network(
        _mediaLink[i],
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
      ));
      images[i]
          .image
          .resolve(new ImageConfiguration())
          .addListener(new ImageStreamListener((ImageInfo info, bool _) {
        heights[i] = (info.image.height *
                MediaQuery.of(context).size.width /
                info.image.width)
            .clamp(0, MediaQuery.of(context).size.height * 4 / 5);
        if (i == 0) {
          setState(() {
            _expandedHeight = heights[i];
          });
        }
        // completer.complete();
      }));
    }
    return SliverAppBar(
      leading: Container(),
      expandedHeight: _expandedHeight,
      floating: false,
      flexibleSpace: FlexibleSpaceBar(
        background: PageView.builder(
          physics: BouncingScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            if (index >= images.length) {
              return Container();
            }
            return images[index];
          },
          itemCount: images.length,
          onPageChanged: (int index) {
            setState(() {
              _expandedHeight = heights[index];
            });
          },
        ),
      ),
    );
  }

  Widget _buildPostHeader() {
    return SliverToBoxAdapter(
      child: Container(
        child: Material(
          color: Theme.of(context).primaryColor,
          child: Container(
            padding: EdgeInsets.only(bottom: 0, left: 0, right: 0, top: 20),
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
                    top: 10,
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
                  ),
                ),
                Container(
                  color: Theme.of(context).primaryColor,
                  padding: EdgeInsets.only(bottom: 15, right: 20, left: 20),
                  child: Html(
                    data: Markdown.markdownToHtml(
                      _body,
                      extensionSet: Markdown.ExtensionSet.gitHubWeb,
                      inlineSyntaxes: [
                        Markdown.CodeSyntax(),
                        Markdown.AutolinkExtensionSyntax()
                      ],
                      blockSyntaxes: [
                        Markdown.BlockquoteSyntax(),
                        Markdown.CodeBlockSyntax(),
                      ],
                    ),
                    defaultTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    onLinkTap: (String url) {
                      debugPrint(url);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PopupWebView(url: url),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostInfo() {
    return SliverToBoxAdapter(
        child: Container(
            // color: Theme.of(context).primaryColor,
            padding: EdgeInsets.only(
              top: 10,
              left: 20,
              right: 20,
              bottom: 10,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              border: Border(
                top: BorderSide(
                  width: 0.25,
                  color: Theme.of(context).accentColor.withOpacity(0.5),
                ),
                bottom: BorderSide(
                  width: 0.25,
                  color: Theme.of(context).accentColor.withOpacity(0.5),
                ),
              ),
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
            )));
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
    if (_postType == PostType.video) {
      return <Widget>[
        _buildVideo(),
        _buildVideoScrubber(),
        _buildPostHeader(),
        _buildPostInfo(),
        _buildComments(),
        _buildCommentLoadingIndicator(),
        SliverFillRemaining(),
      ];
    } else if (_postType == PostType.youtube) {
      return <Widget>[
        _buildYoutubeVideo(),
        _buildPostHeader(),
        _buildPostInfo(),
        _buildComments(),
        _buildCommentLoadingIndicator(),
        SliverFillRemaining(),
      ];
    } else if (_postType == PostType.image) {
      return <Widget>[
        _buildImage(),
        _buildPostHeader(),
        _buildPostInfo(),
        _buildComments(),
        _buildCommentLoadingIndicator(),
        SliverFillRemaining(),
      ];
    } else if (_postType == PostType.text) {
      return <Widget>[
        _buildPostHeader(),
        _buildPostInfo(),
        _buildComments(),
        _buildCommentLoadingIndicator(),
        SliverFillRemaining(),
      ];
    } else if (_postType == PostType.link) {
      return <Widget>[
        _buildPostHeader(),
        _buildLink(),
        _buildPostInfo(),
        _buildComments(),
        _buildCommentLoadingIndicator(),
        SliverFillRemaining(),
      ];
    } else if (_postType == PostType.album) {
      return <Widget>[
        _buildAlbum(),
        _buildPostHeader(),
        _buildPostInfo(),
        _buildComments(),
        _buildCommentLoadingIndicator(),
        SliverFillRemaining(),
      ];
    } else {
      return <Widget>[
        _buildPostHeader(),
        _buildPostInfo(),
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

  Future<PostType> _determinePostType(Submission post) async {
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
          _mediaLink = submission["crosspost_parent_list"][0]["secure_media"]
                  ["reddit_video"]["fallback_url"]
              .toString();
          _postType = PostType.video;
        } else {}
      }
    } else if (submission["secure_media"] != null) {
      if (submission["secure_media"]["reddit_video"] != null) {
        debugPrint("is a video: " +
            submission["secure_media"]["reddit_video"]["fallback_url"]
                .toString());
        _mediaLink = widget
            .submission.data["secure_media"]["reddit_video"]["fallback_url"]
            .toString();
        _postType = PostType.video;
      } else if (submission["secure_media"]["type"] == "youtube.com") {
        _mediaLink = post.url.toString();
        // debugPrint("youtube needs to be implemented");
        _postType = PostType.youtube;
      } else {
        if (post.url.toString() != null &&
            post.url.toString().contains("gfycat")) {
          // debugPrint("is a gfycat: " + post.url.toString());

          _mediaLink = await _fixGfycatUrl(post.url);
          // debugPrint(_mediaLink);
          _postType = PostType.video;
        } else if (post.url.toString().contains("imgur")) {
          await _imgurBullshit(post);
        }
      }
    } else if (post.url.toString().contains("imgur")) {
      await _imgurBullshit(post);
    } else if (submission["selftext"] != "") {
      _body = submission["selftext"].replaceAll('&gt;', '>');
      return PostType.text;
    } else {
      String link = post.url.toString();
      if (link.contains(".jpg") ||
          link.contains(".gif") ||
          link.contains(".png") ||
          link.contains(".jpeg")) {
        debugPrint("some kind of image/gif: " + post.url.toString());
        _mediaLink = post.url.toString();
        _postType = PostType.image;
      } else {
        debugPrint("fallback to link: " + post.toString());
        _mediaLink = post.url.toString();
        _postType = PostType.link;
      }
    }
  }

  _imgurBullshit(post) async {
    _mediaLink = post.url.toString();
    String url = "";
    if (_mediaLink.contains("/a/")) {
      String id = _mediaLink.substring(
          _mediaLink.indexOf("/a/") + 3, _mediaLink.length);
      url = "https://api.imgur.com/3/album/" + id + "/images";
      debugPrint(url);
      var response = await http.get(url, headers: {
        HttpHeaders.authorizationHeader: "Client-ID 995c8e71e9eeafd"
      });
      var responseJson = json.decode(response.body);
      debugPrint(responseJson["data"].length.toString());
      if (responseJson["data"].length == 1) {
        if (responseJson["data"][0]["link"].toString().contains(".mp4")) {
          _mediaLink = responseJson["data"][0]["link"].toString();
          _postType = PostType.video;
        } else {
          _mediaLink = responseJson["data"][0]["link"].toString();
          _postType = PostType.image;
        }
      } else {
        debugPrint(responseJson.toString());
        List<String> links = <String>[];
        for (int i = 0; i < responseJson["data"].length; i++) {
          links.add(responseJson["data"][i]["link"].toString());
          // debugPrint(responseJson["data"][i]["link"].toString());
        }
        _mediaLink = links;
        _postType = PostType.album;
      }
    } else {
      String id = _mediaLink.substring(_mediaLink.indexOf("imgur.com") + 9);
      url = "https://api.imgur.com/3/image/" + id;
      debugPrint(url);
      var response = await http.get(url, headers: {
        HttpHeaders.authorizationHeader: "Client-ID 995c8e71e9eeafd"
      });
      var responseJson = json.decode(response.body);
      debugPrint(responseJson["data"].length.toString());
      if (responseJson["data"]["link"].toString().contains(".mp4")) {
        _mediaLink = responseJson["data"]["link"].toString();
        _postType = PostType.video;
      } else {
        _mediaLink = responseJson["data"]["link"].toString();
        _postType = PostType.image;
      }
    }
  }

  Future<String> _fixGfycatUrl(Uri uri) async {
    RegExp videoNameParser = new RegExp("[a-z]+", caseSensitive: false);
    var videoname = videoNameParser.firstMatch(uri.path).group(0);
    var api = "https://api.gfycat.com/v1/gfycats/$videoname";

    var result = await http.get(api);
    Map decodedResult = jsonDecode(result.body)["gfyItem"];

    // debugPrint(result.body.toString());

    assert(decodedResult != null, result.body);

    debugPrint(decodedResult["mp4Url"].toString());
    return decodedResult["mp4Url"].toString();
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
}
