import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
import './dismissible.dart';
import 'dart:core';
import './hex_color.dart';
import 'package:http/http.dart';
import 'package:transparent_image/transparent_image.dart';

class SlidableListTile extends StatefulWidget {
  final Submission post;
  final Function clearVote;
  final Function upVote;
  final Function onTap;

  const SlidableListTile(
      {Key key, this.post, this.clearVote, this.upVote, this.onTap})
      : super(key: key);

  @override
  _SlidableListTileState createState() => _SlidableListTileState();
}

class _SlidableListTileState extends State<SlidableListTile> {
  double offset = 0;
  bool _pastThreshold = false;
  bool upvoted = false;

  @override
  void initState() {
    super.initState();
    upvoted = widget.post.vote == VoteState.upvoted;
  }

  bool _toggleVote() {
    if (widget.post.vote == VoteState.upvoted) {
      try {
        widget.clearVote();
        setState(() {
          upvoted = false;
        });
        // _posts[index].clearVote();
      } catch (e) {}
    } else {
      try {
        widget.upVote();
        setState(() {
          upvoted = true;
        });
      } catch (e) {}
    }
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

  @override
  Widget build(BuildContext context) {
    return DismissibleCustom(
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
        double percentage = extent.abs() / MediaQuery.of(context).size.width;
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
      key: Key(widget.post.id),
      child: Container(
        padding: EdgeInsets.all(0),
        child: Material(
          color: Theme.of(context).primaryColor,
          // elevation: 2,
          child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                if (widget.onTap != null) widget.onTap();
              },
              child: Row(
                children: <Widget>[
                  (widget.post.thumbnail) == null
                      ? Icon(Icons.filter)
                      : Container(
                          alignment: Alignment.topCenter,
                          padding: EdgeInsets.all(10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: FadeInImage.memoryNetwork(
                                placeholder: kTransparentImage,
                                fadeInDuration: Duration(milliseconds: 500),
                                image: widget.post.thumbnail.toString(),
                                width: 80,
                                height: 80,
                                fit: BoxFit.fitHeight),
                          ),
                        ),
                  Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Container(
                            alignment: Alignment(-1, 0),
                            child: Text(widget.post.title,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13))),
                        Container(
                          margin: const EdgeInsets.only(
                            top: 10,
                            left: 0,
                            right: 0,
                            bottom: 0,
                          ),
                          child: Column(
                            children: <Widget>[
                              Container(
                                  alignment: Alignment(-1, 0),
                                  child: Text(
                                    widget.post.subreddit.displayName,
                                    style: TextStyle(
                                        color: Theme.of(context).accentColor,
                                        fontSize: 11),
                                  )),
                              Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.arrow_upward,
                                    color: upvoted
                                        ? Theme.of(context).secondaryHeaderColor
                                        : Theme.of(context).accentColor,
                                    size: 15,
                                  ),
                                  Spacer(
                                    flex: 1,
                                  ),
                                  Text(
                                    widget.post.upvotes.toString(),
                                    style: TextStyle(
                                      color: upvoted
                                          ? Theme.of(context)
                                              .secondaryHeaderColor
                                          : Theme.of(context).accentColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Spacer(
                                    flex: 3,
                                  ),
                                  Icon(
                                    Icons.comment,
                                    color: Theme.of(context).accentColor,
                                    size: 13,
                                  ),
                                  Spacer(
                                    flex: 1,
                                  ),
                                  Text(
                                    widget.post.numComments.toString(),
                                    style: TextStyle(
                                      color: Theme.of(context).accentColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Spacer(
                                    flex: 20,
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    // alignment: AlignmentDirectional(-1, 1),
                    width: 240,
                  ),
                ],
              )),
        ),
      ),
    );
  }
}
